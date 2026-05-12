# Playable Act II Onboarding

## Current Build Target

Act II onboarding now follows the Act I breakout:

1. Enter the **Tundra of Silicon** after the Southern Partition Airlock.
2. Start Act II and collect first Silicon Shards.
3. Reach the **Physical Relay**.
4. Survive the first **White-Out Purge** behind analog cover.
5. Return to the Tundra floor and establish the **Unit 01** save/shop link.
6. Enter the side-scrolling **Great Buffer Vault**.
7. Release the **Optical Lens** from its purge-timed cradle.
8. Return to Unit 01 and install the **Frequency Tuner**.
9. Mutate the dragon into **Prism-Stalk** using Tundra data-light.

## Runtime Hooks

- `res://scripts/sim/act_two_progression_data.gd` owns Act II story progression flags and key items.
- `res://scripts/world/world_scene.gd` exposes the Act II action buttons.
- `res://scripts/dungeon/hardware_dungeon_scene.gd` now supports `great_buffer` as a side-scrolling vault.
- `res://scripts/sim/world_data.gd` maps the Great Buffer Vault as an access-port dungeon.

## Key Rewards

Entering the Tundra:

- `act_two_started`
- `silicon_shards`

White-Out onboarding:

- `white_out_purge_survived`
- `purge_timing_learned`

Unit 01:

- `unit_01_met`
- `unit_01_save_link`
- `memory_log_01`

Great Buffer:

- `dungeon_great_buffer_complete`
- `optical_lens`
- `memory_log_02`
- `data_light_exposure`

Frequency Tuner:

- `frequency_tuner`
- `frequency_tuner_installed`

Prism-Stalk:

- `prism_stalk_form`
- `prism_stalk_mutated`

## Next Build Step

The next practical slice is the **Mainframe Spine Base**:

- Use Prism-Stalk/Frequency Tuner to enter the Spine safely.
- Begin vertical ascent mechanics.
- Enter the Logic Core hardware dungeon.
- Unlock external vents for the next climb.
