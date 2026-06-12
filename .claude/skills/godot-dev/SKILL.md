---
name: godot-dev
description: Launch, smoke-test, and debug the Dragon Forge Godot 4.6 runtime. Use when working in dragon-forge-godot/ — running the game, headless sim tests, or diagnosing scene/script errors.
---

# Godot runtime dev loop

The Godot build is not driven by npm. Binary: `C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe`.

> ⚠️ `run-godot.ps1` hardcodes the project path as `C:\Users\Scott Morley\Dev\df\dragon-forge-godot`. If the repo is checked out elsewhere (e.g. `C:\dev\dragon-forge`), call the binary directly with `--path` pointing at this checkout's `dragon-forge-godot/`.

## Run
```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --path 'C:\dev\dragon-forge\dragon-forge-godot'
```

## Headless smoke test (the CI-style check — run after any sim change)
```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\dev\dragon-forge\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```
More tests live in `dragon-forge-godot/scripts/tests/` — run the relevant one the same way.

## Layout map
- `scripts/main.gd` + `scenes/main.tscn` — top-level orchestrator (the `App.jsx` analogue); switches world ↔ battle views.
- `scripts/sim/` — pure stateless simulation (combat rules, dragon data, quest manager, signal bus). No scene references allowed here.
- `scripts/world/`, `scripts/battle/`, `scripts/dungeon/` — scene controllers.
- `scripts/vfx/` — effects.

## Conventions
- Setup/ready ordering matters: data must be loaded in `setup()` before UI builds in `_ready()` (see commit `713fc5b` for the failure mode).
- New PNGs need their generated `.import` siblings committed — open the editor once after adding assets.
- For game data/rules ported from the web build, see the `/port-to-godot` skill.
