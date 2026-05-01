# System-Switching Shaders Handoff

## Purpose

Sector transitions should feel like the simulation re-rendering itself, not like ordinary fades.

These effects support:

- Mirror Admin Hard Reset.
- 16-bit to 4K zone transitions.
- Packet Loss / low-integrity flicker.
- The Hardware Husk reboot and OS Load event.

## CRT Power-Off

Used when Mirror Admin attempts Hard Reset.

Visual sequence:

1. Screen glitches.
2. Image collapses vertically into a horizontal beam.
3. Beam collapses horizontally into a single white point.
4. Audio folds into low-pass / high whine.
5. If Skye fails Manual Override, the deletion game-over can trigger.

Implementation:

- `assets/shaders/crt_power_off.gdshader`
- `collapse_factor` drives the effect from `0.0` to `1.0`.
- Keep Diagnostic Lens/HUD on a higher CanvasLayer where possible so it feels external to the collapsing simulation.

## Dither Re-Render Transition

Used when moving between render regimes.

Examples:

- Southern Partition legacy jungle to Hardware Husk.
- 16-bit overgrown buffer to high-fidelity Control Plaza.
- Packet Loss Fog revealing ship schematic underneath.

Implementation:

- `assets/shaders/dither_transition.gdshader`
- Uses a procedural Bayer matrix, avoiding the need for an imported texture.
- `transition_level` controls how much of the new layer cuts through.
- `schematic_tint` can show circuit-board / ship schematic color.

## Transition Controller

`scripts/world/transition_controller.gd` provides reusable tween hooks:

- `trigger_hard_reset()`
- `jam_hard_reset()`
- `play_dither_transition()`
- `set_packet_loss_flicker()`

The controller intentionally does not decide story outcomes. Boss or world logic should decide whether failure means game over, scene change, or Manual Override recovery.

## Packet Loss Cues

Low integrity can flicker the dither transition randomly:

- Briefly expose schematic tint.
- Simulate unstable render chunks.
- Keep gameplay readable by using small intensity and short pulses.
