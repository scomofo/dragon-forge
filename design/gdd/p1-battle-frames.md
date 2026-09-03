# P1 Battle Frames

> **Status**: In progress — 2026-09-02

## Landed

- Arenas at 320×176 with no leftover type: fire, magma, ice, stone, gravity_chamber, npc_firewall_sentinel.
- Authored strips: `vfx_heartforge.webp`, `vfx_absolute_zero.webp`.
- Unique files (copied pixels, still in `VFX_PLACEHOLDERS`): overclock, bastion, hemotoxin, phase_strike, siphon_rift, restoration, recompile.
- Fire stage-3 battle sheet `fire_stage3_battle.webp` — 15×96 (idle 4 / attack 6 / hurt 2 / faint 3). `DragonSprite` plays `_battle` paths as strips.
- Ice stage-3 battle sheet `ice_stage3_battle.webp` — same 15×96 contract.
- `getDragonSprite(id, stage, { battle: true })` returns `battleSheet` when present. `BattleScreen` uses that path.
- Firewall Sentinel 96² blank-shield knight (no printed 404). Attack cell is still idle.

## Honest gap

The fire battle sheet is a pipeline proof. Silhouette is a magma kaiju, not yet the hex-scale biped of the fire stage-3 portrait.

The ice sheet is a working 15-frame strip. It reads more upright than the faceted-quadruped portrait (low rectangle + spike row). Art drop keeps `ice_quadruped_ref.jpg` for the redraw.

Binaries live in the project art drop `snes-aaa-p1/` and must be copied into `public/assets/`.

## Remaining

1. Battle sheets for the other 7 adults on their body plans (storm, stone, venom, shadow, void, light, synthesis).
2. Redraw fire onto hex-scale biped; redraw ice onto faceted quadruped.
3. Authored strips for the seven leftover signatures.
4. 9 NPC sets at 96² with idle + attack + hurt + faint.
5. Crop remaining 352×150 concept arenas.
