# Dragon Forge — To Do

## SNES-AAA quality pass (priority order)

- [x] P0 Identity lock — ADR-0011, art bible, music identity, animation honesty, zone + boss-pattern skeletons
- [ ] P1 Battle frames — art commissions still open (see below); code contracts landed:
  - [x] P1.2 code — 9 signatures own dedicated VFX keys; `VFX_PLACEHOLDERS` cleared; procedural palette/motif/motion per signature (`src/sprites.js`, `src/VfxOverlay.jsx`)
  - [x] P1.1 code — arena contract (`isBannedArtUrl`, `KNOWN_PLACEHOLDER_ARENAS`); `fire.webp` banned; gravity-chamber grid tracked as the one placeholder; 404 language removed from `handoff/ARENA_AND_FORGE_BRIEF.md`
  - [x] P1.3/P1.4 code — `DRAGON_BATTLE_SETS` (9) + `NPC_BATTLE_SETS` (9) at 96px cell, honestly `portrait-only` until sheets land
  - [x] P1.5 code — every boss phase declares its own idle/attack cells; remnant hue-rotate recolors removed
  - [x] P1.3/P1.4 pipeline — pose-driven battle-set loader (`src/battleSets.js`: idle/attack/hurt/faint resolution + sheet/fallback) with strip player (`src/BattleSetSprite.jsx`); `DragonSprite`/`NpcSprite`/`BattleScreen` wired, portraits render unchanged until sheets ship
  - [x] P1.1 registry — `src/arenas.js` covers the 11 battle arenas (all honest placeholders); grade-only filter allowlist with 7 locked content-filter users; `BattleScreen` resolves through it with debug flags
  - [ ] P1 art — authored 1024² arena replacements (gravity chamber + 5 element + 9 NPC), 9 stage-3 dragon sheets (idle 4 / attack 6 / hurt 2 / faint 3 @96px), 9 NPC sheets at same cell, boss phase cells, 9 signature VFX strips
- [ ] P2 Twelve authored tracks — Mirror Admin title-motif arrangement first (`design/gdd/music-identity.md`)
- [ ] P3 Four authored zones — Outer Grid / Frozen Cache / Storm Spine / Admin Core rooms (`src/worldZones.js`)
- [ ] P4 Execute `bossPatterns.js` in `battleEngine`; pick one depth axis (dual techs **or** 4-move kits)
- [ ] P5 Roster expansion only after P1–P3

## Recent Browser QA
- [x] Forge hub refactor: scene/overlays/movement split, CSS extracted, truthful station copy
- [x] Browser Playwright smoke: desktop/tablet/mobile screenshots and overflow checks
- [x] Asset manifest test: runtime dragon, NPC, egg, arena, and boss references checked under public/
- [x] Bespoke Void Dragon evolution sprites: generated void_stage1–4.png
