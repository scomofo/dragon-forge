# Dragon Forge — Godot Rebuild Design

**Status:** Approved 2026-05-01
**Goal:** Rebuild the Vite/React Dragon Forge in Godot 4.6 with the same game design but a native upgrade in feel (animated battles, real tilemap map, controller-first UX, particle/shader VFX).

## Decisions (from brainstorming)

| # | Decision |
|---|---|
| 1 | **Scope:** Port + native upgrade. All 12 Vite screens, but use Godot strengths where they're a clear win. |
| 2 | **Existing project:** Archive `dragon-forge-godot/` → `dragon-forge-godot-archive/`, build a fresh project alongside. Salvage at most: nothing committed up front; lift snippets only when clearly useful and on-direction. |
| 3 | **Target:** Desktop / Windows only. Free to use particles, shaders, controller rumble, larger sprite sheets. No web export concerns. |
| 4 | **Art:** Reuse existing `assets/` from the Vite build. Generate gaps (24 dragon evolution sheets, 10 NPC sheets, new battle VFX, Singularity corruption overlays) via inference.sh and app.1minai.com. |
| 5 | **Sim port:** Auto-translate content tables (`gameData`, `shopItems`, `singularityBosses`, `loreCanon`, `felixDialogue`, `journalMilestones`, etc.) to JSON loaded by Godot. Hand-port engines (`battleEngine`, `fusionEngine`, `hatcheryEngine`, `animationEngine`, `singularityProgress`). vitest cases become GUT acceptance tests. `DEFAULT_SAVE` → `SaveData` Resource. |

## Source-of-truth mapping

| Vite (web) | Godot (rebuild) |
|---|---|
| `src/gameData.js` | `data/game_data.json` + `scripts/sim/game_data.gd` loader |
| `src/forgeData.js`, `src/shopItems.js`, `src/singularityBosses.js`, `src/journalMilestones.js`, `src/loreCanon.js`, `src/felixDialogue.js`, `src/sprites.js` | `data/*.json` + matching loader scripts |
| `src/battleEngine.js` (+ `.test.js`) | `scripts/sim/battle_engine.gd` (+ `tests/test_battle_engine.gd`) |
| `src/fusionEngine.js` (+ `.test.js`) | `scripts/sim/fusion_engine.gd` (+ test) |
| `src/hatcheryEngine.js` (+ `.test.js`) | `scripts/sim/hatchery_engine.gd` (+ test) |
| `src/animationEngine.js` | `scripts/sim/animation_engine.gd` (+ AnimationPlayer integration) |
| `src/soundEngine.js` (750 lines, includes generated music) | `scripts/sim/audio_director.gd` + `audio/` bus setup. Music WAVs/OGGs exported once and shipped as files. |
| `src/persistence.js` (`DEFAULT_SAVE`) | `scripts/sim/save_data.gd` (`Resource`) + `scripts/sim/save_io.gd` (load/save to `user://save.tres`) |
| `src/App.jsx` screen switcher | `scenes/main.tscn` + `scripts/main.gd` scene router |
| 12 `*Screen.jsx` files | 12 `scenes/screens/*.tscn` + matching `scripts/screens/*.gd` |
| `src/gamepadInput.js`, `src/useGamepadController.js` | Godot `InputMap` actions + `scripts/sim/input_router.gd` |

## Project structure

```
dragon-forge-godot/                    (fresh)
  project.godot
  data/                                (auto-translated content)
    game_data.json
    forge_data.json
    shop_items.json
    singularity_bosses.json
    journal_milestones.json
    lore_canon.json
    felix_dialogue.json
    sprite_manifest.json
  assets/                              (copied from repo-root assets/, plus generated gaps)
    dragons/  eggs/  npc/  vfx/  arenas/  decoration/  music/
  scripts/
    main.gd                            (scene router)
    sim/                               (pure logic, no scene refs)
      game_data.gd                     (loads data/*.json into typed dicts)
      battle_engine.gd
      fusion_engine.gd
      hatchery_engine.gd
      animation_engine.gd
      audio_director.gd                (autoload)
      save_data.gd                     (Resource)
      save_io.gd
      input_router.gd                  (autoload)
      singularity_progress.gd
    screens/                           (one file per Vite screen)
      title_screen.gd
      hatchery_screen.gd
      battle_select_screen.gd
      battle_screen.gd
      fusion_screen.gd
      journal_screen.gd
      campaign_map_screen.gd
      shop_screen.gd
      stats_screen.gd
      settings_screen.gd
      singularity_screen.gd
      forge_screen.gd
    components/                        (reusable scene scripts)
      dragon_sprite.gd
      egg_sprite.gd
      npc_sprite.gd
      vfx_overlay.gd
      damage_number.gd
      toast.gd
      nav_bar.gd
      sound_toggle.gd
  scenes/
    main.tscn
    screens/*.tscn                     (12)
    components/*.tscn
  tests/                               (GUT)
    test_battle_engine.gd
    test_fusion_engine.gd
    test_hatchery_engine.gd
    test_lore_canon.gd
    test_save_io.gd
  tools/
    translate_content.mjs              (one-shot Node script: reads src/*.js exports → writes data/*.json)
    asset_gen/                         (inference.sh / 1minai prompt scripts)

dragon-forge-godot-archive/            (renamed from current dragon-forge-godot/)
```

## Scene routing

`main.gd` mirrors `App.jsx`'s screen switcher. It owns:
- `current_screen: Node` (the currently-instanced screen scene)
- `save: SaveData` (loaded once from `user://save.tres`, passed to screens)
- `battle_config: Dictionary` (set when entering battle, includes `return_screen: String`)
- A signal `screen_change_requested(target: String, payload: Variant)` that screens emit

Transition: free `current_screen`, instance the new scene, attach signals, hand it `save`. Music/SFX hooks call `AudioDirector` (autoload) the same way the Vite version calls `playMusic()` / `playSound()` in `handleNavigate`.

Screens never know about each other — they emit `screen_change_requested` and let `main.gd` route. This matches the Vite pattern and keeps each screen testable in isolation.

## Save / data flow

`SaveData` is a `Resource` with the same shape as `DEFAULT_SAVE`:
- Top-level fields: `dragons`, `data_scraps`, `pity_counter`, `milestones`, `defeated_npcs`, `singularity_progress`, `singularity_complete`, `inventory`, `stats`, `last_daily_completed`, `records`, `flags`, `skye`
- `dragons` is a `Dictionary[String, DragonState]` where `DragonState` is itself a small `Resource` (`level`, `xp`, `owned`, `shiny`, `fused_base_stats`)

`save_io.gd` provides:
- `load() -> SaveData` — reads `user://save.tres`, runs migration, returns
- `save(data: SaveData) -> void` — writes to `user://save.tres`
- Migration mirrors `migrateSave()` in `persistence.js`

Mutation pattern: screens call helpers on `save_io.gd` (e.g. `save_io.add_scraps(amount)`), which mutate the autoloaded `SaveData` and persist. This is cleaner than the Vite pattern of "mutate localStorage then `refreshSave()`" and removes the manual refresh.

## Native upgrades over Vite

Areas where Godot earns its keep:

1. **Battle scenes** — replace CSS-keyframe attack animations with `AnimationPlayer` tracks, particle systems for elemental VFX, screen shake / flash via `Camera2D`. The `battlePresentation.js` separation already lines up with this — the engine stays pure, presentation moves into a Godot scene.
2. **Campaign map** — replace the static `CampaignMapScreen.jsx` node graph with a `TileMap`-based world the player walks across, nodes as interactable objects. Reuse `campaignMap.js` data, drive movement with the input router.
3. **Singularity corruption** — replace CSS `corruption-stage-N` filters with a `CanvasModulate` + post-process shader on the screen layer. Far better visual ceiling for the endgame arc.
4. **Controller-first UI** — Godot focus system + `InputMap` give us proper controller nav for free; replace the bespoke `useGamepadController` hook.
5. **Audio** — Godot's audio buses + bus effects replace the 750-line `soundEngine.js` (most of which is web-audio music synthesis). Music is exported to OGG/WAV once and played via streams.

## Asset pipeline

- **Reused as-is:** dragons (where present), eggs, arenas, decoration, NPCs (where present), VFX strips, Felix portrait, music tracks.
- **To generate** (inference.sh primary, 1minai for variations / consistency):
  - 24 dragon evolution sheets (6 elements × 4 stages: Baby / Juvenile / Adult / Elder)
  - 10 NPC sheets (5 new NPCs × idle + attack)
  - New battle VFX particle textures (one per element family, ~6)
  - Singularity corruption overlay textures (3 stages)
- Generation scripts live in `tools/asset_gen/`, parameterized by element + stage. Outputs land in `assets/dragons/<element>/<stage>.png` etc.
- Style guide is captured from existing assets — `tools/asset_gen/style_reference.md` documents palette, line weight, frame size, animation cadence so generated art stays cohesive.

## Testing

- **GUT** for engine tests. Each Vite vitest case becomes a GUT case with the same inputs/expected outputs. Treat the JS test suite as the spec — when GUT matches, the port is correct.
- **Headless smoke test** (carried over from the archived project): `--script res://tests/sim_smoke.gd` instantiates each screen and asserts no errors. Runs in CI.
- **Save round-trip test** ensures `SaveData` Resource serializes / deserializes cleanly through migration.

## Build sequence (preview — full plan in writing-plans)

1. Archive existing project, scaffold fresh Godot 4.6 project, copy assets, set up autoloads.
2. Write `tools/translate_content.mjs`, run it, commit `data/*.json`.
3. Port `save_data.gd` + `save_io.gd`, with round-trip test.
4. Port engines (`battle`, `fusion`, `hatchery`, `animation`, `singularity_progress`) with GUT tests mirroring vitest.
5. Build the **vertical slice screens first** in this order: Title → Hatchery → Battle Select → Battle → Fusion. This is the core loop that proves the rebuild works.
6. Build the supporting screens: Campaign Map (with TileMap upgrade), Shop, Forge, Journal, Stats, Settings, Singularity (with shader upgrade).
7. Asset gap generation pass (in parallel with screen work once the manifest is stable).
8. Polish: controller rumble, screen transitions, audio mixing, particle tuning.

## Out of scope

- Web/mobile export
- Multiplayer
- Loading existing browser localStorage saves into the Godot build (we keep the schema compatible, but no automated import tool)
- Refactoring the Vite build (it stays as the live web version untouched)
