# Dragon Forge — Reconnection Campaign

**Start here: open `project.godot` in Godot 4.6.3 Standard and press F5.** The title must say **DRAGON FORGE / RECONNECTION**. This build has 22 connected rooms, four sectors, salvage upgrades and an ending; it is not the older small-room art prototype.

Choose Begin campaign → press E to hatch Magma → press M → Outer Grid → Enter sector. Use the labeled north portals to continue exploring. After a boss, collect its core, return to the Forge and install it to open the next sector.

Controls: WASD move, mouse aim, 1–4 techniques, Space dodge, Shift guard, E interact, Q repair, M routes, N journal, Esc pause. The title, route map and contextual interaction also provide clickable controls.

The packaged GLBs/textures are ready to import. No Python, Node or asset-generation step is needed to play. This source project is not a standalone application and still requires Godot. Existing prototype saves are preserved; campaign progression is separate.

See `campaign/README.md` for the complete route, saves, tests and limitations. `art/README.md`, `art/POLISH.md` and `validation/README.md` document the inherited art and inspection tools. Those validation scenes remain opt-in: F6 runs the selected scene, while **F5 launches the campaign**. The original small mechanical slice is retained at `world/main.tscn` for regression tests.

This is a compact playable campaign using one guardian and the existing modular art, not the full browser game's dragon collection/fusion/campaign port. The original browser game, frozen Godot runtime and soundtrack are unchanged.
