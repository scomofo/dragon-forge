# Surface / deformation / footwork update

See `POLISH.md` for the implemented repaint, baked stress-pose corrections, and world-space foot-lock contract. The atlas is now 2048×2048; Magma has 13,388 triangles. Earlier asset-set descriptions below remain historical where they cite the original 1024 atlas or triangle count.

# Dragon Forge — first imported character and environment art set

This pass replaces runtime character primitives and most static scene decoration with **shipped glTF 2.0 meshes, real skin bindings, authored animation clips and a shared PBR texture atlas**. The generator is editable source, not a runtime dependency. Open `project.godot` normally; the exported files are included.

These are **original, offline, parametrically authored stylized assets**. They are not purchased models, image-to-3D outputs, photogrammetry, hand-sculpted production-final characters, or evidence that art direction is finished. The production-format pipeline and integration are implemented; further silhouette, deformation, texture and scene-composition review remains worthwhile.

## Visual direction

Magma is a stocky, wingless hex-scale biped: basalt hide, layered oxide-copper scutes, ivory claws and swept horns, an articulated reptilian jaw, six tail segments, and a small molten chest crucible. Emission is concentrated at the eye and core rather than washing out the body. The Warden has a separate crowned/back-armored silhouette; it is not just a scaled recolor of the Sentinel.

The Forge uses warm copper hearths, a physical anvil, incubation ring and core cradle. Outer Grid uses cooler enamel bulkheads, shared deck plates, service channels and a relay crown beyond the arena boundary. Rivets, edge wear, roughness variation and brushed/scaled normal detail share one material language. Repetition is intentionally modular, not an expanded level or additional biome.

## Asset catalog

Each exported asset has one combined mesh and one atlas material. Counts refer to the shipped source GLB, before engine import/optimization.

| Asset | Triangles | Bones | Purpose |
|---|---:|---:|---|
| magma_guardian | 13,340 | 24 | Playable Magma; nine clips |
| firewall_sentinel | 2,064 | 8 | Shield-cycle enemy |
| packet_warden | 2,344 | 8 | Crowned/heavier enemy variant |
| deck_panel | 1,088 | — | Repeated plate deck with gutters/rivets |
| bulkhead | 1,184 | — | Wall, barrier and rail module |
| relay_conduit | 1,960 | — | Interactive heat relay |
| incubator | 1,980 | — | Hatch/rest station |
| core_socket | 2,028 | — | Upgrade station |
| magma_egg | 1,972 | — | Hatch presentation |
| furnace | 1,508 | — | Forge hearth |
| anvil | 396 | — | Forge work surface |
| breach_arch | 604 | — | Gate architecture |
| relay_pylon | 1,548 | — | Exterior relay silhouette |
| warden_dais | 2,164 | — | Low-profile arena focal point |
| cable_tray | 480 | — | Repeated service runs |

`generated/manifest.json` records bounds, counts, clip names, source hash and exact SHA-256 hashes of every mesh and texture. All GLBs refer to the same four neighboring PNGs; keep that folder together when copying to another application. Shared external images in a GLB are intentional and valid.

## Texture and mesh contract

Coordinates are **metres, +Y up, -Z forward**. Actors stand at ground zero. Meshes include position, unit normal, explicit tangent/handedness, UV, vertex tint and indexed triangles. Skinned actors also include normalized weights, valid joint indices and inverse bind matrices. No imported asset carries collision bodies or gameplay callbacks.

The four 1024×1024 PNG maps are `atlas_base` (sRGB color), `atlas_orm` (linear: R occlusion / G roughness / B metallic), `atlas_normal` (OpenGL tangent-space normal), and `atlas_emission` (sRGB emission). A 4×4 palette/trim layout has gutters around every swatch. UV reuse is intentional; this is **not** a unique lightmap UV set or a uniquely painted 4K character texture. No directional illumination is baked into the color atlas.

The runtime uses a cloned material for Magma's heat-linked emission, so changing the guardian does not brighten unrelated scenery. Floors, bulkheads, rails and cable trays use MultiMesh batches. Core assets remain at all graphics settings; only decorative service runs are optional. There is no claim of authored multi-resolution LOD meshes or target-GPU frame-time certification.

## Rig and animation contract

Magma's 24-bone hierarchy includes root, pelvis, chest, neck, head, jaw, paired arm/forearm, thigh/shin/foot, and Tail00–Tail05 joints. Skin seams blend joint weights; the skeleton is not just parented runtime primitive geometry.

| Clip | Duration | Sampling rule |
|---|---:|---|
| idle | 1.80 s | Loop; stationary in reduced motion |
| walk | 0.80 s | Loop scaled to actual movement speed |
| claw | 0.28 s | 0.10 s wind-up + 0.18 s recovery |
| breath | 0.50 s | 0.22 s wind-up + 0.28 s recovery |
| wall | 0.44 s | 0.20 s wind-up + 0.24 s recovery |
| burst | 0.72 s | 0.32 s wind-up + 0.40 s recovery |
| guard | 1.00 s | Held guard pose |
| hurt | 0.24 s | Damage reaction |
| defeat | 0.80 s | Clamped defeat pose |

`presentation/dragon_rig.gd` explicitly samples the imported AnimationPlayer against the existing simulation clock. The animation never deals damage or advances cooldowns. `muzzle_position()` transforms a head-local mouth attachment point through the current skeleton pose; the fire jet begins at the head, not at the actor's waist. Damage/line-of-sight rules remain authoritative and unchanged.

The Sentinel and Warden each have idle, walk, tell, open and hurt clips. Their actor samples the existing shield/tell state machine. Reduced motion quiets optional secondary movement without removing combat anticipation/contact cues.

## Environment integration and collision

`world/set_dressing.gd` places/batches the imported modules. `world/main.gd` retains the pre-existing arena walls, gate and character collision dimensions. Three explicit, always-present simple world proxies are added for the new solid furnaces and anvil, so players and attacks cannot pass through those furnishings. Decorative quality never changes physics. The central route, encounter triggers, progress, module balance and save format are unchanged.

Mandatory impact rings and flame fields sit above the highest deck/dais surface. Runtime energy shields, ground warnings, core halos and particle effects remain lightweight dynamic geometry; they are not falsely described as imported character art. Normal gameplay camera framing is slightly closer. Studio/room inspection cameras in evidence are labeled separately from gameplay.

## Rebuild / inspect / replace

Playing needs only Godot 4.6+ Standard. Offline rebuilding needs Python 3.11+, NumPy and Pillow; optional independent validation needs Node and Khronos `gltf-validator`. They are installed into the CI job or your separate tool environment, **not** the browser project's dependency lockfile.

```bash
python3 -m venv .art-venv
# Activate this environment using your platform's normal activation command.
python3 -m pip install -r tools/art-requirements.txt
python3 tools/build_art.py
python3 tools/validate_art.py

godot --headless --path . --editor --import
godot --headless --path . --script res://tests/run.gd -- --test-mode
godot --headless --path . --script res://tests/art_test.gd -- --test-mode
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://tests/art_review.gd -- --test-mode
```

`tools/validate_gltf.cjs` runs the official Khronos validator without suppressing warnings. Set `GLTF_VALIDATOR_MODULE` to a separately installed module's absolute path, or resolve `gltf-validator` normally in your tool environment. It rejects any error or warning and writes the full report to `artifacts/gltf-report.json`.

The Python source can be edited and rebuilt; the generated GLBs can also be imported into a DCC tool for manual sculpt/retopology/painting. Replacing Magma requires the documented names and durations (or a deliberate rig-adapter update), meter scale, ground pivot, and no gameplay callbacks. Revalidate all contact poses, mouth alignment, UV/tangents, shader textures, reduced motion, and normal gameplay camera silhouettes. Do not silently regenerate over separately hand-edited exports; preserve an alternate DCC source and update the provenance manifest.

## Provenance and acceptance

All meshes, texture patterns, poses and source recipes in this set were created for Dragon Forge in this pass. No third-party art, stock-model license, external AI service, fonts or soundtrack files are bundled. NumPy/Pillow, Khronos Validator and Godot are validation/build dependencies, not art sources. Their software licenses are not licenses for this repository's art. No new redistribution license is granted here.

Automated asset correctness is not visual sign-off. Remaining production review includes extreme-pose deformation, looping foot slide, silhouette/texture refinement, physical-controller play, Mac/Windows behavior, hardware Forward+ lighting/frame times, and final art-direction acceptance. The current room remains the prototype layout. Soundtrack, additional biomes, fusion, reserve dragons, and standalone application exports are outside this art pass.
