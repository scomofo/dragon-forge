// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
// Date: 2026-05-26

# Vertical Slice Report - Dragon Forge - 2026-05-26

## Status

PIVOT - audiovisual/narrative translation failing; production-art pass required.

## Executive Summary

Verdict remains PIVOT. The initial build demonstrated a compact hatch -> map -> battle -> reward loop, passed an automated happy-path smoke test, and was completed by the user in under 1 minute. Revisions improved loop clarity, battle feedback, DragonSim asset usage, and explicit lore text, but the latest human playtest found that the playable slice still does not communicate the depth of the project's documentation. Visuals and SFX feel dull, music is not perceived as present, the Hatchery and Victory screens fail the quality bar, and added/procedural art reads like MS Paint rather than production-adjacent 16-bit cyber-retro art.

## Core Loop Validation

- Start: Forge Hub tutorial state.
- Challenge: Hatch Root Wyrmling, enter Village Edge, fight one training protocol.
- Resolution: Clear node, gain Data Scraps, return to Forge.
- Internal smoke result: `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd` reached `complete` state with 65 Data Scraps.

## Feel Assessment

Revision 4G/4H evidence shows the current approach is the wrong quality path. The slice should stop relying on procedural placeholder compositions for the moments that sell the game. The next useful pass is a production-art and presentation translation pass: select the exact lore beats to stage visually, generate or paint proper Hatchery/Victory/Battle backgrounds, lock approved character/dragon source frames, add a real music bed in the user build, and reduce explanatory text once the visuals carry the premise.

## Technical Findings

- Implemented as a standalone Godot 4.6 project under `prototypes/`.
- Prototype code is intentionally isolated from production project files.
- Current build uses placeholder Control UI and text-first feedback.
- Prototype smoke runner verifies the happy path without importing prototype code into production.

## Velocity Log

| Day | Work Completed |
|---|---|
| 2026-05-26 | Defined slice scope and created first playable scaffold. |
| 2026-05-26 | Added prototype-only smoke runner and verified the full loop reaches completion with expected reward state. |
| 2026-05-26 | Added playtest evidence sheet for the required human debrief. |
| 2026-05-26 | User reported that the slice was tested; detailed observations still need to be captured. |
| 2026-05-26 | Debrief captured: completed in under 1 minute, but presentation/dialogue too thin. Verdict set to PIVOT. |
| 2026-05-26 | Revision 1 added representative visuals/dialogue and passed the same automated happy-path smoke. |
| 2026-05-26 | Revision 2 separated scene visuals from text UI, upgraded the drawn scene beats, and passed the same automated happy-path smoke. |
| 2026-05-26 | User retested Revision 2: click-through works, but visuals remain very basic and not production-ready. Verdict remains PIVOT. |
| 2026-05-26 | Revision 3 rebuilt visuals toward art-bible-aligned 16-bit cyber-retro pixel set pieces, added animation/focus styling, and passed the same automated happy-path smoke. |
| 2026-05-26 | Revision 4 generated a project-local PNG asset pack, wired it into the Godot slice, and passed the same automated happy-path smoke. |
| 2026-05-26 | External `dragonsim` asset docs were reconciled; adopted Felix goggle trait and documented arena/ground-plane constraints for the next asset pass. |
| 2026-05-26 | User clarified DragonSim visuals should be retained; Revision 4B now derives Felix from the clean DragonSim public asset, and derives battle arena, Root stand-in, enemy, and imported elemental sprites from local DragonSim assets. |
| 2026-05-26 | User rejected the low-detail Felix sprite; Revision 4C retired generated/code-drawn Felix fallbacks and regenerated Felix as a higher-fidelity DragonSim-derived bust/portrait. |
| 2026-05-26 | Revision 4D preferred DragonSim `app/public/` runtime sprites, added logic-bomb and recursive-golem support enemies to battle presentation, regenerated the asset pack, and passed the same automated happy-path smoke. |
| 2026-05-26 | Revision 4E restored DragonSim-style battle mode beats: named moves, attack-frame assets, impact VFX, screen shake, floating damage, phase banners, and timed smoke coverage. |
| 2026-05-26 | Revision 4F added DragonSim battle WAVs, raw WAV runtime loading, heavier Thorn Surge timing/scale, and stronger hit recoil/flash while preserving the same smoke path. |
| 2026-05-26 | Revision 4G added in-world Signal Trace lore beats and rewrote slice text so Skye, Felix, Root dragons, Admin deletion routines, Data Scraps, and the Great Reset threat are visible in the playable loop. |
| 2026-05-26 | User retested and reported that visuals/SFX are dull, music is not coming through, Hatchery/Victory screens look absurd, documentation depth is not translating into play, and added art reads like MS Paint. Verdict remains PIVOT. |
| 2026-05-26 | Scott approved a new target-frame contact sheet; Revision 4I extracted first-pass replacement assets for Hatchery, Village Edge battle, Victory/Return, Root Wyrmling, Root Egg, Root attack strip, and Root VFX, then passed the automated happy-path smoke. |
| 2026-05-26 | Revision 4J generated and extracted a second asset board for Forge Hub, Campaign Map, hostile Admin Protocol, Data Scraps, enemy Data Leak frames, and Shadow Burst VFX; guarded the old placeholder generator; smoke still passed. |
| 2026-05-26 | Revision 4K added focused animation frames for Root idle, enemy idle, Root Spark, Thorn Surge, enemy Data Leak, Hatchery reveal, and Data Scraps pickup; wired them into existing draw paths; parse and smoke passed. |
| 2026-05-26 | Revision 4L replaced Battle, Victory, and Hatchery with background-only crops to avoid baked actor duplication, centered Hatchery reveal composition, added a display-renderer screenshot capture helper, and documented CodeGraph's current GDScript limitation. |
| 2026-05-26 | Revision 4M lowered/ducked the looping music bed and added battle actor readability passes so Root/Admin sprites draw more opaquely over the detailed arena. Smoke still passed. |
| 2026-05-26 | Revision 4N added hard-opaque battle-only Root/Admin frame variants, switched battle rendering to those variants, and restyled menus/fonts toward a square 1990s console RPG presentation. Smoke still passed. |
| 2026-05-26 | Revision 4O used online search for the needed licensed UI foundation: added Press Start 2P under SIL OFL, kept the prior local font as fallback, resized UI text for the chunkier pixel face, preserved the approved art assets, and captured display-renderer screenshots. Smoke still passed. |
| 2026-05-26 | Revision 4P removed the unclear center battle spinner, replaced it with enemy-attached TELEGRAPH/target brackets, expanded SFX playback to six layered voices, and added heavier DragonSim SFX layers for battle impact. Smoke still passed. |
| 2026-05-26 | User reported Revision 4P was testing pretty well but the first meaningful action still lacked the earlier exposition/narrative intro. Revision 4Q added a three-beat cold open before Forge Hub and updated smoke/capture coverage. Smoke still passed. |
| 2026-05-26 | User flagged that Egg assets no longer appeared present. Revision 4R restored a standalone four-frame Root Egg idle loop, wired it into cold open/Forge Hub, and added smoke coverage for Egg asset loading. Smoke still passed. |
| 2026-05-26 | User flagged that every attack needs its own visually interesting animation sprite. Revision 4S regenerated distinct Root Spark, Thorn Surge, Guarded Spark, and Data Leak strips; wired Guarded Spark to its own assets/VFX/audio; and updated smoke/capture coverage. Smoke still passed. |
| 2026-05-26 | User clarified the 4S requirement must scale to all attacks and defenses for every dragon and NPC. Added `design/art/battle-animation-coverage.md` as the production carry-forward coverage plan and implementation gate. |
| 2026-05-26 | Added `docs/architecture/battle-animation-manifest-schema.md` and synced ADR-0007, control manifest, and architecture registry so BattleDefinition + MoveDefinition must resolve actor/action animation bindings through BattleAnimationManifest. |
| 2026-05-26 | Added initial production Godot Resource classes and GUT coverage for BattleAnimationManifest, BattleDefinition, MoveDefinition, actor sets, action bindings, clips, and manifest validation. Focused validator suite passes with 8 tests / 17 assertions. |
| 2026-05-26 | Authored the first real `.tres` content fixture at `assets/battle/`: Root Wyrmling vs Admin Protocol manifest, Village Edge battle definition, four move definitions, promoted frame-sequence assets, per-action preview sheets, VFX, and runtime captures. Integration fixture validates the real content. |
| 2026-05-26 | Wired the standalone vertical slice battle presentation to a prototype-local mirror of that `.tres` fixture. Battle drawing now resolves Root Spark, Thorn Surge, Guarded Spark, Data Leak, idle, and VFX keys from the manifest; smoke verifies manifest keys before completing the full loop. |
| 2026-05-26 | Replaced copied/slice-derived Root/Admin reaction coverage with dedicated generated telegraph, hurt, defend-start, defend-hit, and KO strips. Updated preview sheets, manifests, prototype mirror, runtime captures, and smoke/integration gates. |
| 2026-05-27 | User flagged that the player-facing telegraph copy implied choosing a telegraph action. Revision 4T keeps `telegraph` as the internal engine phase but changes playable UI to enemy-warning language: `INCOMING: DATA LEAK`, `ADMIN WARNING`, and response buttons. Smoke now asserts the confusing phrasing stays out of battle copy. |
| 2026-05-27 | User requested Punch-Out!! / Zelda II / SMB-style interstitial energy instead of the tedious ambient bed. Revision 4U generated four original NES-style WAV cues, changed runtime music from one ducked MP3 to scene-swapped cues, and added smoke coverage for cue selection and Godot WAV loading. |
| 2026-05-27 | User reported hearing no music. Revision 4V confirmed the generated WAVs were not silent but the runtime mix was buried at -28 to -34 dB; raised scene music targets to -16/-15/-14/-13 dB and added smoke coverage requiring audible music targets. |
| 2026-05-27 | User still heard no music while SFX remained clear. Revision 4W found looped raw WAV cues had `loop_end = 0`; runtime now assigns explicit loop ranges, and smoke asserts looping cues have valid `AudioStreamWAV` loop ranges. |
| 2026-05-27 | User approved music audibility but noted battle music should indicate tension. Revision 4X rewrote only `music_battle_data_bout.wav` with faster tempo, darker diminished/chromatic motifs, tighter bass pressure, and denser noise percussion. |
| 2026-05-27 | User retested Revision 4X and judged the slice acceptable. Logged the acceptance in `PLAYTEST.md` and created `production/playtests/playtest-2026-05-27-scott-vertical-slice.md`. |

## Recommended Next Steps

1. Keep feature additions frozen until the representative art pass lands.
2. Use the approved target board at `design/art/target-frames/vertical-slice-target-board-approved-2026-05-26.png` as the visual source of truth.
3. Treat Revision 4X as acceptable for Pre-Production reporting; stop open-ended vertical-slice patching unless a new blocker appears.
4. Run the formal Pre-Production gate/readiness review when epics, stories, and first sprint plan exist.
5. Next pipeline step: `/create-epics`, then `/create-stories` for the first production slice.
