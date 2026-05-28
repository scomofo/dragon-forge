# ADR-0003: Input Router Semantic Actions

## Status

Accepted

## Date

2026-05-26

## Context

Dragon Forge is gamepad-first. The approved Input Router GDD requires Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and post-game terminal flows to be completable with d-pad plus confirm/cancel. Godot 4.6 separates keyboard/gamepad focus from mouse/touch focus, so custom UI work must not assume hover and controller focus are the same thing.

## Decision

Input Router owns hardware-to-action translation and active input mode. Feature systems consume semantic actions only.

The Godot InputMap must define each MVP action as a distinct `StringName`, including `ui_up`, `ui_down`, `ui_left`, `ui_right`, `ui_confirm`, `ui_cancel`, `battle_attack`, `battle_defend`, `battle_status`, `battle_consumable`, and `map_pan`.

Controller focus must be explicit and testable through Godot Control focus APIs such as `grab_focus()`. Mouse/touch hover may change presentation, but it must not silently replace keyboard/gamepad focus.

## GDD Requirements Addressed

- `design/gdd/input-router.md`: AC-IN01 through AC-IN06
- `design/gdd/shop.md`: d-pad navigation, confirm/cancel, disabled action behavior
- `design/gdd/singularity.md`: Crown relic flow and Mirror Admin Counter affordance
- `design/gdd/battle-engine.md`: TELEGRAPH action routing

## Implementation Rules

- Feature systems must not branch on raw gamepad button constants.
- Every required flow must have a d-pad plus confirm/cancel path.
- Hover-only interaction is forbidden.
- D-pad row navigation stops at edges unless a GDD explicitly allows wrapping.
- During Singularity `tritone_window`, the UI may relabel Defend as Counter, but the routed action remains `battle_defend`.
- Disabled actions must reject confirm without emitting gameplay actions.

## Alternatives Considered

### Each screen reads raw input

Rejected. It would duplicate mappings, create inconsistent cancel behavior, and make controller QA expensive.

### Mouse-first UI with controller fallback

Rejected. It contradicts the gamepad-first pillar and Godot 4.6 focus model.

### Separate Counter action

Rejected for MVP. Singularity's Counter is a contextual interpretation of Defend during the tritone window, so `battle_defend` remains the canonical action.

## Consequences

Every screen must integrate with Input Router instead of local raw input checks. This improves consistency and makes controller acceptance tests straightforward.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Input / UI |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/input.md`; `docs/engine-reference/godot/modules/ui.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior; `Control.grab_focus()` focus restoration; callable signal connections |
| **Verification Required** | Verify gamepad/keyboard focus and mouse hover remain separate, d-pad plus confirm/cancel completes required flows, and Counter routes as contextual `battle_defend`. |

Input stories must test Godot 4.6 keyboard/gamepad focus separately from mouse/touch hover. Mouse hover may alter presentation but must not be treated as controller focus.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0005, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011 |
| **Blocks** | Any story implementing player-facing controls, screen focus, Battle TELEGRAPH input, Campaign Map traversal, Shop/Crown rows, or terminal dismissal |
| **Ordering Note** | Screen stories must define focus restoration and semantic action handling before acceptance. |
