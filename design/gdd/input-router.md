# Input Router

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-26
> **Implements Pillar**: Gamepad-First Clarity

## Overview

Input Router translates hardware input into game actions for Hub navigation, Campaign Map traversal, menus, Battle Engine TELEGRAPH choices, Shop, Hatchery, Fusion, and Singularity Crown/Mirror Admin flows. It is gamepad-first with keyboard/mouse fallback.

Godot 4.6 separates mouse/touch focus from keyboard/gamepad focus. Input Router owns the active input mode and ensures controller focus remains explicit and testable.

## Player Fantasy

The player should feel like they are holding a reliable instrument. D-pad movement, confirm, cancel, and battle decisions should be predictable enough that tension comes from the world, not the controller.

## Detailed Design

### Core Rules

1. Every MVP flow is completable with d-pad plus confirm/cancel face buttons.
2. Keyboard/mouse are fallback inputs, not privileged paths.
3. Hover-only interaction is forbidden.
4. Input Router emits semantic actions; feature systems do not read raw hardware buttons directly.
5. The current input mode is one of `gamepad`, `keyboard`, `mouse_touch`.
6. In Godot 4.6, keyboard/gamepad focus is maintained separately from mouse hover. Controller focus must call `grab_focus()` on the active Control.
7. D-pad navigation in rows stops at edges unless a specific GDD says wrap.
8. Confirm/cancel mappings must remain consistent across Hub, Shop, Crown, and post-game terminals.
9. During Singularity `tritone_window`, the Battle UI may relabel or decorate Defend as Counter, but the routed action remains `battle_defend`.
10. Rumble is optional presentation; no mechanic may depend on rumble.

### Canonical Actions

| Action | Gamepad | Keyboard | Used By |
|---|---|---|---|
| `ui_up` | D-pad up / left stick up | Up / W | Menus, Hub, Campaign Map |
| `ui_down` | D-pad down / left stick down | Down / S | Menus, Hub, Campaign Map |
| `ui_left` | D-pad left / left stick left | Left / A | Menus, Hub, Campaign Map |
| `ui_right` | D-pad right / left stick right | Right / D | Menus, Hub, Campaign Map |
| `ui_confirm` | South face button | Enter / Space | All confirms |
| `ui_cancel` | East face button | Esc / Backspace | Back/cancel |
| `battle_attack` | Confirm on attack option | Enter on attack option | Battle Engine |
| `battle_defend` | Confirm on Defend/Counter option | Enter on Defend/Counter option | Battle Engine/Singularity |
| `battle_status` | Confirm on status option | Enter on status option | Battle Engine |
| `battle_consumable` | Confirm on item option | Enter on item option | Battle Engine |
| `map_pan` | D-pad/left-stick hold | Arrow/WASD hold | Campaign Map |

The Godot InputMap must define each action above as a distinct `StringName`. Systems may
consume semantic actions only; they must not branch on raw button constants.

## Formulas

### D-pad Tap/Hold Split

```
is_hold = press_duration_seconds >= D_PAD_HOLD_THRESHOLD
```

Tap navigates a graph/menu. Hold pans the Campaign Map when that context supports panning.

## Edge Cases

| ID | Case | Resolution |
|---|---|---|
| EC-IN01 | Mouse hover changes visual focus while gamepad focus remains elsewhere | Input mode changes to `mouse_touch`; keyboard/gamepad focus is preserved for next gamepad event. |
| EC-IN02 | Controller disconnects mid-menu | Stay on current focus; keyboard fallback works immediately. |
| EC-IN03 | Confirm pressed during disabled action | Play blocked feedback; no state change. |
| EC-IN04 | Tritone window closes while Defend has focus | UI removes Counter affordance; confirm routes normal Defend if legal, or blocked state if Defend cooldown applies. |
| EC-IN05 | Save commit in progress while cancel pressed | Cancel is ignored only for the uninterruptible commit window; UI must show busy state. |

## Dependencies

| System | Relationship |
|---|---|
| Dragon Forge Hub | Station row navigation and activation. |
| Campaign Map | Node graph d-pad movement, map pan, Replay prompt, CROWN entry. |
| Battle Engine | TELEGRAPH action selection and disabled Defend cooldown state. |
| Shop | Single-row item navigation, dwell reveal, confirmation dialogs. |
| Hatchery/Fusion | Confirm/cancel on transactional flows. |
| Singularity | Crown relic flow, post-game terminals, Mirror Admin KERNEL_PANIC Counter affordance. |

## Tuning Knobs

| Knob | Default | Safe Range | Notes |
|---|---|---|---|
| `D_PAD_HOLD_THRESHOLD` | 0.25s | 0.15-0.5s | Shared with Campaign Map. |
| `FOCUS_RESTORE_DELAY_MS` | 0 | 0-100 | Delay before restoring focus after screen transitions. |
| `RUMBLE_ENABLED_DEFAULT` | true | bool | Accessibility setting can disable. |

## Acceptance Criteria

| ID | Criterion |
|---|---|
| AC-IN01 | Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and post-game terminals are completable with d-pad + confirm/cancel only. |
| AC-IN02 | D-pad navigation stops at row ends in Shop and multi-relic Crown selection. |
| AC-IN03 | Mouse hover does not steal keyboard/gamepad focus in Godot 4.6 controller tests. |
| AC-IN04 | During `tritone_window`, selecting the focused Defend/Counter option emits `battle_defend`; Singularity resolves Counter. |
| AC-IN05 | Disabled actions visibly reject confirm and emit no gameplay action. |
| AC-IN06 | Keyboard fallback can complete every required flow. |

## Open Questions

| ID | Question | Blocking? | Notes |
|---|---|---|---|
| OQ-IN01 | Final controller glyph art. | No | UI polish. |
| OQ-IN02 | Whether left stick can duplicate d-pad menu navigation. | No | D-pad remains canonical. |
