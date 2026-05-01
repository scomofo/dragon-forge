# Playable Mainframe and Restoration Route

## Current Build Target

The playable chain now continues beyond Act II onboarding:

1. Install **Insulated Grip** with Unit 01.
2. Travel to **Mainframe Spine Base**.
3. Catch the first **Thermal Chimney** to begin vertical ascent.
4. Enter the side-scrolling **Logic Core** dungeon.
5. Turn the live terminal with the Insulated Grip.
6. Unlock **External Vents**.
7. Climb to **Legacy Peak**.
8. Bypass **Root Sentinel** and recover the **Floppy Disk Backup**.
9. Travel to **Mainframe Crown**.
10. Choose Total Restore, The Patch, or Hardware Override.
11. Unlock **Read-Only Free-Roam**.
12. Review the ending panel / zero-G credits run readout.
13. Explore the revealed map with ending-specific Historical Site labels.

## Runtime Hooks

- `res://scripts/sim/act_two_progression_data.gd` now owns the Spine and Restoration route helpers.
- `res://scripts/world/world_scene.gd` exposes the route as objective branches and action buttons.
- `res://scripts/dungeon/hardware_dungeon_scene.gd` completes the Logic Core with `external_vents_unlocked`.
- `res://scripts/sim/restoration_data.gd` still owns the choice matrix and ending state.
- Restoration choices now create an ending presentation payload, credits-run state, postgame state, and revealed map labels.

## Key Rewards

Insulated Grip:

- `insulated_grip`
- `insulated_grip_installed`

Mainframe ascent:

- `mainframe_spine_ascent_started`
- `thermal_venting_learned`

Logic Core:

- `external_vents_unlocked`
- `dungeon_logic_core_complete`
- `logic_core_vents_unlocked`

Root Sentinel:

- `root_sentinel_bypassed`
- `floppy_disk_backup`
- `kernel_blade`

Restoration:

- `restoration_choice_total_restore`, `restoration_choice_patch`, or `restoration_choice_hardware_override`
- `credits_run_complete`
- `read_only_free_roam`
- `ending_presentation`
- `credits_run`
- `postgame_state`

## Completion Definition

The current prototype now has a complete story route from New Landing through the Restoration choice and into Read-Only Free-Roam. It is still mechanically rough, but the overworld-to-dungeon-to-choice-to-postgame spine exists and is verified by smoke tests.

The first combat beat is now required: after First Flight, the **Search & Index Daemon** appears at New Landing as the Mirror Admin's first response to the beacon. Defeating it grants `search_index_daemon_defeated` and unlocks the Cooling Intake objective.

Act II now has a required antagonist beat: after Unit 01 comes online, the **Mirror Admin Projection** manifests in the Tundra. Defeating it grants `mirror_admin_tundra_repelled` and `parity_trace`; the Great Buffer will not release the Optical Lens until that flag is present.

Hardware Dungeons now declare physical anomaly pressure. The Great Buffer displays **The Indexer**, and the Logic Core displays the **Sentinel Drone** in the side-scrolling HUD so dungeon interiors feel actively defended. Once the main room mechanism is fixed, defended dungeons expose an **Anomaly Core**. The exit stays locked until Skye disables the core with the correct action.

Anomalies now attack during defended dungeons. The Indexer sweeps a sorting-arm lane through the Great Buffer, while Sentinel Drone fires lighting-weapon columns that become readable when Skye has diagnostic protection.

Anomaly attacks now telegraph before they become damaging. The Great Buffer shows "Sorting Arm Sweep incoming" before the Indexer lane activates; the Logic Core uses "Diagnostic Lens Warning" before the Sentinel Drone fires. These are now authored patterns rather than static lanes: the Indexer sweep moves horizontally, and Sentinel Drone exposes safe spots between light columns.

Hardware Dungeon rooms are now data-driven. The Cooling Intake has a two-valve tutorial turbine layout, the Airlock has firewall-breach stepping platforms, the Great Buffer has a vault layout, and the Logic Core has a denser vertical data-conduit layout.

Hardware Dungeon movement now has coyote time, jump buffering, and a deliberate fast-fall multiplier so side-scrolling rooms can ask for tighter jumps without feeling brittle.

Dragon support now affects side-scrolling rooms. Magma-Core can assist from outside the dungeon and expand internal service platforms, preserving the bond between Skye and the dragon even when Skye is on foot.

Dungeon entry now uses shared story-gate rules. If Skye reaches a hardware entrance too early, the action button stays locked and explains the missing prerequisite instead of letting the player enter a dead-end room.

The finale is no longer only a status message. Restoration now creates a credits-run HUD payload, animated zero-G credits display, Felix ending line, postgame state, and ending-specific revealed map labels. The Review Credits Run action replays the fly-down by revealing credits lines over time and naming each descent segment from Mainframe Crown back to New Landing. The credits run also exposes camera/transition state so the visual pass can drive terminal-sky, schematic paintover, and pastoral-settle effects.

## Next Build Step

The best next work is polish and feel:

- Improve side-scroller collision and player feel beyond the current forgiveness pass.
- Add rendered visual staging to the animated credits fly-down using the current camera/transition state.
- Expand hardware-dungeon boss interactions with additional phases, vulnerability windows, and dragon-assist variants.
- Replace placeholder geometry with generated/handmade sprites.
