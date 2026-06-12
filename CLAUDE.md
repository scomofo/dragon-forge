# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Dragon Forge** — a dragon-collecting/fusion/battle game shipped in two parallel implementations:

1. **Browser build (`src/`, `index.html`, `vite.config.js`)** — the live React 18 + Vite design lab. This is what is currently deployed (`base: '/dragon-forge/'`). Treat this as the source of truth for game systems, balance, and content.
2. **Godot runtime (`dragon-forge-godot/`)** — Godot 4.6 production spine being grown into the longer-term RPG overworld + authored battle scenes. It re-implements the same simulation in GDScript and reuses art from the browser build.
3. **`dragon-forge-reborn/`** — built artifacts only (no source); ignore unless explicitly working on it.

The browser game is feature-complete and deployed; outstanding work is mostly art generation (see `TODO.md`).

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

Content/data modules (no logic, just tables): `gameData`, `forgeData`, `shopItems`, `singularityBosses`, `loreCanon`, `felixDialogue`, `journalMilestones`, `sprites`. New content usually means editing these, not the engines.

The Singularity is the endgame arc and has its own progression file (`singularityProgress.js`) plus a corruption-stage CSS class applied at the root (`corruption-stage-N`). Stage drives visual filters and music.

Sound: every nav/screen change calls `playSound(...)` and `playMusic(...)` from `soundEngine.js`. When adding a screen, wire both in `handleNavigate`.

CSS is split into per-screen modules under `src/styles/` (mentioned in TODO).

## Godot runtime (`dragon-forge-godot/`)

Godot 4.6 project. Not driven by npm — launch with the local Godot binary:

```powershell
.\run-godot.ps1
# or
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot'
```

Headless smoke test:
```powershell
& '...\Godot_v4.6.2-stable_win64.exe' --headless --path '...\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Layout:
- `scripts/sim/` — pure simulation modules (dragon data, combat rules, BattleEngine, DragonProgression, TechniqueData, etc.). The GDScript counterpart to `src/*Engine.js`. No scene state.
- `scripts/world/` — one-zone overworld slice: `world_screen.gd` (procedural 2D map builder, screen controller), `player_dragon.gd` (CharacterBody2D walk/fly), `encounter_zone.gd` (Area2D trigger), `boss_gate.gd` (gated StaticBody2D). Entry point for the Godot build's gameplay differentiator.
- `scripts/screens/` — UI screen controllers (hatchery, battle, fusion, shop, etc.), each `extends Control` and used by `scripts/main.gd`'s screen router.
- `scripts/components/` — reusable UI nodes (DragonSpriteComponent, etc.).
- `scripts/tests/` — headless smoke tests (`sim_smoke.gd`).
- `scenes/main.tscn` is the entry; `scripts/main.gd` is the top-level screen router (analogous to `App.jsx`). `scenes/world/world.tscn` is the overworld entry.

When porting a system from web → Godot: data/rules go into `scripts/sim/` as a stateless module; screen controllers go into `scripts/screens/`; world-specific nodes go into `scripts/world/`.

## Cross-build notes

- Art lives in `assets/` at the repo root and is referenced by both builds. The Godot project has copied a subset under `dragon-forge-godot/assets/`. When adding sprites, update both if the system is mirrored.
- `handoff/` contains art briefs and reference material for outstanding generation work — see `TODO.md` "Needs Art Generation".
- `docs/superpowers/` is workflow scaffolding, not game code.

## Platform

Windows 11. Shell snippets in this repo are PowerShell. Use forward-slash paths in JS/Vite config; PowerShell paths for the Godot launcher.
