# ADR-0015: Audio Event Routing And Mix Ownership

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Audio / Scripting / Presentation |
| **Knowledge Risk** | LOW - local reference records no major 4.4-4.6 audio API breaks |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/audio.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | None beyond Godot 4 callable signal and Node patterns covered by ADR-0002/0005 |
| **Verification Required** | Verify audio events never block gameplay, muted/missing assets are safe, pools stay within budget, corruption mixes update from committed state, and tritone cues are synchronized to Mirror Admin windows. |

Audio Director uses ordinary Godot AudioStreamPlayer nodes, buses, callable signals, and presentation services. It does not require physics, navigation, networking, rendering post-processing, or deprecated Godot 3 APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0010 Singularity Boss And Ending Orchestration; ADR-0011 Corruption Rendering Pipeline |
| **Enables** | Audio Director implementation stories; corruption mix stories; Mirror Admin tritone cue stories; SFX pooling tests |
| **Blocks** | Any story that routes semantic events to music/SFX, owns corruption audio mix changes, plays tritone counter cues, or creates pooled audio presentation services |
| **Ordering Note** | This ADR must be Accepted before Audio Director stories are generated. |

## Context

Audio Director subscribes to semantic milestones, owns music and SFX presentation, responds to corruption class changes, and provides Mirror Admin tritone cues. Shared event ADRs say audio cannot block gameplay, but Audio needs a binding routing and ownership decision so no gameplay system waits on playback or mutates audio internals directly.

## Decision

Audio will be implemented as presentation-only `AudioDirectorService` plus screen adapters/pools. It subscribes to semantic events after foundation services boot and owns buses, cue lookup, pooling, mix profiles, and playback lifecycle.

```gdscript
class_name AudioDirectorService
extends Node

signal audio_event_started(event_id: StringName)
signal audio_event_finished(event_id: StringName)

func configure(audio_library: AudioLibrary, accessibility: AccessibilitySettings) -> void
func handle_event(payload: PresentationAudioEventPayload) -> AudioEventResult
func apply_corruption_mix(corruption_class: StringName) -> AudioMixResult
func play_tritone_counter_cue(payload: TritoneCounterPayload) -> AudioEventResult
func set_bus_volume(bus_id: StringName, volume_db: float) -> AudioBusResult
```

Gameplay systems emit semantic events and continue. They must never wait for `audio_event_finished()` to progress gameplay. `audio_event_finished()` is presentation telemetry only.

## Authored Data

```gdscript
class_name AudioLibrary
extends Resource

@export var cue_definitions: Array[AudioCueDefinition]
@export var mix_profiles: Array[AudioMixProfile]
```

```gdscript
class_name AudioCueDefinition
extends Resource

@export var cue_id: StringName
@export var stream: AudioStream
@export var bus_id: StringName
@export var max_instances: int
@export var fallback_cue_id: StringName
```

Missing optional cues log warnings and return non-blocking failure results. Required cue IDs validate at content-lock time, not at gameplay event time.

## Mix Ownership

Audio Director owns:

- Music state
- SFX routing
- Bus volumes
- Corruption mix profiles
- Tritone counter cue playback
- Audio player pools

Audio Director reads but does not own:

- Corruption class
- Mirror Admin phase
- Counter windows
- Battle outcome
- Journal unlock/read state
- Save data

## GDD Requirements Addressed

| GDD | Requirement |
|-----|-------------|
| `design/gdd/audio-director.md` | Music cues, SFX events, corruption-stage audio degradation, Mirror Admin tritone cue, and no gameplay authority. |
| `design/gdd/singularity.md` | Corruption transitions, Mirror Admin phases, and tritone counter windows emit semantic events for audio presentation. |
| `design/gdd/battle-engine.md` | Battle runtime events can trigger SFX without blocking turn resolution. |
| `design/gdd/input-router.md` | Haptics/audio feedback must not replace required visual or textual affordances. |

## Alternatives Considered

### Gameplay systems play AudioStreamPlayers directly

Rejected. Direct playback scatters mix ownership, pooling, and accessibility behavior.

### Audio completion gates gameplay state

Rejected. Muted buses, missing assets, and platform audio failures must never block progression.

### One global audio dictionary

Rejected. Typed Resources support validation, fallback cues, and content review better than ad hoc dictionaries.

## Consequences

- Gameplay remains deterministic and independent from audio playback.
- Audio can be tested with missing/muted assets.
- Corruption audio and corruption rendering stay separate presentation services driven by the same committed state.
- Tritone cues have a clear owner without adding gameplay authority to Audio Director.

## Verification Plan

- Unit tests for event routing lookup and missing optional cues.
- Integration tests that gameplay continues when audio is muted or a cue is missing.
- Manual/audio sign-off for corruption mix profiles and tritone counter cue timing.
- Performance checks for pooled player limits and overlapping SFX bursts.
