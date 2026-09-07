# Guardian evolution / Reconnection

Continue the normal 22-room campaign with F5. The title now includes **GUARDIAN
EVOLUTION**. Both old guardian forms, the roster, routes and ending remain.

## Earn and select

Bond points are derived from unique saved achievements, not an extra currency:
20 per unshielded patrol, 35 per shield guardian, 70 per sector boss, 100 for the
final encounter, 15 per salvage cache and 25 per installed sector core. Bond ranks
I / II / III begin at 0 / 120 / 280. Both guardians share the journey; a late Rime
recruit inherits its milestones. Repeat visits, retries, swaps and repeated
interaction cannot farm bond.

At **Bond III and two installed sector cores**, visit the right-hand Guardian
Nursery in the Forge. Press E, then choose a guardian's Evolution button. P opens
the same collection screen from anywhere, but selections are only applied near
the Nursery. Completing the ordinary first two sectors gives 300 points without
any optional caches, so no replay grind is needed.

The first free choice evolves that guardian. Later choices freely change its
specialization at the same station, without undoing evolution. No salvage is
spent. The Nursery rests both guardians as the existing safe Forge already does.

| Guardian | Specialization | Change |
| --- | --- | --- |
| Crowned Magma | Flashfire | Breath cooldown 2.4 -> 1.8 seconds |
| Crowned Magma | Furnace Heart | Flame Wall lifetime 3.6 -> 4.8 seconds |
| Aurora Rime | Deep Winter | Ice breath/field Chill duration 3 -> 4.5 seconds |
| Aurora Rime | Glacial Ward | Aegis duration 4 -> 6 seconds |

Every evolved guardian receives +10% maximum health (after shared plating and
module adjustments) and +10% technique damage. Existing power upgrades and modules
still apply. Aegis keeps its original 55% mitigation. No attack contact time, heat
cost, hit range, movement speed or collider is changed. Longer field/chill values
are snapshotted at cast; switching guardians cannot reassign their ownership.
Damage and cooldown values on the actual HUD reflect the selected specialization.
The values are provisional and have not received human balance acceptance.

## Forms and runtime boundaries

`campaign/evolutions/` contains two complete committed skinned GLBs. Crowned Magma
adds a three-part furnace crown, shoulder mantles and a crucible rim. Aurora Rime
adds an antler crest and layered dorsal ice fans. These are additions to the
existing body designs, **not a new body topology, hand sculpt, recolor or whole-body
scale change**. Young assets/textures are unchanged. Original vertices, triangles,
joint order, rest transforms, inverse binds and animation keys are preserved
byte-for-byte in the exported evolved variants. Each has the same nine clips and
uses the same foot solver as its younger counterpart. Added plates may still need
artist review at extreme poses. Slopes and moving-platform grounding are not added.

`tools/build_evolutions.py` is the offline editable authoring source; it uses the
existing isolated art requirements. Playing needs no Python, Blender, Node or bake.
The character inspector now offers both evolved variants with their actual material,
clay, close-up cameras, clips and independent sole probes. The campaign remains
F5; opening a validation scene and using F6 runs that review scene only.

## Compatibility and testing

Campaign schema 3 adds only `evolutions: {fire: "", ice: ""}`. Valid versions 1 and
2 migrate in memory; no evolution is automatically selected, and no write occurs
on load. Bond derives from already-earned milestones, so completed campaigns can
evolve immediately at the Nursery. The normal first successful write backs up the
old bytes. Malformed or future saves stay protected. Older builds cannot read this
new schema and should not be used to continue its save; retain the backup.
Exact mid-fight HP and heat continue to be session state, not persistent snapshots.

Validation commands (from the native project):

```sh
python3 tools/validate_evolutions.py
# GLTF_VALIDATOR_MODULE may point to an isolated official gltf-validator install.
node tools/validate_evolutions.cjs
godot --headless --path . --editor --import
godot --headless --fixed-fps 60 --path . --script res://campaign/tests/evolution_tests.gd -- --test-mode
godot --path . --rendering-method gl_compatibility --script res://campaign/tests/evolution_capture.gd -- --test-mode
```

The new tests cover gates, idempotence, v1/v2 migration and backups, malformed
choices, actual ability damage/cooldown/chill/ward/field effects, swap ownership,
Nursery proximity, modal pause and both imported forms. Motion checks skin actual
sole vertices during travel, stop and breath; they require stance coverage rather
than passing by releasing every foot. These are finite flat-deck samples, not a
proof against every intersection. Capture setups deliberately seed progression for
review and are not evidence of an unassisted campaign playthrough or target-GPU FPS.
