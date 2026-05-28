# Dragon Forge Vertical Slice Target Frames

> **Status**: Approved direction
> **Approved by**: Scott
> **Date**: 2026-05-26
> **Source image**: `vertical-slice-target-board-approved-2026-05-26.png`
> **Purpose**: Freeze feature additions and establish visual source-of-truth before replacing vertical-slice art.

## Approval Summary

Scott approved the generated target-frame contact sheet with "love that." Treat this board as the art-direction gate for the next vertical-slice asset pass. The current Godot slice should not receive new mechanics or more procedural/code-drawn visual patches until assets are replaced from this direction.

## Approved Frames

1. **Hatchery** - Warm forge workshop plus ancient server machinery. Felix, Skye, and the Root Egg are staged around an intimate hatching beat with gold/green life light and cyan diagnostic traces.
2. **Village Edge Battle** - Low-angle DragonSim-style arena with pastoral surface, exposed hardware seams, and a clear ground plane around 70% down the frame.
3. **Victory / Return** - Stabilized route and recovered Data Scraps without treasure-chest shorthand. Reward should read as repaired signal and recovered hostile code.
4. **Root Wyrmling** - Creature-first Root starter with root-antler horns, bark plates, green/gold body, cyan sap/circuit markings, expressive eyes, and bottom-center battle stance.
5. **Root Attack / VFX Strip** - Four-frame attack direction preserving one shared Root Wyrmling silhouette and anchor: idle/windup, root spark charge, thorn surge impact, recoil/settle.

## Production Rules

- Preserve the art bible rule: warm 16-bit pastoral RPG being visibly debugged by ancient machinery.
- Preserve DragonSim-quality pixel rendering, not simple block shapes or abstract diagnostic panels.
- Preserve Felix identity from DragonSim: messy white hair, expressive grin, long coat, glowing cyan-green goggles.
- Do not use captions, filenames, or UI labels inside generated art.
- Do not treat the approved board as final shipping art. It is a target frame for generating or painting replacement assets.
- Keep runtime replacement filenames stable where possible: `hatchery.png`, `battlefield.png`, `victory.png`, `root_wyrmling.png`, `root_attack_0.png` through `root_attack_3.png`, and Root VFX files.

## Next Work Order

1. Split the approved board into per-frame briefs.
2. Generate or paint individual production-direction assets from each brief.
3. For Root attack, start from an approved Root Wyrmling seed frame and generate the full strip together, then normalize scale and bottom-center anchor before engine integration.
4. Replace prototype PNGs only after the individual assets match this target board.
5. Run an in-user-build playtest with music/SFX enabled before reconsidering the vertical-slice verdict.

## Asset Buildout 1 - 2026-05-26

The approved board has been split into first-pass prototype replacement assets. These are production-direction assets for retest, not final shipping art.

Output folders:

- Reviewable extracted assets: `design/art/target-frames/extracted-assets/`
- Active Godot slice assets: `prototypes/dragon-forge-vertical-slice/assets/slice/`
- Archived rejected assets: `prototypes/dragon-forge-vertical-slice/assets/slice/rejected-revision-4g/`

Generated / replaced files:

- `hatchery.png`
- `battlefield.png`
- `victory.png`
- `root_wyrmling.png`
- `root_egg.png`
- `root_attack_0.png` through `root_attack_3.png`
- `vfx_root_spark.png`
- `vfx_thorn_surge.png`

Preview sheet:

- `design/art/target-frames/extracted-assets/asset-build-preview-2026-05-26.png`

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- Result: complete loop reached with 65 Data Scraps.

Known limitations:

- Hatchery uses a full portrait target frame adapted into the slice's current 16:9 stage with side-fill. It should be reviewed in-engine before final approval.
- Root VFX are extracted from the approved strip and may still need a clean artist-generated transparent pass before production.
- This buildout intentionally does not add new mechanics or new slice states.

## Asset Buildout 2 - 2026-05-26

The second buildout extends the approved direction to the remaining older visual beats and the hostile admin effects. It uses a new generated target sheet:

- `design/art/target-frames/vertical-slice-target-board-2-approved-direction-2026-05-26.png`

Output folders:

- Reviewable extracted assets: `design/art/target-frames/extracted-assets-2/`
- Active Godot slice assets: `prototypes/dragon-forge-vertical-slice/assets/slice/`
- Archived prior assets: `prototypes/dragon-forge-vertical-slice/assets/slice/rejected-revision-4i/`

Generated / replaced files:

- `forge_hub.png`
- `village_edge_map.png`
- `enemy_protocol.png`
- `data_scraps.png`
- `enemy_attack_0.png` through `enemy_attack_3.png`
- `vfx_shadow_burst.png`

Preview sheet:

- `design/art/target-frames/extracted-assets-2/asset-build-preview-2-2026-05-26.png`

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- Result: complete loop reached with 65 Data Scraps.

Pipeline guard:

- `tools/generate_slice_assets.gd` is now guarded so it will not overwrite target-board assets unless explicitly run with `--force-placeholder-regen`.

## Animation Buildout 1 - 2026-05-26

The first sprite-animation pass adds the minimum frame coverage needed for a more alive vertical-slice retest. It does not add mechanics or new states.

Output folders:

- Individual frame assets: `prototypes/dragon-forge-vertical-slice/assets/slice/`
- Review copies: `design/art/target-frames/animation-buildout-1/`
- Horizontal review sheets: `design/art/target-frames/animation-buildout-1/sheets/`
- Source snapshot before animation derivation: `prototypes/dragon-forge-vertical-slice/assets/slice/animation-buildout-1-source-snapshot/`

Generated frame sets:

- `root_idle_0.png` through `root_idle_3.png`
- `enemy_idle_0.png` through `enemy_idle_3.png`
- `root_spark_attack_0.png` through `root_spark_attack_5.png`
- `thorn_surge_attack_0.png` through `thorn_surge_attack_5.png`
- `enemy_data_leak_0.png` through `enemy_data_leak_5.png`
- `hatch_reveal_0.png` through `hatch_reveal_7.png`
- `data_scraps_pickup_0.png` through `data_scraps_pickup_3.png`

Review sheets:

- `design/art/target-frames/animation-buildout-1/animation-buildout-preview-2026-05-26.png`
- `design/art/target-frames/animation-buildout-1/animation-sheets-review-2026-05-26.png`

Runtime integration:

- Root idle now plays on map, battle idle, and victory.
- Root Spark and Thorn Surge now use separate six-frame attack strips.
- Enemy idle now flickers during battle; Data Leak uses a six-frame effect strip.
- Hatchery now overlays an eight-frame hatch reveal.
- Victory now loops a four-frame Data Scraps pickup animation.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- `godot --path prototypes/dragon-forge-vertical-slice -s res://tools/capture_slice_screenshots.gd`
- Result: complete loop reached with 65 Data Scraps.
- Runtime captures: `design/art/target-frames/runtime-captures/`

## Background-Only Composition Pass - 2026-05-26

Revision 4L removes baked actor duplication from the runtime backgrounds. Earlier target-board backdrops included dragons, enemies, Felix, Skye, or the egg as part of the painted scene; the runtime now has animated sprites for those subjects, so those baked actors would fight the animation layer.

Source board:

- `design/art/target-frames/vertical-slice-background-only-board-2026-05-26.png`

Output folders:

- Reviewable background-only crops: `design/art/target-frames/background-only-buildout/`
- Active Godot slice assets: `prototypes/dragon-forge-vertical-slice/assets/slice/`
- Archived character-baked backgrounds: `prototypes/dragon-forge-vertical-slice/assets/slice/rejected-character-baked-backgrounds/`

Replaced files:

- `battlefield.png`
- `victory.png`
- `hatchery.png`

Runtime composition changes:

- Battle and victory backdrops now leave empty actor spaces for animated sprites.
- Hatchery backdrop now leaves the hatching ring empty, while `hatch_reveal_*` supplies the egg/dragon motion.
- Felix is drawn as an overlay portrait in Hatchery so the beat keeps mentor presence without baking him into the background.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- Result: complete loop reached with 65 Data Scraps.

Capture note:

- `tools/capture_slice_screenshots.gd` exists for runtime screenshots, but it requires a display renderer. Running it with `--headless` intentionally fails because Godot's dummy renderer has no viewport texture to read.

## Revision 4M Music And Battle Readability Polish - 2026-05-26

Human retest feedback:

- Music was becoming tedious.
- Battle characters looked slightly transparent and hard to see.

Changes:

- Lowered the looping music bed and added state-based target volume:
  - Forge/Hatchery: quieter ambient bed.
  - Map: slightly ducked.
  - Battle: heavily ducked so SFX and action read first.
  - Victory/Reward: still present but less repetitive.
- Added battle actor readability rendering:
  - Dark silhouette pass behind main Root/Admin combatants.
  - Subtle element-colored glow pass.
  - Double-draw of the actual animated sprite to counter semi-transparent source pixels.
  - Background support enemies reduced in opacity so the primary target is clearer.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- Result: complete loop reached with 65 Data Scraps.

## Revision 4N Battle Opacity And Retro UI Pass - 2026-05-26

Human retest feedback:

- Battle characters were still too transparent.
- Fonts and menus read too modern for the intended 1990s console RPG feel.

Changes:

- Added hard-opaque battle-only sprite variants:
  - `root_idle_battle_0.png` through `root_idle_battle_3.png`
  - `enemy_idle_battle_0.png` through `enemy_idle_battle_3.png`
  - `root_spark_attack_battle_0.png` through `root_spark_attack_battle_5.png`
  - `thorn_surge_attack_battle_0.png` through `thorn_surge_attack_battle_5.png`
- Runtime battle now uses those battle-only variants instead of the softer source frames.
- Added a local non-antialiased monospaced font stand-in at `prototypes/dragon-forge-vertical-slice/assets/ui/dragon_forge_8bit_standin.ttf`.
- Reworked menu styling toward NES-era RPG boxes:
  - Square panel corners.
  - Higher-contrast dark menu fills.
  - Thicker light/cyan/gold borders.
  - Uppercase button text with `>` selector prefix.
  - Smaller, denser bitmap-style typography.

Known limitation:

- `dragon_forge_8bit_standin.ttf` is a temporary stand-in, not the final NES-style pixel font. It removes the modern default UI feel enough for retest, but production should replace it with an approved pixel typeface.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- Result: complete loop reached with 65 Data Scraps.

## Revision 4O Licensed Pixel Font Pass - 2026-05-26

Online search was used only for a high-confidence licensed UI foundation, not for replacing the approved visual target frames.

Added files:

- `prototypes/dragon-forge-vertical-slice/assets/ui/PressStart2P-Regular.ttf`
- `prototypes/dragon-forge-vertical-slice/assets/ui/PressStart2P-OFL.txt`
- `prototypes/dragon-forge-vertical-slice/assets/ui/README.md`

Runtime changes:

- `VerticalSliceController.gd` now loads Press Start 2P first and falls back to the previous local stand-in if needed.
- UI font sizes were reduced to account for Press Start 2P's chunkier glyph metrics.
- Battle banners and floating battle numbers now use smaller pixel-font sizes to avoid modern/vector-like presentation and layout overflow.

Source and license:

- Press Start 2P is sourced from the Google Fonts `ofl/pressstart2p` repository and is licensed under the SIL Open Font License 1.1.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- Result: complete loop reached with 65 Data Scraps.

## Revision 4P Battle Telegraph And SFX Weight Pass - 2026-05-26

Human retest feedback:

- The blue spinning ring in the middle of battle was unclear.
- Battle SFX sounded too dinky for the intended 1990s console-hit battle feel.

Visual changes:

- Removed the center TELEGRAPH spinner.
- Added enemy-attached warning/target brackets, a flashing `!`, and compact intent labels.
- The enemy warning signal now points at the Admin Protocol instead of a neutral center-screen ring.

Audio changes:

- `VerticalSliceController.gd` now uses six rotating SFX voices so layered sounds can overlap.
- SFX cues are built from layered WAVs with per-layer volume and pitch settings.
- Additional DragonSim WAVs copied into the slice:
  - `boss_low_heartbeat.wav`
  - `boss_void_glitch.wav`
  - `forge_quantum_break.wav`
  - `atk_glacier_crack.wav`
  - `hatch_shiny_sting.wav`

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- `godot --path prototypes/dragon-forge-vertical-slice -s res://tools/capture_slice_screenshots.gd`
- Result: complete loop reached with 65 Data Scraps.
- Runtime captures: `design/art/target-frames/runtime-captures/`

## Revision 4Q Narrative Cold Open Pass - 2026-05-26

Human retest feedback:

- Revision 4P was testing pretty well.
- The first meaningful action still lacked earlier exposition/narrative intro context.

Narrative changes:

- Added a three-beat cold open before Forge Hub:
  - `Rendered World Failure`
  - `Dragon Forge Signal`
  - `Root Egg`
- The beats establish world failure, Skye's resident/operator status, Felix's urgency, and the Root Egg as a living guardian.
- The first meaningful action is now explicitly framed as hatching the Root Egg.

Runtime changes:

- Added `intro_felix` and `intro_egg` states.
- Updated smoke coverage for the new intro path.
- Updated runtime capture sequencing to include the three intro beats.
- Runtime capture helper now clears old PNGs before writing the current sequence.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- `godot --path prototypes/dragon-forge-vertical-slice -s res://tools/capture_slice_screenshots.gd`
- Result: complete loop reached with 65 Data Scraps.
- Runtime captures: `design/art/target-frames/runtime-captures/`

## Revision 4R Root Egg Asset Restoration - 2026-05-26

Human retest feedback:

- The slice appeared to no longer have Egg assets.

Root cause:

- `root_egg.png` existed, but it was too easy to read as a small prop or baked hatch overlay rather than a standalone pre-hatch asset.

Asset changes:

- Added `root_egg_idle_0.png` through `root_egg_idle_3.png`.
- Review sheet: `design/art/target-frames/egg-asset-restoration/root-egg-idle-preview-2026-05-26.png`.

Runtime changes:

- Cold open and Forge Hub now render the standalone Root Egg idle loop.
- Hatchery reveal still uses `hatch_reveal_*`, with the Root Egg idle loop as fallback.
- Smoke test now asserts that `root_egg` and `root_egg_idle_0` load.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- `godot --path prototypes/dragon-forge-vertical-slice -s res://tools/capture_slice_screenshots.gd`
- Result: complete loop reached with 65 Data Scraps.
- Runtime captures: `design/art/target-frames/runtime-captures/`

## Revision 4S Distinct Attack Animation Sprites - 2026-05-26

Human retest feedback:

- Each attack needs its own visually interesting animation sprite.

Asset changes:

- Regenerated `root_spark_attack_*` and `root_spark_attack_battle_*` as a cyan/gold bolt-lunge strip.
- Regenerated `thorn_surge_attack_*` and `thorn_surge_attack_battle_*` as a bark/green ground-eruption strip.
- Added `guarded_spark_attack_*` and `guarded_spark_attack_battle_*` as a dedicated shield/counter strip.
- Regenerated `enemy_data_leak_*` as a hostile magenta/cyan glitch strip.
- Regenerated `vfx_root_spark.png`, `vfx_thorn_surge.png`, and `vfx_shadow_burst.png`; added `vfx_guarded_spark.png`.

Review copies:

- `design/art/target-frames/attack-animation-buildout-2/`
- Preview sheet: `design/art/target-frames/attack-animation-buildout-2/attack-animation-buildout-2-preview-2026-05-26.png`

Runtime changes:

- Guarded Spark now has its own sprite prefix, VFX, and layered SFX cue.
- Runtime capture sequencing now records Root Spark, enemy Data Leak, Thorn Surge, and Guarded Spark in one pass.
- Smoke coverage now asserts the distinct attack/VFX assets load and clears battle with Root Spark -> Thorn Surge -> Guarded Spark.
- Production carry-forward coverage plan: `design/art/battle-animation-coverage.md`.

Verification:

- `godot --headless --path prototypes/dragon-forge-vertical-slice --quit`
- `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`
- `godot --path prototypes/dragon-forge-vertical-slice -s res://tools/capture_slice_screenshots.gd`
- Result: complete loop reached with 65 Data Scraps.
- Runtime captures: `design/art/target-frames/runtime-captures/`
