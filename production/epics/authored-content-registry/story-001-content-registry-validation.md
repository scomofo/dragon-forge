# Story 001: Content Registry Validation

> **Epic**: Authored Content Registry
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/systems-index.md`
**Requirement**: `TR-data-001`
**ADR Governing Implementation**: ADR-0004: Authored Content Resources
**ADR Decision Summary**: Cross-system content with stable IDs uses typed Resources or approved generated tables validated at load time.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Runtime must not mutate shared authored `.tres` Resources.

**Control Manifest Rules**:
- Required: CM-DATA-01, CM-DATA-02, CM-DATA-03
- Forbidden: Hardcoded implementation-facing IDs in scattered scripts
- Guardrail: Duplicate/missing required IDs are boot blockers.

## Acceptance Criteria

- [x] ContentRegistry loads required authored content definitions by stable `StringName` IDs.
- [x] Startup validation rejects duplicate required IDs.
- [x] Startup validation reports missing required IDs with actionable errors.
- [x] Runtime code receives read-only definitions or safe copies, not mutable shared Resource state.

## Implementation Notes

Start with screen IDs and battle fixture IDs already used by the vertical slice; expand later via system stories.

## Out of Scope

- Full Campaign Map node set.
- Full Journal, Shop, Audio, and Singularity content libraries.

## QA Test Cases

- **AC-1**: duplicate ID rejection
  - Given: two definitions with the same required ID
  - When: ContentRegistry validates
  - Then: validation fails with the duplicated ID
  - Edge cases: optional duplicate, empty ID
- **AC-2**: missing required ID
  - Given: required ID list includes `hub`
  - When: no matching content definition exists
  - Then: startup validation reports `hub` as missing
  - Edge cases: optional content warns but does not block

## Test Evidence

**Required evidence**:
- `tests/unit/content/test_content_registry_validation.gd`

**Status**: [x] Created - 6 content registry unit tests passing; full unit/integration suite passing with 44 tests / 484 assertions

## Dependencies

- Depends on: None
- Unlocks: Scene Flow Story 001, authored feature content stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Unit test at `tests/unit/content/test_content_registry_validation.gd`; focused suite passes with 6/6 tests and 49 assertions; full unit/integration suite passes with 44/44 tests and 484 assertions.
**Code Review**: Complete; no required changes. ContentRegistry validates stable IDs, blocks duplicate required IDs and missing required IDs with actionable messages, warns for optional duplicates, loads real battle fixture Resources, and returns deep duplicated Resource definitions to runtime callers.
