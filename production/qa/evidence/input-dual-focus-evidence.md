# Input Dual Focus Evidence

> **Story**: `production/epics/input-router/story-003-godot-46-dual-focus.md`
> **Date**: 2026-05-27
> **Engine**: Godot 4.6.3
> **Reviewer**: Codex

## Scope

This evidence covers the foundation InputRouter dual-focus contract before final feature screens exist. Final theme styling and focus-ring art remain out of scope for this story.

## Verification

| Acceptance Criterion | Evidence | Result |
|---|---|---|
| Mouse hover does not steal keyboard/gamepad focus in controller tests. | `tests/unit/input/test_dual_focus_input_router.gd::test_mouse_hover_tracking_does_not_steal_keyboard_gamepad_focus` keeps Godot keyboard/gamepad focus on the original focused button while `record_hovered_control()` tracks another button and switches input mode to `mouse_touch`. | PASS |
| Disabled actions visibly reject confirm and emit no gameplay action. | `tests/unit/input/test_dual_focus_input_router.gd::test_disabled_actions_reject_confirm_without_gameplay_action` confirms disabled `battle_attack` emits `semantic_action_rejected(payload)` for presentation feedback and does not emit `semantic_action(payload)`. | PASS |
| InputRouter can restore focus to a requested Control after top-level scene transition. | `tests/unit/input/test_dual_focus_input_router.gd::test_focus_can_restore_to_requested_control_after_transition` confirms `restore_focus_after_transition()` calls `grab_focus()`, emits `focus_restored(control)`, and rejects disabled controls with `focus_restore_failed(&"control_disabled")` while preserving the previous focus owner. | PASS |

## Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/input -gselect=test_dual_focus_input_router.gd -gexit
```

Result: 3/3 tests passing, 25 assertions.

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/input -gexit
```

Result: 9/9 tests passing, 97 assertions.

## Sign-Off

| Role | Scope | Decision |
|---|---|---|
| QA | Automated dual-focus harness | [x] Approved |
| UI/Accessibility | Focus separation and disabled-action feedback hook | [x] Approved |
