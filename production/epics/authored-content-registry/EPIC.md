# Epic: Authored Content Registry

> **Layer**: Foundation
> **GDD**: `design/gdd/systems-index.md`
> **Architecture Module**: Authored Content Loader
> **Status**: Ready
> **Stories**: Created

## Overview

Build the stable-ID content loading and validation foundation used by later feature systems. This epic owns required-vs-optional content definitions, duplicate/missing ID detection, read-only runtime access to authored data, and early fixture validation for screen IDs and battle fixture content.

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|------------------|-------------|
| ADR-0004: Authored Content Resources | Shared content with stable IDs uses typed Resources or approved generated tables validated at load time. | HIGH |
| ADR-0005: Godot Scene Flow And Autoload Boundaries | Required screen IDs are registered through authored content or approved tables before SceneFlow opens screens. | HIGH |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-data-001 | Cross-system content with stable IDs is implemented as typed Resources or approved generated tables. | ADR-0004 |

## Definition of Done

This epic is complete when:

- ContentRegistry validates required stable IDs and rejects duplicate required IDs.
- Missing required IDs fail startup with actionable validation errors.
- Optional content can warn without blocking.
- Runtime consumers receive read-only definitions or safe runtime copies, not shared mutable authored Resources.

## Next Step

Run `/story-readiness production/epics/authored-content-registry/story-001-content-registry-validation.md`, then `/dev-story`.
