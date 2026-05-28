# Interaction Pattern Library

> **Status**: In Design
> **Author**: Scott + ux-designer
> **Last Updated**: 2026-05-26
> **Template**: Interaction Pattern Library

---

## Overview

Dragon Forge uses a gamepad-first interaction model with keyboard/mouse fallback. The shared pattern library keeps player-facing screens consistent across Hub, Campaign Map, Battle, Shop, Hatchery, Fusion, Journal, Crown, and post-game terminals.

All patterns assume Godot 4.6 dual-focus behavior: keyboard/gamepad focus and mouse hover are separate states. Feature systems consume semantic actions from Input Router, not raw hardware button constants.

---

## Pattern Catalog

| Pattern | One-Line Description | Required For |
|---|---|---|
| Explicit Focus Ring | Current keyboard/gamepad focus is always visible and restored after top-level transitions. | All Control screens |
| D-Pad Row | Horizontal focus movement stops at row ends unless wrap is explicitly specified. | Shop, Crown relic flow |
| D-Pad Spatial Map | Directional input moves to authored adjacent nodes only. | Campaign Map |
| Confirm / Cancel Pair | South face button confirms; east face button cancels or backs out. | All required flows |
| Short Press vs Hold | Short confirm activates; long confirm reveals or confirms, using a configurable threshold. | Shop, irreversible actions |
| Disabled But Focusable | Unavailable actions can keep focus and explain why they are blocked. | Shop, Hatchery, Fusion, gates |
| Transaction Confirmation | Persistent state changes show cost, current state, projected state, and confirm/cancel. | Shop, Hatchery, Fusion |
| Post-Commit Feedback | Success feedback fires only after durable save commit succeeds. | Economy, progression, endings |
| TELEGRAPH Action Menu | Battle actions are selectable only during TELEGRAPH through semantic input. | Battle Engine |
| Counter-Ready Affordance | Defend remains the routed action while presentation signals tritone counter readiness. | Mirror Admin |
| Contextual HUD Reveal | HUD elements appear only after the player has earned the relevant knowledge. | Matrix tracker |
| Terminal Readout | Lore/system messages use confirm/cancel dismissal without modal stat leaks. | Gates, Journal, Crown |

---

## Patterns

### Explicit Focus Ring

**Use when**: A screen has any interactive Control node.

**Rules**:
- The active keyboard/gamepad focus target must be visible without input.
- Top-level scene changes must end by requesting focus through Input Router.
- Mouse hover may highlight a different element, but must not move keyboard/gamepad focus.
- Controller reconnect or mode switch should restore the last valid focus target when possible.

**Acceptance hook**: A QA tester can navigate the whole screen without a pointer and can identify focus at rest.

### D-Pad Row

**Use when**: Items are presented as an ordered horizontal set.

**Rules**:
- Left/right move one item at a time.
- Left at the first item and right at the last item stop; no wrap unless a screen-specific GDD says otherwise.
- Disabled, owned, or in-pack slots remain navigable when the player must understand their state.
- Confirm acts on the focused item only.

**Known users**: Shop item row, Crown multi-relic row.

### D-Pad Spatial Map

**Use when**: The screen represents authored adjacency rather than a list.

**Rules**:
- Directional input moves only to the authored adjacent node in that direction.
- Invalid directions play a small visual nudge and preserve state.
- D-pad tap moves cursor; d-pad hold pans camera when the Campaign Map is larger than the viewport.
- Node tooltips appear only after cursor inactivity and dismiss on directional input.

**Known users**: Campaign Map.

### Confirm / Cancel Pair

**Use when**: A player accepts, dismisses, backs out, or confirms an action.

**Rules**:
- Confirm must map to semantic `ui_confirm`.
- Cancel/back must map to semantic `ui_cancel`.
- Confirm dismissals must not accidentally accept a purchase, fusion, or ending choice.
- Cancel from destructive confirmation returns to the prior safe state unless the GDD explicitly marks the action irreversible.

### Short Press vs Hold

**Use when**: One focused object needs both quick activation and deeper inspection.

**Rules**:
- Short press is less than the configured threshold.
- Hold is greater than or equal to the configured threshold.
- Hold input is consumed by the reveal/hold state and must not trigger the short-press action on release.
- Thresholds that affect accessibility must be player settings.

**Known users**: Shop dwell reveal; possible irreversible Fusion confirm.

### Disabled But Focusable

**Use when**: The player needs to see why an action is unavailable.

**Rules**:
- Disabled actions preserve focus.
- Confirm produces brief visible feedback and no state mutation.
- If the reason is player-actionable, the screen states the broad reason without leaking hidden exact requirements unless allowed by the GDD.

**Known users**: Shop insufficient funds and in-pack states, Hatchery pull disabled, Fusion activation, Campaign gates.

### Transaction Confirmation

**Use when**: A choice mutates save data, currency, inventory, progression, or ending state.

**Rules**:
- Show the subject, current value, projected value, and result of confirming.
- Confirm starts the transaction; cancel returns to the focused item.
- Inputs are ignored only while the transaction is in progress.
- UI/audio success events wait for commit success.

**Known users**: Shop purchases, Hatchery pulls, Fusion, Crown ending choice.

### TELEGRAPH Action Menu

**Use when**: The player selects a battle action.

**Rules**:
- Action selection is accepted only during TELEGRAPH.
- Defend is always visible, even when blocked by cooldown.
- Consumables appear only when their runtime flag or owner-settled availability permits.
- NPC intent signal is visible before IMPACT.

### Counter-Ready Affordance

**Use when**: Mirror Admin opens a `tritone_window`.

**Rules**:
- The focused Defend option may be visually relabeled or accented, but the routed action remains `battle_defend`.
- The affordance must not rely on audio alone.
- The visible phase and mirrored/canonical element state remain present while the counter affordance is active.

### Contextual HUD Reveal

**Use when**: A HUD element represents discovered knowledge.

**Rules**:
- Do not instantiate the element before the player meets its knowledge trigger.
- After the trigger, reveal within one frame of the relevant state change or event.
- Keep the revealed element stable across future visits.

**Known users**: Campaign Map elemental matrix tracker after reading `elemental_resonance`.

### Terminal Readout

**Use when**: The game communicates denial, lore, archive, or post-game state.

**Rules**:
- Text is dismissible with confirm or cancel unless the GDD says auto-advance.
- Readouts avoid exact hidden stat leaks where lore opacity is a design pillar.
- Post-game readouts cannot reopen ending selection or battle transitions.

---

## Gaps & Patterns Needed

- Main menu and pause menu patterns are not yet specified.
- Localization expansion and text truncation patterns need a dedicated pass before key screens are implemented.
- Corruption overlay and restored gold-code presentation patterns must follow ADR-0011.
- Screen-reader focus labels need implementation proof once Godot UI scenes exist.

---

## Open Questions

- Should left stick duplicate d-pad menu navigation outside Campaign Map camera pan, or remain disabled to keep d-pad canonical?
- Should irreversible Fusion confirmation use hold-confirm or a two-step confirmation? Fusion GDD allows either.
- Should the post-game terminal readout pattern include a persistent archive icon language shared with Journal?
