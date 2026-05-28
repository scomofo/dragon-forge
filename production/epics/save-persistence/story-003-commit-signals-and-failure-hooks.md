# Story 003: Commit Signals And Failure Hooks

> **Epic**: Save / Persistence
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/save-persistence.md`
**Requirement**: `TR-save-003`
**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0002: Semantic Event Contracts
**ADR Decision Summary**: Committed-state signals fire only after successful save commit; missing listeners must not affect progression.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Use callable signal connections, not string-based `connect()`.

**Control Manifest Rules**:
- Required: CM-GLOB-02, CM-SAVE-04, CM-EVT-01
- Forbidden: Emitting committed-state signals before file commit
- Guardrail: Debug failure injection must be unavailable in release exports.

## Acceptance Criteria

- [x] `save_committed` emits exactly once after successful file commit and reload validation.
- [x] Commit failure emits no durable committed-state signal.
- [x] Debug failure injection API is unavailable in release export builds.

## Implementation Notes

Keep failure injection behind a debug-only build guard. Tests may use debug hooks; production code paths must not expose them.

## Out of Scope

- Specific feature event payloads for Campaign Map, Shop, Journal, or Singularity.

## QA Test Cases

- **AC-1**: successful emit
  - Given: a listener connected to `save_committed`
  - When: a valid transaction commits
  - Then: the listener is called once after reload validation
  - Edge cases: no listeners connected
- **AC-2**: failed commit suppression
  - Given: failure injection is enabled
  - When: commit fails
  - Then: no committed-state signal fires
  - Edge cases: listener throws, listener absent
- **AC-3**: release hook stripping
  - Given: release export/test configuration
  - When: failure injection API is queried
  - Then: it is unavailable or inert
  - Edge cases: debug build still exposes test hooks

## Test Evidence

**Required evidence**:
- `tests/integration/save/test_commit_signals_and_failure_hooks.gd`

**Status**: [x] Created - 4 commit signal/failure hook integration tests passing; full unit/integration suite passing with 29 tests / 338 assertions

## Dependencies

- Depends on: Story 002
- Unlocks: all feature stories requiring committed-state events

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/save/test_commit_signals_and_failure_hooks.gd`; focused suite passes with 4/4 tests and 18 assertions; full unit/integration suite passes with 29/29 tests and 338 assertions.
**Code Review**: Complete; no required changes. Signals use callable connections in tests, `save_committed` emits only after commit reload validation, failed commits emit `save_failed` but never `save_committed`, and failure injection is gated by `OS.is_debug_build()`.
