# SNES-AAA Roadmap

> **Status**: Active
> **Last Updated**: 2026-09-02
> **North star**: late-90s SNES AAA *discipline* (authored fights, one art language, earned songs, places to walk) — not CT map-count.
> **Content ancestor**: Pokémon Red + tragic simulation frame. Dual techs are how we steal CT depth without 14 playable humans.

## Priority order

Work the list in order. Do not expand the roster (P5) or add engines until P1 has real frames.

### P0 — Identity lock

Done in this pass.

- ADR-0011: browser is the 1.0 cartridge; Godot is frozen 2.0 research.
- Art bible + `src/artBible.js` reject tests.
- Music identity + `MUSIC_COMMISSION`.
- Honest animation contract in `src/sprites.js` (stage portraits are single-frame).
- Four-zone data in `src/worldZones.js` (P3 skeleton, no new nodes yet).
- Twelve boss patterns in `src/bossPatterns.js` (P4 skeleton, not yet executed by `battleEngine`).

### P1 — Battles look like battles

1. Replace leftover-type arenas (`fire.webp` labels, gravity-chamber grid).
2. Author signature VFX; clear `VFX_PLACEHOLDERS`.
3. Stage-3 battle frame sets for 9 dragons.
4. 9 NPC battle frame sets at the same cell size. Delete printed "404."
5. Boss phase cells.

### P2 — Twelve tracks

Commission list in `design/gdd/music-identity.md`. Mirror Admin arrangement first.

### P3 — Four authored zones

`OUTER_GRID` → `FROZEN_CACHE` → `STORM_SPINE` → `ADMIN_CORE`. Each zone: 3-screen path, 1 lab/town room, 1 setpiece, 1 mid-boss, 1 zone boss. Replace the 9-node graph only after rooms exist.

### P4 — Combat authorship

Execute `bossPatterns.js` in `battleEngine`. Then pick **one** depth axis: field-2 + 6 dual techs, *or* 4-move kits + visible tells. Not both in the same sprint.

### P5 — Roster expansion

16 or 24 dragons only after P1–P3. New stills that cannot animate or live in a zone are journal entries, not content.
