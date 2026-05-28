# Story 001: Semantic Event Contract Harness

> **Epic**: Semantic Events / Payload Contracts
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: Architecture semantic-event contract
**ADR Governing Implementation**: ADR-0002: Semantic Event Contracts
**ADR Decision Summary**: Cross-system notifications use semantic signals/payloads with stable IDs; missing listeners or muted audio never block progression.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Use callable signal connections and named typed payloads where signals cross system boundaries.

**Control Manifest Rules**:
- Required: CM-EVT-01, CM-EVT-04
- Forbidden: UI widget names, raw input events, or audio completion as gameplay authority
- Guardrail: Durable-state events are emitted only after SaveService commit success.

## Acceptance Criteria

- [x] A shared semantic event contract module defines naming and payload conventions for committed-state and presentation events.
- [x] Missing listeners do not block gameplay progress.
- [x] Presentation-only events can fire without mutating durable state.
- [x] Durable-state event examples are gated by SaveService commit success.

## Implementation Notes

Start with event examples needed soon: `save_committed`, `screen_changed`, `battle_ended`, `journal_entry_available`, `corruption_class_changed`, and `ending_resolved`.

## Out of Scope

- Full AudioDirector implementation.
- Full Journal and Singularity event handling.

## QA Test Cases

- **AC-1**: missing listener tolerance
  - Given: an event is emitted with no listeners
  - When: caller continues
  - Then: no error or blocked state occurs
  - Edge cases: listener added and removed
- **AC-2**: durable event ordering
  - Given: a durable event depends on save commit
  - When: commit fails
  - Then: the durable event does not emit
  - Edge cases: presentation event still emits when allowed

## Test Evidence

**Required evidence**:
- `tests/integration/events/test_semantic_event_contract_harness.gd`

**Status**: [x] Created - 5 semantic event contract integration tests passing; full unit/integration suite passing with 57 tests / 636 assertions

## Dependencies

- Depends on: Save / Persistence Story 003
- Unlocks: Audio, Journal, Battle, Campaign Map, and Singularity integration stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/events/test_semantic_event_contract_harness.gd`; focused suite passes with 5/5 tests and 72 assertions; full unit/integration suite passes with 57/57 tests and 636 assertions.
**Code Review**: Complete; no required changes. SemanticEventContract defines stable committed-state and presentation event examples, emits named payloads with no-listener tolerance, allows presentation-only events without durable mutation, and suppresses durable events unless a SaveService commit result succeeded.
