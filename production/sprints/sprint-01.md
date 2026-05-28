# Sprint 01 - 2026-05-27 to 2026-06-09

## Sprint Goal

Establish the Foundation services required before Core and Feature implementation: typed saves, staged transactions, semantic input, content validation, and safe scene flow.

## Capacity

- Total days: 10
- Buffer: 2 days reserved for review, integration drag, and Godot 4.6 API verification
- Available: 8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| SAVE-001 | [SaveData Resource](../epics/save-persistence/story-001-save-data-resource.md) | gameplay-programmer / godot-gdscript-specialist | 1.0 | None | Typed `SaveData` Resource round-trips and does not serialize `game_state`. |
| SAVE-002 | [Save Transaction Commit And Rollback](../epics/save-persistence/story-002-save-transaction-commit-rollback.md) | gameplay-programmer / godot-gdscript-specialist | 1.5 | SAVE-001 | Commit writes temp/backup/swap/reload; injected failure preserves canonical save. |
| SAVE-003 | [Commit Signals And Failure Hooks](../epics/save-persistence/story-003-commit-signals-and-failure-hooks.md) | gameplay-programmer / qa-tester | 1.0 | SAVE-002 | `save_committed` emits once after success and never on failed commit; debug hooks excluded from release. |
| INPUT-001 | [Semantic Action Router](../epics/input-router/story-001-semantic-action-router.md) | ui-programmer / godot-specialist | 1.0 | None | Canonical MVP actions dispatch as semantic `StringName` actions without raw device constants. |
| INPUT-003 | [Godot 4.6 Dual Focus](../epics/input-router/story-003-godot-46-dual-focus.md) | ui-programmer / accessibility-specialist | 1.0 | INPUT-001 | Mouse hover does not steal gamepad/keyboard focus; disabled actions reject confirm. |
| CONTENT-001 | [Content Registry Validation](../epics/authored-content-registry/story-001-content-registry-validation.md) | tools-programmer / godot-specialist | 1.0 | None | Duplicate and missing required stable IDs fail validation with actionable errors. |
| SCENE-001 | [Scene Flow Safe Transitions](../epics/scene-flow/story-001-scene-flow-safe-transitions.md) | engine-programmer / godot-specialist | 1.5 | CONTENT-001 | SceneFlowService transitions by stable ID and preserves current screen on failure. |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| SCENE-002 | [Bootstrap Service Order](../epics/scene-flow/story-002-bootstrap-service-order.md) | engine-programmer / godot-specialist | 1.0 | SAVE-001, INPUT-001, CONTENT-001, SCENE-001 | Boot order is content, save, input, scene flow, presentation, hub, focus. |
| EVENTS-001 | [Semantic Event Contract Harness](../epics/semantic-events/story-001-semantic-event-contract-harness.md) | gameplay-programmer / qa-tester | 1.0 | SAVE-003 | Missing listeners do not block; durable events wait for commit success. |
| INPUT-002 | [D-Pad Confirm Cancel Flows](../epics/input-router/story-002-dpad-confirm-cancel-flows.md) | ui-programmer / accessibility-specialist | 1.0 | INPUT-001, INPUT-003 | Required flows have d-pad plus confirm/cancel evidence. |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| SAVE-004 | [Ending ID Load Projection](../epics/save-persistence/story-004-ending-id-load-projection.md) | gameplay-programmer | 0.5 | SAVE-001 | `ending_id` loads as read-only projection for post-game flow. |
| INPUT-004 | [Contextual Counter Routing](../epics/input-router/story-004-contextual-counter-routing.md) | ui-programmer / gameplay-programmer | 0.5 | INPUT-001 | Tritone Counter UI still emits canonical `battle_defend`. |

## Carryover From Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| None | First production sprint after accepted vertical slice. | N/A |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Godot 4.6 Resource save semantics differ from assumptions | Medium | High | Start with SAVE-001/SAVE-002 and verify against `docs/engine-reference/godot/`. |
| Focus behavior varies across mouse, keyboard, and gamepad | Medium | High | Keep INPUT-003 in Must Have and capture manual evidence. |
| Scene Flow depends on final screen assets not yet productionized | Low | Medium | Use stub screens and stable IDs; defer final UI composition. |
| No sprint QA plan yet | High | Medium | Run `/qa-plan sprint` before starting `/dev-story`. |

## Dependencies On External Factors

- Godot 4.6.3 local installation remains the implementation target.
- Manual gamepad/keyboard focus checks require local input hardware.

## Definition Of Done For This Sprint

- [ ] All Must Have tasks completed.
- [ ] All Must Have stories pass `/story-done`.
- [ ] All Logic/Integration stories have passing unit/integration tests.
- [ ] Visual/UI stories have evidence docs under `production/qa/evidence/`.
- [ ] `/smoke-check sprint` passes.
- [ ] QA plan exists at `production/qa/qa-plan-sprint-01.md`.
- [ ] No S1/S2 bugs in delivered Foundation services.
- [ ] Design/architecture documents updated for any deviations.

> Warning: No QA plan exists yet for Sprint 01. Run `/qa-plan sprint` before implementation begins so each story has test-case requirements and the sprint can eventually pass production quality gates.
