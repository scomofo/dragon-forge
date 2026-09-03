# ADR-0011: Browser Build Is the 1.0 Cartridge

## Status

Accepted

## Date

2026-09-02

## Last Verified

2026-09-02

## Decision Makers

scomofo — SNES-AAA quality pass

## Summary

The React 18 + Vite browser build (`src/`, deployed at `/dragon-forge/`) is the **1.0 cartridge**. Godot 4.6 (`dragon-forge-godot/`) is a **frozen 2.0 research slice** for a future walkable overworld. It must not receive new gameplay systems, balance numbers, or content that the browser build does not already own. ADR-0001 remains the historical record of why two trees exist; this ADR ends treating them as co-equal ship targets.

## Decision

1. **Ship target for v1.0** is the browser build only.
2. **Content, balance, and art law** live in `src/` + `public/assets/` + `design/gdd/`.
3. **Godot** may be opened to prototype a four-zone overworld *after* P3 is specified in data (`src/worldZones.js`). Ports flow browser → Godot, never the reverse, until a future ADR promotes Godot to 2.0.
4. New systems land in `src/*Engine.js` first, with a Vitest sibling, before any GDScript twin is written.
5. Do not add dragons, moves, bosses, or tracks to Godot that the browser build does not already ship.

## Validation

- `CLAUDE.md` names browser as the 1.0 cartridge and Godot as frozen 2.0 research.
- No new Godot sim modules are required to ship P0–P2.
- `src/worldZones.js` is the zone source of truth even if Godot later renders them.
