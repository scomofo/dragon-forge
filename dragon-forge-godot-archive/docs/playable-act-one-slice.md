# Playable Act I Slice

## Current Build Target

The current playable slice is:

1. Start at **New Landing**.
2. Trigger **First Flight** from the action panel.
3. Receive the **10mm Wrench** and Root Dragon bond.
4. Travel to **Felix Workshop**.
5. Enter the side-scrolling **Cooling Intake** hardware dungeon.
6. Tighten pressure valves, disable steam hazards, reach the exit relay, and return to the overworld.
7. Travel to the **Overgrown Buffer**.
8. Trigger **Kernel Recovery** to rescue the Weaver and compile Magma-Core.
9. Return to **Felix Workshop** and weave the **Friction Saddle**.
10. Travel to the **Southern Partition Gate**.
11. Enter the side-scrolling **Southern Partition Airlock**.
12. Pull the Primary Breaker with the 10mm Wrench.
13. Exit into the **Tundra of Silicon**, completing Act I.

## Runtime Flow

- `res://scenes/main.tscn` owns the router.
- `res://scripts/main.gd` switches between:
  - `WorldScene`
  - `BattleScene`
  - `HardwareDungeonScene`
- `WorldScene` emits `dungeon_requested` when Skye enters a mapped Access Port.
- `HardwareDungeonScene` emits `dungeon_closed` with the updated profile and completion result.

## Cooling Intake Controls

- `A/D` or arrow keys: move.
- `W` / Up: jump.
- `Space` / Enter: use wrench.
- `Esc`: return to overworld.

## Cooling Intake Completion

The Cooling Intake grants:

- `cooling_intake_relay`
- `dungeon_cooling_intake_complete`

Kernel Recovery grants:

- `kernel_recovery_complete`
- `magma_core_compiled`
- `magma_core_form`
- `heat_shard`
- `silken_data`

Friction Saddle crafting grants:

- `friction_saddle`
- `friction_saddle_crafted`

Southern Partition Airlock grants:

- `firewall_bypass`
- `dungeon_southern_partition_airlock_complete`

Entering the Tundra grants:

- `act_one_complete`

This proves the new dual-layer structure:

- The overworld is the Pastoral Render.
- The side-scrolling dungeon is the Hardware Layer.
- The wrench is a physical verb rather than a menu item.

## Next Build Step

The next practical slice is **Act II's Great Buffer / Tundra onboarding**:

- White-Out Purge timing.
- Unit 01 mobile shop/save point.
- Optical Lens retrieval in a side-scrolling vault.
- Prism-Stalk mutation setup.
