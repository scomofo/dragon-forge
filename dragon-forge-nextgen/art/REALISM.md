# Creature realism pass — September 2026

Scott's family playtest asked for much more realistic dragons. This pass revises
the playable **Magma, Rime, Arc and Nox**, plus **Crowned Magma, Aurora Rime and
Tempest Arc**. It establishes a more believable animal direction for the four
reptilian body plans. The remaining five guardian identities retain their art.

## Visible changes

- Magma has a tapered muzzle, temporal/cheek volume, smaller recessed amber eyes,
  articulated teeth, slimmer keratin horns, and a less cylindrical torso.
- Rime has a fuller shoulder/chest, blended limb joints, individual toes in place
  of box feet, a continuous skinned tail, and mineral dorsal spines.
- Arc has thin curved flight membranes, scalloped trailing edges, supporting
  fingers and a thumb claw. Wing skin blends across the wrist; the distal wing
  follows the power stroke with a delay. Its chest and forelimbs carry more mass.
- Nox has a ribbed flexible frill, a continuous tail, broader proximal limbs,
  individual digits and a more defined snout and mouth.
- Fine hide scales, mottled pigmentation, keratin growth grain, and membrane
  veins have corresponding base-color, normal, occlusion and roughness detail.
  Irises and pupils are physical, non-emissive features. Elemental cores remain
  readable. Magma has dedicated maps so its repaint does not recolor the Forge.

The shapes and surfaces are original parametric art, not scanned animals or a
hand-sculpted photoreal asset pack. Texture swatches still share a 4×4 atlas;
per-part density and anatomical sculpting can be refined further through playtest.

## Motion and integration

The existing collider dimensions, combat timings, damage, progression and save
format remain authoritative. Both planted-foot systems stay active. Rime's toes
change its measured sole geometry; the solver derives contacts from that geometry.
Rime now queries the center and four sole extrema when finding support: a single
ray through a recessed deck seam could otherwise sink a neighboring toe into a
plate. The unchanged walking regression passes its 4 mm penetration tolerance and
15 mm stance-drift limit with the revised feet.
Nox still has no world-space foot-lock solver, and Arc intentionally hovers.

Rime, Arc and Nox previously rotated the lower jaw upward during breath. Their
revised clips open the mandible below the palate. A new test evaluates a jaw-tip
point in head coordinates, so head anticipation cannot disguise a reversed hinge.
The previous exports fail five checks including the inherited evolved forms;
the revised set passes all 28. All nine clip names and durations are retained.

Evolved forms are rebuilt from the revised parents. The existing export validators
check that parent geometry, joint bindings and clip tracks are preserved byte for
byte in each evolved mesh. Idle sway is quieter for Magma and Nox.

## Reproduce and review

Use the pinned NumPy/Pillow versions in `tools/art-requirements.txt`, then run from
`dragon-forge-nextgen` in this order:

```bash
python3 tools/build_art.py
python3 tools/build_ice_guardian.py
python3 tools/build_storm_guardian.py
python3 tools/build_venom_guardian.py
python3 tools/build_evolutions.py
python3 tools/build_tempest.py
python3 tools/validate_creature_detail.py
```

Wait for authoring to finish before importing in Godot. No authoring step is
required to play; all GLBs and textures are committed. Manifests record source,
helper, compiler and export hashes, and the exact authoring dependency versions.

In Godot 4.6.3, open `validation/character_inspection.tscn` with F6. Inspect neutral
and strong rim light, clay, head closeups and every clip. The existing gameplay
arena exposes real Magma contacts and foot planting. F5 runs the campaign.

```bash
godot --headless --path . --editor --import
godot --headless --path . --script res://validation/realism_tests.gd
godot --path . --rendering-method gl_compatibility --script res://validation/capture_realism.gd
godot --path . --rendering-method forward_plus --script res://validation/capture_realism.gd
```

The capture runner uses the actual inspector for all four models, all nine clips,
and neutral/rim/head views; it then captures all four through the production
campaign actor and camera. Its 52 images per renderer use prepared, save-isolated
states. The `Nextgen Magma polish` workflow publishes these alongside the existing
foot-motion and low/high/reduced-motion evidence.

Automated deformation/format checks and software-rendered captures do not certify
target-PC performance or whether the kids accept the new appearance. The next
family sitting should compare the four dragons from the normal game camera, then
check closeups, turning, breath, and wing/frill motion in the inspector.
