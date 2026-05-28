# ADR-0004: Authored Content Resources

## Status

Accepted

## Date

2026-05-26

## Context

Several approved GDDs require authored IDs and data tables: Journal fragments, terminal entries, Audio pitch definitions, Shop catalog items, Singularity SCAR/protected node IDs, and Campaign Map node metadata. These tables must be inspectable by designers and stable enough for save data, tests, and cross-GDD references.

Godot `Resource` files provide typed authored data that can be loaded by runtime systems while keeping content out of hardcoded control flow.

## Decision

Author designer-owned content as typed Godot `Resource` data where the content has a stable ID, appears in multiple systems, or is referenced by save data.

Hardcoded constants are allowed only for local implementation details that are not referenced by save data, tests, or other systems.

## GDD Requirements Addressed

- `design/gdd/journal.md`: `JournalFragment` Resources and terminal IDs
- `design/gdd/audio-director.md`: pitch lookup table and cue routing data
- `design/gdd/shop.md`: deterministic item catalog and prices
- `design/gdd/campaign-map.md`: authored node data fields
- `design/gdd/singularity.md`: SCAR node IDs, protected node IDs, ending IDs

## Implementation Rules

- Stable IDs used in save data must not be renamed without a migration.
- Content Resources must validate required IDs at load time.
- Systems should reference content by ID, not by display text.
- Placeholder prose is allowed in content data when marked as draft; placeholder IDs are not allowed in implementation-facing contracts.
- Campaign Map economy tuning for Shop OQ-SH01 remains blocked until authored Act 3/4 node distribution and playtest data exist.

## Alternatives Considered

### Hardcode all tables in scripts

Rejected. It would make review, tuning, localization, and save migration harder.

### Store authored data only in Markdown GDD tables

Rejected for implementation. GDD tables define the contract, but runtime needs loadable data with validation.

### Use untyped dictionaries for all content

Rejected for MVP architecture. Typed Resources offer clearer validation and editor support.

## Consequences

Implementation must create content Resource classes and loaders before feature systems can fully wire data. This adds early setup work but makes later design iteration safer.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / Resources |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Typed custom Resources; explicit deep duplication for nested Resource runtime copies when needed |
| **Verification Required** | Validate required IDs at boot/content-lock time, reject duplicate or missing IDs, and prove runtime code does not mutate shared authored `.tres` Resources. |

Godot authored Resources are mutable at runtime, so implementation must distinguish immutable content definitions from runtime state. When a Resource-derived data structure needs a staged mutable copy, use explicit deep duplication or typed runtime objects according to the owning ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0005, ADR-0007, ADR-0008, ADR-0009, ADR-0010, ADR-0011 |
| **Blocks** | Any story implementing shared content IDs, authored catalogs, map data, boss definitions, Journal fragments, audio pitch tables, or visual profile Resources |
| **Ordering Note** | Stable IDs referenced by save data or tests must not be renamed without migration. |
