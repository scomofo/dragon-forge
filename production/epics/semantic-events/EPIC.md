# Epic: Semantic Events / Payload Contracts

> **Layer**: Foundation
> **GDD**: `docs/architecture/architecture.md`
> **Architecture Module**: Semantic Events
> **Status**: Ready
> **Stories**: Created

## Overview

Build the shared signal and payload convention harness that keeps systems decoupled. This epic owns semantic event naming, typed payload conventions, missing-listener tolerance, and commit-before-emit examples for durable-state notifications.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0002: Semantic Event Contracts | Cross-system notifications use semantic signals and stable payloads; missing listeners and muted audio cannot block progression. | HIGH |
| ADR-0001: Save Transaction Boundary | Durable-state events must fire only after save commit success. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-003 | Committed-state signals fire only after save commit success. | ADR-0001, ADR-0002 |
| Architecture | Cross-system notifications use semantic signals with stable payloads. | ADR-0002 |

## Definition of Done

This epic is complete when:

- Shared semantic event conventions are implemented and documented in code.
- Missing listeners do not block gameplay progression.
- Presentation-only events can fire without durable mutation.
- Durable-state event examples are gated by SaveService commit success.

## Next Step

Run `/story-readiness production/epics/semantic-events/story-001-semantic-event-contract-harness.md`, then `/dev-story`.
