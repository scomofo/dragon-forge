# Tempest & Sound

The default Run Project entry remains the complete Reconnection campaign. This pass
adds Arc's first evolution and integrates ten recordings already present in the
repository. No new soundtrack composition, enemy model, biome or standalone export.

## Play

Use Godot **4.6.3 Standard**, allow imports, and click **Run Project** (Cmd+B on
macOS / F5 on Windows and Linux with default key mappings). Choose Continue to
keep the campaign. The title includes **TEMPEST & SOUND**. Import a complete ZIP
into a new empty folder rather than copying files into an older project.

Arc is still earned via the Conductor Lattice / Fire + Ice fusion recipe. After
hatching Arc, reach Bond III and install **three sector cores**, including Storm
Spine. At the right-hand Forge Guardian Nursery, open Arc's Evolution card.
Evolution costs no salvage, preserves the parents and does not change your pair.
Equip Arc at the Nursery and use Tab to swap the selected active/reserve pair.

**Tempest Arc** gains 10% maximum health and technique damage, as the other evolved
guardians do. Choose one specialization, changeable freely at the Nursery:

* **Thunderhead**: Lance and Static Well apply **6 seconds of Charge**, up from 4.
* **Overcharge**: Discharge cooldown becomes **6.75 seconds**, down from 9.

Heat cost, warning/contact timings, range, movement and shield checks are unchanged.
Static fields snapshot Charge duration as well as damage and caster identity. A
blocked hit cannot apply/consume Charge. A successful Discharge consumes Charge
for the existing single 50% damage bonus. The evolution changes neither flight
physics nor collision: Arc is still a hovering visual over a grounded controller.

The exported variant adds 500 triangles of crown forks, conductor vanes and wing
armor. It retains all original body vertices, the 17-joint rig, inverse binds and
nine animation tracks. It reuses the Storm textures. This is parametric art, not
newly sculpted anatomy. It has no foot-planting contract. The two grounded dragons
retain their existing flat-deck solvers.

## Audio

**Audio settings** is available on the title screen and pause menu. Master, Music
and Sound Effects are independent sliders. Mute All and Mute When Unfocused are
separate toggles. Preferences are saved when leaving the audio panel, not on every
slider tick. Corrupt/future settings are preserved and changes remain session-only.
The panel returns to its originating title or pause screen; it does not accidentally
resume a fight. No microphone, network, streaming service or external account is used.

Title, Forge, exploration, battles, bosses, Mirror Admin, Singularity, defeat and
ending use existing repository recordings. Victory is a one-shot sting. Two music
decks crossfade over 0.65 seconds; repeated requests do not restart tracks. Opening
menus ducks the bed. By default losing focus pauses/silences music and clears
transient effects. Returning focus does not undo a user's mute or zero volume.
This is track switching, not synchronized adaptive stems or beat-matched music.

The private audio mix has a limiter, ten rate-limited effect voices, two music
players and one stinger. Synthesized effects distinguish Fire/Ice/Storm at actual
technique contact, with separate accepted-command, hit, shield, guard, damage,
warning, impact, swap, repair, relay, hatch, evolution and fusion cues. These are
initial sound-design assets; subjective mix/device acceptance still requires play.
SFX envelopes cannot change combat timing, inflict damage or trigger rewards.

### Provenance and format correction

`audio/manifest.json` records the source paths, fixed repository revision and SHA-256
of all ten recordings. The native copies are byte-for-byte identical to the original
files. `public/assets/music/music_battle.mp3` actually contains PCM WAV data; only
the native filename is corrected to `music_battle.wav` so Godot chooses the right
decoder. The browser source and all original recordings remain unchanged.

## Saves and scope

Campaign schema **5** adds an initially empty Storm specialization to valid schemas
1–4. It never awards an unearned evolution, resets milestones or writes on load.
The next successful write retains the previous bytes through the existing backup
mechanism. Unknown/foreign/unearned/future choices are rejected. Audio preferences
live separately in `user://reconnection-audio.json`; campaign data and graphics
preferences are not audio settings. Mid-fight health remains session-only as before:
Continue restores the pair at the current room entrance.

## Reproducible checks

`tools/build_tempest.py` is offline authoring source, not needed to play. The
committed GLB is checked with `tools/validate_tempest.py` (geometry prefix, rig,
keys, texture paths and hashes) and the Khronos validator via
`tools/validate_tempest.cjs`. Neither validation command rewrites exports.

`campaign/tests/tempest_tests.gd` checks prerequisites, migration, state ownership,
independent effects, the actual model, shields, contact timing and field snapshots.
`campaign/tests/audio_tests.gd` checks track decoding, bounded players, crossfade
reversal, zero/mute/focus transitions, pause behavior, preferences, real game signals,
and non-silent vs muted PCM sampled from the actual Godot output bus. No microphone
is involved. `audio_capture.gd` records a labeled scripted output tour; it is not a
recording of a full unassisted playthrough or of the user's computer.

`tempest_capture.gd` renders prepared visual checkpoints with separate inspection
and gameplay cameras. Passing regression tests is not a verdict on human balance,
art quality, audible speaker/headphone mix or target Mac/Windows/GPU performance.

Future scope remains full life stages, more fusion recipes/guardians, distinct
campaign enemy models, terrain-general grounding and standalone app exports.
