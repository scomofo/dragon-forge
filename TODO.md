# Dragon Forge — To Do

## SNES-AAA quality pass (priority order)

- [x] P0 Identity lock — ADR-0011, art bible, music identity, animation honesty, zone + boss-pattern skeletons
- [ ] P1 Battle frames — crop/replace leftover arenas, dedicated signature VFX, stage-3 anim sets, NPC sets at the same cell size
- [ ] P2 Twelve authored tracks — Mirror Admin title-motif arrangement first (`design/gdd/music-identity.md`)
- [ ] P3 Four authored zones — Outer Grid / Frozen Cache / Storm Spine / Admin Core rooms (`src/worldZones.js`)
- [ ] P4 Execute `bossPatterns.js` in `battleEngine`; pick one depth axis (dual techs **or** 4-move kits)
- [ ] P5 Roster expansion only after P1–P3

## Recent Browser QA
- [x] Forge hub refactor: scene/overlays/movement split, CSS extracted, truthful station copy
- [x] Browser Playwright smoke: desktop/tablet/mobile screenshots and overflow checks
- [x] Asset manifest test: runtime dragon, NPC, egg, arena, and boss references checked under public/
- [x] Bespoke Void Dragon evolution sprites: generated void_stage1–4.png
