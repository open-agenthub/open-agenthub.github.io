import { createRequire } from 'node:module';
import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';

// Use the session browser so screenshots exercise the deployed static files and hydration.
const require = createRequire(process.env.PLAYWRIGHT_PACKAGE || '/opt/session-agent/package.json');
const { chromium } = require('playwright-core');
const [endpoint, baseline, output] = process.argv.slice(2);
assert(endpoint && baseline && output, 'Usage: node browser.mjs CDP_URL BASELINE_DOCS OUTPUT_DIR');
const root = path.resolve(import.meta.dirname, '../..');
await fs.mkdir(output, { recursive: true });
const browser = await chromium.connectOverCDP(endpoint);
const context = browser.contexts()[0];
const page = await context.newPage();
page.setDefaultTimeout(10000);
let phase = 'before';
await context.route('https://example.com/**', async route => {
  let pathname = decodeURIComponent(new URL(route.request().url()).pathname);
  const base = pathname.startsWith('/docs/') ? (phase === 'before' ? baseline : path.join(root, 'docs')) : root;
  if (pathname.startsWith('/docs/')) pathname = pathname.slice(5);
  if (pathname.endsWith('/')) pathname += 'index.html';
  if (!path.extname(pathname)) pathname += '.html';
  const file = path.resolve(base, '.' + pathname);
  assert(file.startsWith(path.resolve(base) + '/'));
  try { await route.fulfill({ path: file }); }
  catch { await route.fulfill({ status: 404, body: 'Missing local file' }); }
});
const results = {};
for (phase of ['before', 'after']) {
  const errors = [];
  page.on('pageerror', error => errors.push(error.message));
  results[phase] = {};
  for (const route of ['/', '/docs/', '/docs/getting-started', '/docs/workspace']) {
    for (const width of [1440, 390]) {
      await page.setViewportSize({ width, height: 1000 });
      await page.goto('https://example.com' + route, { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      const info = await page.evaluate(() => ({ title: document.title, text: document.querySelector('main, .VPContent')?.innerText,
        width: innerWidth, scrollWidth: document.documentElement.scrollWidth,
        headings: [...document.querySelectorAll('h1,h2')].map(e => e.innerText) }));
      assert(info.text && info.headings.length, 'Page content missing');
      assert(info.scrollWidth <= width, `Overflow: ${phase} ${route} ${width}`);
      const key = route.replaceAll('/', '_') + '-' + width;
      results[phase][key] = info;
      if (phase === 'after') assert.deepEqual(info, results.before[key]);
      await page.screenshot({ path: path.join(output, `${phase}${key}.png`) });
    }
  }
  await page.setViewportSize({ width: 1440, height: 1000 });
  await page.goto('https://example.com/docs/', { waitUntil: 'networkidle' });
  await page.locator('button.DocSearch-Button, button.VPNavBarSearch, .VPNavBarSearch button').first().click();
  await page.getByRole('searchbox').fill('workspace');
  await page.waitForTimeout(500);
  assert(await page.locator('.VPDocSearch .result, .VPLocalSearchBox .result').count() > 0, 'Search results missing');
  await page.keyboard.press('Escape');
  await page.getByRole('switch').click();
  assert(await page.locator('html.dark').count() === 1, 'Theme toggle failed');
  await page.getByRole('switch').click();
  assert.deepEqual(errors, []);
}
await fs.writeFile(path.join(output, 'results.json'), JSON.stringify(results, null, 2));
await context.unrouteAll();
await page.close();
await browser.close();
console.log('PASS: desktop/mobile content, headings, overflow, search, theme and browser errors');
