# Act II: Tundra of Silicon and Mainframe Spine

## Purpose

Act II shifts Dragon Forge from fantasy survival into system warfare. The Mirror Admin stops hiding the machine and turns the backend into a weapon. The player leaves the cable jungle and enters a cold, exposed zero-fill sector where navigation, cover, and vertical flight matter.

## Tundra of Silicon

The Tundra is a blinding silicon whiteout: flat heat-sink plates, low vibration, no jungle data-drafts, and periodic cache-clearing weather.

### White-Out Purge

- The Admin periodically clears the sector cache.
- The screen washes nearly white.
- Skye must hide behind a Physical Relay or take heavy texture-wipe damage.
- Prism-Stalk can eventually refract the purge into beam charge.

### Flight Rule

Magma-Core cannot rely on external data-drafts here. It must self-thrust by burning internal heat. This gives reliable lift but costs energy and increases tactical pressure.

## Unit 01: The Kernel

The Kernel is a physical repair robot from the Astraeus, not a normal NPC. It has rusted analog plating, a holographic face, and a damaged identity table.

Roles:

- Mobile shop
- Save point
- Analog upgrade station
- Memory-log quest giver

Its first quest is **Recover Unit 01 Logs**, which sends Skye toward the Mainframe Spine to recover logs that can restore its original designation.

## Kernel Upgrades

| Upgrade | Relic | Function |
| --- | --- | --- |
| Insulated Grip | 10mm Wrench | Lets Skye turn live data-bolts safely. |
| Frequency Tuner | Diagnostic Lens | Predicts the next White-Out Purge by reading the Mainframe heartbeat. |

## Prism-Stalk Mutation

The Mainframe Spine is protected by refractive shielding. To penetrate it, Skye needs the Optical Lens and repeated exposure to stable Tundra data-light.

Prism-Stalk abilities:

- Sensor invisibility against Mirror Admin scans.
- Diagnostic refraction.
- White-Out Purge conversion into a beam counterattack.

## Mainframe Spine

The mountain is a vertical server rack.

The higher Skye climbs, the older the code becomes:

- Base: 4K modern render, cold security lighting, vertical self-thrust.
- Midsection: 16-bit legacy code, narrow cache vents, older security routines.
- Peak: raw ASCII, frequency-only navigation, and the eventual top-of-spine boss space.

## Implementation Hooks

- `res://scripts/sim/act_two_tundra_data.gd` owns white-out purge, self-thrust lift, Unit 01, upgrades, Prism mutation, refraction, and Mainframe floor metadata.
- `res://scripts/sim/world_data.gd` includes the Tundra of Silicon, Physical Relay, and Mainframe Spine Base.
- `res://scripts/sim/sidequest_data.gd` includes Unit 01 and Recover Unit 01 Logs.

## Next Design Step

Detail the Mainframe Spine level design before the ASCII boss. The vertical traversal grammar should define what the boss can exploit.
