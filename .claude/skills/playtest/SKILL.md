---
name: playtest
description: Run the full Dragon Forge browser test pass — unit tests plus Playwright smoke across desktop/tablet/mobile — and review the screenshot artifacts. Use before declaring browser-build work done.
---

# Playtest the browser build

## 1. Unit tests
```powershell
npm test                                   # all vitest suites (node env, pure engines)
npx vitest run src/battleEngine.test.js    # single file
npx vitest run -t "name pattern"           # single test by name
```

## 2. Playwright smoke
```powershell
npm run playtest:smoke
```
Runs `scripts/playtest-smoke.mjs`: drives the app at desktop, tablet, and mobile viewports, checks for overflow, and writes screenshots to `.playtest-artifacts/`.

## 3. Review artifacts — this is the point, don't skip it
Read the screenshots in `.playtest-artifacts/` with the Read tool and actually look at them:
- Layout overflow or clipped UI at tablet/mobile widths.
- Sprites rendering (broken images show as empty boxes).
- Screen-specific CSS regressions (styles are per-screen modules under `src/styles/`).

## 4. Targeted manual check
For changes to a specific screen, also run `npm run dev` and exercise the touched flow directly — battles entered via every entry point (`handleBeginBattle`, `handleBeginCampaignBattle`, `handleEngageBoss`) must return to the correct screen (`returnScreen` on `battleConfig`).

Report results faithfully: paste failing test output, name the screenshot showing a regression.
