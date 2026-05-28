# Dragon Forge Vertical Slice Asset Manifest

// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
// Date: 2026-05-26

## Purpose

This folder contains project-local raster assets for the Dragon Forge vertical-slice prototype. Revisions 4I-4S replace the worst rejected procedural art with approved-direction target-board assets, focused animation frames, background-only runtime composition assets, battle-readable opaque frames, a licensed retro UI font, restored standalone Root Egg frames, and distinct per-attack battle strips. These files are production-direction retest assets, not final shipping art.

## Generation

The older procedural/DragonSim placeholder generator is now guarded because it can overwrite the target-board assets. Run it only when intentionally regenerating deprecated placeholder output:

```bash
godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tools/generate_slice_assets.gd -- --force-placeholder-regen
```

Normal asset buildout should use the approved target boards under `design/art/target-frames/`, crop/normalize outputs into `res://assets/slice/`, and archive replaced assets before overwriting.

Attack animation retest assets can be reproduced with:

```bash
/Users/Scott_1/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 prototypes/dragon-forge-vertical-slice/tools/generate_attack_animation_assets.py
```

## Assets

| File | Use |
|---|---|
| `forge_hub.png` | Forge Hub backdrop: server rack, forge, hatchery ring, Bulkhead |
| `hatchery.png` | Hatchery result backdrop |
| `village_edge_map.png` | Campaign Map / Village Edge backdrop |
| `battlefield.png` | Battle backdrop and telegraph staging |
| `victory.png` | Reward/route-clear backdrop |
| `root_wyrmling.png` | Root Wyrmling sprite |
| `felix.png` | High-fidelity Professor Felix bust derived from DragonSim `app/public/felix.png`; replaces the rejected low-detail generated sprite |
| `felix_portrait.png` | Larger Professor Felix portrait derived from DragonSim `app/public/felix.png` |
| `enemy_protocol.png` | Detached Training Protocol enemy sprite |
| `root_egg.png` | Root Egg sprite |
| `root_egg_idle_0.png` - `root_egg_idle_3.png` | Four-frame standalone Root Egg idle/pulse loop for cold open, Forge Hub, and hatch fallback |
| `data_scraps.png` | Reward/Data Scraps sprite |
| `dragonsim_fire.png` | Imported Fire dragon reference sprite |
| `dragonsim_ice.png` | Imported Ice dragon reference sprite |
| `dragonsim_shadow.png` | Imported Shadow dragon reference sprite |
| `dragonsim_stone.png` | Imported Stone dragon reference sprite |
| `dragonsim_storm.png` | Imported Storm dragon reference sprite |
| `dragonsim_venom.png` | Imported Venom dragon reference sprite |
| `npc_logic_bomb.png` | Imported DragonSim Logic Bomb support enemy sprite |
| `npc_recursive_golem.png` | Imported DragonSim Recursive Golem support enemy sprite |
| `root_attack_0.png` - `root_attack_3.png` | Four-frame Root attack strip extracted from the approved Revision 4I target board |
| `enemy_attack_0.png` - `enemy_attack_3.png` | Four-frame enemy attack strip derived from DragonSim `shadow_attack.png` for the hostile protocol's Data Leak beat |
| `root_idle_0.png` - `root_idle_3.png` | Four-frame Root Wyrmling idle/breath loop derived from the approved Root starter source |
| `enemy_idle_0.png` - `enemy_idle_3.png` | Four-frame hostile Admin Protocol idle/glitch loop |
| `root_spark_attack_0.png` - `root_spark_attack_5.png` | Six-frame Root Spark move strip |
| `thorn_surge_attack_0.png` - `thorn_surge_attack_5.png` | Six-frame Thorn Surge heavy move strip |
| `guarded_spark_attack_0.png` - `guarded_spark_attack_5.png` | Six-frame Guarded Spark shield/counter move strip |
| `root_idle_battle_0.png` - `root_idle_battle_3.png` | Hard-opaque battle-only Root idle frames for readability over detailed arenas |
| `enemy_idle_battle_0.png` - `enemy_idle_battle_3.png` | Hard-opaque battle-only Admin Protocol idle frames |
| `root_spark_attack_battle_0.png` - `root_spark_attack_battle_5.png` | Hard-opaque battle-only Root Spark frames |
| `thorn_surge_attack_battle_0.png` - `thorn_surge_attack_battle_5.png` | Hard-opaque battle-only Thorn Surge frames |
| `guarded_spark_attack_battle_0.png` - `guarded_spark_attack_battle_5.png` | Hard-opaque battle-only Guarded Spark frames |
| `enemy_data_leak_0.png` - `enemy_data_leak_5.png` | Six-frame enemy Data Leak effect strip |
| `hatch_reveal_0.png` - `hatch_reveal_7.png` | Eight-frame hatching overlay for Hatchery Result |
| `data_scraps_pickup_0.png` - `data_scraps_pickup_3.png` | Four-frame reward pickup loop for Victory/Return |
| `vfx_root_spark.png` | Root Spark impact VFX sprite |
| `vfx_thorn_surge.png` | Thorn Surge special-move VFX sprite |
| `vfx_guarded_spark.png` | Guarded Spark shield/counter VFX sprite |
| `vfx_shadow_burst.png` | Enemy Data Leak / shadow impact VFX sprite |

## Revision 4I Asset Buildout

Files replaced from the approved target board:

- `hatchery.png`
- `battlefield.png`
- `victory.png`
- `root_wyrmling.png`
- `root_egg.png`
- `root_attack_0.png` through `root_attack_3.png`
- `vfx_root_spark.png`
- `vfx_thorn_surge.png`

Review copies and a preview sheet live in `design/art/target-frames/extracted-assets/`. The previously rejected versions are archived under `assets/slice/rejected-revision-4g/`.

## Revision 4J Asset Buildout

Files replaced from the second approved-direction target board:

- `forge_hub.png`
- `village_edge_map.png`
- `enemy_protocol.png`
- `data_scraps.png`
- `enemy_attack_0.png` through `enemy_attack_3.png`
- `vfx_shadow_burst.png`

Review copies and a preview sheet live in `design/art/target-frames/extracted-assets-2/`. The prior versions are archived under `assets/slice/rejected-revision-4i/`.

## Revision 4K Animation Buildout

New sprite-animation frame sets:

- `root_idle_0.png` through `root_idle_3.png`
- `enemy_idle_0.png` through `enemy_idle_3.png`
- `root_spark_attack_0.png` through `root_spark_attack_5.png`
- `thorn_surge_attack_0.png` through `thorn_surge_attack_5.png`
- `enemy_data_leak_0.png` through `enemy_data_leak_5.png`
- `hatch_reveal_0.png` through `hatch_reveal_7.png`
- `data_scraps_pickup_0.png` through `data_scraps_pickup_3.png`

Runtime integration lives in `src/VerticalSliceController.gd`. Review copies and sprite sheets live in `design/art/target-frames/animation-buildout-1/`.

## Revision 4L Background-Only Composition

Files replaced with background-only crops so runtime sprites/animations do not duplicate baked target-frame actors:

- `battlefield.png`
- `victory.png`
- `hatchery.png`

Review copies live in `design/art/target-frames/background-only-buildout/`. The previous character-baked versions are archived under `assets/slice/rejected-character-baked-backgrounds/`.

## Revision 4N Battle Opacity And Retro UI

Battle-only hard-opaque variants were added for Root/Admin combatants and wired into the battle renderer. Review copies live in `design/art/target-frames/battle-opacity-buildout/`.

UI font stand-in:

- `prototypes/dragon-forge-vertical-slice/assets/ui/dragon_forge_8bit_standin.ttf`

This font was a temporary non-antialiased monospaced stand-in. It remains as a fallback only after Revision 4O.

## Revision 4O Licensed Pixel Font

Online search was used to replace the temporary UI font with a licensed retro pixel typeface:

- `prototypes/dragon-forge-vertical-slice/assets/ui/PressStart2P-Regular.ttf`
- `prototypes/dragon-forge-vertical-slice/assets/ui/PressStart2P-OFL.txt`
- `prototypes/dragon-forge-vertical-slice/assets/ui/README.md`

Source: Google Fonts `ofl/pressstart2p`.

License: SIL Open Font License 1.1.

Runtime integration lives in `src/VerticalSliceController.gd`, which loads Press Start 2P first and falls back to `dragon_forge_8bit_standin.ttf` if the licensed font fails to load.

## Audio Assets

| File | Use |
|---|---|
| `../audio/atk_static_discharge.wav` | Root Spark and hostile Data Leak windup SFX, copied from DragonSim |
| `../audio/atk_fire_slash.wav` | Thorn Surge windup SFX, copied from DragonSim |
| `../audio/hit_crit_thud.wav` | Shared impact hit SFX, copied from DragonSim |
| `../audio/boss_low_heartbeat.wav` | Low-end battle body layer for Root Spark, Thorn Surge, hatch, and impacts, copied from DragonSim |
| `../audio/boss_void_glitch.wav` | Admin Data Leak and enemy collapse glitch layer, copied from DragonSim |
| `../audio/forge_quantum_break.wav` | Heavy Thorn Surge / enemy collapse break layer, copied from DragonSim |
| `../audio/atk_glacier_crack.wav` | Sharp impact/crack layer for battle hits, copied from DragonSim |
| `../audio/hatch_shiny_sting.wav` | Hatch completion and reward shimmer layer, copied from DragonSim |

## Revision 4P Battle Telegraph And Layered SFX

The unclear center battle spinner was removed. Battle TELEGRAPH feedback now renders as enemy-attached brackets, a flashing `!`, and compact intent labels.

SFX playback now uses six rotating `AudioStreamPlayer` voices so layered cues can overlap. Runtime integration lives in `src/VerticalSliceController.gd`.

## Revision 4R Root Egg Asset Restoration

User flagged that the slice no longer appeared to have Egg assets. `root_egg.png` still existed, but it was functioning like a small prop or as part of `hatch_reveal_*`, so the egg no longer read as a standalone asset beat.

Restored / added:

- `root_egg_idle_0.png` through `root_egg_idle_3.png`

Review copies:

- `design/art/target-frames/egg-asset-restoration/`

Runtime integration:

- Forge Hub and the Root Egg cold-open beat now use `root_egg_idle_*`.
- Hatchery reveal keeps using `hatch_reveal_*`, with `root_egg_idle_*` as the fallback if reveal frames are missing.
- Smoke test now asserts `root_egg` and `root_egg_idle_0` load.

## Revision 4S Distinct Attack Animation Sprites

User flagged that each attack needs its own visually interesting animation sprite. The previous Root Spark and Thorn Surge strips were too close to each other, and Guarded Spark reused Root Spark.

Generated / replaced:

- `root_spark_attack_0.png` through `root_spark_attack_5.png`
- `root_spark_attack_battle_0.png` through `root_spark_attack_battle_5.png`
- `thorn_surge_attack_0.png` through `thorn_surge_attack_5.png`
- `thorn_surge_attack_battle_0.png` through `thorn_surge_attack_battle_5.png`
- `guarded_spark_attack_0.png` through `guarded_spark_attack_5.png`
- `guarded_spark_attack_battle_0.png` through `guarded_spark_attack_battle_5.png`
- `enemy_data_leak_0.png` through `enemy_data_leak_5.png`
- `vfx_root_spark.png`
- `vfx_thorn_surge.png`
- `vfx_guarded_spark.png`
- `vfx_shadow_burst.png`

Visual identities:

- Root Spark: forward bolt lunge with cyan/gold electrical clusters.
- Thorn Surge: ground-root eruption with bark, green thorns, and leaf/shard bursts.
- Guarded Spark: cyan/green shield sigil with a small counterbolt.
- Data Leak: hostile magenta/cyan glitch stream and data shards.

Review copies:

- `design/art/target-frames/attack-animation-buildout-2/`
- Preview sheet: `design/art/target-frames/attack-animation-buildout-2/attack-animation-buildout-2-preview-2026-05-26.png`

Runtime integration:

- `Guarded Spark` now has its own frame prefix and VFX instead of reusing Root Spark.
- Screenshot capture now records Root Spark, enemy Data Leak, Thorn Surge, and Guarded Spark in one scripted pass.
- Smoke test now asserts all required attack/VFX textures load and completes battle using Root Spark -> Thorn Surge -> Guarded Spark.

## Replacement Notes

- The old Revision 4G `hatchery.png` and `victory.png` were explicitly rejected as representative vertical-slice art and are archived under `rejected-revision-4g/`; do not restore them for retest.
- Do not spend another pass adding code-drawn shapes or simple overlays to these PNGs. Future improvements should be standalone generated or hand-painted production-direction frames based on the approved target board.
- Approved target-frame direction now lives at `design/art/target-frames/vertical-slice-target-board-approved-2026-05-26.png`, with notes in `design/art/target-frames/vertical-slice-target-frames.md`. Use that board as the source of truth for the next asset replacement pass.
- Keep the same filenames if replacing with hand-made or AI-generated production-adjacent assets.
- Current `VerticalSliceController.gd` loads PNGs directly with `Image.load()` and `ImageTexture.create_from_image()` so the prototype does not depend on Godot import metadata.
- Target style is art-bible aligned: 16-bit pastoral RPG surface with cyber-retro diagnostic overlays, charcoal UI, Data Cyan focus, Restored Gold rewards, and Render Green life/Root element.
- External DragonSim planning docs and assets are reconciled in `DRAGONSIM-RECONCILIATION.md`. DragonSim is now a required visual-guidelines source for the slice asset pass. Felix must remain derived from the DragonSim source image unless a later replacement is explicitly approved.
- The earlier generated/pixel-block Felix sprite is retired and must not be reused.
- Prefer clean DragonSim `app/public/` runtime assets over raw source-sheet material when both exist. Raw `assets/` files remain reference/fallback inputs unless explicitly called out above.
- AI generation or online asset sourcing can be used for the next pass, but only from approved in-game seed frames or clearly licensed sources, and with the same filenames/transparent PNG expectations so this manifest remains stable.
- Battle animation strips intentionally preserve DragonSim's chunky four-frame, 90s console battle cadence. Improve them by normalizing anchors, adding in-between polish, or regenerating full strips from approved seeds; do not replace the battle mode with static click feedback.
- Root Spark, Thorn Surge, Guarded Spark, and enemy Data Leak now have separate six-frame strips. Preserve this move distinction in future sprite generation.
- Audio is loaded with `AudioStreamWAV.load_from_file()` so the slice can use raw copied WAVs without relying on Godot import metadata.
- Do not run the older placeholder generator without `--force-placeholder-regen`; doing so intentionally reverts target-board assets to deprecated generated placeholders.
