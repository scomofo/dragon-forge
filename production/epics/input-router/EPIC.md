# Epic: Input Router

> **Layer**: Foundation
> **GDD**: `design/gdd/input-router.md`
> **Architecture Module**: Input Router
> **Status**: Ready
> **Stories**: Created

## Overview

Build the semantic input foundation for gamepad-first Dragon Forge screens. This epic owns InputMap action definitions, active input mode, Godot 4.6 focus restoration, semantic action dispatch, disabled-action rejection, and contextual battle/counter routing.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0003: Input Router Semantic Actions | Feature systems consume semantic actions only; d-pad plus confirm/cancel must complete required flows; Godot 4.6 keyboard/gamepad focus stays distinct from mouse hover. | HIGH |
| ADR-0005: Godot Scene Flow And Autoload Boundaries | InputRouter is a Foundation service and restores focus after top-level screen transitions. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-input-001 | Route hardware input into semantic actions; feature systems do not branch on raw device constants. | ADR-0003 |
| TR-input-002 | Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals are completable by d-pad plus confirm/cancel. | ADR-0003 |
| TR-input-003 | Preserve separate gamepad/keyboard focus and mouse hover behavior under Godot 4.6 dual focus. | ADR-0003 |

## Definition of Done

This epic is complete when:

- Canonical MVP actions are defined as distinct `StringName` InputMap actions.
- InputRouter emits semantic actions without exposing raw hardware constants to feature systems.
- D-pad row navigation, disabled-action rejection, keyboard fallback, and Godot 4.6 dual-focus behavior have test or evidence coverage.
- Battle `battle_defend` can be interpreted contextually as Counter during Singularity tritone windows.

## Next Step

Run `/story-readiness production/epics/input-router/story-001-semantic-action-router.md`, then `/dev-story` on the first ready story.
