# Story 001: Scene Flow Safe Transitions

> **Epic**: Scene Flow / Boot Pipeline
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: Architecture scene-flow contract
**ADR Governing Implementation**: ADR-0005: Godot Scene Flow And Autoload Boundaries
**ADR Decision Summary**: SceneFlowService owns top-level screen transitions by stable screen ID and preserves the current screen if the next screen fails.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Use `PackedScene.instantiate()` and callable signal connections.

**Control Manifest Rules**:
- Required: CM-SCENE-02, CM-SCENE-03, CM-SCENE-04
- Forbidden: Scattered hardcoded root-scene paths
- Guardrail: Never free the active screen before the replacement is valid.

## Acceptance Criteria

- [x] SceneFlowService registers screens by stable `StringName` IDs and `PackedScene` resources.
- [x] Duplicate registration returns an explicit failure result.
- [x] Changing to an unregistered screen returns failure and preserves current screen.
- [x] Instantiation/setup failure preserves current screen and emits `screen_change_failed`.

## Implementation Notes

Use typed result objects or named result values for `SceneChangeResult`, including success, unregistered ID, duplicate registration, instantiation failure, setup failure, transition already in progress, and focus restoration failure.

## Out of Scope

- Final visual screen content.
- Feature-specific payload interpretation.

## QA Test Cases

- **AC-1**: successful transition
  - Given: `hub` and `map` screens are registered
  - When: `change_screen(&"map")` succeeds
  - Then: active screen ID becomes `map`
  - Edge cases: current screen exists, no current screen
- **AC-2**: failed transition preserves current
  - Given: active screen is `hub`
  - When: `change_screen(&"missing")` is requested
  - Then: active screen remains `hub` and failure result names the missing ID
  - Edge cases: duplicate registration, setup failure

## Test Evidence

**Required evidence**:
- `tests/integration/scene_flow/test_scene_flow_safe_transitions.gd`

**Status**: [x] Created - 5 scene-flow integration tests passing; full unit/integration suite passing with 49 tests / 538 assertions

## Dependencies

- Depends on: Authored Content Registry Story 001
- Unlocks: Story 002, all feature screen stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/scene_flow/test_scene_flow_safe_transitions.gd`; focused suite passes with 5/5 tests and 54 assertions; full unit/integration suite passes with 49/49 tests and 538 assertions.
**Code Review**: Complete; no required changes. SceneFlowService registers stable screen IDs, returns named failure reasons for duplicate/unregistered/instantiation/setup failures, instantiates candidates with `PackedScene.instantiate()` only after `can_instantiate()` validation, and preserves the active screen until a replacement is valid.
