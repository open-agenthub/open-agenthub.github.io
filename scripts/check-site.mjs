import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
const root=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const html=fs.readFileSync(path.join(root,'index.html'),'utf8');
assert.equal((html.match(/<h1[ >]/g)||[]).length,1,'One main heading');
assert.match(html,/<html lang="en">/);
assert.match(html,/<meta name="description" content="[^"]+">/);
assert.match(html,/<link rel="canonical" href="https:\/\/open-agenthub.github.io\/">/);
assert.doesNotMatch(html,/\{\{|<x-dc|support\.js/,'Homepage must render without the old JS runtime');
const schema=JSON.parse(html.match(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/)[1]);
assert.equal(schema.name,'Open AgentHub');
const ids=new Set([...html.matchAll(/\bid="([^"]+)"/g)].map(m=>m[1]));
for(const [,url] of html.matchAll(/(?:href|src)="([^"]+)"/g)){
  if(url.startsWith('#'))assert.ok(ids.has(url.slice(1)),`Missing anchor ${url}`);
  else if(!/^[a-z]+:/i.test(url))assert.ok(fs.existsSync(path.resolve(root,url)),`Missing file ${url}`);
}
for(const [,url] of fs.readFileSync(path.join(root,'sitemap.xml'),'utf8').matchAll(/<loc>([^<]+)<\/loc>/g)){
  const p=new URL(url).pathname;
  const local=path.join(root,p.endsWith('/')?`${p}index.html`:`${p}.html`);
  assert.ok(fs.existsSync(local),`Missing sitemap page ${url}`);
}
const png=fs.readFileSync(path.join(root,'social-card.png'));
assert.equal(png.readUInt32BE(16),1200);assert.equal(png.readUInt32BE(20),630);
console.log('PASS: metadata, JSON-LD, headings, local links, anchors, sitemap destinations and 1200×630 social card');
