# SNES-AAA Roadmap

> **Status**: Active
> **Last Updated**: 2026-09-05
> **North star**: late-90s SNES AAA *discipline* (authored fights, one art language, earned songs, places to walk) — not CT map-count.
> **Content ancestor**: Pokémon Red + tragic simulation frame. Dual techs are how we steal CT depth without 14 playable humans.

## Priority order

Scott is handling P2 (soundtrack) separately. Agent work can proceed from P1 animation/readability polish to P3 gameplay and authored rooms without waiting on soundtrack composition. Do not expand the roster (P5) or add engines until P1 has real frames.

### P0 — Identity lock

Done in this pass.

- ADR-0011: browser is the 1.0 cartridge; Godot is frozen 2.0 research.
- Art bible + `src/artBible.js` reject tests.
- Music identity brief (soundtrack owned separately by Scott).
- Honest animation contract in `src/sprites.js` (stage portraits are single-frame).
- Four-zone data in `src/worldZones.js` (all four authored room routes implemented).
- Boss pattern data in `src/bossPatterns.js` (all 13 patterns now execute in `battleEngine`).

### P1 — Battles look like battles

1. Replace leftover-type arenas (`fire.webp` labels, gravity-chamber grid).
2. Author signature VFX; clear `VFX_PLACEHOLDERS`.
3. Stage-3 battle frame sets for 9 dragons.
4. 9 NPC battle frame sets at the same cell size. Delete printed "404."
5. Boss phase cells.

The P1 assets and subsequent polish have landed: battle strips include squash-and-stretch in-betweens, Void and Protocol Vulture have stronger silhouette lighting, and the Singularity's surge/void forms have distinct structures. Hands-on motion/readability acceptance remains part of the release review. Asset coverage is not the final visual-quality gate.

### P2 — Twelve tracks

Scott's separate soundtrack workflow has delivered the twelve-track commission and runtime wiring, recorded in `TODO.md`, `design/gdd/music-identity.md`, and `MUSIC_COMMISSION` in `src/soundEngine.js`. Gameplay work preserves that soundtrack and its routing. Playback reliability fixes remain independent of composition.

### P3 — Four authored zones

`OUTER_GRID` → `FROZEN_CACHE` → `STORM_SPINE` → `ADMIN_CORE`. Each zone: 3-screen path, 1 lab/town room, 1 setpiece, 1 mid-boss, 1 zone boss. Replace the 9-node graph only after rooms exist.

All four routes are implemented alongside the existing campaign map: Outer Grid (7 rooms), Frozen Cache (8), Storm Spine (8), and Admin Core (8). Each has saved choices, encounter checkpoints, an optional cache, and a return reward. The span, thaw junction, wire fork, and cold lanterns have dedicated choice animations and room travel transitions; backgrounds reuse shipped art. The zone shot scripts verify presentation states, while first-time comprehension, controls, and timed pacing remain hands-on acceptance work tracked in `TODO.md`.

Guidance remembers the last entered expedition and keeps its objective ahead of the daily challenge. When the next encounter requires another zone's clear, NEXT names that prerequisite and opens its zone. Legacy saves without an entry marker resume the furthest entered unfinished sector; completed routes release guidance after all encounters and the return reward are done. New Game+ resets the entry marker with room progress.

### P4 — Combat authorship

Execute `bossPatterns.js` in `battleEngine`. Then pick **one** depth axis: field-2 + 6 dual techs, *or* 4-move kits + visible tells. Not both in the same sprint.

Execution is now live for all 13 patterns; dual-tech support and tests also exist. Review the existing implementation and observed player decisions before expanding either depth axis.

### P5 — Roster expansion

16 or 24 dragons only after P1–P3. New stills that cannot animate or live in a zone are journal entries, not content.

## What earns the next production milestone

The target is a replayable 15–20 minute opening slice: awaken → first dragon → Outer Grid route → readable boss → meaningful reward → return to the Forge. All four zones are now playable alongside the nine-node campaign; opening duration and player response still need a measured acceptance pass.

| Quality gate | Evidence required before calling the slice polished |
|---|---|
| Player purpose | A new player can explain the immediate objective and start making choices in the first two minutes without coaching. |
| Combat authorship | Test players can explain an enemy tell, choose a counter, and describe why a loss happened. |
| Animation | At normal and reduced motion, entry/anticipation/contact/recovery remain readable; low-contrast actors separate from their arenas. |
| Musical identity (Scott's parallel work) | The supplied soundtrack meets the approved brief and is integrated for release. Composition does not block development of the playable slice. |
| Place and pacing | Outer Grid has a three-room path, a lab, a setpiece, a mid-boss and a boss, with a clear return route and no mandatory repeat-fight grind. |
| Reliability | Clean install, save/resume, first hatch, first battle, failure/retry, sound controls, keyboard/gamepad and narrow-screen play all pass in real browsers. |

Use observed playtests to decide when the slice is ready. Test counts and asset totals cannot establish that the game is compelling or predict a commercial hit.
