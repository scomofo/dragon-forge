# Updated Magma polish validation

The gameplay arena now reports authored LOCK/SWING states and independent skinned-sole stance drift. `polish_tests.gd` tests the real correction; `../art/POLISH.md` describes limits and paired baseline methodology. The inspector continues to show the exported, baked animation without runtime IK. The original proximity metric below is retained as a separate diagnostic, not the new contact contract.

# Dragon Forge — two real-asset validation scenes

These are executable Godot scenes, not generated concept pictures. They load the
committed art from PR #26 and isolate review from the original game. No meshes,
textures, rig clips, combat values, or save schemas are changed by this pass.
The sole main-runtime hook is a read-only cache of instancing transforms in
`Art.batch`, needed because Godot's headless dummy renderer has no transform
readback. Rendering and collision in the game are unchanged.

## Open either scene

Use Godot **4.6.3 Standard** (the version used for validation). Import the included
`dragon-forge-nextgen/project.godot` once. In the FileSystem dock, double-click
one of these files and press **F6 (Run Current Scene)**:

- `res://validation/character_inspection.tscn`
- `res://validation/gameplay_arena.tscn`

**F5 still runs the main game**. Neither review scene replaces the main scene.

From the repository root on macOS/Linux, with the existing launcher:

```bash
bash run-nextgen.sh res://validation/character_inspection.tscn
bash run-nextgen.sh res://validation/gameplay_arena.tscn
# Older GPUs / driver troubleshooting:
bash run-nextgen.sh --compatibility res://validation/gameplay_arena.tscn
```

On Windows, open the scene in the editor and press F6, or use the executable:

```powershell
& "C:\Tools\Godot\Godot.exe" --path dragon-forge-nextgen res://validation/character_inspection.tscn
& "C:\Tools\Godot\Godot.exe" --path dragon-forge-nextgen res://validation/gameplay_arena.tscn
```

## 1. Character inspection

The neutral white key and fill reveal the actual texture colors; the separately
switchable strong cool rim reveals silhouette and joint overlap. This is not a
beauty shot that hides the mesh behind effects.

Choose Magma, Sentinel, or Warden, and inspect their actual imported animation
library. Magma has nine clips. `Cycle every clip` advances through even the
non-looping attacks and defeat, with a short hold at the end. Selecting a clip
manually turns automatic cycling off. Playback speeds are 0.25x, 0.5x, 1x, 2x.
Play/Pause, a scrubber, and +/- 1/60-second stepping keep exact extreme poses
repeatable. Scrubbing and looping reset drift tracking so a discontinuous seek
is not reported as skating.

Full body, Shoulders, Hips/feet, Jaw/head, and Rear/tail camera presets are
available. Right-mouse drag orbits; the mouse wheel zooms. Use Full PBR to check
surface wear, Albedo only to separate paint from lighting, and Neutral clay to
inspect the underlying shoulder/hip volume. Materials are private duplicates;
these modes do not edit or re-export an asset. The skeleton overlay is an optional
bone-line reference, not an X-ray mesh/deformation validator.

**Studio walking is in place.** It is suitable for inspecting the clip, not for
certifying world-space foot planting. Sentinel/Warden do not have the same foot
bone contract: the inspector explicitly reports unavailable sole diagnostics
rather than inventing zero drift for those actors.

## 2. Gameplay arena validation

The scene subclasses `world/main.gd`, instantiating the original dragon actor,
rig, enemies, effects, HUD, and `presentation/camera_rig.gd`. It does not implement
alternate combat or a cinematic camera. `test_mode` is set before base initialization,
so it never loads or writes normal progress or preferences. Selecting graphics
quality/reduced motion applies to the review session only.

Select a no-enemy movement lane, a Sentinel encounter, or a Warden encounter.
Manual play uses the normal WASD/mouse, 1-4 abilities, Space dodge, Shift guard,
and Esc pause bindings. The original mapped controller input remains available,
but physical-device acceptance is still needed.

Seven optional short input replays exercise walk-stop-reverse, guard-strafe,
the four stationary attacks, and breath while moving. They inject normal actions
into the existing controller, at **1x simulation time**. They do not alter damage,
force the enemy shield open, heal enemies, or provide immunity. The selected enemy
remains live. Restart each take for a clean comparison; a replay is not an AI
playtest or a balance assessment. Do not simultaneously steer during an input replay.

Review hotkeys (also available when frozen):

| Key | Action |
| --- | --- |
| F6 | Reset the selected review stage and its measurements |
| F7 | Hide/show the review panel and sole markers; original HUD stays visible |
| F8 | Export the current report |
| F9 | Arm/disarm pause on the next player ability contact |
| F10 | Resume after review freeze or native pause |

F9 freezes **after** the original combat tick, actor movement, rig sampling, and
sole sampling. Heat, pose, and event data therefore refer to the same tick. F10
resumes without changing `Engine.time_scale`. Ordinary pause/focus loss and scene
exit release replay-injected actions. No queued replay movement should leak into
another scene.

## What the foot diagnostic measures

Up to eight low-rest-position vertices per foot are selected from the actual
skinned mesh, with at least 80% influence from its named Foot.L/Foot.R joint. CPU
skinning uses the imported skin inverse-bind matrices and current skeleton poses,
including world translation and rotation. The readout reports the lowest sampled
sole height relative to a downward surface ray at the sampled sole centroid.

In the arena, review-only triangle colliders reproduce the imported deck and dais.
They use layer 128, which the real player/enemies/combat rays do not collide with.
Thus the readout compares feet with the **visible art surface**, not only the
lower, invisible gameplay collision slab. The studio has a flat review plane.

The marker is orange when near-ground drift exceeds 3 cm or penetration exceeds
2 cm. These are provisional review thresholds, not shipping acceptance metrics.
A near-surface interval begins below +6 cm and ends above it (or deeper than -25 cm);
horizontal movement is measured from the interval's first sample. This is **not**
an authored contact window, a contact sensor, or an IK foot lock. Stance/swing
intent, turning feet, and uneven triangles can produce ambiguous readings. It
samples soles, not every vertex, and cannot certify the absence of interpenetration.
Use the pictures and continuous motion alongside the report.

Reports contain raw samples, thresholds, maximum drift, minimum clearance,
renderer/engine, the loaded GLB SHA-256, playback context, and—in the arena—actual
ability-start/contact events with authored windup and physics-frame numbers.
They contain up to 7,200 foot samples (about 60 seconds at 60 Hz); excess samples
are counted in `samples_dropped`. Reset before a new take. Long-session summary
extrema continue updating after the sample buffer fills.

Exports are local JSON files under `user://validation_reviews/`. Use Godot's
Project > Open User Data Folder to find them. There is no upload, telemetry,
normal-save mutation, or automatic art-asset overwrite. Engine captures produced
by the automated script go to `artifacts/review-scenes/` instead.

## Review gate before art rollout

1. Inspect head, shoulders, and hips through each extreme and its recovery, under
   PBR and clay lighting. Mark the clip/time and include a screenshot for any gap,
   collapse, tooth intrusion, or texture stretching. A finite pose is not proof
   of good deformation.
2. Run the same candidate in the movement lane and live encounter at the normal
   game camera. Check forward/reverse movement, stop/start, strafing, moving
   attacks, stationary attacks, guard, dodge, and interruptions.
3. Use F9 to inspect all four contact poses; export the event/sole report. Review
   ordinary playback and reduced motion at Low and High. Do not turn off enemy
   warnings just to improve a capture.
4. Compare the same scenarios before/after a candidate asset/planting change,
   keyed by asset hashes. Sign off visual deformation, foot stability, and
   material readability separately from harness correctness.

The present scenes intentionally retain the current art baseline. They expose
existing sliding and deck penetration; **this pass does not claim texture repaint,
corrective skinning, IK implementation, or a completed foot-slide fix**.

## Automated validation

From the project folder:

```bash
godot --headless --path . --editor --import
godot --headless --path . --script res://validation/review_tests.gd
godot --headless --path . --script res://tests/run.gd -- --test-mode
godot --headless --path . --script res://tests/art_test.gd -- --test-mode
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://validation/capture_reviews.gd
```

The harness tests exact seeking/stepping, clip cycling, private materials, real
skin/world transforms, surface probing, authoritative contacts for all four
abilities, injected-action cleanup, contact freeze/resume, and save isolation.
The capture script opens these same interactive scenes and records ten views
plus three baseline reports. Software-rendered evidence is not a GPU benchmark,
physical-controller test, Mac/Windows acceptance pass, or art-direction sign-off.

Implementation references: Godot AnimationPlayer.seek and Skeleton3D's documented
skeleton-relative get_bone_global_pose. Skin probes explicitly multiply by the
skeleton's world transform; animations remain non-authoritative for damage.

- https://docs.godotengine.org/en/4.6/classes/class_animationplayer.html
- https://docs.godotengine.org/en/4.6/classes/class_skeleton3d.html
