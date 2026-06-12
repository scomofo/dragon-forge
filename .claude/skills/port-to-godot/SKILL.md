---
name: port-to-godot
description: Port a game system from the browser build (src/*.js) to the Godot runtime following the repo's sim/controller convention. Use when asked to bring a web feature, engine, or data table into the Godot build.
---

# Port a system from web to Godot

The browser build (`src/`) is the source of truth for game systems, balance, and content. Porting means re-expressing it in GDScript, not redesigning it.

## Procedure
1. **Read the source of truth first.** The web implementation lives in `src/*Engine.js` (logic) and the data modules (`gameData.js`, `forgeData.js`, `shopItems.js`, `singularityBosses.js`, etc.). Read the `.test.js` sibling too — it documents the expected behavior and edge cases.
2. **Split by the repo convention:**
   - Data + rules → a **stateless module in `dragon-forge-godot/scripts/sim/`** (the GDScript counterpart of `*Engine.js`). No scene-tree access, no signals to UI — pure functions over dictionaries, mirroring the JS module's shape.
   - Scene behavior → a controller in the matching `scripts/world/`, `scripts/battle/`, or `scripts/dungeon/` folder.
3. **Port the numbers exactly.** Copy stat tables, type-chart multipliers, formulas, and RNG ranges verbatim from the JS. Balance changes are a separate task — never fold them into a port.
4. **Port the tests.** Translate the key cases from the `.test.js` file into a script under `dragon-forge-godot/scripts/tests/` (follow `sim_smoke.gd`'s pattern) and run it headless:
   ```powershell
   & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\dev\dragon-forge\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
   ```
5. **Art:** copy any needed sprites from `assets/` (repo root) or `public/assets/` into `dragon-forge-godot/assets/`, open the editor once to generate `.import` files, and commit them.

## Cross-checks before calling it done
- Same inputs → same outputs as the JS engine for at least the test-file cases.
- The sim module has zero `get_node`/scene dependencies (keeps it headless-testable).
- `scenes/main.tscn` / `scripts/main.gd` wiring updated if the system needs a screen.
