# Dragon Forge - next-generation playable prototype

A small, native **3D mechanical slice**, inspired by the existing Dragon Forge browser cartridge. One animated procedural Magma guardian, an authored Forge / Outer Grid arena, four abilities, a shield-cycle enemy, reactive heat conduits, and a persistent return reward. This is not the finished 15-25 minute vertical slice or a production-art build.

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
| Retry after defeat | R, or Menu > Retry | Menu > Retry |

Gamepad names use Xbox-style logical labels; other controllers map through Godot. Physical-controller acceptance is still required. Touch and browser controls are not implemented.

## The playable loop

1. Press E / B at the amber hatch ring to awaken Magma.
2. Walk north to the cyan conduit. Aim at it and land **two Magma Breaths** to power the gate. Wait for the breath cooldown between casts.
3. Cross into Outer Grid. Clear two Firewall Sentinels and the larger Packet Warden. The Warden speeds up below half health.
4. Shield closed means attacks are blocked. Bait the **fixed-position impact marker**, dodge or guard, then counter during the OPEN window. A successful guard extends that window. Two breath hits on the arena conduit cause an overload that damages and exposes an enemy within its marked radius.
5. Collect the dropped core at the north end, return south, and install it in the right-hand Forge socket. The Forge's core and lighting change. Menu > New expedition offers a confirmed reset of **prototype-only** progress.

Heat is an ability budget, not damage. It cools over time; high heat can prevent casting or dodging. Claw is heat-free. Flame Wall creates a short-lived ground field rather than physical cover. Enemy attacks and combat rules do not depend on particle visibility.

## What is actually implemented

- CharacterBody3D movement and collision, directional aiming, dodge invulnerability, guard, cooldowns and heat.
- Elevated smoothed camera with bounded optional impact motion.
- A geometric Magma biped with independently moving legs, tail, idle and attack motion. **This is a procedural blockout, not a finished rigged dragon asset.**
- Reusable Sentinel actor, a telegraph/strike/recovery state machine, and a stronger Warden variant. The spatial shield mechanic deliberately adapts, rather than claims identical balance to, `src/bossPatterns.js`.
- Authored 3D Forge / arena layout, blocked gate, two heat conduits, line-of-sight checks, staged encounters, defeat/retry, core pickup and visible home upgrade.
- Emissive materials, dynamic lights, shader ground effects and bounded GPU particle bursts under Forward+.
- Low / Medium / High / Ultra graphics controls. Render scale, MSAA, sun shadows, particle budgets, glow, ambient occlusion and volumetric fog vary where supported. Compatibility mode uses a reduced feature set, not fake GPU effects. Changing quality never switches renderer at runtime.
- Reduced motion disables camera shake, particle bursts and several animated effects; mandatory impact boundaries and counter cues remain visible.
- FPS / draw-call counters, actual simulation pause, focus-loss pause, keyboard/gamepad mappings and clickable abilities.
- Separate milestone saves with validation, checked temporary writes and a previous-write backup. Unreadable or future-version saves are preserved and not overwritten; the HUD shows a session-only save warning. No automatic backup restoration is claimed.

Quality and reduced-motion settings currently apply **for the current session**. Mid-fight health, heat and exact positions do not persist: resume returns to the Forge with completed milestones retained.

## Architecture and boundaries

This folder is a separate Godot project with its own `res://` and `user://` namespace, `dragon-forge-nextgen-prototype`. It follows the existing runtime's simulation/presentation separation without loading its legacy autoloads. No existing browser/Godot files, assets, music choices, save schemas or entry scenes are replaced.

- `sim/`: combat rules, enemy state machine, heat, progression and storage.
- `actors/`: collision/movement and scene adapters for those rules.
- `world/`: authored geometry, encounters and milestone orchestration.
- `presentation/`: replaceable geometry/rig, camera, VFX, UI, input and quality profiles.
- `tests/`: native rule/integration checks, real-renderer smoke capture and packaging checks.

Canonical inheritance: Magma's hex-scale biped silhouette (`src/artBible.js` / `design/gdd/art-bible.md`); Magma Breath and Flame Wall; Forge / Outer Grid identity; Firewall Sentinel's shield-and-counter philosophy; restoration as a meaningful return reward. Cinder Claw, Core Burst, the Packet Warden variant, spatial timings and heat values are **prototype additions**, not changes to cartridge balance.

The repository's soundtrack remains untouched. This prototype is currently silent. Reserve swapping, fusion/evolution, the other zones, imported models/animation, production audio integration, rebinding, exports and a measured opening-duration playtest are later work, not implemented features.

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

`.github/workflows/nextgen.yml` runs the native checks and software-OpenGL smoke capture on PRs, uploading logs and four screenshots as `nextgen-test-evidence`. It fails on Godot parse/script errors even where the process exit status alone could be misleading. `validate.py` is **only a packaging check**, not an engine test.

Native tests cover resource loading, ability rules, heat, guard/dodge, target locking, reward idempotency, save roundtrips/corruption protection, actual hatch/conduit/gate/encounter wiring, persistent field damage, pause, graphics-state independence, death/retry and core installation. The scripted completion uses controlled damage to traverse milestones; it does **not** establish that the combat is balanced or enjoyable.

Software-renderer captures do not establish Forward+ performance, finished visual quality, or Mac/Windows compatibility. Before treating the slice as accepted, play it on the target Mac/PC: verify aim and movement, controller feel, normal/reduced-motion readability, UI fit at 1280x720 and 1920x1080, real save/resume and failure behavior, and Low versus High frame times. No target-hardware FPS claim has been measured yet.
