# Input D-Pad Confirm Cancel Evidence

> **Story**: `production/epics/input-router/story-002-dpad-confirm-cancel-flows.md`
> **Date**: 2026-05-27
> **Engine**: Godot 4.6.3
> **Reviewer**: Codex

## Scope

This evidence covers the foundation navigation contract and automated harness before final Hub, Shop, Campaign Map, Battle, Crown, and terminal screens are implemented. Final visual screen composition remains out of scope for this story.

## Verification

| Acceptance Criterion | Evidence | Result |
|---|---|---|
| Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals have d-pad plus confirm/cancel paths in the navigation contract. | `tests/unit/input/test_dpad_confirm_cancel_contract.gd::test_required_flows_have_dpad_confirm_cancel_navigation_contracts` verifies all six required flow IDs define d-pad navigation, confirm, cancel, and `hover_required = false`. | PASS |
| Row navigation stops at row ends for Shop and multi-relic Crown selection. | `tests/unit/input/test_dpad_confirm_cancel_contract.gd::test_shop_and_crown_row_navigation_stop_at_row_ends` verifies Shop and Crown left/right navigation clamps at row ends. | PASS |
| Keyboard fallback can complete every required flow. | `tests/unit/input/test_dpad_confirm_cancel_contract.gd::test_keyboard_fallback_bindings_exist_for_required_navigation_actions` verifies keyboard bindings exist for d-pad directions, confirm, and cancel through InputRouter/InputMap setup. | PASS |

## Flow Contract

| Flow | Navigation | Confirm | Cancel | Hover Required | Edge Rule |
|---|---|---|---|---|---|
| Hub | `ui_left`, `ui_right` | `ui_confirm` | `ui_cancel` | No | Wrap, per Hub GDD station row |
| Shop | `ui_left`, `ui_right` | `ui_confirm` | `ui_cancel` | No | Stop at row ends |
| Campaign Map | `ui_up`, `ui_down`, `ui_left`, `ui_right`, `map_pan` | `ui_confirm` | `ui_cancel` | No | Stop unless node graph authoring permits a connection |
| Battle TELEGRAPH | `ui_up`, `ui_down`, battle semantic choices | `ui_confirm` / battle action | `ui_cancel` | No | Stop at row ends |
| Crown | `ui_left`, `ui_right` | `ui_confirm` | `ui_cancel` | No | Stop at row ends |
| Terminals | `ui_up`, `ui_down` | `ui_confirm` | `ui_cancel` | No | Stop at row ends |

## Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/input -gselect=test_dpad_confirm_cancel_contract.gd -gexit
```

Result: 4/4 tests passing, 58 assertions.

## Sign-Off

| Role | Scope | Decision |
|---|---|---|
| QA | Automated navigation-contract harness | [x] Approved |
| UI/Accessibility | D-pad/keyboard fallback contract and edge behavior | [x] Approved |
