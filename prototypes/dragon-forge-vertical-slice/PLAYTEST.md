// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
// Date: 2026-05-26

# Vertical Slice Playtest Sheet

## Build

- Path: `prototypes/dragon-forge-vertical-slice`
- Run command: `godot --path prototypes/dragon-forge-vertical-slice`
- Smoke command: `godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd`

## Test Protocol

Play from the first screen without developer guidance or shortcuts.

Target loop:

1. Start at the cold open.
2. Reach Forge Hub.
3. Hatch the Root Egg.
4. Enter Village Edge.
5. Start the training battle.
6. Win the battle.
7. Return to the Forge with the reward state visible.

## Session 1 - Internal Human Playtest

| Question | Answer |
|---|---|
| Tester | Scott |
| Date | 2026-05-26 |
| Build status before playtest | Internal smoke pass |
| Did the tester complete the full loop without guidance? | Yes; reached "Slice Loop Complete". |
| Time to first meaningful action | Under 1 minute. |
| Total loop time | Under 1 minute. |
| Did the hatch beat communicate warmth/bonding? | Weak signal: current build has no graphics and only short sentence descriptions. |
| Did the map node communicate what to do next? | Mechanically clickable, but presentation is too sparse to validate map feel. |
| Did TELEGRAPH make battle intent/actions legible? | Mechanically legible enough to click through, but too text-only to validate battle feel. |
| Was reward resolution clear? | Mechanically clear enough to complete the loop. |
| What confused or stopped the tester? | Nothing stopped completion; the major issue is that there are no graphics, no real dialogue, and only one-sentence descriptions. |
| Does this quality feel achievable for full production? | Not validated at representative quality. The loop structure is testable, but presentation/dialogue quality is below vertical-slice bar. |

## Verdict

PIVOT.

Reason: the loop is complete and fast, but the build is too text-only to validate the Dragon Forge fantasy or production-quality presentation. Keep the loop structure, but revise the slice to include representative visuals, clearer authored dialogue beats, and stronger battle/map feedback before attempting a PROCEED verdict.

## Revision 1 - Ready For Retest

Changes made after PIVOT:

- Added prototype-drawn representative panels for Forge Hub, Hatchery result, Campaign Map, Battle, and Victory/Reward states.
- Added authored Felix/System/Battle dialogue beats for start, hatch, map entry, battle telegraph, victory, defeat, and loop completion.
- Added clearer visual emphasis for dragon/enemy HP, map node path, hazard tile, reward Scraps, and Forge diagnostic motif.
- Re-ran the same automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Does the revised presentation now feel like Dragon Forge rather than a clickable outline?
2. Does Felix's dialogue improve warmth and stakes?
3. Are map/battle/reward states visually distinguishable?
4. Is the loop still clear and fast?
5. New verdict: PROCEED, PIVOT, or KILL.

Allowed verdicts:

- **PROCEED**: loop completes, fantasy is recognizable, pipeline feels achievable.
- **PIVOT**: loop has promise but one or more core assumptions need revision.
- **KILL**: repeated slice evidence shows the concept cannot deliver its fantasy or is not feasible.

## Revision 2 - Ready For Retest

Revision 1 still read as text over colored diagnostic shapes. Revision 2 responds by separating the visual stage from the reading UI:

- Rebuilt the screen layout so the illustrated scene area sits above dialogue/body/log panels instead of underneath them.
- Reworked drawn visuals to read as scene beats: Forge bench/server bars/Bulkhead, cracked Root Egg and hatchery monitors, Village Edge route nodes and hazard tile, battle silhouettes with HP bars and telegraph marker, and reward Scraps/cleared route.
- Preserved the same loop, buttons, state names, and smoke-test expectations.
- Re-ran the automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Are visuals and text now separated clearly enough to read?
2. Do the hand-drawn placeholders communicate the intended beat better than colored boxes?
3. Does the slice still feel too placeholder to validate production presentation?
4. New verdict: PROCEED, PIVOT, or KILL.

## Session 2 - Revision 2 Human Playtest

| Question | Answer |
|---|---|
| Tester | Scott |
| Date | 2026-05-26 |
| Build status before playtest | Revision 2 smoke pass |
| Did the tester complete the full loop without guidance? | Yes; the click-through loop works. |
| Was the loop mechanically readable? | Yes; state progression and clicks are understandable. |
| Did the visuals meet vertical-slice quality? | No. Visuals remain very basic, and none of the graphics are remotely production-ready. |
| Does this validate the game as a representative section of the actual product? | No. It validates structure only, not visual fantasy or production presentation. |
| What confused or stopped the tester? | Nothing blocked completion; the blocker is insufficient visual fidelity. |

## Revision 2 Verdict

PIVOT.

Reason: the interaction loop works, but the build is still a functional prototype/greybox rather than a representative vertical slice. A PROCEED verdict requires production-adjacent visuals for at least one complete hatch -> map -> battle -> reward sequence.

## Revision 3 - Ready For Retest

Revision 3 begins the production-adjacent art/UI pass requested after the Revision 2 PIVOT:

- Reworked the scene stage into a 16-bit pixel-art style presentation using crisp rectangular sprite construction instead of abstract shapes.
- Added art-bible-aligned set pieces: server racks with animated diagnostic lights, Felix sprite, forge/hearth, hatchery ring, cracked Root Egg, Root Wyrmling sprite, pastoral hills/trees, hazard tile, battle enemy sprite, telegraph marker, reward chest, and scanline/diagnostic overlays.
- Added subtle continuous animation: egg glow, dragon idle bob, server-light pulses, battle telegraph ring, corruption shimmer, reward sparkle, and stage transition flash.
- Polished button focus/hover/pressed styles toward the charcoal/cyan/gold diagnostic HUD direction.
- Preserved the same loop, state names, reward math, and smoke-test path.

Retest focus:

1. Does the build now read closer to a small 16-bit cyber-retro RPG scene rather than a greybox?
2. Are Forge, Hatchery, Map, Battle, and Reward instantly distinguishable without reading the body copy?
3. Does this feel production-adjacent enough to keep investing in the vertical slice, or does it still need actual asset production before a PROCEED verdict?

## Revision 4 - Ready For Retest

Revision 4 moves from runtime-only scene drawing to a project-local raster asset pack:

- Added generated PNG backdrops for Forge Hub, Hatchery, Village Edge Map, Battle, and Victory.
- Added generated PNG sprites for Felix, Root Egg, Root Wyrmling, Detached Training Protocol, and Data Scraps.
- Added `assets/slice/ASSET-MANIFEST.md` and `tools/generate_slice_assets.gd` so another agent can regenerate or replace the assets.
- Updated `VerticalSliceController.gd` to load the PNGs directly through `Image.load()` / `ImageTexture.create_from_image()` and draw them in the slice.
- Preserved the same loop, state names, reward math, and smoke-test path.

Retest focus:

1. Does the slice now feel asset-backed instead of code-drawn?
2. Are the raster backdrops/sprites close enough to judge the art direction?
3. If still not production-ready, which specific asset should be replaced first with hand-made or AI-generated final-direction art?

## Revision 4A - Dragonsim Asset Planning Reconciliation

After Revision 4, the older `dragonsim` asset files were reviewed and reconciled against this slice. Findings:

- The files had not been used in earlier slice planning.
- They provide useful direction for Felix, arena framing, 70% ground-plane anchoring, elemental arena mood, Null Void treatment, and future VFX prompts.
- They are not wholesale source-of-truth for this Godot slice because they come from a separate React simulator, use conflicting element labels/progression triggers, and several local PNGs are not reliable drop-in arena assets.
- The immediate change folded in is Felix's glowing goggle treatment in the generated sprite path.
- Detailed reconciliation is recorded in `assets/slice/DRAGONSIM-RECONCILIATION.md`.

## Revision 4B - Dragonsim Asset Integration

User clarified that DragonSim visual guidelines should be retained and as many DragonSim sprites as possible should be used/adapted. Revision 4B updates the asset pass accordingly:

- `felix.png` and `felix_portrait.png` are now derived from the clean DragonSim `app/public/felix.png` asset.
- `battlefield.png` is cropped from the DragonSim arena reference sheet.
- `root_wyrmling.png` is adapted from the DragonSim Venom dragon sheet as a temporary Root stand-in.
- `enemy_protocol.png` is adapted from the DragonSim Shadow dragon sheet.
- Fire, Ice, Stone, Storm, Shadow, and Venom DragonSim sprites are imported as visible Forge hologram/reference sprites.
- `DRAGONSIM-RECONCILIATION.md` now treats DragonSim as a visual-guidelines source, not merely background reference.

Retest focus:

1. Does Felix now read as the intended DragonSim Felix?
2. Do the imported dragon sprites improve perceived production quality?
3. Is the adapted Venom-as-Root sprite acceptable temporarily, or should a true Root sprite be the next asset generation target?

## Revision 4C - Felix Sprite Rejection

User clarified that the issue was the low-detail Felix sprite itself, not just source-sheet artifacts. Revision 4C retires the generated/simple Felix sprite path:

- `felix.png` is regenerated at higher fidelity from the clean DragonSim `app/public/felix.png` source.
- The hand-drawn/generated Felix fallback was removed from the asset generator.
- The code-drawn fallback Felix was removed from the Godot controller.
- Felix is now treated as a high-fidelity bust/portrait asset, not a tiny simplified body sprite.

Retest focus:

1. Does the in-slice Felix now preserve the DragonSim source quality?
2. Is Felix large/readable enough in Forge and Hatchery scenes?

## Revision 4D - DragonSim Runtime Asset Pass

Revision 4D tightens the DragonSim import path around clean runtime/exported assets:

- DragonSim `app/public/` sprites are now the preferred local source for character/enemy derivatives when available.
- The battle scene now uses the DragonSim bit-wraith as the primary enemy and adds logic-bomb plus recursive-golem support sprites as faint background threats.
- The manifest now records all imported NPC sprites and the rule that raw source-sheet material remains reference/fallback only.
- AI generation access is reserved for the next pass if the approved seed frames still need a true Root starter, stronger arena, or Root-themed VFX.
- Re-ran the automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Does the battle scene now feel more like a DragonSim-derived enemy encounter rather than a single placeholder enemy?
2. Is the current high-fidelity Felix treatment acceptable as the locked mentor source for the slice?
3. Which asset should be generated or hand-painted next: true Root Wyrmling, Village Edge battle arena, or Root/TELEGRAPH VFX?

## Revision 4E - Battle Mode Restoration

User clarified that the target battle feel is a 90s console hit: named moves, special attacks, visible windup/impact/recoil, animated attack frames, VFX, and chunky but appealing sprite timing. Revision 4E restores that direction inside the Godot slice:

- Added DragonSim-derived four-frame attack assets for the temporary Root starter and hostile protocol.
- Follow-up cleanup: the DragonSim `venom_attack.png` source was rejected because it contains baked filename/checkerboard artifacts; Root attack frames now use the clean `venom.png` seed with synthesized lunge/VFX frames.
- Added Root Spark, Thorn Surge, and Defend as named battle actions instead of a generic Attack/Defend pair.
- Added a timed battle-presentation sequence: TELEGRAPH -> player windup -> player impact -> enemy windup -> enemy impact -> TELEGRAPH / victory.
- Added impact VFX, screen shake, floating damage numbers, move banners, and battle-phase labels.
- Updated the smoke test to wait for timed battle beats instead of assuming instant damage resolution.
- Re-ran the automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Does battle now feel closer to the DragonSim/90s console inspiration?
2. Are Root Spark and Thorn Surge visually distinct enough to justify keeping both?
3. Are the four-frame attacks charmingly chunky or distractingly rough?
4. Which should be polished next: Root-specific animation frames, attack SFX, richer VFX, or a stronger arena background?

## Revision 4F - Battle Feel Polish

User clicked through Revision 4E and reported progress. Revision 4F keeps the same loop and focuses only on battle feel:

- Added DragonSim WAV assets for Root/Shadow discharge, Thorn Surge windup, and hit impact.
- Wired battle SFX to windup and impact beats through `AudioStreamWAV.load_from_file()` so raw WAVs work without import metadata.
- Made Thorn Surge read heavier than Root Spark with longer windup, larger lunge, stronger shake, and larger sprite scaling during impact.
- Added visible enemy recoil/flash on player impact and player recoil on enemy impact.
- Preserved the same damage math and reward path.
- Re-ran the timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Do SFX and recoil make hits feel more like a real battle mode?
2. Is Thorn Surge now distinct enough from Root Spark?
3. Are the remaining rough spots mostly asset-quality problems, timing problems, or arena/background problems?

## Revision 4G - Narrative Clarity Pass

User clicked through Revision 4F and reported that it was hard to tell how much lore and plot were actually represented in the slice. Revision 4G keeps the same loop and adds explicit in-world story tracking:

- Added a `SIGNAL TRACE` panel below dialogue so each state carries a compact lore/plot beat.
- Reframed the opening around Skye registering as both resident and operator of the Rendered World.
- Clarified Felix as Forge-keeper and anxious mentor who treats simulated people/dragons as alive.
- Clarified Root dragons as living guardian protocols used to anchor damaged places.
- Clarified Village Edge as pastoral surface over hardware seams.
- Clarified the battle enemy as an Admin deletion/quarantine routine, not a random monster.
- Clarified Data Scraps as recoverable hostile code that keeps the Forge awake.
- Clarified the Great Reset / Mirror Admin threat as the visible reason this first repair matters.
- Re-ran the timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Can a new player now name who Skye is and why she matters?
2. Can they explain what Felix wants?
3. Can they tell why the Root Egg, Village Edge battle, and Data Scraps matter to the plot?
4. Does the extra lore aid clarity, or does it crowd the screen?

## Session 3 - Revision 4G/4H Human Playtest

| Question | Answer |
|---|---|
| Tester | Scott |
| Date | 2026-05-26 |
| Build status before playtest | Revision 4G narrative clarity plus in-progress audio/visual attraction pass |
| Did the tester complete the loop? | Yes; clicked through the slice. |
| Did visuals and SFX create engagement? | No. Visuals and SFX are dull, there is no music in the tested feel, and there is no compelling reason to engage with the game yet. |
| Did hatchery/victory screens meet quality bar? | No. Tester called the Hatchery and Victory screens absurd. |
| Did lore/plot come through despite documentation depth? | No. The project has detailed documentation, but it is not coming through in the playable slice. |
| Art quality assessment | The newly added/procedural art reads like MS Paint and should not be considered production-adjacent. |

## Revision 4G/4H Verdict

PIVOT.

Reason: the playable slice still fails the vertical-slice promise. It has functioning loop mechanics, some imported DragonSim assets, and more explicit text, but it does not yet translate the rich documentation into a compelling audiovisual experience. Further code-drawn or procedurally composed art is unlikely to solve this. The next pass must use real art-direction and asset-production workflow: approved source frames, generated/painted production-style backgrounds, stronger character staging, music that actually plays in the user build, and less reliance on explanatory text.

## Revision 4H Target-Frame Approval

Feature additions are frozen. Scott approved the visual target board stored at `design/art/target-frames/vertical-slice-target-board-approved-2026-05-26.png`.

Retest is blocked until the slice replaces the rejected procedural art with production-direction assets derived from that target board:

1. Hatchery
2. Village Edge battle
3. Victory / Return
4. Root Wyrmling
5. Root attack / VFX strip

## Revision 4I - Asset Buildout Ready For Retest

Revision 4I builds the approved target board into first-pass slice assets:

- Replaced Hatchery, Battlefield, and Victory backgrounds with target-board-derived art.
- Replaced the temporary Venom-derived Root Wyrmling with the approved Root starter source frame.
- Replaced Root Egg, Root Spark VFX, Thorn Surge VFX, and Root four-frame attack assets from the approved board.
- Archived the rejected Revision 4G procedural assets under `assets/slice/rejected-revision-4g/`.
- Added review copies and preview sheet under `design/art/target-frames/extracted-assets/`.
- Re-ran the timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Does the slice now visually communicate the documented Dragon Forge premise without relying on explanatory text?
2. Does Hatchery feel like an emotional hatching beat rather than a placeholder screen?
3. Does Village Edge battle now read as the intended pastoral world over exposed machinery?
4. Does Victory/Return read as repaired signal and recovered code rather than absurd reward shorthand?
5. Are the Root Wyrmling and Root attack/VFX good enough to continue, or do they need a clean standalone generation pass?

## Revision 4J - Asset Buildout 2 Ready For Retest

Revision 4J continues asset replacement without adding features:

- Replaced Forge Hub with a production-direction forge/server workshop background.
- Replaced Village Edge Campaign Map with a readable pastoral-over-hardware node map.
- Replaced the hostile Admin Protocol enemy sprite with a stronger corruption/cyan admin silhouette.
- Replaced Data Scraps with a readable gold/cyan recovered-code reward pile.
- Replaced enemy attack frames and Shadow Burst VFX with cleaner Data Leak effect frames.
- Archived the replaced Revision 4I-era assets under `assets/slice/rejected-revision-4i/`.
- Added review copies and preview sheet under `design/art/target-frames/extracted-assets-2/`.
- Guarded `tools/generate_slice_assets.gd` so it does not accidentally overwrite the new target-board assets.
- Re-ran the timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Does the Forge Hub now open with the same quality signal as Hatchery/Battle/Victory?
2. Does the Campaign Map now read as a real map screen instead of a placeholder route?
3. Does the hostile Admin Protocol feel more like a meaningful first enemy?
4. Do the Data Scraps and Data Leak VFX improve reward/combat feedback?
5. Is the slice visually coherent enough to shift attention to audio/music and in-engine composition polish?

## Revision 4K - Animation Buildout Ready For Retest

Revision 4K adds focused animation coverage without changing mechanics:

- Added Root Wyrmling idle/breath loop.
- Added hostile Admin Protocol idle/glitch loop.
- Added separate six-frame Root Spark and Thorn Surge strips.
- Added six-frame enemy Data Leak strip.
- Added eight-frame Hatchery reveal overlay.
- Added four-frame Data Scraps pickup loop.
- Wired the new frames into map, battle, hatchery, and victory draw paths.
- Added review sheets under `design/art/target-frames/animation-buildout-1/`.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Does the Root Wyrmling feel alive at idle?
2. Are Root Spark and Thorn Surge now visually distinct as separate moves?
3. Does enemy Data Leak communicate hostile intent before impact?
4. Does the hatch beat feel less static?
5. Does the reward pickup feel like recovered code rather than a static icon?

## Revision 4L - Background-Only Composition Ready For Retest

Revision 4L cleans up runtime composition after the animation pass:

- Replaced Battle, Victory, and Hatchery backgrounds with background-only crops.
- Archived the previous character-baked backgrounds under `assets/slice/rejected-character-baked-backgrounds/`.
- Centered Hatchery reveal animation on the new empty hatching ring.
- Restored Felix as a runtime overlay portrait in Hatchery rather than a baked background character.
- Added `tools/capture_slice_screenshots.gd` for display-renderer screenshot capture; it intentionally refuses `--headless`.
- Confirmed CodeGraph cannot currently index this GDScript codebase because the CLI reports `*.gd` files as unsupported language.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Do Battle and Victory now avoid double-drawn actors?
2. Does the Hatchery reveal sit naturally on the background ring?
3. Does Felix's Hatchery portrait help the emotional beat without cluttering the screen?
4. Is the visual composition now coherent enough to focus the next pass on audio/music?

## Revision 4M - Music And Battle Readability Polish

Human retest feedback after Revision 4L:

- Music gets a little tedious.
- Battle characters are slightly transparent and hard to see.

Revision 4M response:

- Lowered the music from a prominent loop into an ambient bed.
- Added state-based music targets so battle and reward duck the loop further.
- Added a battle readability draw path: dark silhouette pass, subtle element glow, and double-draw for main Root/Admin combatants.
- Reduced background support-enemy opacity so they do not compete with the primary enemy.
- Preserved mechanics, timing, reward math, and asset filenames.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Is the music now less fatiguing over a full click-through?
2. Are Root Wyrmling and Admin Protocol readable on the battle background?
3. Do support enemies now read as atmosphere rather than unclear primary targets?

## Revision 4N - Battle Opacity And Retro UI Ready For Retest

Human retest feedback after Revision 4M:

- Battle characters are still too transparent.
- Fonts and menus look too modern; the slice should replicate a 1990s console RPG feel.

Revision 4N response:

- Added hard-opaque battle-only Root/Admin frame variants.
- Updated battle rendering to use those battle-specific variants.
- Added local non-antialiased monospaced font stand-in.
- Reworked menu panels and buttons toward square, high-contrast, NES-era RPG boxes.
- Buttons now use uppercase text and `>` selector prefix.
- Preserved mechanics, timing, reward math, and state flow.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.

Retest focus:

1. Are Root Wyrmling and Admin Protocol finally opaque/readable enough in battle?
2. Do menus now read closer to 1990s console RPG UI?
3. Is the temporary font acceptable for slice retest, or does it still need a true pixel font before verdict?

## Revision 4O - Licensed Pixel Font Pass Ready For Retest

User approved searching online for suitable elements where needed. Revision 4O uses that only for the clearest current gap: a licensed retro UI font.

- Added `PressStart2P-Regular.ttf` from the Google Fonts `ofl/pressstart2p` repository.
- Copied the SIL Open Font License locally as `assets/ui/PressStart2P-OFL.txt`.
- Updated runtime UI loading to use Press Start 2P first, with the older local stand-in as fallback.
- Reduced UI font sizes and battle-banner text sizing to fit the chunkier pixel typeface.
- Kept the approved art-direction assets unchanged; no web sprite/audio grab bag was imported.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.
- Ran display-renderer screenshot capture successfully; images are in `design/art/target-frames/runtime-captures/`.

Retest focus:

1. Do dialogue, status text, buttons, and battle banners now land closer to the intended 1990s/NES-era feel?
2. Are the reduced font sizes readable on the actual display?
3. Does the UI now support the slice enough to move back to music/SFX and sprite polish?

## Revision 4P - Battle Telegraph And SFX Weight Ready For Retest

Human retest / clarification:

- The blue spinning ring in the middle of battle was unclear.
- Battle sound effects sounded dinky rather than dramatic.

Revision 4P response:

- Removed the center spinning telegraph ring from battle.
- Added enemy-attached NES-style warning/target brackets with a flashing `!` and compact intent labels.
- Telegraph now appears on the Admin Protocol enemy as `ADMIN INTENT`; enemy windup labels `DATA LEAK`; player attacks label the enemy as `TARGET`.
- Reworked SFX playback from one replace-each-other player to six rotating voices so layered sounds can overlap.
- Added heavier DragonSim WAV layers: low heartbeat, void glitch, quantum break, glacier crack, and shiny sting.
- Layered Root Spark, Thorn Surge, Data Leak, impacts, enemy collapse, hatch, and reward cues with volume/pitch variation.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.
- Ran display-renderer screenshot capture successfully; images are in `design/art/target-frames/runtime-captures/`.

Retest focus:

1. Does the enemy-attached telegraph read clearly without explanation?
2. Do Root Spark, Thorn Surge, enemy Data Leak, and hit impacts feel more dramatic?
3. Are any new layered SFX too loud, too long, or fatiguing?

## Revision 4Q - Narrative Cold Open Ready For Retest

Human retest feedback after Revision 4P:

- The loop is testing pretty well and completes unguided.
- The first meaningful action still does not feel reached because earlier exposition/narrative intro context is missing.

Revision 4Q response:

- Added a three-beat cold open before Forge Hub:
  - Rendered World failure: pastoral surface breaks into deletion warnings.
  - Felix signal: Skye is both resident and operator, and Felix is trying to steady her.
  - Root Egg premise: the egg is alive, not a key, and hatching it is the first meaningful action.
- Preserved the same hatch -> map -> battle -> reward loop after the cold open.
- Updated smoke and runtime-capture scripts to include the new intro states.
- Runtime captures now clear old PNGs before writing the current sequence.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.
- Ran display-renderer screenshot capture successfully; images are in `design/art/target-frames/runtime-captures/`.

Retest focus:

1. Does the cold open restore enough exposition without feeling like a lore dump?
2. Does hatching the Root Egg now feel like the first meaningful action?
3. Can the player name who Skye is, what Felix wants, what the Admin threatens, and why the egg matters before entering battle?

## Revision 4R - Root Egg Asset Restoration Ready For Retest

Human retest feedback after Revision 4Q:

- The slice appeared to no longer have Egg assets, which felt like an oversight.

Revision 4R response:

- Confirmed `root_egg.png` still existed, but was reading as a small prop / hatch overlay rather than a dedicated asset.
- Added four standalone Root Egg idle frames: `root_egg_idle_0.png` through `root_egg_idle_3.png`.
- Wired the new egg idle loop into the cold open and Forge Hub so the egg is visibly present before hatching.
- Kept `hatch_reveal_*` as the hatching animation, with the new egg idle loop as fallback.
- Added smoke coverage that fails if the Root Egg asset or idle frame set is missing.
- Re-ran parse and timed automated happy-path smoke: complete loop reached with 65 Data Scraps.
- Ran display-renderer screenshot capture successfully; images are in `design/art/target-frames/runtime-captures/`.

Retest focus:

1. Does the Root Egg now read as a visible asset before hatching?
2. Does the Hatchery reveal still communicate egg -> dragon transformation?
3. Is the restored egg too large, too dark, or appropriately prominent?

## Revision 4S - Distinct Attack Animation Sprites Ready For Retest

Human retest feedback after Revision 4R:

- Each attack needs its own visually interesting animation sprite.

Revision 4S response:

- Regenerated six-frame strips for Root Spark, Thorn Surge, Guarded Spark, and enemy Data Leak.
- Root Spark now reads as a cyan/gold bolt lunge.
- Thorn Surge now reads as a bark/green ground-root eruption instead of a second electric-vine burst.
- Guarded Spark now has its own shield/counter animation and VFX instead of reusing Root Spark.
- Enemy Data Leak now leans into magenta/cyan glitch streams and hostile data shards.
- Updated battle flow routing so Defend/Guarded Spark uses `guarded_spark_attack_battle_*` and `vfx_guarded_spark`.
- Updated runtime capture sequencing to record Root Spark, enemy Data Leak, Thorn Surge, and Guarded Spark in one scripted pass.
- Updated smoke coverage so it fails if any required attack strip or Guarded Spark VFX is missing.
- Re-ran parse and timed automated smoke: complete loop reached with 65 Data Scraps.
- Ran display-renderer screenshot capture successfully; images are in `design/art/target-frames/runtime-captures/`.

Retest focus:

1. Can you tell which attack was used without reading the move banner?
2. Does Guarded Spark now feel like a defensive/counter move rather than Root Spark with different text?
3. Are the new effect sprites more exciting, or do they still need AI/artist-generated full-strip replacement?

## Session 4 - Revision 4X Acceptance Retest

| Question | Answer |
|---|---|
| Tester | Scott |
| Date | 2026-05-27 |
| Build status before playtest | Revision 4X smoke pass; generated scene music audible, loop ranges fixed, battle cue revised for tension. |
| Did the tester complete the full loop without guidance? | Yes; no blocker reported. |
| Did enemy warning copy resolve the telegraph confusion? | Acceptable. The player-facing copy now reads as incoming enemy action rather than a player telegraph choice. |
| Did the new music play audibly? | Yes; after Revision 4W loop-range fix and Revision 4V level pass, music was audible. |
| Did the battle music communicate enough tension? | Acceptable after Revision 4X tension rewrite. |
| Were SFX clear? | Yes; SFX were clear during the earlier no-music retest and remained acceptable. |
| Overall slice quality after this pass | Acceptable for moving out of repeated asset/audio patching and into formal vertical-slice reporting. |

## Revision 4X Verdict

ACCEPTABLE FOR PRE-PRODUCTION REPORTING.

Reason: The hatch -> map -> battle -> reward loop is complete, smoke-tested, and human-retested after the major presentation blockers were addressed. Remaining work should be tracked as production/polish scope rather than continuing open-ended vertical-slice patching.
