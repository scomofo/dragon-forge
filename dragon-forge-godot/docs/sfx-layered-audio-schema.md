# Layered SFX Audio Schema

## Purpose

Dragon Forge uses sound to reveal the difference between the pastoral high-fantasy facade and the underlying hardware reality.

Every major sound should have two layers:

- World Layer: the acoustic sound NPCs and the fantasy world perceive.
- System Layer: the raw electronic, MIDI, or hardware signal Skye learns to perceive.

Together, these form the Dual-Tone soundscape.

## Dual-Tone SFX

| Action / Event | World Layer | System Layer | Combined Effect |
| --- | --- | --- | --- |
| Dragon Roar | Deep reptilian growl | Sustained MIDI chord tied to dragon frequency | Handshake audio for CE3K-style communication |
| Opening the Technical Manual | Heavy parchment or leather rustle | HDD spin-up or disk-read whir | Reveals the "relic" as physical hardware-adjacent |
| Using the Mirror Cape | Soft wind-like whoosh | Bit-crushed stutter / audio glitch | Signals temporary clipping through simulation code |
| Garbage Collector | Distant low storm rumble | Harsh rhythmic deletion pulse | Creates dread of data deletion |

## MIDI-Combat Harmonics

Combat audio is feedback and mechanic.

- Security Daemons and the Mirror Admin emit attack frequencies.
- Example: A4 / 440Hz can signal a readable incoming attack.
- A correct matching roar triggers a Resonance Ping.
- A clashing roar triggers a Discordant Growl and stamina penalty.

Perfect Block:

- Player matches the incoming frequency.
- Play a clear bell-like ping.
- Deflect, stall, or invert the incoming attack depending on encounter rules.

Dissonance Penalty:

- Player responds with the wrong frequency.
- Play a rough, clashing growl.
- Apply Logic Error feedback and stamina loss.

## Regional Ambience

### Southern Partition

World Layer:

- Wet leaves.
- Bird calls.
- Heavy rain.
- Dense jungle movement.

System Layer:

- Persistent server fan hum.
- Fan hum grows louder near the Hardware Husk.
- Occasional disk-read chirps in deep jungle sectors.

### Reflective Kernel

World Layer:

- Near silence.
- Skye's footsteps and dragon movement feel exposed.

System Layer:

- Every sound echoes back 100ms later.
- Echo is slightly bit-crushed to imply Parity monitoring.
- Phase 3 Kernel Panic drops most World Layer audio and relies on MIDI/sine navigation.

### Kernel Core

World Layer:

- Vast, sterile room tone.
- Soft windless pressure.

System Layer:

- Low command-line hum.
- UI-like confirmation tones from AI Sub-processes.
- V.O.X. communicates through Piano-Key notes rather than normal speech.

### Loom of Life

World Layer:

- Biogel bubbles.
- Mechanical arm servos.
- Deep cathedral-scale room resonance.

System Layer:

- Printer calibration tones.
- DNA Stability confirmation pings.
- Resonance scan sweeps tied to dragon MIDI frequencies.

## UI SFX

- Menu navigation: mechanical keyboard clicks.
- Save game: Success Handshake five-note motif.
- Diagnostic Lens: scanline chirp and short modem-like lock-on.
- Admin overlay toggle: low command prompt thump followed by bounding-box trace tone.
- Undo Button: tape-stop reverse swell, then clean parity restoration ping.
- Command-Line Whistle: short terminal beep followed by the summoned dragon's MIDI signature.

## Kernel Panic Audio Rules

During Mirror Admin Phase 3:

- World Layer volume goes to 0.0 or near-silent.
- System Layer becomes primary navigation.
- MIDI waves, frequency pings, and spatial rhythm cues must be readable.
- Every major incoming attack should have a distinct note, interval, or chord.

Pseudo-code sketch:

```python
class SFXEngine:
    def __init__(self):
        self.system_volume = 1.0
        self.world_volume = 0.5

    def play_action_sfx(self, action_id, frequency=None):
        audio.play(SFX_LIBRARY[action_id].world_sample)

        if frequency:
            audio.play_midi_tone(frequency, SFX_LIBRARY[action_id].wave_form)
        else:
            audio.play(SFX_LIBRARY[action_id].system_sample)

    def enter_kernel_panic(self):
        self.world_volume = 0.0
        self.system_volume = 1.0
```

## Final Soundscape Transition

In the Physicality Protocol ending, System Layer audio should gradually fade out.

The mechanical hum of the Hardware Husk gives way to:

- Real wind.
- Biological breathing.
- Physical wing movement.
- Real fire.
- Natural ground traction.

This signals that the Forge is complete: the world no longer needs to sound like data pretending to be life.
