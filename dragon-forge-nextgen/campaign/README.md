# Dragon Forge: Reconnection

This is a **compact, end-to-end playable campaign**, not the previous single-room mechanical prototype or the full browser game's feature set. The default entry is `campaign/main.tscn`. F5 starts the campaign title screen. Character inspection and the original mechanical arena remain separate scenes.

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

Existing polished Magma, four techniques, guard/dodge, foot planting and imported environmental kit are reused. Encounter variants use the Sentinel/Warden models; this pass does **not** supply thirteen unique creature models. Their locked warnings are circles, a beam lane, a three-circle fan and a ring with a safe center. The impact checks use the same locked geometric payloads as the warning display. Normal guardians have a recovery counter window; scouts have no shield. Electrical/thermal floor hazards have a gold warning interval.

Salvage is earned once per encounter/cache. The Forge anvil offers three permanent three-level upgrades: +20 HP per plating level, +12% technique damage per power level, +4 cooling/sec per cooling level (half while guarding). Prices are 30/60/90 per track. No mandatory farming is required; defeated encounters and recovered caches do not regenerate rewards.

The original three core modules become available after the first installation and can be changed freely at the Forge. **Q** spends a repair charge to restore up to 60 HP. The Forge, shelter lanterns and defeat retry restore the two charges. Taking another room's door alone does not refill them. Defeat retries the current room rather than restarting the campaign. Already cleared encounters, relays, upgrades and rewards persist.

Felix's radio and field records explain the story and mechanics. Read records are kept in the journal. There are no character voices or soundtrack integration in this build; existing soundtrack files and the browser game are untouched.

## Controls

WASD/arrows move; mouse or right stick aims; 1–4 / X,Y,LB,RB use techniques. Space/A dodges; Shift/LT guards; E/B interacts. Q or the clickable Repair button heals. M / Routes opens the map. N / Journal opens records. Esc/Start pauses. The route map, records, upgrades and menus have native focusable buttons; dedicated controller shortcuts for Q/M/N are not yet provided. Physical-controller acceptance remains open.

## Saves and compatibility

Campaign milestones use **`user://reconnection-campaign.json`**, within the existing nextgen user-data directory. The old `nextgen-progress.json` is read only on first campaign creation: a valid existing Magma hatch and module carry over with 30 starter salvage. The prototype's single-room encounter clears are not misrepresented as completion of these new sectors. It is never overwritten. Existing browser saves are separate.

Campaign writes validate data, verify a temporary write and retain the prior save as `.bak`. Unknown/future/corrupt data is preserved and write-blocked, with an on-screen session-only warning. No automatic backup restoration is claimed. Continue returns to the last entered room's entrance with full health and repair charges, not the exact mid-fight frame. Explicit New campaign replaces only this campaign's progress after confirmation. Settings remain in the existing separate preferences file.

## Tests

Use Godot 4.6.3 Standard. Tests use `--test-mode` and test-only storage paths, not normal saves.

```sh
godot --headless --path . --editor --import
godot --headless --path . --script res://campaign/tests/run.gd -- --test-mode
godot --headless --fixed-fps 60 --path . --script res://campaign/tests/play_smoke.gd -- --test-mode
godot --path . --rendering-method gl_compatibility --audio-driver Dummy --script res://campaign/tests/capture.gd -- --test-mode
```

The traversal suite checks all rooms, prerequisites, real spell/relay/actor wiring, caches, upgrades, core return/install, ending, retry, pause, movement and save behavior. It uses controlled setup/damage for complete coverage and is not a player-experience verdict. The controller smoke policy separately defeats a patrol, the first boss and the final boss using actual movement, techniques, guard and finite repair charges without direct damage injection or forced shield openings. Those are bounded automated scenarios, not human playtests or difficulty measurements.

Visual capture setup seeds prerequisites to inspect sectors independently. It does not pretend that screenshots prove an unassisted playthrough. The rendering tests use software graphics, not target-hardware benchmarks.

## Boundaries

One controllable dragon. No reserve swapping, full creature collection, fusion/evolution, extra biomes beyond these routes, multiplayer, voiced dialogue, soundtrack integration or standalone executable is supplied. This is a short complete campaign path with the existing asset kit, not the original game's full content port. Durations, balance, target Mac/PC frame times and physical controllers still need human acceptance. Shared polished assets, legacy simulation and validation scenes are not replaced by these campaign adapters.
