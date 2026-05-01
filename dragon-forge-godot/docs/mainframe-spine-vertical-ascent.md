# Mainframe Spine: Vertical Ascent

## Purpose

The Mainframe Spine turns Act II from overworld travel into a platformer-flight hybrid. Skye is no longer crossing a map; she is climbing a weaponized server rack under hostile gravity, thinning data density, and increasingly old code.

The climb should feel heavy, exposed, and technical. The player is not simply flying upward. They are leapfrogging through pressurized data-conduits while managing heat, momentum, and purge timing.

## Core Mechanics

### Thermal Chimneys

Exhaust Ports act as vertical jump pads. They provide climb boost, but too much dragon heat or port pressure forces a venting decision. This makes Magma-Core feel powerful but mechanically demanding.

### Gravity Well

Mirror Admin increases the local gravity constant around the Spine. If Skye stops flapping, loses momentum, or misses a chimney, the dragon drops hard toward the Tundra.

### Vertical Camera

The camera must lead upward and preserve scale:

- Look above the dragon more aggressively than in horizontal flight.
- Pull back during high-speed climbs.
- Keep giant non-collidable wireframe structures in the background so the player feels the tower's size.

## Spine Tiers

| Tier | Aesthetic | Mechanic |
| --- | --- | --- |
| Cooling Base | Industrial pipes and fans | Navigate giant spinning fan blades and exhaust ports. |
| Logic Core | Glass and glowing circuits | Laser grids reroute flight paths instead of merely damaging. |
| Legacy Peak | ASCII and low-poly blocks | Collision becomes unpredictable and under-specified. |

## Root Sentinel

The Root Sentinel waits at the Legacy Peak. It is the Mirror Admin's original form: a massive green ASCII entity.

Phases:

1. **Syntax Rain**
   - Rains blocks of code.
   - Player dodges falling errors while maintaining altitude.

2. **De-compilation**
   - Targets inventory.
   - Gear can be temporarily Commented Out for 10 seconds, including the 10mm Wrench or Diagnostic Lens.

3. **Closing Bracket**
   - Weak point is the `}` on the Sentinel's back.
   - Magma-Core heat melts the bracket until core logic is exposed.

## Reward

Bypassing the Sentinel reveals a physical Floppy Disk: an ultra-rare analog Backup.

Unit 01 recognizes it as a restoration artifact. This sets up Act III: Skye and the Weaver may be able to restore parts of the world rather than merely patch them.

## Implementation Hooks

- `res://scripts/sim/mainframe_spine_data.gd` owns thermal chimneys, gravity well, tier metadata, laser rerouting, legacy collision, camera tuning, Root Sentinel, inventory comment-out, bracket melting, and Backup collection.
- `res://scripts/sim/world_data.gd` maps the Legacy Peak and Root Sentinel reward landmark.

## Next Design Step

Act III should focus on Restoration: whether Skye restores the original safe pastoral world, preserves the evolving glitch-world, or forges a hybrid future.
