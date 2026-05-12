# Act III: The Restoration

## Purpose

The Restoration is Dragon Forge's endgame. The Floppy Disk Backup contains the Original Seed: the pre-crash world before Mirror Admin, Thread, awakened NPCs, and the pastoral glitch culture.

The conflict shifts from survival to authorship. Skye can save the hardware by overwriting the current world, preserve the people by filtering the restore, or free the glitch-world by destroying the original seed.

## Final Hub: Mainframe Crown

After the Root Sentinel, Skye reaches the top of the Mainframe Spine. The sky is a terminal of raw system logs. Massive cooling fans hum in near silence.

At the center is a gold-plated physical drive. The Floppy Disk Backup must be inserted here.

Mirror Admin does not attack at first. It explains the cost:

> Restoration will delete unintentional data: Felix, The Weaver, Unit 01, and your dragon.

## Three Endings

| Choice | Analog Relic | Result |
| --- | --- | --- |
| Total Restore | 10mm Wrench | Lock the drive. Original Seed overwrites the world. Hardware is stabilized, but post-crash citizens are deleted. |
| The Patch | Diagnostic Lens | Filter the restore. The Husk is repaired, Thread stops, and NPCs remain as Recognized Citizens. |
| Hardware Override | Kernel Blade | Smash the drive. Original Seed is destroyed. Mirror Admin is disabled, but the free glitch-world remains unstable. |

## Final Flight: Credits Run

After the choice, the system begins a massive re-render. Skye flies down the Mainframe Spine in zero-G Root Authority while credits appear as 3D text in the air.

The chosen ending determines the visual paintover:

- Total Restore: cold colony-ship sterility.
- Patch: hybrid high-fidelity textures preserving circuitry and living glitch-history.
- Hardware Override: unstable but free glitch-world.

## Postgame: Read-Only Mode

The game transitions to free roam:

- Final dragon evolution remains.
- Dragon scales shimmer with Restored gold code.
- The 2D map is fully revealed.
- Glitch sites become Historical Sites.
- Unit 01 remains as an achievement librarian at the Spine base.

## Final Boss: Mirror Reflection

If Skye tries to reverse their choice at the last second, Mirror Admin makes one final stand by taking the form of Skye's own dragon.

It mirrors every normal move. The solution is a Logic Paradox found through the unorthodox manual: a move the Admin cannot replicate because it violates clean system logic, such as flying backward into a collision glitch.

## Implementation Hooks

- `res://scripts/sim/restoration_data.gd` owns the 99% prompt, three choice matrix, credits run, postgame state, Mirror Reflection, and Logic Paradox resolution.
- `res://scripts/sim/world_data.gd` maps the Mainframe Crown as the Restoration hub.

## Canon Ending Preference

The Patch is the thematic default. It honors the hardware, preserves the citizens, and lets the fantasy-machine hybrid become Dragon Forge's final identity.
