# Website dependency proof

Issue: open-agenthub/open-agenthub#486.

The only package manifest is `docs-src/package.json`. The published site serves
committed static files; it does not run the documentation development server.

Keep the stable documentation generator and update compatible transitive packages
through the lockfile. Its stable release still requests the older bundler major,
so the manifest narrowly overrides that generator's bundler to `^6.4.6`. The
installed framework plugin accepts both bundler majors. This avoids an alpha
generator migration and a global override affecting unrelated consumers. Downgrading
the direct dependency or hiding audit findings would leave the cause unresolved.

From the repository root:

```sh
cd docs-src
npm ci
npm audit
npm run build
cd ..
node scripts/check-site.mjs
node scripts/check-docs-links.mjs
node tests/WebsiteAuditProof/modules.mjs /path/to/client-modules.json
node tests/WebsiteAuditProof/browser.mjs CDP_URL /path/to/baseline/docs /path/to/evidence
```

Before installing updates, build the baseline lockfile and copy `docs/` outside
the checkout. The browser script routes a sample origin to local files, compares
landing/docs/install/workspace pages at desktop and mobile sizes, and checks
search, theme switching and uncaught browser errors. It uses the session browser's
installed automation package; `PLAYWRIGHT_PACKAGE` may point to another package.json
with that dependency installed. The module script instruments the generator's
installed build entry point to record modules with rendered code in the client
output. Recheck its internal build export when upgrading the generator.

Classification (package severity includes inherited findings):

| Package | Severity | Location | Resolution |
| --- | --- | --- | --- |
| @vue/server-renderer | high | Build only; absent from client modules | 3.5.40 → 3.5.45 |
| esbuild | moderate | Build/development only | 0.21.5 → 0.25.12 via bundler override |
| nanoid | high | Build only; absent from client modules | 3.3.17 → 3.3.20 |
| source-map-js | high | Build only; absent from client modules | 1.2.1 → 1.2.2 |
| vite | high | Build/development only; generated preload helper is served | 5.4.21 → 6.4.6, scoped override |
| vitepress | moderate | Client theme/router/search served; finding inherited from build tooling | Stable 1.6.4 retained; update bundler |
| vue | high | Client runtime served; finding inherited from build renderer | 3.5.40 → 3.5.45 |

Audit severity does not establish that an advisory's affected code is reachable in
a static page. The client inventory distinguishes served runtime code from the
build renderer and tooling. No affected server runs on the static host.

Generated module inventories, screenshots and results belong outside Git. Upload
screenshots to session Files and record measured outcomes in the pull request.
