# ADR-0005: Godot Scene Flow And Autoload Boundaries

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / UI / Input |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/input.md`; `docs/engine-reference/godot/modules/ui.md`; `docs/engine-reference/godot/breaking-changes.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior; Godot 4.x `PackedScene.instantiate()`; callable signal connections |
| **Verification Required** | Verify Autoload order, explicit bootstrap initialization, reentrant transition handling, screen ID validation, and controller focus restoration after every top-level screen transition. |

Godot 4.6 separates mouse/touch focus from keyboard/gamepad focus. Scene transitions that create or replace `Control` screens must explicitly restore keyboard/gamepad focus through Input Router and must not assume mouse hover is equivalent to controller focus.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources |
| **Enables** | ADR-0006 Dragon Data Model And Progression Services; ADR-0007 Battle Runtime State Machine; Campaign Map Content And Reward Pipeline ADR; Economy And Shop Transaction Boundaries ADR |
| **Blocks** | Pre-production story generation for any top-level screen, boot flow, service access, or scene transition implementation |
| **Ordering Note** | This ADR must be Accepted before implementation stories assume where services live or how scenes transition. |

## Context

### Problem Statement

Dragon Forge needs a single Godot scene-flow and service-access pattern before stories are generated. The approved GDDs require Hub, Hatchery, Fusion, Shop, Campaign Map, Battle, Singularity Crown, Journal, Save Lantern, and post-game terminal flows to transition cleanly while preserving gamepad-first focus, save-commit ordering, authored content validation, and semantic event boundaries.

Without this ADR, implementation stories may independently choose different root scenes, Autoload patterns, screen IDs, signal timing, and service lookup styles. That would make systems harder to test and could contradict the accepted Save, Input, Event, and Content ADRs.

### Constraints

- Godot 4.6 dual focus requires explicit keyboard/gamepad focus restoration after screen changes.
- Feature systems must not write durable state directly; screen changes that depend on durable state must wait for Save / Persistence commit success.
- Feature systems must not consume raw hardware input or branch on device constants.
- Stable screen IDs must be authored and validated like other cross-system content IDs.
- Presentation systems may be persistent, but they must not become gameplay authorities.

### Requirements

- Boot foundation services in a deterministic order.
- Keep Autoloads limited and explicit.
- Provide one owner for top-level screen transitions.
- Use stable `StringName` screen IDs and registered `PackedScene` resources.
- Keep one active top-level screen at a time.
- Preserve current screen if the next screen fails to register, instantiate, or set up.
- Restore controller focus after each top-level screen transition.
- Avoid deprecated Godot patterns: `PackedScene.instance()` and string-based `connect()`.

## Decision

Dragon Forge will use a persistent bootstrap/root scene that orchestrates startup after Autoload construction. Autoloads are limited to foundation services and read-only registries:

- `ContentRegistry`
- `SaveService`
- `InputRouter`
- `SceneFlowService`

`AudioDirector` may be persistent as a global presentation service, but it is not a Foundation Autoload. It registers after foundation boot, owns presentation only, and must not be required for gameplay correctness.

`SceneFlowService` owns top-level screen transitions. Feature systems request screen changes through `change_screen(screen_id, payload)` and must not instantiate unrelated root scenes directly. The service keeps one active top-level screen at a time. Screen-local dialogs, panels, and internal UI states remain owned by the active screen unless they replace the top-level screen.

Screen registration is authored-content compliant. Required screen IDs are defined as typed Resources or an approved table loaded through `ContentRegistry`. Duplicate required IDs or missing required IDs are boot blockers. Optional presentation screens or assets may warn and use fallback behavior.

Transition ordering is explicit:

1. Autoloads are constructed by Godot.
2. The bootstrap/root scene runs an explicit startup phase.
3. `ContentRegistry` loads and validates required IDs.
4. `SaveService` loads, repairs, and migrates the selected save slot.
5. `InputRouter` initializes active input mode and action context.
6. `SceneFlowService` registers required screens.
7. Persistent presentation services, including `AudioDirector`, subscribe to semantic events.
8. `SceneFlowService` opens the initial Hub screen.
9. `InputRouter` restores first keyboard/gamepad focus.

Scene changes that depend on durable state must occur after save commit success. `screen_changed` is runtime/presentation state, not a durable-state event.

### Architecture Diagram

```text
Godot Autoload construction
        |
        v
BootstrapRoot._ready()
        |
        v
ContentRegistry.load_all()
        |
        v
SaveService.load_slot()
        |
        v
InputRouter.set_context()
        |
        v
SceneFlowService.register_screen_ids()
        |
        v
Presentation services subscribe
        |
        v
SceneFlowService.change_screen(&"hub", payload)
        |
        v
InputRouter.request_focus(first_control)
```

### Key Interfaces

```gdscript
class_name SceneFlowService

signal screen_change_started(payload: ScreenTransitionPayload)
signal screen_changed(payload: ScreenTransitionPayload)
signal screen_change_failed(result: SceneChangeResult)

func register_screen(screen_id: StringName, scene: PackedScene, required: bool = true) -> void
func change_screen(screen_id: StringName, payload: ScreenTransitionPayload) -> SceneChangeResult
func get_active_screen_id() -> StringName
func get_active_screen() -> Node
```

```gdscript
class_name ScreenTransitionPayload

var screen_id: StringName
var source_screen_id: StringName
var reason: StringName
var focus_target_id: StringName
var save_snapshot: SaveSnapshot
var commit_result: SaveCommitResult
var context_tags: Array[StringName]
```

`ScreenTransitionPayload` may carry stable IDs, read-only snapshots, and prior commit results. It must not carry mutable `SaveData`, `SaveTransaction`, raw node paths into unrelated scenes, or hardcoded Autoload singleton names.

`SceneChangeResult` must distinguish at least:

- success
- unregistered screen ID
- duplicate registration
- instantiation failure
- setup failure
- transition already in progress
- focus restoration failure

Transition failure behavior:

- Instantiate and set up the next top-level screen before releasing the current one.
- If registration, instantiation, or setup fails, keep the current screen active and return a failed `SceneChangeResult`.
- Free replaced top-level screens with `queue_free()` after the replacement is active.
- Guard reentrant transitions with an internal queue or `call_deferred()` when transitions are requested during signal handling.

## Alternatives Considered

### Alternative 1: Each Feature Scene Manages Its Own Transitions

- **Description**: Hub, Shop, Campaign Map, Battle, and Singularity scenes instantiate each other directly.
- **Pros**: Fast to prototype; fewer foundation classes.
- **Cons**: Hidden dependencies, inconsistent focus restoration, difficult test setup, and high risk of feature systems bypassing save/event boundaries.
- **Rejection Reason**: Contradicts the need for stable story handoffs and gamepad-first QA.

### Alternative 2: Many Broad Autoload Singletons

- **Description**: Every major system becomes a globally reachable Autoload singleton.
- **Pros**: Easy access from any scene; simple early implementation.
- **Cons**: Encourages tight coupling, hardcoded singleton paths, difficult isolated tests, and unclear ownership between Foundation, Core, Feature, and Presentation layers.
- **Rejection Reason**: Too much global state for a project whose GDDs rely on explicit ownership and transaction boundaries.

### Alternative 3: Bootstrap Root With Limited Foundation Autoloads

- **Description**: A persistent root scene initializes a small set of foundation Autoloads, and SceneFlow owns top-level transitions through registered screen IDs.
- **Pros**: Clear boot order, testable services, authored screen IDs, safer transitions, and consistent focus restoration.
- **Cons**: More upfront structure; implementation stories must respect service boundaries.
- **Rejection Reason**: Chosen.

## Consequences

### Positive

- Feature stories have one path for top-level screen changes.
- Controller focus can be tested consistently after every transition.
- Screen IDs become authored, validated contracts instead of scattered constants.
- Failed transitions preserve the current playable screen instead of leaving the tree half-mutated.
- Scene Flow can be unit/integration tested independently from feature logic.

### Negative

- Early implementation must build bootstrap, registration, and transition infrastructure before feature screens can freely link together.
- Feature scenes cannot shortcut by loading other screens directly.
- Stories must include setup payloads and service references explicitly.

### Risks

- **Autoload order assumptions**: Godot creates Autoloads before the bootstrap scene, but `_ready()` order can hide accidental dependencies.
  - **Mitigation**: Autoload construction must stay light; bootstrap root owns explicit initialization.
- **Reentrant transitions**: A transition requested inside signal handling may mutate the scene tree at an unsafe time.
  - **Mitigation**: Queue transitions or defer tree mutation with `call_deferred()`.
- **Focus drift after scene replacement**: Godot 4.6 separates mouse hover from keyboard/gamepad focus.
  - **Mitigation**: Every top-level transition ends with `InputRouter.request_focus()`, and QA verifies controller focus.
- **Presentation service confusion**: Audio Director is persistent but could be mistaken for a Foundation service.
  - **Mitigation**: Audio Director is Presentation-only and must not block progression or own gameplay state.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `input-router.md` | Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals must be completable with d-pad plus confirm/cancel. | Scene transitions restore keyboard/gamepad focus through Input Router after top-level screen changes. |
| `save-persistence.md` | Committed-state signals must fire only after save commit success. | Screen changes that depend on durable state wait for Save / Persistence commit success; `screen_changed` remains runtime/presentation state. |
| `dragon-forge-hub.md` | Hub stations route to Hatchery, Fusion, Shop, Journal, Save Lantern, and Bulkhead flows. | SceneFlow provides the single top-level transition path from Hub station activations to feature screens. |
| `campaign-map.md` | Bulkhead departure/return, battle entry, CROWN entry, and post-game free-roam require stable screen transitions. | SceneFlow registers map, battle, Crown, and Hub screen IDs and keeps failed transitions from corrupting current navigation. |
| `singularity.md` | Crown and Mirror Admin flows require strict transition and focus control. | Singularity requests top-level screen changes through SceneFlow and keeps durable state ordering tied to Save / Persistence. |
| `audio-director.md` | Audio subscribes to semantic events and must not own gameplay state. | Audio Director may persist as Presentation service after foundation boot, but cannot block gameplay or serve as a Foundation dependency. |

## Performance Implications

- **CPU**: Minimal steady-state cost. Screen registration occurs at boot; transitions instantiate one top-level scene at a time.
- **Memory**: Keeps only one active top-level screen by default. Persistent foundation services stay resident.
- **Load Time**: Startup does more validation upfront. This is intentional; missing required screens fail early.
- **Network**: None. MVP is local single-player.

## Migration Plan

No production Godot scene flow exists yet in this workspace. Implementation should proceed in this order:

1. Create foundation Autoload scripts for `ContentRegistry`, `SaveService`, `InputRouter`, and `SceneFlowService`.
2. Create `BootstrapRoot.tscn` as the project main scene.
3. Add required screen ID Resources or approved registration table.
4. Implement `SceneFlowService.register_screen()` and `change_screen()`.
5. Add integration tests for boot order, missing screen IDs, duplicate registration, failed instantiation, reentrant transition requests, and focus restoration.
6. Update feature stories to request transitions through `SceneFlowService`.

## Validation Criteria

- `project.godot` Autoload order is documented and verified.
- Autoload `_ready()` methods do not depend on another service's completed explicit initialization.
- Boot fails early on missing or duplicate required screen IDs.
- Optional presentation screen/assets warn but do not block boot.
- Failed screen instantiation keeps the current screen active.
- Reentrant transition requests are queued/deferred and do not mutate the tree mid-signal.
- Replaced top-level screens are freed with `queue_free()`.
- After every top-level transition, the expected first `Control` has keyboard/gamepad focus.
- Mouse hover does not steal keyboard/gamepad focus in Godot 4.6 controller tests.
- No feature system instantiates unrelated root scenes directly.

## Related Decisions

- ADR-0001: Save Transaction Boundary
- ADR-0002: Semantic Event Contracts
- ADR-0003: Input Router Semantic Actions
- ADR-0004: Authored Content Resources
- `docs/architecture/architecture.md`
