import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';

// Record actual rendered modules, since a development dependency can still ship client code.
const root = path.resolve(import.meta.dirname, '../..');
const output = process.argv[2];
assert(output, 'Usage: node modules.mjs OUTPUT_JSON');
const directory = path.join(root, 'docs-src/node_modules/vitepress/dist/node');
const cli = await fs.readFile(path.join(directory, 'cli.js'), 'utf8');
const chunk = cli.match(/from ['"](.+chunk-[^'"]+)['"]/)[1];
const exports = await import(path.join(directory, chunk));
const results = {};
await exports.b(path.join(root, 'docs-src'), {
  onAfterConfigResolve(config) {
    config.vite ||= {};
    config.vite.plugins ||= [];
    config.vite.plugins.push({
      name: 'record-client-modules',
      generateBundle(options, bundle) {
        if (options.dir !== path.join(root, 'docs')) return;
        const modules = Object.values(bundle).filter(item => item.type === 'chunk')
          .flatMap(item => Object.entries(item.modules).filter(([, value]) => value.renderedLength > 0).map(([id]) => id));
        results[options.dir || 'client'] = [...new Set(modules)].sort();
      }
    });
  }
});
await fs.writeFile(output, JSON.stringify(results, null, 2));
console.log('Module inventory written to', output);
