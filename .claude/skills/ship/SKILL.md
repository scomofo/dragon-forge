---
name: ship
description: Pre-release check and deploy for the Dragon Forge browser build (GitHub Pages). Use when asked to ship, release, deploy, or verify the production build.
---

# Ship the browser build

Deploys are automatic: any push to `master` triggers `.github/workflows/deploy.yml`, which runs `npm ci && npm run build` and publishes `dist/` to GitHub Pages. There is no manual deploy step — shipping means getting a verified commit onto `master`.

## Pre-push gate
```powershell
npm test                 # all engine suites
npm run build            # must succeed clean — this is exactly what CI runs
npm run preview          # serve the built bundle
npm run playtest:smoke   # viewport screenshots to .playtest-artifacts/
```
Review the smoke screenshots before pushing, not after.

## Production gotchas
- `vite.config.js` sets `base: '/dragon-forge/'` — asset URLs that work under `npm run dev` (served at `/`) can 404 in production. Always reference assets relatively or through Vite imports; verify with `npm run preview`, which applies the base path.
- `src/assetManifest.test.js` guards sprite references against `public/`; if it fails, the deployed game will have missing images.
- Saves live in `localStorage` under `dragonforge_save`. Any save-shape change must be backward-compatible via `migrateSave` in `src/persistence.js` — deployed players' existing saves must load. Test by writing an old-shape save into localStorage and loading.

## After pushing
Watch the run: `gh run watch` (or `gh run list --workflow=deploy.yml --limit 1`). The Pages URL is printed in the workflow's environment output. Spot-check the live site for the changed screens.
