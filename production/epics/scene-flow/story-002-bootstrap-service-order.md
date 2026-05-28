# Story 002: Bootstrap Service Order

> **Epic**: Scene Flow / Boot Pipeline
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `docs/architecture/architecture.md`
**Requirement**: Architecture boot and initialization path
**ADR Governing Implementation**: ADR-0005: Godot Scene Flow And Autoload Boundaries
**ADR Decision Summary**: BootstrapRoot initializes content, save, input, scene flow, presentation subscribers, initial Hub screen, and focus restoration in deterministic order.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Avoid hidden Autoload `_ready()` side effects.

**Control Manifest Rules**:
- Required: CM-SCENE-01, CM-GLOB-06
- Forbidden: Feature code relying on hidden Autoload `_ready()` side effects
- Guardrail: Presentation services subscribe after foundation services are ready.

## Acceptance Criteria

- [x] BootstrapRoot starts ContentRegistry before SaveService.
- [x] SaveService loads or creates selected slot before InputRouter context setup.
- [x] SceneFlowService registers required screens before opening the initial Hub screen.
- [x] InputRouter restores first keyboard/gamepad focus after the initial screen opens.

## Implementation Notes

This story can use stub services/screens and a boot log for deterministic order tests.

## Out of Scope

- Full final Hub implementation.
- Save slot selection UI.

## QA Test Cases

- **AC-1**: boot order
  - Given: instrumented foundation services
  - When: BootstrapRoot starts
  - Then: boot log order is content, save, input, scene flow, presentation subscribers, hub, focus
  - Edge cases: content validation failure, save load failure
- **AC-2**: boot blocker behavior
  - Given: required content validation fails
  - When: BootstrapRoot starts
  - Then: initial Hub screen is not opened and the failure is surfaced
  - Edge cases: optional content warning

## Test Evidence

**Required evidence**:
- `tests/integration/bootstrap/test_bootstrap_service_order.gd`

**Status**: [x] Created - 3 bootstrap integration tests passing; full unit/integration suite passing with 52 tests / 564 assertions

## Dependencies

- Depends on: Scene Flow Story 001, Save / Persistence Story 001, Input Router Story 001
- Unlocks: first production vertical-slice scene work

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Integration test at `tests/integration/bootstrap/test_bootstrap_service_order.gd`; focused suite passes with 3/3 tests and 26 assertions; full unit/integration suite passes with 52/52 tests and 564 assertions.
**Code Review**: Complete; no required changes. BootstrapRoot uses explicit dependency injection, logs deterministic startup order, blocks before save/input/screen opening on content or save failure, registers screens before opening Hub, and delegates first focus restoration through SceneFlowService/InputRouter.
