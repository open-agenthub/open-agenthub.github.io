// Checks every internal link and anchor in the built documentation (docs/**/*.html).
// VitePress reports dead page links at build time, but not missing #anchors, so a renamed
// heading silently breaks links into it; this check reads the generated HTML instead.
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const docs = path.join(root, 'docs');
const pages = new Map();
for (const file of fs.readdirSync(docs, { recursive: true })) {
  if (!file.endsWith('.html')) continue;
  const html = fs.readFileSync(path.join(docs, file), 'utf8');
  const ids = new Set([...html.matchAll(/\bid="([^"]+)"/g)].map(m => m[1]));
  const route = '/docs/' + file.replace(/\\/g, '/').replace(/(^|\/)index\.html$/, '$1').replace(/\.html$/, '');
  pages.set(route, { html, ids });
}
const problems = [];
let checked = 0;
for (const [route, { html }] of pages) {
  const main = html.slice(html.indexOf('<main'), html.lastIndexOf('</main>'));
  for (const [, href] of main.matchAll(/<a [^>]*href="([^"]+)"/g)) {
    if (/^[a-z]+:/i.test(href) || href.startsWith('mailto:')) continue;
    const [p, hash] = href.split('#');
    const target = p === '' ? route : p.replace(/\.html$/, '');
    const page = pages.get(target);
    checked++;
    if (!page) problems.push(`${route}: missing page ${href}`);
    else if (hash && !page.ids.has(decodeURIComponent(hash))) problems.push(`${route}: missing anchor ${href}`);
  }
}
if (problems.length) { console.error(problems.join('\n')); process.exit(1); }
console.log(`PASS: ${checked} internal links and anchors in ${pages.size} documentation pages`);
