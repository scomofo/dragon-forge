# Story 003: Production Shell Main Scene Smoke Path

> **Epic**: Scene Flow / Boot Pipeline
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-27
> **Last Updated**: 2026-05-27

## Context

**GDD**: `docs/architecture/architecture.md`, `design/gdd/dragon-forge-hub.md`
**Requirement**: Architecture boot and initialization path; `TR-hub-001`, `TR-hub-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**Specific GDD Trace**:
- Hub return focus policy: on Hub entry from Campaign Map or battle result, focus defaults to Hatchery Ring; Save Lantern confirm does not change focus.
- AC-HUB-07: Hub entry from Campaign Map or post-battle defaults focus to Hatchery Ring (index 0).
- AC-HUB-55: returning from Campaign Map ends TRANSITIONING, enters HUB_FLOOR, and accepts input in the target scene.

**ADR Governing Implementation**: ADR-0005: Godot Scene Flow And Autoload Boundaries; ADR-0003: Input Router Semantic Actions
**ADR Decision Summary**: BootstrapRoot initializes Foundation services in deterministic order, opens the initial Hub screen through SceneFlowService, and restores keyboard/gamepad focus after top-level screen changes.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Root project smoke must use a configured `project.godot` main scene and avoid hidden Autoload `_ready()` side effects. No gameplay-loop performance impact is expected because this story creates a minimal launch shell only; manual frame-rate smoke may remain deferred until a playable runtime path exists.

**Control Manifest Rules**:
- Required: CM-SCENE-01, CM-SCENE-02, CM-IN-02
- Forbidden: Scattered hardcoded root-scene paths or feature screens instantiating each other directly
- Guardrail: This story may use a minimal Hub shell, but the boot path must be production-owned rather than a test-only harness.

---

## Acceptance Criteria

*From architecture and Hub/Scene Flow contracts, scoped to this story:*

- [x] The root `project.godot` defines a production main scene that can boot headlessly without parser/runtime errors.
- [x] The main scene starts the existing BootstrapRoot/SceneFlow path and opens a stable initial Hub shell screen through `SceneFlowService`.
- [x] The initial shell registers stable screen IDs through authored/content-backed configuration or an explicit production bootstrap fixture, not ad hoc scene paths.
- [x] Keyboard/gamepad focus restoration is requested for the initial shell through the existing Input Router/Scene Flow contract, defaulting to the minimal Hatchery Ring focus target required by AC-HUB-07.
- [x] The shell exits any TRANSITIONING boot state into HUB_FLOOR and accepts input in the target scene, matching AC-HUB-55.
- [x] `/smoke-check sprint` can mark production shell/main-menu launch as PASS instead of DEFERRED.

## Implementation Notes

Create the smallest production-owned shell path that makes root launch smokeable: likely a `BootstrapRoot.tscn` or equivalent main scene plus a minimal Hub shell scene/control that satisfies existing BootstrapRoot and SceneFlow contracts. Keep visuals greybox if needed; this story is about boot ownership and smokeability, not final Hub presentation.

## Out of Scope

- Final Hub station art, Felix ambient presentation, and full roster UI.
- Save slot selection UI.
- Campaign Map, Shop, Hatchery, Fusion, or Journal screen composition.
- Production performance optimization beyond basic launch/smoke viability.

## QA Test Cases

- **AC-1**: root project launch
  - Given: the root `project.godot`
  - When: Godot launches the configured main scene in headless or test mode
  - Then: startup completes without parser/runtime errors and reaches the initial shell
  - Edge cases: content validation or save initialization failure surfaces without opening an invalid shell
- **AC-2**: scene-flow-owned initial Hub shell
  - Given: BootstrapRoot starts normally
  - When: screens are registered and the initial shell opens
  - Then: `SceneFlowService` reports the active screen as the Hub shell ID
  - Edge cases: duplicate or missing screen IDs return named failures
- **AC-3**: smoke check unlock
  - Given: `/smoke-check sprint` runs after this story
  - When: production shell/main-menu smoke is evaluated
  - Then: the launch check can be recorded as PASS and no longer deferred due to missing main scene
  - Edge cases: manual frame-rate smoke may remain scoped to later playable runtime paths

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd`
- Sprint smoke report showing production shell/main-menu launch is no longer deferred

**Status**: [x] Created - focused Scene Flow production shell suite passed with 4/4 tests and 37 assertions; full unit/integration suite passed with 123/123 tests and 6,891 assertions; Sprint 03 smoke refresh recorded production shell/main-menu launch as PASS in `production/qa/smoke-sprint-03-2026-05-27.md`.

## Dependencies

- Depends on: Scene Flow Story 001, Scene Flow Story 002, Input Router Story 001, Input Router Story 003
- Unlocks: player-facing smoke checks, Hub presentation stories, and Sprint smoke reports without a missing-main-scene condition

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None
**Test Evidence**: Integration story evidence at `tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd`; focused suite passes with 4/4 tests and 37 assertions; full unit/integration suite passes with 123/123 tests and 6,891 assertions; smoke evidence at `production/qa/smoke-sprint-03-2026-05-27.md`.
**Implementation Summary**: Added a configured production main scene at `scenes/bootstrap/BootstrapRoot.tscn`, a minimal Hub shell scene at `scenes/hub/HubShell.tscn`, production default boot wiring on `BootstrapRoot`, and a Hub shell focus target that exits to `hub_floor` with Hatchery Ring focus. Code-review fixes ensure direct `boot()` calls update `get_last_boot_result()`, malformed screen registrations return named failures instead of runtime type errors, focus restoration is asserted through `InputRouter.focus_restored`, and production shell/main-menu smoke is no longer deferred.

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 6/6 passing
**Deviations**: None. Manual frame-rate/performance smoke remains deferred by story scope because the shell is a minimal greybox runtime path, not a playable performance target.
**Test Evidence**: Integration evidence at `tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd`; focused suite passes with 4/4 tests and 37 assertions; adjacent Scene Flow/bootstrap suites pass with 12/12 tests and 117 assertions; full unit/integration suite passes with 123/123 tests and 6,891 assertions; smoke evidence at `production/qa/smoke-sprint-03-2026-05-27.md` records production shell/main-menu launch as PASS.
**QA Coverage Gate**: ADEQUATE
**Code Review**: Complete - `/code-review` verdict APPROVED.
