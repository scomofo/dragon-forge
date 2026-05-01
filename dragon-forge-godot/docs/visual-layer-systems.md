# Visual Layer Systems Handoff

## Purpose

Dragon Forge's visual identity depends on the transition between two layers:

- Pastoral Layer: high-fantasy world, dragons, villages, jungle, parchment relics.
- System Layer: metadata, bounding boxes, MIDI, scanlines, command lines, hardware, and de-rendering.

The player should increasingly see both layers at once as Skye becomes an administrator.

## Diagnostic Lens

The Diagnostic Lens is the primary System Layer HUD.

Visual rules:

- Transparent green scanlines.
- Bounding boxes around entities.
- Metadata readouts for HP, level, Code Integrity, Packet Integrity, dragon condition grades, and memory-address-like IDs.
- Should feel like Skye is seeing the simulation's debug view, not opening a separate menu.

Godot implementation direction:

- Keep using the current Diagnostic Index and encounter readouts.
- Expand toward an in-world overlay drawn over map entities and battle targets.
- Lens activation should play a static click.

## Threads VFX

Threads are silver-white falling code.

Visual rules:

- Streaks of `0`, `1`, and broken command glyphs.
- Skybox leak origin.
- On impact, affected surfaces should lose texture fidelity and reveal neon-green source geometry.

Godot implementation direction:

- `ThreadfallOverlay` draws falling code streaks over the overworld when Threadfall intensity is active.
- `thread_derender.gdshader` provides a canvas-item shader for turning texture bands into green source-code stripes based on corruption level.

## Mirror Admin Parity Shield

The Mirror Admin should look like a mercury copy of Skye's current build.

Visual rules:

- Reflective silver-white base.
- Tint shifts toward the player's active dragon element.
- In Kernel Panic or de-prioritization phases, visual fidelity collapses toward wireframe/bounding-box reads.

Godot implementation direction:

- `VisualSystemData.mirror_parity_tint` provides a deterministic tint pulse from base mercury toward player element color.
- Battle scene applies that tint to `sys_admin`.
- Future phase work should add floor loss, HUD deletion, and audio-only MIDI cues.

## Asset Manifest

- `vfx_thread_fall`: particle or overlay of falling 16-bit characters.
- `mat_husk_aluminum`: real-world brushed aluminum for the Hardware Husk.
- `ui_midi_spectrogram`: waveform visualizer for the Handshake and Kernel Panic.
- `env_packet_fog`: pixel-dithered volumetric fog.
- `shader_thread_derender`: shader that reveals source-code stripes as corruption rises.

## Undo Button GFX

The Undo Button should trigger a brief blue-tinted reverse-playback filter.

Visual sequence:

1. Screen tint shifts blue.
2. Scanlines reverse direction.
3. Recent motion ghosts pull backward.
4. Parity restoration ping flashes once.

This should communicate rollback without relying on explanatory text.
