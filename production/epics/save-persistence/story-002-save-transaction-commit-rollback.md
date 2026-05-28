# Story 002: Save Transaction Commit And Rollback

> **Epic**: Save / Persistence
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/save-persistence.md`
**Requirement**: `TR-save-002`
**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary
**ADR Decision Summary**: Runtime systems mutate staged transaction copies and Save / Persistence commits by temp write, backup, rename, reload validation, and rollback on failure.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Use `duplicate_deep()` where nested Resources require staged isolation.

**Control Manifest Rules**:
- Required: CM-SAVE-02, CM-SAVE-03
- Forbidden: Partial saves and direct feature file writes
- Guardrail: Validate rollback by reloading canonical save after injected failure.

## Acceptance Criteria

- [x] `begin_transaction(reason)` returns a staged mutable save copy isolated from canonical state.
- [x] `commit_transaction(tx)` writes temp, verifies, backs up, swaps, reload-validates, then returns success.
- [x] Injecting `after_temp_write_before_swap` leaves the canonical save unchanged after reload.

## Implementation Notes

Model commit results as named result data, not anonymous ad hoc dictionaries. Keep file I/O inside SaveService only.

## Out of Scope

- Feature-specific transaction helpers for Shop, Hatchery, Fusion, or Singularity.
- Release export stripping for failure injection: Story 003.

## QA Test Cases

- **AC-1**: successful commit
  - Given: a canonical save with `player_scraps = 0`
  - When: a transaction stages `player_scraps = 10` and commits
  - Then: reload returns `player_scraps = 10`
  - Edge cases: first save with no `.bak`, existing `.bak`
- **AC-2**: injected rollback
  - Given: a canonical save with `player_scraps = 0`
  - When: failure is injected after temp write before swap
  - Then: reload still returns `player_scraps = 0`
  - Edge cases: temp file exists, backup file exists

## Test Evidence

**Required evidence**:
- `tests/integration/save/test_save_transaction_commit_rollback.gd`

**Status**: [x] Created - 4 save transaction integration tests passing; full unit/integration suite passing with 25 tests / 320 assertions

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, feature transaction stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/save/test_save_transaction_commit_rollback.gd`; focused suite passes with 4/4 tests and 51 assertions; full unit/integration suite passes with 25/25 tests and 320 assertions.
**Code Review**: Complete; required changes resolved by typing transaction/result surfaces, rejecting invalid transaction objects before property access, and splitting validation/temp-write/swap helpers.
