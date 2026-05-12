# Dragon Flight: Aero-Traction Handoff

## Purpose

Dragon flight in Dragon Forge should feel like pastoral fantasy colliding with system physics.

The player is not just flying through air. They are flying through data density, render pressure, skybox leaks, thermal drafts, and unstable simulation boundaries.

## Core Feel

Flight should have traction.

Dragons should feel powerful and physical, but not frictionless. The world should push back:

- High-fidelity zones give reliable lift.
- Hardware Husk vents create thermal/data drafts.
- Skybox leaks thin the air and reduce lift.
- Packet loss zones cause wing flicker and control instability.
- Analog relic weight improves ground traction but reduces flight speed.

## Aero-Traction Physics

Primary variables:

- `air_density`: falls with altitude and skybox instability.
- `data_density`: sector-specific simulation richness.
- `lift`: based on speed, wing state, and density.
- `drag`: rises during unstable render zones and high-G turns.
- `integrity`: wing/body stability under Threadfall or de-rendering.
- `traction_force = velocity * grip_factor * air_density * wing_surface_area`.

Prototype rule:

Start with a controllable `CharacterBody3D` flight slice, but tune it like a dragon mount rather than a jet:

- Smooth forward thrust.
- Heavy banking.
- Lift tied to speed.
- Noticeable stall when data density collapses.
- Strong feedback when catching drafts.

## Data Density

Altitude and sector stability affect the air.

Example behavior:

- Near Hardware Husk: stronger thermal uplift and stable controls.
- Above Skybox Leak: low density, wing wireframe flicker, reduced lift.
- Southern Jungle: packet fog creates drag bursts and visual dropout.
- Great Salt Flats: low render density, high stamina/bandwidth drain.

## Admin Flight Abilities

Flight maneuvers unlock through dragon firmware evolution.

### Clip-Dash

Short-range phase burst.

- Ignores collision briefly.
- Used for unrendered walls and Permission Gate gaps.
- Should feel like a controlled violation of physics.

### Packet-Burst

High-speed dash.

- Leaves 16-bit artifact trail.
- Drains bandwidth/heat.
- Can outrun Threadfall or cross low-density gaps.

### Hover-Lock

Physics pause.

- Dragon suspends itself in the air.
- Useful for MIDI matching, relic inspection, and vertical puzzles.
- Should look system-like, not natural hovering.

## Flight VFX

Wing-Tip Vortices:

- GPUParticles3D trails of glowing binary code.
- Stronger during high-G turns and Packet-Burst.

Velocity Glitch:

- Chromatic aberration at max speed.
- Edges of the pastoral world smear, showing render stress.

Skybox Stall:

- Wings flicker into wireframe.
- Lift meter drops.
- Audio shifts toward thin MIDI hiss.

## Flight HUD

The flight HUD should mix aircraft instrumentation and server monitoring.

| Element | Source Data | Meaning |
| --- | --- | --- |
| Pitch Ladder | Dragon orientation | Flight attitude |
| Bandwidth Bar | Speed / asset loading | How fast the world can stream ahead |
| Integrity Meter | Wing/body stability | Thread and de-render damage |
| Density Readout | Sector/altitude | Available lift and render support |
| Heat Meter | Overclock/boost use | Risk of thermal runaway |

## Aero-MIDI Sync

In Atmospheric Processor-style missions, flight becomes harmonic navigation.

The wind emits a MIDI frequency. Skye tilts the dragon's wings to catch or match the tone. Correct resonance boosts thrust and stabilizes the climb.

Implementation direction:

- Use `AudioStreamPlayer` on a bus with `SpectrumAnalyzer` later if needed.
- For the first prototype, simulate target/player frequency numerically like Lunar Echo.
- Apply frequency match as `thrust_multiplier` or `lift_multiplier`.

## First Build Slice

Do not start with a giant open-world flight system.

Recommended prototype:

1. `DragonFlightController.gd` with data-density lift/drag.
2. `FlightTuningData.gd` helper for density, stall, drift, MIDI boost, and velocity glitch math.
3. Simple flight HUD readouts.
4. One test arena: Hardware Husk vent column into a Skybox Leak stall zone.
5. Packet-Burst and Hover-Lock as first two special maneuvers.

Success criteria:

- Flying low feels stable and weighty.
- Climbing too high clearly loses lift.
- Drafts feel rewarding.
- Boosting looks and sounds like the simulation is struggling to render ahead.
- The player understands "traction in the air" without reading a manual.
