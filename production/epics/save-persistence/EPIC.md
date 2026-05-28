# Epic: Save / Persistence

> **Layer**: Foundation
> **GDD**: `design/gdd/save-persistence.md`
> **Architecture Module**: Save / Persistence
> **Status**: Ready
> **Stories**: Created

## Overview

Build the typed durable-state foundation for Dragon Forge. This epic owns `SaveData`, save slots, staged transactions, rollback behavior, and commit-after-save signals so later systems can mutate durable state without direct file writes or partial commits.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0001: Save Transaction Boundary | Durable gameplay state lives in typed `SaveData`; systems mutate staged `SaveTransaction` copies and emit committed-state signals only after file commit success. | HIGH |
| ADR-0002: Semantic Event Contracts | Durable-state events use semantic payloads and fire only after commit success; missing listeners cannot block gameplay. | HIGH |
| ADR-0005: Godot Scene Flow And Autoload Boundaries | SaveService is a Foundation service booted before scene flow and presentation subscribers. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-001 | Persist all durable gameplay state through typed `SaveData` Resource. | ADR-0001 |
| TR-save-002 | Multi-field durable changes use staged transactions with temp write, backup, reload validation, and rollback. | ADR-0001 |
| TR-save-003 | Committed-state signals fire only after save commit success. | ADR-0001, ADR-0002 |

## Definition of Done

This epic is complete when:

- All stories are implemented, reviewed, and closed via `/story-done`.
- `SaveData` round-trips through Godot Resource save/load.
- Save transaction rollback, failure injection, and commit-before-emit ordering are covered by unit/integration tests.
- Release exports cannot access debug failure injection hooks.
- Feature stories can depend on SaveService without direct file writes.

## Next Step

Run `/story-readiness production/epics/save-persistence/story-001-save-data-resource.md`, then `/dev-story` on the first ready story.
