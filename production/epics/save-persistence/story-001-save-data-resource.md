# Story 001: SaveData Resource

> **Epic**: Save / Persistence
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/save-persistence.md`
**Requirement**: `TR-save-001`
**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary
**ADR Decision Summary**: Durable state must live in typed `SaveData` Resources, not ad hoc dictionaries or direct feature writes.
**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify Resource save/load behavior and avoid shallow mutation leaks for nested data.

**Control Manifest Rules**:
- Required: CM-SAVE-01, CM-GLOB-05
- Forbidden: Ad hoc JSON/dictionary MVP durable save schema
- Guardrail: Stable IDs stored in save data must not be renamed without migration.

## Acceptance Criteria

- [ ] `SaveData` exists as a typed Resource with MVP durable fields required by approved GDDs.
- [ ] A default new slot can be created and serialized as a loadable Godot Resource.
- [ ] Serialized save data uses `ending_id` for post-game authority and does not serialize `game_state`.

## Implementation Notes

Start with the minimum durable fields needed by approved architecture contracts: dragon roster, Scraps, campaign node state, shop flags, journal read/unlocked IDs, Singularity fields, and `ending_id`. Avoid implementing feature logic here.

## Out of Scope

- SaveTransaction commit/rollback flow: Story 002.
- Commit-state signals and failure injection: Story 003.

## QA Test Cases

- **AC-1**: `SaveData` round-trip
  - Given: a default `SaveData`
  - When: it is saved and loaded through Godot Resource APIs
  - Then: required fields survive with default values
  - Edge cases: empty arrays, empty `ending_id`, zero Scraps
- **AC-2**: no serialized `game_state`
  - Given: a saved default slot
  - When: the file is inspected after load
  - Then: post-game authority is represented by `ending_id`, not `game_state`
  - Edge cases: `ending_id == ""`, `ending_id != ""`

## Test Evidence

**Required evidence**:
- `tests/unit/save/test_save_data_resource.gd`

**Status**: [x] Created - 9 save tests passing; full unit/integration suite passing with 21 tests / 269 assertions

## Dependencies

- Depends on: None
- Unlocks: Story 002

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Logic story evidence at `tests/unit/save/test_save_data_resource.gd`
**Code Review**: Complete — lead-programmer CONCERNS with no blockers; non-blocking documentation/evidence-count notes resolved before closure

### Acceptance Criteria Verification

| Criterion | Evidence | Status |
|-----------|----------|--------|
| `SaveData` exists as a typed Resource with MVP durable fields required by approved GDDs. | `src/save/save_data.gd`, `src/dragon/dragon_record.gd`, `test_save_data_script_exists_and_is_resource`, `test_default_slot_contains_mvp_durable_fields`, `test_exported_field_types_match_architecture_contracts`, `test_dragon_roster_uses_typed_dragon_records` | Covered |
| A default new slot can be created and serialized as a loadable Godot Resource. | `test_default_slot_round_trips_with_pristine_defaults`, `test_default_slot_round_trips_through_godot_resource_api`, `test_nested_arrays_dictionaries_and_loaded_resources_do_not_share_mutations` | Covered |
| Serialized save data uses `ending_id` for post-game authority and does not serialize `game_state`. | `test_serialized_save_data_uses_ending_id_not_game_state`, `test_default_slot_contains_mvp_durable_fields` | Covered |

### Verification Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/save -gexit
godot --headless --import --path . && godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```
