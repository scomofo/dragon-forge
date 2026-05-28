# Vertical Slice Audio Assets

// VERTICAL SLICE - NOT FOR PRODUCTION
// Date: 2026-05-26

These WAV/MP3 files are prototype audio assets for the Dragon Forge vertical slice.

## Original Slice Music

Revision 4U replaces the single ambient `Crystal_Shell.mp3` bed with short original chiptune cues. The references were Punch-Out!!, Zelda II, and Super Mario Bros. interstitial energy, but the melodies and patterns here are original generated material.

Generated cues:

- `music_forge_ready_room.wav` - 12.8s Forge/Hub ready-room loop.
- `music_map_node_select.wav` - 8.57s route/node-select interstitial loop.
- `music_battle_data_bout.wav` - 20.87s urgent battle loop.
- `music_victory_scrap_jingle.wav` - 4.74s non-looping reward jingle.

Regenerate with:

```bash
python3 prototypes/dragon-forge-vertical-slice/tools/generate_slice_music.py
```

## DragonSim Sources

The current battle/audio pass reuses local DragonSim audio from `/Users/Scott_1/DEV/DF/dragonsim/app/public/audio/` so the slice stays aligned with the existing DragonSim palette.

Revision 4P added:

- `boss_low_heartbeat.wav`
- `boss_void_glitch.wav`
- `forge_quantum_break.wav`
- `atk_glacier_crack.wav`
- `hatch_shiny_sting.wav`

## Runtime Use

`src/VerticalSliceController.gd` loads raw WAV files with `AudioStreamWAV.load_from_file()`.

Music now swaps by scene key (`forge`, `map`, `battle`, `victory`) instead of ducking one track across the whole slice. Forge, map, and battle music loop; victory plays as a short jingle.

Revision 4V raises the cue targets into an audible range after human retest reported no music:

- Forge: `-16 dB`
- Map: `-15 dB`
- Battle: `-14 dB`
- Victory: `-13 dB`

Revision 4W fixes raw WAV loop setup. `AudioStreamWAV.load_from_file()` leaves `loop_end` at `0`, so setting `LOOP_FORWARD` without an explicit range can make looped music stop immediately. The runtime now sets looped cues to `loop_begin = 0` and `loop_end = round(length * mix_rate)`.

Revision 4X revises `music_battle_data_bout.wav` for more tension: faster tempo, darker diminished/chromatic tones, tighter bass ostinato, sharper alarm pulses, and denser noise percussion. Forge, map, and victory cues are unchanged in direction.

Battle SFX are layered across six rotating `AudioStreamPlayer` voices. This allows windup, crack, low body, and glitch tails to overlap instead of cutting each other off.

These are retest assets, not final mastered game audio.
