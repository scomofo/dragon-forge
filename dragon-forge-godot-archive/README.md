# Dragon Forge Godot Runtime

This is the production-runtime spine for the new Dragon Forge direction. The browser build remains the fast design lab; this Godot project is where the RPG overworld, authored battle scenes, and higher-end animation pipeline can harden.

## Current Slice

- Godot 4.6 project scaffold.
- Separate simulation modules for dragons, combat, tactical battles, and overworld movement.
- Main scene that switches from a 2D overworld to a battle view.
- Initial battle UI with selectable techniques and deterministic state transitions.
- First copied web prototype assets for dragons, sentinel, and VFX strips.

## Run

Use the installed Godot binary:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot'
```

Or use the project launcher:

```powershell
.\run-godot.ps1
```

Smoke test:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```
