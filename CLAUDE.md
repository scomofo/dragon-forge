# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## Project Overview

**Dragon Forge** — a dragon-collecting/fusion/battle game. **The 1.0 cartridge is the browser build.** See `docs/architecture/adr-0011-browser-is-the-cartridge.md`.

1. **Browser build (`src/`, `index.html`, `vite.config.js`)** — React 18 + Vite. Deployed at `base: '/dragon-forge/'`. Source of truth for systems, balance, content, art law, and music identity. This is what we ship.
2. **Godot runtime (`dragon-forge-godot/`)** — Godot 4.6 **2.0 research slice** (overworld prototype). Frozen for new gameplay systems. Ports flow browser → Godot, never the reverse, until a future ADR promotes it.
3. **`dragon-forge-reborn/`** — built artifacts only (no source); ignore unless explicitly working on it.

Outstanding work is the SNES-AAA quality pass in priority order (`design/gdd/snes-aaa-roadmap.md`): identity lock (P0, landed) → battle frames (P1) → twelve tracks (P2) → four zones (P3) → boss scripts (P4) → roster growth (P5). Do not add engines or species before P1 has real frames. Art rejects live in `design/gdd/art-bible.md` and `src/artBible.js`.

**Soundtrack ownership (Scott, 2026-09-04):** Scott is handling the soundtrack separately. P2 runs in parallel and does not block agent work on gameplay, battle readability, animation, exploration, onboarding, or pacing. Preserve existing music assets and track choices unless soundtrack integration is requested; do not compose replacement tracks or build soundtrack audition features. Playback and input defects remain appropriate to fix.

## Browser build (`src/`)

### Commands
Run from the repo root:
- `npm run dev` — Vite dev server
- `npm run build` — production build to `dist/`
- `npm run preview` — preview built bundle
- `npm test` — run vitest once
- `npm run playtest:smoke` — Playwright smoke pass across desktop/tablet/mobile, writing screenshots to `.playtest-artifacts/`
- `npm run test:watch` — vitest watch mode
- Single test file: `npx vitest run src/battleEngine.test.js`
- Single test by name: `npx vitest run -t "name pattern"`

Test environment is `node` (configured in `vite.config.js`); no jsdom — engine modules are pure JS and tested directly.

### Architecture

Top-level state lives in `src/App.jsx`, which is a screen switcher driven by a `screen` enum and a single `save` object. Navigation flows through `handleNavigate(target)`; battles are entered via `handleBeginBattle` / `handleBeginCampaignBattle` / `handleEngageBoss`, all of which set `battleConfig` then switch to the BATTLE screen. The `returnScreen` field on `battleConfig` is what tells `handleBattleEnd` where to go back to — preserve it when adding new battle entry points.

Save state is the central data structure. It is loaded once from `localStorage` (`persistence.js`, key `dragonforge_save`) into a single `save` object that is passed to every screen. Mutations are made by screen code calling persistence helpers, then calling `refreshSave()` to re-read from storage. The `DEFAULT_SAVE` shape in `persistence.js` is the schema; `migrateSave` handles forward-compat on load.

Engine vs. presentation separation:
- `*Engine.js` files (`battleEngine`, `fusionEngine`, `hatcheryEngine`, `animationEngine`, `soundEngine`, `gamepadInput`) are pure logic with `.test.js` siblings.
- `*Screen.jsx` files are React shells that compose engines + sprites + VFX.
- `battlePresentation.js` separates what the battle looks like (camera, timing) from what it does (`battleEngine.js`).

Content/data modules (no logic, just tables): `gameData`, `forgeData`, `shopItems`, `singularityBosses`, `loreCanon`, `felixDialogue`, `journalMilestones`, `sprites`, `artBible`, `worldZones`, `bossPatterns`. New content usually means editing these, not the engines.

The Singularity is the endgame arc and has its own progression file (`singularityProgress.js`) plus a corruption-stage CSS class applied at the root (`corruption-stage-N`). Stage drives visual filters and music.

Sound: every nav/screen change calls `playSound(...)` and `playMusic(...)` from `soundEngine.js`. When adding a screen, wire both in `handleNavigate`.

CSS is split into per-screen modules under `src/styles/` (mentioned in TODO).

## Godot runtime (`dragon-forge-godot/`)

Godot 4.6 project. Frozen for new gameplay systems (ADR-0011). Launch with the local Godot binary only when prototyping the future overworld:

```powershell
.\run-godot.ps1
```

Layout:
- `scripts/sim/` — pure simulation modules. GDScript counterpart to `src/*Engine.js`.
- `scripts/world/` — 20×10 two-zone slice. Do not add content here that `src/worldZones.js` does not already name.
- `scripts/screens/` — UI screen controllers.
- `scripts/components/` — reusable UI nodes.
- `scripts/tests/` — headless smoke tests.

When porting a system from web → Godot: data/rules go into `scripts/sim/` as a stateless module; screen controllers go into `scripts/screens/`; world-specific nodes go into `scripts/world/`.

## Cross-build notes

- Art is tracked per-build: **`public/assets/` is the source of truth for the browser build**. New web art must be placed in `public/assets/` to ship and must pass `design/gdd/art-bible.md`.
- `handoff/` contains art briefs. P1 work starts there only if the brief names a body plan from `src/artBible.js`.
- `docs/superpowers/` is workflow scaffolding, not game code.

## Platform

Windows 11. Shell snippets in this repo are PowerShell. Use forward-slash paths in JS/Vite config; PowerShell paths for the Godot launcher.
