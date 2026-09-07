# Dragon Forge - next-generation playable prototype

A small, native **3D mechanical slice**, inspired by the existing Dragon Forge browser cartridge. One imported skinned Magma guardian, a modular Forge / Outer Grid environment, four abilities, a shield-cycle enemy, reactive heat conduits, and a persistent return reward with three build choices and a replayable field test. The first textured/skinned asset set is integrated; this is not an accepted final-art build or a finished 15-25 minute vertical slice.

## Play

Use **Godot 4.6 or newer, standard edition**. The native test workflow pins 4.6.3; no engine upgrade or dependency change is imposed on either existing game. Open **this folder's `project.godot`**, then press **F5**. There is no npm step for this prototype.

From the repository root on macOS / Linux:

```bash
bash run-nextgen.sh
# Older graphics hardware / driver troubleshooting:
bash run-nextgen.sh --compatibility
# A nonstandard Godot installation (spaces are supported):
GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot" bash run-nextgen.sh
```

Windows PowerShell:

```powershell
.\run-nextgen.ps1 -GodotPath "C:\Tools\Godot\Godot.exe"
.\run-nextgen.ps1 -GodotPath "C:\Tools\Godot\Godot.exe" -Compatibility
```

`npm run dev` still launches the original browser game, **not** this 3D prototype. No standalone application export is included yet.

## Imported character and environment art

This version ships **15 GLB assets and a shared four-map 1024px PBR atlas**: a 24-bone, nine-clip Magma guardian; separately exported plated Sentinel and crowned Warden; and twelve environment/station modules. Most static decoration and all character primitives have been replaced. The game needs no Python, Blender, npm install or asset-generation step to play.

The models and textures are original, offline, parametrically authored assets. They are skinned/UV-mapped production-format files, **not hand-sculpted final art**. `art/README.md` documents asset counts, rig/UV/material contracts, provenance, editable build source, and remaining art review. Combat rules and saves are unchanged. The new furnaces/anvil have explicit collision proxies; graphics settings never remove these. Ground telegraphs clear the deck/dais and breath starts at the animated mouth attachment point.

## Presence and combat pass

This version adds articulated head/jaw/shoulder/tail poses, distinct claw/breath/stomp/burst motion, and actual wind-up → contact → recovery timing. Hits happen once at contact; a dodge cancels the pending technique without refunding heat or cooldown. A short **160 ms keyboard/controller ability buffer** accepts a command near the end of recovery or cooldown. It expires rather than firing a surprise attack after a stall, pause or retry. Aim commits when the technique starts; movement remains available at a reduced speed.

Cinder Claw now sweeps an arc, Magma Breath projects a clipped fire jet, Flame Wall leaves a marked persistent field, and Core Burst uses a radial pulse. Enemy tells retain a fixed outer boundary and show a numerical countdown. The dedicated enemy HUD shows the remaining impact/counter window. No rule depends on particles being enabled.

Outer Grid gains a suspended relay-station backdrop and an octagonal Warden platform; the Forge gains copper machinery and restoration-linked floor circuits. Repeated panels and light strips use shared instancing batches. Optional ornament drops out on Low/Medium. These structures now use the imported modular asset set described above; they are not a hardware performance claim.

Graphics and reduced-motion preferences now persist in their own `nextgen-preferences.json` file. Missing preferences use Medium and normal motion. Unreadable or future-version preferences are not overwritten; a warning indicates session-only settings. The clarity-and-core pass migrates prototype progress to schema v2 at the same location, as described below.

## Controls

| Action | Keyboard / mouse | Standard mapped gamepad |
|---|---|---|
| Move | WASD / arrow keys | Left stick / D-pad |
| Aim | Move mouse; movement keys restore movement-facing aim | Right stick, or movement direction |
| Cinder Claw | 1 / J / HUD button | X |
| Magma Breath | 2 / K / HUD button | Y |
| Flame Wall | 3 / L / HUD button | Left bumper |
| Core Burst | 4 / I / HUD button | Right bumper |
| Dodge | Space | A |
| Guard | Hold Shift | Hold left trigger |
| Interact / rest | E | B |
| Pause / graphics | Esc / F1 | Start |
| Retry after defeat | R, or checkpoint-sheet button | Focused checkpoint-sheet button |
| Diagnostics | F3, or Pause > Diagnostics | Pause > Diagnostics |

Gamepad names use Xbox-style logical labels; other controllers map through Godot. Physical-controller acceptance is still required. Touch and browser controls are not implemented.

## The playable loop

1. Press E / B at the amber hatch ring to awaken Magma.
2. Walk north to the cyan conduit. Aim at it and land **two Magma Breaths** to power the gate. Wait for the breath cooldown between casts.
3. Cross into Outer Grid. Follow the floor marker to two Firewall Sentinels and the larger Packet Warden. Each encounter waits for you to approach its relay; there is no automatic next-wave ambush while you are still at the previous checkpoint. The Warden speeds up below half health.
4. Shield closed means attacks are blocked. Bait the **fixed-position impact marker**, dodge or guard, then counter during the OPEN window. A successful guard extends that window. Two breath hits on the arena conduit cause an overload that damages and exposes an enemy within its marked radius.
5. Collect the dropped core at the north end and follow the breach waypoint home. At the right-hand socket, press E / B and choose **Coolant Heart**, **Bastion Shell**, or **Cinder Catalyst**. The game pauses while you choose. Your actor's stats, the Forge core and its lighting change.
6. Use the socket again to **field-test** the installed module against a Warden. Winning saves a test badge, not another core. Return and swap modules freely. You do not need to reset your expedition to replay combat.
7. Defeat offers **Retry checkpoint** or **Return to Forge**. Retry restores full health just before the next uncleared relay, preserving all completed milestones and your module. Menu > Reset prototype progress is a separate confirmed destructive action.

Heat is an ability budget, not damage. It cools over time; high heat can prevent casting or dodging. Claw is heat-free. Flame Wall creates a short-lived ground field rather than physical cover. Enemy attacks and combat rules do not depend on particle visibility.

## Forge module choices

| Module | Actual effect | Trade-off / role |
|---|---|---|
| Coolant Heart | Cooling 24/sec instead of 16/sec; guarding halves either rate. | Sustained casting and more available dodge heat. |
| Bastion Shell | 156 max HP instead of 120; guard takes 20% of incoming damage instead of 25%. | More forgiving defense. |
| Cinder Catalyst | Technique damage ×1.25; technique heat ×1.20. | Stronger counters with less thermal headroom. Claw remains heat-free. |

These are provisional values, not measured balance conclusions. Module effects apply to direct attacks and persistent flame-field damage. World conduit overload damage stays unchanged. Core choices cannot be changed away from the Forge or during a live trial. Field tests repeat the existing Warden; they are not a new zone or enemy species.

## This pass: clarity and reward

A compact objective card replaces the full-width instruction block. Contextual interaction prompts appear only when a valid action is nearby. A quiet destination marker routes through the physical breach. Enemy HP, shield state, impact timer and counter window now have a dedicated fixed HUD position; duplicate floating name/status blocks are hidden. Skill cards keep readable text while cooling and use the same short input buffer as keyboard/controller commands. Diagnostics are optional (F3), rather than occupying the main title panel.

Progress schema **v2** migrates valid v1 milestones on load, without rewriting the old file until the next successful save. That first write retains the old bytes as the previous-write backup. Already restored v1 Forges get a free pending module choice at the socket. Unknown/future or unreadable saves are still preserved and block writes. Progress, chosen module and test badge persist; an unfinished trial resumes at the Forge and can be started again. This does not migrate or alter either original game's saves.

## What is actually implemented

- CharacterBody3D movement and collision, directional aiming, dodge invulnerability, guard, cooldowns and heat.
- Elevated smoothed camera with bounded optional impact motion.
- An imported, UV-mapped 24-bone Magma mesh with nine animation clips, full shared PBR textures, and simulation-clock pose sampling. **First-pass parametric art, not final visual approval.**
- Reusable Sentinel actor, a telegraph/strike/recovery state machine, and a stronger Warden variant. The spatial shield mechanic deliberately adapts, rather than claims identical balance to, `src/bossPatterns.js`.
- Authored 3D Forge / arena layout, blocked gate, two heat conduits, line-of-sight checks, staged encounters, defeat/retry, core pickup and visible home upgrade.
- Emissive materials, dynamic lights, shader ground effects and bounded GPU particle bursts under Forward+.
- Low / Medium / High / Ultra graphics controls. Render scale, MSAA, sun shadows, particle budgets, glow, ambient occlusion and volumetric fog vary where supported. Compatibility mode uses a reduced feature set, not fake GPU effects. Changing quality never switches renderer at runtime.
- Reduced motion disables camera shake, particle bursts and several animated effects; mandatory impact boundaries and counter cues remain visible.
- FPS / draw-call counters, actual simulation pause, focus-loss pause, keyboard/gamepad mappings and clickable abilities.
- Separate versioned milestone/module/trial saves with validation, checked temporary writes and a previous-write backup. Unreadable or future-version saves are preserved and not overwritten; the HUD shows a session-only save warning. No automatic backup restoration is claimed. New schema and migration behavior are described above.

Quality and reduced-motion settings persist separately from milestones. Mid-fight health, heat and exact positions do not persist: resume returns to the Forge with completed milestones retained.

## Architecture and boundaries

This folder is a separate Godot project with its own `res://` and `user://` namespace, `dragon-forge-nextgen-prototype`. It follows the existing runtime's simulation/presentation separation without loading its legacy autoloads. No existing browser/Godot files, assets, music choices, save schemas or entry scenes are replaced.

- `sim/`: combat rules, enemy state machine, heat, progression and storage.
- `actors/`: collision/movement and scene adapters for those rules.
- `world/`: authored geometry, encounters and milestone orchestration.
- `presentation/`: imported asset library/rig adapters, camera, VFX, UI, input and quality profiles.
- `art/`: shipped GLBs, shared PBR atlas, manifest and art contract.
- `tools/`: optional offline art authoring and validation; not required to play.
- `tests/`: native rule/integration checks, real-renderer smoke capture and packaging checks.

Canonical inheritance: Magma's hex-scale biped silhouette (`src/artBible.js` / `design/gdd/art-bible.md`); Magma Breath and Flame Wall; Forge / Outer Grid identity; Firewall Sentinel's shield-and-counter philosophy; restoration as a meaningful return reward. Cinder Claw, Core Burst, the Packet Warden variant, spatial timings and heat values are **prototype additions**, not changes to cartridge balance.

The repository's soundtrack remains untouched. This prototype is currently silent. Reserve swapping, fusion/evolution, the other zones, final art polish, production audio integration, rebinding, exports and a measured opening-duration playtest are later work, not implemented features.

## Tests and evidence

From this folder (substitute the executable path as needed):

```bash
python3 tests/validate.py
# Native import / parse pass:
godot --headless --path . --editor --import
# Rule, save and real-scene integration checks; never uses your normal save:
godot --headless --path . --script res://tests/run.gd -- --test-mode
# Real renderer; outputs screenshots to artifacts/:
godot --path . --rendering-method gl_compatibility --script res://tests/visual_smoke.gd -- --test-mode
```

`.github/workflows/nextgen.yml` runs the native checks and software-OpenGL smoke capture on PRs, uploading logs and twelve screenshots as `nextgen-test-evidence`. It fails on Godot parse/script errors even where the process exit status alone could be misleading. `validate.py` is **only a packaging check**, not an engine test.

Native tests cover resource loading, ability rules, heat, guard/dodge, target locking, reward idempotency, save roundtrips/corruption protection, actual hatch/conduit/gate/encounter wiring, persistent field damage, pause, graphics-state independence, death/retry and core installation. The scripted completion uses controlled damage to traverse milestones; it does **not** establish that the combat is balanced or enjoyable.

The current capture suite covers opening, relay charge, an enemy tell, burst and breath contact, reduced motion, settings, defeat, module choice, restored Forge and trial completion; the choice screen is also captured at 1920x1080. These are scripted engine states, not proof of balance or enjoyment.

Software-renderer captures do not establish Forward+ performance, finished visual quality, or Mac/Windows compatibility. Before treating the slice as accepted, play it on the target Mac/PC: verify aim and movement, controller feel, normal/reduced-motion readability, UI fit at 1280x720 and 1920x1080, real save/resume and failure behavior, and Low versus High frame times. No target-hardware FPS claim has been measured yet.


### Added acceptance checks

The native suite now covers one-and-only-one attack contact (including long frames), recovery lockouts, committed aim, dodge/death cancellation, bounded input buffering, pause/resume grace, presentation-only pose sampling, preference roundtrips and corruption protection, optional detail toggles and transient-effect lifetime bounds. Automated captures include ability contact, reduced motion, menus, core choice, the restored Forge and field-test completion.

Still required on target hardware: physical keyboard/controller feel, actual Forward+ rendering, Low/High frame-time profiling, hands-on save/resume, ability balance and opening pacing. No 15–25 minute duration, final production-art finish, audio integration or standalone app export is claimed. The imported mesh/skin/clip pipeline is now implemented and documented in `art/README.md`.
