# ADR-0002: Semantic Event Contracts

## Status

Accepted

## Date

2026-05-26

## Context

The approved GDDs define many cross-system notifications: corruption changes drive audio, Journal unlocks request Hub console glow, Battle Engine emits presentation events, and Singularity emits ending and Mirror Admin milestones. These signals must be legible to downstream systems without granting those systems ownership over gameplay state.

The project also needs a shared rule for when durable-state notifications can fire relative to save commits.

## Decision

Cross-system notifications use semantic Godot signals or event payloads. Payloads describe game meaning, not hardware input, UI widgets, or private implementation objects.

Signals that announce durable state changes must fire only after ADR-0001 save commit success. Presentation-only signals may fire immediately, but they must not be used as durable-state authority.

## GDD Requirements Addressed

- `design/gdd/audio-director.md`: event inputs, corruption mix, Mirror Admin phase audio, tritone cues
- `design/gdd/journal.md`: Journal unlock and terminal routing events
- `design/gdd/save-persistence.md`: commit-before-emit ordering
- `design/gdd/singularity.md`: corruption class, Mirror Admin, and ending milestone events

## Implementation Rules

- Signal names must describe gameplay meaning, such as `corruption_class_changed(payload)` or `ending_resolved(ending_id)`.
- Payloads should carry stable IDs (`StringName` or string IDs from authored data), not direct node references unless the recipient owns presentation for that node.
- Audio Director may subscribe to semantic events but must never own gameplay state.
- Journal / Console may unlock/read content from semantic milestones but must not resolve endings or map traversal.
- A missing listener must never break gameplay progression.
- A muted or missing audio cue must never block state transitions.

## Alternatives Considered

### Direct calls between every system pair

Rejected. Direct calls would make feature order and dependencies difficult to reason about as Singularity, Journal, Audio, and Hub integration expands.

### One global untyped event bus

Rejected for now. A single untyped bus would hide ownership and make acceptance criteria harder to trace.

### Audio-completion-gated gameplay

Rejected except where a GDD explicitly defines a fallback timeout. Audio is presentation and accessibility state; gameplay must remain deterministic when muted.

## Consequences

Systems must define their outbound semantic events as part of implementation. This creates slightly more upfront contract work, but makes integration tests and handoffs much easier.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / Events |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Callable signal connections; typed payload classes or typed signal arguments |
| **Verification Required** | Verify durable events emit only after commit success, presentation events do not mutate durable state, and missing listeners do not block gameplay. |

Implementations must use callable signal connection syntax and must not use deprecated string-based `connect()`. Payloads should be named typed classes where a signal crosses system boundaries.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary for durable commit ordering |
| **Enables** | ADR-0005, ADR-0007, ADR-0008, ADR-0010, ADR-0011 |
| **Blocks** | Any story implementing cross-system committed-state notifications or semantic presentation events |
| **Ordering Note** | Presentation-only events may fire before save commits only when no downstream system treats them as durable authority. |
