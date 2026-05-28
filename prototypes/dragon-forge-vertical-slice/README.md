// VERTICAL SLICE - NOT FOR PRODUCTION
// Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
// Date: 2026-05-26

# Dragon Forge Vertical Slice

Run from this directory:

```bash
godot --path .
```

Headless parse/smoke check:

```bash
godot --headless --path . --quit
godot --headless --path . -s res://tests/smoke_vertical_slice.gd
```

This prototype is a reference-only Pre-Production vertical slice. Production stories must rebuild the feature from GDDs, ADRs, and the control manifest rather than importing prototype code.

## What You Should See

The current revision is still prototype-authored art, but it should no longer look like text over plain color blocks. Each screen should show a dedicated 16-bit cyber-retro stage area above the UI:

- Forge Hub: workshop/server racks, Felix sprite, forge/hearth, hatchery ring, glowing Root Egg, locked Bulkhead.
- Cold Open: Rendered World failure, Felix's rescue signal, and a visible animated Root Egg before the first hatch action.
- Hatchery: animated hatchery ring, restored standalone Root Egg frames feeding into the hatch reveal, small green dragon, diagnostic monitors.
- Campaign Map: pastoral hills/trees, route nodes, Forge start, red hazard tile.
- Battle: Root Wyrmling and hostile protocol sprites, HP bars, enemy-attached TELEGRAPH marker, named moves, attack-frame animation, VFX, screen shake, floating damage, and layered DragonSim-derived attack SFX.
- Victory: reward Scraps/chest, sparkle feedback, cleared route, returning dragon.

Dialogue and action text should appear in separate panels below the visual stage.
The `SIGNAL TRACE` panel should make the slice's lore readable during play: Skye is both resident/operator, Felix is the Forge-keeper mentor, Root dragons are living repair protocols, Village Edge is a damaged rendered route, the battle enemy is an Admin deletion routine, and Data Scraps are recovered code.

## Raster Asset Pass

Revision 4 adds project-local PNG assets under `assets/slice/` and loads them in the controller as `ImageTexture`s. To regenerate them:

```bash
godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tools/generate_slice_assets.gd
```

See `assets/slice/ASSET-MANIFEST.md` for the asset list and replacement notes.
