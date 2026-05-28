# Dragonsim Asset Reconciliation

// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
// Date: 2026-05-26

## Source Files Reviewed

External source directory: `/Users/Scott_1/DEV/DF/dragonsim/`

| File | Use In This Pass |
|---|---|
| `Asset Download Manifest [PNG].md` | Identified old simulator source assets and Felix reference. |
| `Asset Integration Map.md` | Identified logic names for Felix, elemental arenas, Null Void, and Repair Bay overlay. |
| `Dragon Asset Generation Guide.md` | Folded in arena framing, Felix key traits, and ground-plane alignment guidance. |
| `Dragon Simulator Master Specs.md` | Folded in 16-bit cyber-retro style, elemental arena concept, Felix role, and 70% battle ground-plane guidance. |
| `asset_generation_prompts.json` | Captured usable future prompts for arenas, VFX, Null Void, and Felix portrait. |
| `app/public/` runtime assets | Preferred source for clean Felix, elemental dragon sheets, NPC sheets, and arena images when usable. |

## Visual Guidelines Status

The DragonSim visual guidelines are now treated as binding direction for this prototype's next asset passes, with the current Dragon Forge GDD taking precedence only when names/progression conflict. In practical terms:

- Preserve the DragonSim high-fidelity 16-bit pixel rendering standard.
- Preserve the Felix look from DragonSim: messy white hair, eccentric grin, coat, and glowing goggles.
- Preserve and adapt dragon sprites from DragonSim wherever the current slice has a matching use.
- Use DragonSim arena framing as the battle-scene target: 512x256 source framing, low-angle perspective, high-contrast silhouettes, and a clear ground plane around 70% down the frame.
- Prefer clean runtime/exported DragonSim files under `app/public/` over raw source sheets when both exist, because the public files avoid sheet headers, UI fragments, and other non-game material.

## Existing Local Source Assets Found

| Path | Assessment |
|---|---|
| `/Users/Scott_1/DEV/DF/dragonsim/assets/felix_pixel.jpg` | Raw must-have reference. Contains source-sheet UI/header material, so it is not used directly for the slice derivative anymore. |
| `/Users/Scott_1/DEV/DF/dragonsim/app/public/felix.png` | Must-have clean Felix asset. Used to generate `felix.png` and `felix_portrait.png` without the raw source-sheet/ASCII/UI material. |
| `/Users/Scott_1/DEV/DF/dragonsim/app/public/sprites/*.png` | Preferred source for imported elemental dragon sprites. First-frame crops are chroma-keyed, resized, and kept as `dragonsim_*.png` references. |
| `/Users/Scott_1/DEV/DF/dragonsim/app/public/sprites/npc/*.png` | Preferred source for enemy sprites. `bit_wraith`, `logic_bomb`, and `recursive_golem` are now integrated into the battle scene. |
| `/Users/Scott_1/DEV/DF/dragonsim/app/public/arenas/*.png` | Usable arena source family after trimming top filename/checker content. `arenas/venom.png` currently drives `village_edge_map.png`. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/arenas.jpg` | Used as source for `battlefield.png` by cropping the strongest low-angle arena panel. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons.png` | Kept as a visual reference sheet; not directly extracted because per-element sheets are cleaner. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons/fire.png` | Extracted to `dragonsim_fire.png` for visible Forge hologram/reference use. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons/ice.png` | Extracted to `dragonsim_ice.png` for visible Forge hologram/reference use. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons/stone.png` | Extracted to `dragonsim_stone.png` for visible Forge hologram/reference use. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons/storm.png` | Extracted to `dragonsim_storm.png` for visible Forge hologram/reference use. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons/shadow.png` | Extracted to `dragonsim_shadow.png` and adapted as `enemy_protocol.png`. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/dragons/venom.png` | Extracted to `dragonsim_venom.png` and adapted/tinted as `root_wyrmling.png` until a true Root sprite exists. |
| `/Users/Scott_1/DEV/DF/dragonsim/assets/fire.png`, `ice.png`, `stone.png`, `storm.png`, `shadow.png`, `venom.png` | Present but visually appear mostly black/transparent in local inspection, so they are not reliable drop-in arena assets for this slice. |

## Constraints Folded Into Revision 4B

- Felix must read as an eccentric mentor with messy white hair and glowing cyan/green goggles.
- Low-detail/generated Felix sprites are not acceptable. Felix must be represented by the high-fidelity DragonSim public asset or an explicitly approved replacement at comparable fidelity.
- Battle scenes should maintain a clear ground plane at roughly 70% down the scene, matching the old simulator's sprite anchoring guidance.
- Future battle backgrounds should target a 512x256 source frame or preserve that aspect internally before scaling into the Godot viewport.
- Arena art should use low-angle perspective, atmospheric lighting, high-contrast foreground silhouettes, and clear elemental identity.
- Null Void / endgame visual language should be monochrome glitch, broken UI, green code, grayscale/invert treatment, and digital fragmentation.
- Repair Bay / Forge diagnostic scenes may reuse storm/static/cyan visual language as blurred or low-opacity technical overlays.
- Imported elemental dragon sprites should remain available in the slice asset folder even when the current loop only uses Root/enemy variants.

## Constraints Folded Into Revision 4D

- The app-public DragonSim runtime assets are now the first-choice local source for sprite derivatives.
- The battle presentation includes DragonSim NPC support silhouettes (`logic_bomb`, `recursive_golem`) around the primary bit-wraith enemy to better test the enemy-family visual language.
- AI generation access may be used for the next higher-fidelity pass, but the sprite-pipeline rule applies: start from an approved seed frame, generate/edit a full strip together, preserve transparent backgrounds, and normalize scale/anchor before in-engine approval.
- Felix remains a must-have DragonSim source asset. Any later Felix replacement must preserve the current DragonSim identity and be explicitly approved before replacing `felix.png` or `felix_portrait.png`.

## Constraints Folded Into Revision 4E

- DragonSim battle mode is now a preservation target, not just an asset source. The slice should retain named moves, special-move identity, windup/impact/recoil timing, floating damage, attack VFX, and crunchy four-frame battle animation.
- Existing DragonSim attack sheets are valid only after inspection. `shadow_attack.png` drives the hostile protocol's Data Leak beat; `venom_attack.png` is contaminated with baked filename/checkerboard editor material, so temporary Root attack frames are synthesized from the clean `venom.png` seed instead.
- The current four-frame cadence is allowed to feel chunky in the 90s console sense, but frame anchors must stay stable and action silhouettes must read at game scale.
- Missing Root-specific animation should be generated or painted as full strips from an approved seed frame, then normalized before replacing `root_attack_0.png` through `root_attack_3.png`.
- Future battle polish should add frame timing, attack SFX, and richer impact VFX before discarding any visually usable DragonSim sprites.

## Revision 4G/4H Human Retest Rejection

The latest human retest rejects the current generated/procedural presentation as representative art. Even with DragonSim source usage, lore text, SFX hooks, and battle timing, the slice still reads as dull and MS Paint-like. The detailed GDD/art direction is not coming through in play.

Do not treat the current hatchery, victory, or simple composite background assets as approved visual direction. They are placeholders that validate file loading only. The next asset pass must produce actual target frames for the screen beats, then use those frames as the source of truth for replacement PNGs and sprite strips.

Required next asset gates before another vertical-slice verdict:

1. Approved Hatchery target frame: Felix, Skye/Root Egg, forge machinery, emotional hatching beat, no crude geometric filler.
2. Approved Village Edge battle target frame: DragonSim-style 512x256 low-angle arena, clear 70% ground plane, pastoral surface plus diagnostic seam.
3. Approved Victory/Return target frame: reward meaning, repaired route, Data Scraps, no absurd chest/placeholder composition.
4. Approved Root Wyrmling and Root attack strip: not a Venom recolor unless explicitly accepted as temporary.
5. In-user-build music/SFX audibility check, not just headless smoke.

Approval update: Scott approved the new target-frame contact sheet on 2026-05-26. The approved board is stored at `design/art/target-frames/vertical-slice-target-board-approved-2026-05-26.png`, with written production notes at `design/art/target-frames/vertical-slice-target-frames.md`.

## Constraints Reconciled Or Deferred

- The old DragonSim element taxonomy uses Magma/Static/Ice/Venom/Stone/Shadow/Solar/Lunar. The current Dragon Forge GDD uses Fire/Ice/Storm/Stone/Venom/Shadow/Void plus a Root starter for the slice. The old taxonomy is reference-only unless reconciled by a GDD change.
- The old React logic names (`FELIX_PORTRAIT`, `ARENA_FIRE`, etc.) were not imported as Godot constants. The prototype keeps its own `assets/slice/*.png` filenames.
- CSS-specific instructions such as `mix-blend-mode: color-dodge` are treated as art direction only. Equivalent Godot shader/material treatment can be designed later.
- The old trigger "Collection of 3 Stage IV dragons" for Null Void conflicts with the current approved Singularity/Matrix progression model and is not adopted.

## Next Asset Recommendations

1. Keep Felix derived from `/Users/Scott_1/DEV/DF/dragonsim/app/public/felix.png`; do not reintroduce the raw source-sheet UI/header material or the old low-detail generated Felix sprite.
2. Replace `battlefield.png` with a true 512x256 low-angle Village Edge / Testing Field arena: pastoral foreground, diagnostic seam, clear 70% ground plane, TELEGRAPH-readable center.
3. Replace the adapted `root_wyrmling.png` with a real Root-element starter sprite sheet that matches the DragonSim dragon rendering quality.
4. Add VFX sprites from the old prompt family but Root-themed first: root spark, diagnostic telegraph, Data Scrap burst.
5. Keep imported DragonSim elemental sprites available for future hatchery/roster/elemental-matrix screens.
6. If using inference / app.1min.ai for asset work, use the DragonSim public sprites as approved seed/reference inputs and bring results back through `tools/generate_slice_assets.gd` or a documented replacement step before retest.
7. Continue the battle restoration pass by improving the Root attack strip, enemy special strips, and move-specific VFX while preserving DragonSim's named-move battle feel.
