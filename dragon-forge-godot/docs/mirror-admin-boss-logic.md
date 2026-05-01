# Mirror Admin Boss Logic Handoff

## Purpose

The Mirror Admin is a Security Daemon built to enforce parity. It does not fight like a monster. It observes Skye's current state, mirrors what can be mirrored, predicts what cannot be mirrored, and de-prioritizes the arena when it loses control.

## Phase State Machine

| Phase | System State | Boss Logic |
| --- | --- | --- |
| Phase 1: Parity | Stable | Mirrors player element and MIDI frequency. Gains defensive alignment against the active dragon type. |
| Phase 2: Overclock | Throttling | Predicts player velocity and drops Thread Mines along the projected flight path. |
| Phase 3: Kernel Panic | Critical | De-renders arena geometry, removes collision from platforms, and forces permanent flight pressure. |

## Packet Integrity Defense

The Mirror Admin does not use a normal HP bar.

It has:

- Packet Integrity: the real boss health.
- Packet Shield: regenerating firewall rings around the core.
- Core Exposure: true only after shields are stripped.

If the player stops pressuring the shield, the Admin re-downloads shield packets from the Hardware Husk.

## Undo / Dissonance Weakness

The Mirror Admin is bound by Rollback Protocol.

When it prepares Mass Deletion, Skye can answer with a dissonant roar:

- Match is not the goal.
- Skye uses a tritone-like "opposite" frequency.
- Correct dissonance causes Buffer Overflow.
- Admin freezes for 3 seconds.
- Textures flicker into pink Missing Texture.
- Core Code becomes exposed.

## Hard Reset

At 5 percent Packet Integrity, the Admin attempts a Hard Reset.

Visual direction:

- Screen shrinks toward a single white CRT dot.
- Audio folds into a high-pitched whine.
- The world appears moments away from rebooting.

Counter:

- Skye uses Manual Override / analog relic inventory to physically jam the reset button.
- Admin is forced into a permanent Read-Only state.

## Current Implementation Assets

- `scripts/sim/mirror_admin_logic.gd`: reusable state, prediction, packet shield, dissonance, and hard reset logic.
- `assets/shaders/arena_degradation.gdshader`: spatial shader for server-platter floor holes.
- `assets/shaders/crt_power_off.gdshader`: canvas shader for the Hard Reset power-off collapse.
