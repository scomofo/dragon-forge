# Audio Director

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-26
> **Implements Pillar**: The Wrong Song

## Overview

Audio Director owns music, ambience, UI sounds, combat presentation sounds, corruption degradation, and event cue routing. Other systems emit semantic events; Audio Director maps them to buses, cues, fades, and mix states.

For Singularity, audio is not decoration. The corruption classes are audible degradation, and the Mirror Admin tritone counter is a required player-facing cue: six semitones above the current target pitch.

## Player Fantasy

Dragon Forge should sound like a fantasy world gradually remembering it is running on failing hardware. The player hears comfort become diagnosis: pastoral ambience thins into static, music loses fidelity, and by the Crown the world has become quiet enough that one wrong interval can matter.

## Detailed Design

### Core Rules

1. Audio Director subscribes to system signals and never owns gameplay state.
2. Required buses: `Master`, `Music`, `Ambience`, `SFX`, `UI`, `Voice`.
3. SFX players are pooled; gameplay systems must not instantiate audio players ad hoc.
4. Corruption class changes update music degradation and ambience layers after the committing signal is received.
5. Audio cues must never be the sole communication channel for required gameplay state.
6. Music and ambience may fade; UI confirmation, cancel, TELEGRAPH, Counter, and KO sounds must remain legible above degradation layers.
7. `tritone_counter_resolved(payload)` plays a counter-tone exactly six semitones above `target_pitch_id`.
8. `mirror_admin_phase_changed(payload)` drives phase motifs and mix changes.
9. `audio_event_complete(event_id)` emits when a one-shot cue with completion semantics finishes.
10. Muting a bus must not block state transitions; systems must rely on signals/timers, not audible playback, for logic.

### Corruption Mix Table

| Class | Music | Ambience | Required Cue |
|---|---|---|---|
| NOMINAL | Full-fidelity act music | Biome ambience | None |
| ANOMALY | Brief data chirp, no persistent degradation | Edge pixel/static tick | `corruption_anomaly` |
| WARNING | Battle intro transient bit-crush | Hazard pre-battle static | `hazard_status_prime` |
| ALERT | REST/LORE ambience cuts on SCAR nodes | Dry static on arrival | `scar_arrival` |
| CRITICAL | Sample-rate reduction and intermittent dropouts | Low hardware layer enters | `critical_phase_enter` |
| BREACH | Final degraded Mirror Admin/Crown bed | Hardware substrate bed | `breach_phase_enter` |

### Event Inputs

| Signal/Event | Required Audio Response |
|---|---|
| `node_type_entered(type)` | Type-specific arrival stinger/ambience handoff. |
| `act_entered(act_id)` | Crossfade to act music/bulkhead bed. |
| Battle presentation signals | `miss`, `resisted_hit`, `normal_hit`, `effective_hit`, `critical_hit`, `status_apply`, `reflect`, `ko`. |
| `corruption_class_changed(payload)` | Apply class degradation and play transition cue. |
| `mirror_admin_phase_changed(payload)` | Switch phase motif; play CRITICAL/BREACH cues on phase entry. |
| `tritone_window_changed(is_open, reason)` | Open/cancel counter telegraph cue. |
| `tritone_counter_resolved(payload)` | Play six-semitone counter-tone and impact accent. |
| `ending_resolved(ending_id)` | Transition to ending-specific post-game music profile. |

### Pitch Definitions

Mirror Admin phase profiles provide `target_pitch_id`. Audio Director owns the lookup table
that maps pitch IDs to semitone offsets. The table is authored data, not code constants.

| `target_pitch_id` | Semitone Offset | Notes |
|---|---:|---|
| `admin_root_c` | 0 | Default PARITY target. |
| `admin_overclock_f_sharp` | 6 | OVERCLOCK dissonance target. |
| `admin_kernel_b` | 11 | KERNEL_PANIC target. |
| `void_insert_e` | 4 | Void acquisition accent. |

## Formulas

### Tritone Counter Pitch

```
counter_pitch_semitones = pitch_map[target_pitch_id] + 6
```

If the result exceeds the authored pitch set, wrap by octave while preserving pitch class.

## Edge Cases

| ID | Case | Resolution |
|---|---|---|
| EC-AU01 | Two corruption transitions settle in one tick | Queue transition cues in state order; CRITICAL before BREACH. |
| EC-AU02 | Audio muted during tritone window | UI still shows Counter affordance; Audio Director emits no sound but returns success. |
| EC-AU03 | Cue asset missing | Log missing asset, play fallback UI tick on SFX bus, do not block gameplay. |
| EC-AU04 | `audio_event_complete` listener absent | Cue completes normally; signal with no receivers is a no-op. |

## Dependencies

| System | Relationship |
|---|---|
| Campaign Map | Emits act/node/corruption-related events. |
| Battle Engine | Emits combat presentation profile signals. |
| Dragon Forge Hub | Consumes `audio_event_complete(event_id)` for Elder timing fallback. |
| Hatchery | Emits pull animation/reveal/shiny events. |
| Fusion Engine | Emits `fusion_complete` and `elder_emerged`. |
| Shop | Emits transaction state cues and Unit 01 voice hooks. |
| Singularity | Primary consumer/source for corruption degradation, Mirror Admin phase music, tritone counter, and ending profiles. |

## Tuning Knobs

| Knob | Default | Safe Range | Notes |
|---|---|---|---|
| `MUSIC_FADE_SECONDS` | 1.0 | 0.1-4.0 | Standard music transitions. |
| `CORRUPTION_CUE_MAX_SECONDS` | 2.0 | 0.5-3.0 | Must respect Singularity phase beats. |
| `SFX_POOL_SIZE` | 16 | 8-32 | Concurrent one-shot SFX. |
| `TRITONE_CUE_DB` | -3 | -12 to 0 | Must cut through BREACH bed. |

## Acceptance Criteria

| ID | Criterion |
|---|---|
| AC-AU01 | Audio buses `Music`, `Ambience`, `SFX`, `UI`, and `Voice` exist and can be volume-controlled independently. |
| AC-AU02 | `corruption_class_changed(payload)` with CRITICAL then BREACH in one tick plays transition cues in that order. |
| AC-AU03 | `tritone_counter_resolved` plays a pitch class six semitones above `target_pitch_id`. |
| AC-AU04 | Muting all audio buses does not prevent Crown, Mirror Admin, battle, or Hub state transitions. |
| AC-AU05 | Missing cue assets log an error and use fallback SFX without crashing. |
| AC-AU06 | `audio_event_complete(event_id)` emits for `elder_emerged` after the cue finishes. |

## Open Questions

| ID | Question | Blocking? | Notes |
|---|---|---|---|
| OQ-AU01 | Final composition assets for each act and corruption class. | No | Blocks final polish, not implementation contracts. |
| OQ-AU02 | Exact Unit 01 voice processing chain. | No | Shop defines register; Audio owns processing. |
