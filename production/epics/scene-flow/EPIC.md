# Epic: Scene Flow / Boot Pipeline

> **Layer**: Foundation
> **GDD**: `docs/architecture/architecture.md`
> **Architecture Module**: Scene Flow
> **Status**: Ready
> **Stories**: Created

## Overview

Build the Godot boot and top-level screen transition foundation. This epic owns BootstrapRoot startup order, screen registration, safe `change_screen()` behavior, failure preservation, and first focus restoration hooks.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0005: Godot Scene Flow And Autoload Boundaries | BootstrapRoot initializes Foundation services in order; SceneFlowService owns top-level screen transitions and preserves current screens on failure. | HIGH |
| ADR-0003: Input Router Semantic Actions | InputRouter restores keyboard/gamepad focus after top-level screen transitions. | HIGH |
| ADR-0004: Authored Content Resources | Screen IDs are stable authored IDs validated before transition use. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| Architecture | Boot foundation services in deterministic order and route top-level transitions through SceneFlowService. | ADR-0005 |

## Definition of Done

This epic is complete when:

- SceneFlowService registers screens by stable `StringName` IDs.
- Failed transitions preserve the current top-level screen.
- Bootstrap order is content, save, input, scene flow, presentation subscribers, initial screen, focus restore.
- Scene flow uses Godot 4 `PackedScene.instantiate()` and callable signal connections.
- The root project has a production main scene that can boot a smokeable shell path for QA.

## Next Step

Run `/story-readiness production/epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md`, then `/dev-story`.
