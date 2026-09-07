# Boss Identities

This pass replaces the shared Warden presentation for the four sector bosses and
Singularity. The 22-room campaign is still the default project entry, with all three
guardians, their evolutions, fusion, upgrades, audio, and schema-5 saves intact.

## Five imported body plans

| Encounter | Body plan | Readable techniques |
|---|---|---|
| Buffer Overflow | Low tracked furnace, paired ram arms, split storage shell | Ram Impact (circle); Pressure Vent (safe-center ring) |
| Memory Leak | Suspended cryogenic archive bell, hanging memory ribbons | Archive Lance (locked beam); Cold Snap (circle) |
| Stack Overflow | Offset levitating processor tower, three emitters | Triple Fault (three circles); Stack Trace (locked beam) |
| Mirror Admin | Split mirror mantle, chest eye, ceremonial seal | Access Denied (ring); Audit Ray (beam); Revoke (three circles) |
| The Singularity | Hollow tetrahedral cage, gyroscopes, luminous central star | Core Ray (beam); Fragmentation (three circles); Event Horizon (ring) |

Five separate skinned GLBs share one new four-map 1024-square PBR atlas. Their
geometry and bone/animation data are new; these are not recolors of the Sentinel.
The editable offline builder uses the existing compiler, not existing character meshes.
The existing 22 GLBs, twelve texture maps and ten recordings are unchanged.

This is first-pass, low-poly parametric art, not final hand-sculpted production art.
Buffer rolls on track runners; the other four are suspended/hovering. They do not
claim a planted-foot IK contract. All retain the original grounded enemy collider,
pathfinding and collision masks, so hovering does not permit flight through walls.
Magma and Rime's foot solvers are unchanged.

## Attack timing remains authoritative

Each boss has idle, travel, recovery-open and defeat clips, plus a separate tell
and strike for every attack in its existing sequence: 44 clips across the five models.
Tell time is normalized to the actual locked duration. The tell's final bone pose
is the strike's first pose. The strike is sampled before the authoritative impact
signal is emitted; no animation method track can cause damage or duplicate rewards.

Facing commits to the locked direction. Moving the player cannot bend a warning.
The same existing `Patterns` payload still draws warnings and checks damage.
A short 0.16-second outline holds after impact; the open core/shield state and the
HUD identify the counter window. The HUD names the current boss technique while
retaining the explicit movement instruction. Beam visuals originate at the imported
core socket; this is not a change to beam reach, collision, or hit tests.

Enemy health, damage, attack sequence, enrage thresholds, tell/recovery durations,
range, speed, shield rules, Chill/Charge, and progression rewards are unchanged.
The final boss opens its cage/rings across the same three existing health phases;
this is a fixed phase pose, not a flashing effect or a new invulnerability interval.

On defeat the actor still leaves combat immediately. Only its mesh is reparented
to the room for a bounded 0.85-second collapse; the cosmetic remainder has no
collider, combat callbacks, or additional reward. Changing rooms also removes it.

## Camera readability

The shared camera's defaults preserve the old prototype. Campaign boss encounters
opt into a capped shared focus and a slightly wider, smoothly settled camera distance.
This keeps tall silhouettes below the central enemy HUD at tested engagement range,
without changing movement, aiming rays, damage, quality settings or reduced-motion rules.
Ordinary enemies return to the original framing. Projection checks cover the boss
head and the player's support area at 1280 x 720; they are finite checks, not an
assertion that every extreme position, window size or tail pose is obstruction-free.

## Review both ways

- **Character inspection:** open `validation/character_inspection.tscn` and Run
  Current Scene. The last five entries are the new bosses. Neutral key/fill, optional
  strong rim, clay/albedo/PBR overrides, clip cycling, scrubbing and close views all
  use the actual exports. This is in-place inspection, not a locomotion/physics test.
- **Boss rehearsal:** open `validation/boss_arena.tscn` and Run Current Scene.
  Select any of the five actual boss rooms and fight with the real campaign camera,
  movement, abilities, damage and attack clock. Explicit health presets sample
  later phases. **F9** arms a freeze after the next real boss impact; **F10** resumes
  a contact freeze; **F7** hides the review panel. F10 does not dismiss a normal pause
  menu. Prepared guardians/milestones are review state only.

Rehearsal sets `test_mode` before initialization. It neither loads nor writes normal
campaign/audio/graphics preferences. It does not grant rewards to a player's save.
Previously cleared campaign bosses stay cleared; review them here without resetting
real progress. Run Project still starts the normal campaign, not this rehearsal.

## Verification

`GODOT=/path/to/godot bash tools/test_bosses.sh` runs the imported boss tests and the
existing suites. The audio-output test must run on wall time, not `--fixed-fps`,
because the mixer works on a separate real-time thread. No microphone is used.
`python tools/validate_bosses.py` checks hashes, local texture paths, skin bounds,
finite geometry, distinct geometry fingerprints, and tell/strike pose continuity.
`GLTF_VALIDATOR_MODULE=... node tools/validate_bosses.cjs` invokes the independent
Khronos glTF validator. No Python/Node or authoring step is needed to play.

The native boss tests exercise actual room-to-rig routing, all imported clips,
locked-target immutability, strike-frame synchronization, shield/counter behavior,
reduced-motion timing, phase thresholds, collider invariance, death cleanup,
inspection options and save-isolated rehearsal. A bounded controller fights all
five bosses with real inputs/guard/techniques and finite repairs; checkpoints are
prepared, and this is not human balancing or a full unassisted campaign playthrough.

Scripted engine captures use both gameplay and inspection cameras. Their setup
seeds progression and samples/fixes poses. Software OpenGL/Vulkan evidence is not
a target-GPU benchmark. Mac/Windows performance, physical controllers, human fun,
final art, improved enemy anatomy, wider alchemy and standalone exports remain open.
