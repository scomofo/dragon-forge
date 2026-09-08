# Dragon Forge: Reconnection

This is a **compact, end-to-end playable campaign**. Open `project.godot` in **Godot 4.6.3 Standard** and press **F5** to launch `campaign/main.tscn`. Character inspection and the original mechanical arena remain separate scenes. The current development pass adds Synthesis and schema 11; its release status depends on the checks for the exact revision being reviewed.

## First two minutes

Choose **Begin campaign**. Press **E** at the hatch ring to awaken Magma. Walk north to the **EXPEDITIONS** arch, or press **M** and choose **Outer Grid / Enter sector**. In the Field Locker, continue through the north portal. The first patrol is unshielded; later guardians must be countered after their telegraphed attack. There is no mandatory fire-puzzle gate preventing departure from the Forge.

## What is included

The Forge, five authored rooms in each of four sectors, and the Singularity chamber: **22 connected rooms and 13 encounters**. Each sector has a rest shelter, an approach fight, a guarded relay junction, an optional salvage cache and a boss. Travel is through labeled physical portals with real dependency checks. Only one room is streamed at a time.

| Sector | Main route | Optional branch | Boss |
|---|---|---|---|
| Outer Grid | Field Locker → Signal Approach → Firewall Span → Overflow Vent | Maintenance Cache | Buffer Overflow |
| Frozen Cache | Cold Archive → Mute Channel → Thaw Junction → Memory Vault | Frozen Vault | Memory Leak |
| Storm Spine | Overclock Gantry → Live Wire → Wire Fork → Logic Core | Capacitor Cache | Stack Overflow |
| Admin Core | Mirror Vestibule → Recursive Gate → Cold Lanterns → Protocol Throne | Admin Vault | Mirror Admin |

The names and themes inherit `src/worldZones.js` and the browser canon. The spatial rooms and combat patterns are new adaptations, not a claim to have ported every browser encounter or dragon.

Clear each boss, **collect its pedestal core**, take the return portal and install the core at the Forge socket. This opens the next sector. Four installed cores open the Singularity. Its three health phases introduce beam, then fan, then ring combinations; stabilizing its pedestal reaches a written ending. Post-ending exploration stays available.

## Combat and growth

The collection can contain **nine guardians**, with **two selected for an expedition**. Recruitment follows each recipe's prerequisites, not a mandatory roster order. Nox and Umbra can join before optional Arc or Cairn; Cairn can also be the first reserve. Recruiting later guardians preserves the selected pair and produces valid saves.

| Guardian | Recruitment route | Combat identity |
|---|---|---|
| Magma / Fire | Awaken at the Forge hatch ring | Heat relays, Fire damage and shattering Chill |
| Rime / Ice | Rescue the Frozen Vault egg; hatch at the Forge Nursery | Chill and Crystal Aegis |
| Arc / Storm | Evolve Magma and Rime, restore two cores, recover the Capacitor Cache lattice; fuse at the Forge | Charge and Tempest Discharge |
| Cairn / Stone | Recover the Admin Vault imprint; restore three cores; temper with Magma at the Forge | Guarded hits build Resolve for Earthshatter |
| Nox / Venom | Recover the Frozen Vault culture; restore three cores; stabilize with Rime at the Forge | Toxin stacks and Septic Bloom |
| Umbra / Shadow | Fire + Venom resonance at the Forge after awakening Nox | Dodge-earned Phase and Phase Strike |
| Null / Void | Stabilize the Singularity; recover its preserved Void imprint; stabilize and awaken at the Forge | Push, pull, drain and timed reflection |
| Lumen / Light | Stabilize the Singularity pedestal; Lumen awakens directly | Shield-respecting radiant damage and self-restoration |
| Prism / Synthesis | Own Lumen and Null; create Synthesis resonance and awaken at the Forge | Rift displacement, direct beam and status-selecting Recompile |

Parents and existing progression are retained. Magma and Rime can evolve at Bond III with two restored cores; Arc's Tempest evolution requires three restored cores. Specializations can be reconfigured at the Nursery. See [GUARDIANS.md](GUARDIANS.md), [EVOLUTION.md](EVOLUTION.md), [FUSION.md](FUSION.md), [STONE.md](STONE.md), [VENOM.md](VENOM.md), [SHADOW.md](SHADOW.md), [VOID.md](VOID.md), [LIGHT.md](LIGHT.md) and [SYNTHESIS.md](SYNTHESIS.md) for the feature contracts.

Umbra gains one Phase when a real incoming hit intersects its dodge window, capped at two. Phase Strike gains 30% damage per stack and consumes stored Phase only after dealing damage. Misses, interrupted windups and closed shields preserve the stacks. Post-hit invulnerability grants no Phase.

Null has four techniques:

| Slot | Technique | Effect |
|---|---|---|
| 1 | Rift Shard | Direct basic attack |
| 2 | Void Rift | Damages and pushes exposed enemies |
| 3 | Null Reflect | A 1.2-second window halves incoming damage; surviving a landed attack counters its actual source, subject to that attacker's shield |
| 4 | Siphon Rift | Damages and pulls exposed enemies; heals Null for 40% of actual damage dealt, capped at maximum HP |

The reflection counter is based on damage actually received, capped at 20 per hit. Shield-blocked hits provide no push, pull or siphon healing. Bosses and enemies with locked attack warnings remain anchored; ordinary displacement uses collision-aware movement. Void does not bypass shields or move an already committed attack warning.

Lumen is a gold-and-white winged biped with stained-glass wing panels. Stabilizing the Singularity awards Light directly, keeps all owned guardians and preserves the selected expedition pair. Void is optional and no Forge recipe is required.

| Slot | Technique | Effect |
|---|---|---|
| 1 | Prism Claw | 22 base damage |
| 2 | Radiant Beam | 36 base damage in the aimed attack area |
| 3 | Solar Flare | 42 base damage around Lumen; closed shields block it |
| 4 | Restoration | Heals Lumen for 25% of its own maximum HP; 34 heat and a 12-second cooldown |

All Light attacks use ordinary shield checks. Restoration affects the active Lumen only and never revives a fallen guardian. The current combat model has no player ailment or accuracy system, so this adaptation provides no cleanse or Dazzle effect.

Prism retains Void's diamond frame and fills it with hard gold-and-white Light panes. Its canonical Light + Void recipe retains both parents and every existing guardian; the expedition pair changes only when selected at the Nursery.

| Slot | Technique | Effect |
|---|---|---|
| 1 | Convergence Shard | 26 base damage |
| 2 | Void Rift | 32 base damage and up to 1.25 m of collision-respecting push on exposed ordinary foes |
| 3 | Radiant Beam | 36 base damage in a direct aimed line; no persistent field |
| 4 | Recompile | 46 base radial damage with the best available existing status payoff on each target |

Recompile chooses Chill/Fire at 1.4×, Charge/Storm at 1.5×, or Toxin/Venom at 1.25–1.75×, selecting the highest multiplier and breaking ties in Fire, Storm, Venom order. An unmarked target receives the neutral 1× hit. Only the selected status is consumed, and only after actual damage; closed shields preserve all marks. This is an explicit native adaptation of browser Advantage: native enemies have no target-affinity field to copy. Prism grants no healing, reflection, Phase, new ailments or thermal relay power.

Five imported bosses have their own models and attack clips; ordinary encounter variants reuse the Sentinel/Warden models. Locked warnings use circles, a beam lane, a three-circle fan and a ring with a safe center. Impact checks use those same locked shapes. Shielded enemies expose recovery windows; scouts have no shield. Electrical/thermal floor hazards have a gold warning interval.

Salvage is earned once per encounter/cache. The Forge anvil offers three permanent three-level upgrades: +20 HP per plating level, +12% technique damage per power level, +4 cooling/sec per cooling level (half while guarding). Prices are 30/60/90 per track. No mandatory farming is required; defeated encounters and recovered caches do not regenerate rewards.

The original three core modules become available after the first installation and can be changed freely at the Forge. **Q** spends a repair charge to restore up to 60 HP. The Forge, shelter lanterns and defeat retry restore the two charges. Taking another room's door alone does not refill them. Defeat retries the current room rather than restarting the campaign. Already cleared encounters, relays, upgrades and rewards persist.

Felix's text radio and field records explain the story and mechanics. Read records are kept in the journal. The existing ten soundtrack recordings and native effects are integrated, with audio settings on the title and pause menus; there are no character voices. See [TEMPEST_AUDIO.md](TEMPEST_AUDIO.md) for audio behavior and provenance.

## Controls

WASD/arrows move; mouse or right stick aims; 1–4 / X,Y,LB,RB use techniques. Space/A dodges; Shift/LT guards; E/B interacts. Q or the clickable Repair button heals the active guardian. Tab / right-stick click swaps to the reserve; P opens Guardians. M / Routes opens the map. N / Journal opens records. Esc/Start pauses. The route map, records, upgrades and menus have native focusable buttons; dedicated controller shortcuts for Q/M/N are not yet provided. Physical-controller acceptance remains open.

## Saves and compatibility

Campaign milestones use **`user://reconnection-campaign.json`**, within the existing nextgen user-data directory. The old `nextgen-progress.json` is read only on first campaign creation: a valid existing Magma hatch and module carry over with 30 starter salvage. The prototype's single-room encounter clears are not misrepresented as completion of these new sectors. It is never overwritten. Existing browser saves are separate.

Campaign **schema 11** adds the `synthesis_forged` flag and Synthesis ownership. Valid older saves receive no Synthesis progress; awakening Prism requires earned Light and Void parents plus the forged resonance. Schema 10 introduced Light ownership without another persisted unlock flag. A completed campaign must own Light; valid completed saves from schema 9 and earlier receive that earned guardian during in-memory migration. Unfinished saves receive no Light. Loading preserves the original save bytes, existing guardian order and any selected expedition pair. The existing recovered/forged Void progression remains independent. Ownership accepts legitimate optional recruitment orders while rejecting unknown, duplicate or unearned guardians. The selected expedition remains limited to two owned guardians.

Campaign writes validate data, verify a temporary write and retain the prior exact bytes as `.bak`. Unknown/future/corrupt data is preserved and write-blocked, with an on-screen session-only warning. No automatic backup restoration is claimed. Continue returns to the last entered room's entrance with full health and repair charges, rather than the exact mid-fight frame. Explicit New campaign replaces only this campaign's progress after confirmation. Settings remain in the existing separate preferences file. Phase and Null Reflect are session combat state, not saved milestones.

## Tests

Use Godot 4.6.3 Standard. Tests use `--test-mode` and test-only storage paths, not normal saves.

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://campaign/tests/run.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/recruitment_tests.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/synthesis_tests.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/synthesis_combat_tests.gd -- --test-mode
godot --headless --fixed-fps 60 --path . --script res://campaign/tests/synthesis_runtime_tests.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/light_tests.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/light_combat_tests.gd -- --test-mode
godot --headless --fixed-fps 60 --path . --script res://campaign/tests/light_runtime_tests.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/void_tests.gd -- --test-mode
godot --headless --path . --script res://campaign/tests/void_combat_tests.gd -- --test-mode
godot --headless --fixed-fps 60 --path . --script res://campaign/tests/void_runtime_tests.gd -- --test-mode
godot --headless --fixed-fps 60 --path . --script res://campaign/tests/play_smoke.gd -- --test-mode
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://campaign/tests/capture.gd -- --test-mode
```

The traversal suite checks all rooms, prerequisites, real spell/relay/actor wiring, caches, upgrades, core return/install, ending, retry, pause, movement and save behavior. It uses controlled setup/damage for complete coverage and is not a player-experience verdict. The controller smoke policy separately defeats a patrol, the first boss and the final boss using actual movement, techniques, guard and finite repair charges without direct damage injection or forced shield openings. Those are bounded automated scenarios, not human playtests or difficulty measurements.

Visual capture setup seeds prerequisites to inspect sectors independently. It does not pretend that screenshots prove an unassisted playthrough. The rendering tests use software graphics, not target-hardware benchmarks.

The **Nextgen Synthesis guardian** workflow runs the inherited regression stack and Synthesis acceptance with OpenGL and Forward+ captures, and produces an editor-project ZIP. **Nextgen standalone playtests** separately builds Windows/macOS/Linux exports and checks each on a native runner. A release requires successful results for the same feature revision; this documentation alone does not establish a passing release. See [../release/README.md](../release/README.md) for standalone launch instructions.

## Boundaries

The scope is a short campaign with nine potential guardians, two field slots, earned evolution/resonance, Forge Trials and the existing soundtrack. The full browser collection/content, additional biomes, multiplayer and voiced dialogue remain outside this adaptation. Forge Trials keep their records separate from campaign rewards and unlocks.

Balance, duration, character readability/deformation, target Mac/PC frame times, physical controllers and audio still need human acceptance. The optional first-pass guardian rigs, including Umbra, Null, Lumen and Prism, are not certified for planted-foot behavior. Software-rendered captures and prepared combat fixtures provide review evidence, not that certification. Shared polished assets, legacy simulation and validation scenes remain available.
