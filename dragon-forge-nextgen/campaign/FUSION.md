# Reconnection: Resonance Fusion

Forge resonance recruits new guardians while retaining parents and progression.
The campaign supports nine owned guardians with an explicit two-slot expedition.
The existing 22 rooms, thirteen encounters, parent evolutions and ending remain.

| Result | Native recipe or preserved source | Feature contract |
|---|---|---|
| Arc / Storm | Evolved Fire + Ice, stabilized by the recovered lattice | Storm details below |
| Cairn / Stone | Fire + preserved Stone imprint | [STONE.md](STONE.md) |
| Nox / Venom | Ice + preserved Venom culture | [VENOM.md](VENOM.md) |
| Umbra / Shadow | Fire + Venom | [SHADOW.md](SHADOW.md) |
| Null / Void | Preserved post-ending Void imprint | [VOID.md](VOID.md) |
| Prism / Synthesis | Light + Void | [SYNTHESIS.md](SYNTHESIS.md) |

Light itself is the direct Singularity completion reward and requires no Forge recipe.
With Lumen and Null owned, create Synthesis resonance and awaken Prism at the same
Forge station. Both parents, all other guardians and the selected pair are retained.

## Earn Arc

1. Rescue and hatch Rime, then evolve both parents at the Guardian Nursery. The existing
   requirement is Bond III (280) and two installed sector cores.
2. In Storm Spine, defeat the Fork Guardian at Wire Fork. Use its west side passage to
   Capacitor Cache. Press E at the right-hand **Conductor Lattice** plinth.
   This is separate from the salvage cache; already claimed caches do not prevent rescue.
3. Return to the Forge. **Resonance Fusion** is on the left at (-7, 0, 8).
   Its preview lists the parents, missing requirements and the non-destructive result.
4. Choose **Create Storm egg / keep both parents**, then **Hatch Arc / free**.
   Forging and hatching are separate persistent, idempotent milestones. No salvage is spent.
5. Walk to the right-hand **Guardian Nursery**, open Guardians and choose Arc's
   **Equip as reserve** button. Close the panel and press Tab to take point.

The canonical browser recipe in `src/fusionEngine.js` maps Fire + Ice to Storm and marks
that opposing pair unstable. This native adaptation uses the recovered lattice to stabilize
an offspring without sacrificing either parent. It intentionally does not port random
stability penalties or parent consumption. No hidden fee, duplicate reward or auto-evolution.

## Two field slots, nine potential guardians

One active + one reserve are physically available. Other owned guardians remain at the
Forge. A benched guardian is not simulated and cannot provide an extra knockout handoff.
Choose any two owned guardians at the Nursery. Equipment changes there rest the
selected pair; the Nursery is a safe-town station, not an in-combat heal.

Tab swaps the two selected guardians only. The 2.5-second shared swap cooldown, committed
attacks/dodges, independent HP/heat/cooldowns and reserve cooling remain. Persistent fields
retain their original caster, duration and damage snapshot through swaps. Checkpoint retry
restores exactly the selected pair. No autonomous companion AI is added.

Thermal relays still require Magma. With Ice/Storm selected, return to the Forge and equip
Magma before using an unpowered heat gate. Esc / Return to Forge is always available;
this update does not force elemental puzzles open or silently change the player's pair.

## Storm kit (provisional balance)

| Technique | Damage | Heat | Cooldown | Contact | Recovery |
|---|---:|---:|---:|---:|---:|
| Spark Talon | 20 | 0 | 0.55s | 0.12s | 0.21s |
| Arc Lance | 32 | 22 | 2.6s | 0.26s | 0.34s |
| Static Well | 10 per 0.6s tick | 30 | 6s | 0.24s | 0.30s |
| Tempest Discharge | 52 | 40 | 9s | 0.34s | 0.42s |

Lance and Well apply **4 seconds of Charge** on a landed hit. Tempest consumes Charge for
**+50% damage once**. A closed shield blocks both new Charge and Discharge; blocked hits do
not consume an existing mark. Charge never changes the enemy tell clock. Chill and Fire
shatter remain separate. The static field lasts 3.6 seconds and uses the existing wall
geometry/line-of-sight checks. No chain-hit-through-walls or shield-bypass mechanic is claimed.

Arc has 102 base HP (85% of Magma's unmodified baseline). Existing modules, salvage health,
power and cooling upgrades apply. Arc also has the earned Tempest evolution described in
[TEMPEST_AUDIO.md](TEMPEST_AUDIO.md).
All effects resolve through the real campaign actor and contact signals, not an alternate
combat engine. Changing visual quality or reduced motion does not change the combat rules.

## Assets and presentation

`fusion_assets/storm_guardian.glb` is an original hovering, winged drake: 2,056 triangles,
17 bones, nine clips. Its egg is a separate 324-triangle export. Four 1024-square PNG maps
supply base color, ORM, tangent-space normal and controlled emission. The original nineteen
GLBs and eight maps are unchanged. These are editable parametric assets, not hand-sculpted
cinematic art. Offline source: `tools/build_storm_guardian.py`; existing pinned authoring
dependencies are in `tools/art-requirements.txt`. Godot plays the committed assets directly.

Arc intentionally hovers; it is not a flying player controller. The same grounded collider,
movement boundaries, speed and dodge rules apply, so it cannot cross missing decks or walls.
No foot-lock or terrain-grounding claim is made for Arc. The inspector explicitly reports
that no planted-foot contract applies. Magma and Rime retain their existing foot solvers.
The inspector includes Arc as its seventh entry. Reduced motion quiets the idle bob and
secondary wings/tail but retains action poses and mandatory combat feedback.

## Save compatibility

Campaign schema 4 introduced `lattice_recovered`, `storm_forged`, and `loadout`. Current
schema 11 adds `synthesis_forged` without auto-granting its reward. Earlier versions
migrate in memory without granting unearned resonance or modifying original files on load.
The next successful write backs up the prior bytes via the existing store. Existing rooms,
cores, salvage, guardians, evolutions and upgrades remain. Malformed/future saves stay
write-blocked. These changes never touch browser or prototype saves.

An empty `loadout` means automatic selection of the owned guardian or pair only while
at most two guardians are owned. Recruiting later guardians records the current pair explicitly. An explicit pair must contain two
different owned guardians and include the active one. Unowned/duplicate/three-slot and
unearned-Storm states are rejected. Mid-combat resources remain session-only as in earlier
campaign builds; Continue restores the pair at the recorded room entrance.

## Reproducible validation

- `campaign/tests/fusion_tests.gd`: prerequisite rejection, idempotence, actual plinth/fusion/
  nursery wiring, source-save migration/backup, field selection, contact timing, shielded
  Charge/Discharge, persistent ownership, knockout/bench isolation and imported clips.
- `campaign/tests/fusion_play.gd`: bounded guard/counter policy in Live Wire and Logic Core
  using real player movement, techniques and finite repairs. Setup grants an earned state;
  combat does not inject damage or force vulnerability. Not human balance testing.
- `campaign/tests/fusion_capture.gd`: scripted recruitment/menu/combat/inspection checkpoints.
  Captures seed prerequisites and freeze contact poses, not an unassisted playthrough.
- `tools/validate_fusion.cjs`: official Khronos glTF validation of both new committed assets.

Use Godot 4.6.3 Standard. **F5 runs Reconnection**, while opening a validation scene and F6
runs that tool only. The root-project import ZIP includes explicit directory entries.
Hardware performance, physical controller feel, final artwork/animation and general terrain
remain human acceptance work. The current campaign includes the additional resonance
recipes above, the existing soundtrack and editor plus standalone packages; each feature
revision requires its own full release gates.
