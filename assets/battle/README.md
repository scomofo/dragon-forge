# Battle Content Assets

This folder contains production-facing battle animation content Resources and the first validated asset fixture.

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

Source provenance:

- Attack, idle, VFX, preview, and runtime-capture assets were promoted from the approved vertical-slice target-frame work under `design/art/target-frames/`.
- Root Spark, Thorn Surge, Guarded Spark, and Data Leak use actual 6-frame action sequences.
- Telegraph, hurt, defend-start, defend-hit, and KO clips now use dedicated generated reaction strips derived from approved Root/Admin battle seed frames.
- Human art-direction review is still required before broader production art lock, but this fixture no longer relies on copied idle/attack frames for reaction coverage.

Validation:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/integration/battle -ginclude_subdirs -gexit
```

Runtime proof:

- The standalone vertical slice mirrors this fixture under `prototypes/dragon-forge-vertical-slice/assets/battle/`.
- `prototypes/dragon-forge-vertical-slice/src/VerticalSliceController.gd` resolves battle clip and VFX keys through the mirrored manifest instead of choosing action sprite paths directly from move-name branches.
- Prototype smoke verifies the manifest-resolved Root Spark and Data Leak keys before completing the full loop.
