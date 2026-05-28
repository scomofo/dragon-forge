# Battle Content Assets

This folder mirrors the production-facing battle animation content Resources for the standalone vertical slice.

## Root Wyrmling vs Admin Protocol

Primary Resources:

- `animation_manifests/root_wyrmling_vs_admin_protocol.tres`
- `battles/village_edge_admin_protocol.tres`
- `moves/root_spark.tres`
- `moves/thorn_surge.tres`
- `moves/guarded_spark.tres`
- `moves/data_leak.tres`

Asset folders:

- `actors/root_wyrmling/battle/`
- `actors/admin_protocol/battle/`
- `vfx/`
- `previews/`
- `runtime_captures/village_edge_admin_protocol/`

Notes:

- Attack, idle, VFX, preview, and runtime-capture assets mirror the root fixture.
- Telegraph, hurt, defend-start, defend-hit, and KO clips use dedicated generated reaction strips derived from approved Root/Admin battle seed frames.
- The prototype mirror uses local `src/battle_content/` Resource scripts without global `class_name`s so the root project does not receive duplicate Godot global class registrations.

Validation:

```bash
godot --headless --path prototypes/dragon-forge-vertical-slice -s res://tests/smoke_vertical_slice.gd
```
