import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const endpoint=process.argv[2];
if(!endpoint)throw Error('Usage: node scripts/render-preview.mjs http://BROWSER_HOST:9222 (uses the active browser tab)');
const tabs=await (await fetch(`${endpoint}/json/list`)).json();
const tab=tabs.find(t=>t.type==='page');
if(!tab)throw Error('No browser page');
const ws=new WebSocket(tab.webSocketDebuggerUrl);
await new Promise((resolve,reject)=>{ws.onopen=resolve;ws.onerror=reject});
let id=0;const pending=new Map();
ws.onmessage=({data})=>{const m=JSON.parse(data);if(m.id){const p=pending.get(m.id);pending.delete(m.id);m.error?p.reject(Error(JSON.stringify(m.error))):p.resolve(m.result)}};
const send=(method,params={})=>new Promise((resolve,reject)=>{const i=++id;pending.set(i,{resolve,reject});ws.send(JSON.stringify({id:i,method,params}))});
const fonts=fs.readFileSync(`${root}/fonts/fonts.css`,'utf8').replace(/url\('([^']+)'\)/g,(_,p)=>`url('data:font/woff2;base64,${fs.readFileSync(`${root}/fonts/${p}`).toString('base64')}')`);
function inline(file){const dir=path.dirname(file);return fs.readFileSync(file,'utf8').replace(/<link rel="stylesheet" href="[^"]*fonts\/fonts.css">/,`<style>${fonts}</style>`).replace(/<link rel="stylesheet" href="landing.css">/,`<style>${fs.readFileSync(`${root}/landing.css`,'utf8')}</style>`).replace(/src="([^"\s]*favicon.svg)"/g,(_,p)=>`src="data:image/svg+xml;base64,${fs.readFileSync(path.resolve(dir,p)).toString('base64')}"`)}
await send('Page.enable');await send('Runtime.enable');
async function render(file,width,height,out){await send('Emulation.setDeviceMetricsOverride',{width,height,deviceScaleFactor:1,mobile:false});await send('Page.navigate',{url:'about:blank'});const {frameTree}=await send('Page.getFrameTree');await send('Page.setDocumentContent',{frameId:frameTree.frame.id,html:inline(file)});await send('Runtime.evaluate',{expression:'document.fonts.ready',awaitPromise:true});const {data}=await send('Page.captureScreenshot',{format:'png',captureBeyondViewport:false});fs.writeFileSync(out,Buffer.from(data,'base64'));}
await render(`${root}/assets/social-card.html`,1200,630,`${root}/social-card.png`);
for(const width of [1440,390,320]){await render(`${root}/index.html`,width,1000,`/tmp/agenthub-${width}.png`);const {result}=await send('Runtime.evaluate',{expression:`JSON.stringify({width:innerWidth,scrollWidth:document.documentElement.scrollWidth,h1:document.querySelectorAll('h1').length,title:document.title,details:document.querySelectorAll('details').length,missingAnchors:[...document.querySelectorAll('a[href^="#"]')].filter(a=>!document.getElementById(a.hash.slice(1))).map(a=>a.hash)})`});console.log(result.value);const check=JSON.parse(result.value);if(check.scrollWidth>width||check.h1!==1||check.missingAnchors.length)throw Error('Layout/semantics check failed');}
await send('Page.bringToFront');
await send('Emulation.setFocusEmulationEnabled',{enabled:true});
const before=await send('Runtime.evaluate',{expression:"document.querySelector('.faq-list summary').focus(); document.querySelector('.faq-list details').open"});
await send('Input.dispatchKeyEvent',{type:'keyDown',key:'Enter',code:'Enter',windowsVirtualKeyCode:13,text:'\r'});
await send('Input.dispatchKeyEvent',{type:'keyUp',key:'Enter',code:'Enter',windowsVirtualKeyCode:13});
await send('Runtime.evaluate',{expression:'new Promise(r=>requestAnimationFrame(()=>requestAnimationFrame(r)))',awaitPromise:true});
const after=await send('Runtime.evaluate',{expression:"document.querySelector('.faq-list details').open"});
if(before.result.value===after.result.value){console.log(await send('Runtime.evaluate',{expression:JSON.stringify('JSON.stringify({active:document.activeElement.outerHTML,focus:document.hasFocus(),open:document.querySelector(".faq-list details").open})')}));throw Error('FAQ keyboard toggle failed');}
console.log('PASS: native FAQ toggles with Enter');
await send('Emulation.setDeviceMetricsOverride',{width:1440,height:1000,deviceScaleFactor:1,mobile:false});ws.close();
