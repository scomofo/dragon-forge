# Story 004: Ending ID Load Projection

> **Epic**: Save / Persistence
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/save-persistence.md`
**Requirement**: `TR-save-001`, `TR-save-002`
**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary
**ADR Decision Summary**: `ending_id != ""` is the only persistent post-game authority.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Runtime systems should read snapshots/projections, not mutate live SaveData.

**Control Manifest Rules**:
- Required: CM-SAVE-05, CM-GLOB-07
- Forbidden: Serialized `game_state = "post_game"`
- Guardrail: Campaign Map reads post-game state through a snapshot/projection.

## Acceptance Criteria

- [x] Ending commit writes `ending_id` only.
- [x] Loading a save with `ending_id != ""` exposes that value to Campaign Map as read-only state for `MAP_FREE_ROAM`.

## Implementation Notes

Provide a minimal read projection or snapshot API; do not implement Campaign Map flow here.

## Out of Scope

- Singularity Crown ending resolution.
- Campaign Map free-roam UI.

## QA Test Cases

- **AC-1**: ending load projection
  - Given: a save with `ending_id = "garden"`
  - When: SaveService loads the slot
  - Then: the read projection exposes `ending_id = "garden"` and no persisted `game_state`
  - Edge cases: empty ending, unknown ending ID warning

## Test Evidence

**Required evidence**:
- `tests/integration/save/test_ending_id_load_projection.gd`

**Status**: [x] Passing — focused save integration suite and full unit/integration suite pass.

## Dependencies

- Depends on: Story 001
- Unlocks: Campaign Map post-game and Singularity ending stories

## Completion Notes

- Implemented `SaveStateProjection` for Campaign Map load-time post-game reads.
- Added `SaveService.load_state_projection()` as the runtime-facing read API and kept canonical `SaveData` loading internal.
- Added `SaveService.has_current_save()` for bootstrap existence checks without exposing mutable save data.
- Verified non-empty `ending_id` projects `MAP_FREE_ROAM`; empty `ending_id` projects `MAP_EXPLORE`; unknown non-empty IDs warn without blocking projection.
- Test evidence: `tests/integration/save/test_ending_id_load_projection.gd`.
