# Story 001: Scrap Read, Affordability, And Results

> **Epic**: Economy Ledger
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.5 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/shop.md`, `design/gdd/campaign-map.md`
**Requirement**: `TR-shop-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0009: Economy And Shop Transaction Boundaries
**ADR Decision Summary**: `EconomyLedger` is the sole mutation boundary for `player_scraps`; it returns named results and does not write save files directly.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Read helpers should accept save snapshots or staged save data without retaining live mutable references.

**Control Manifest Rules (this layer)**:
- Required: CM-GLOB-10, CM-ECO-01
- Forbidden: Direct `player_scraps +=` or `player_scraps -=` from feature systems
- Guardrail: The ledger is a transaction helper, not an independent save writer.

---

## Acceptance Criteria

*From GDD `design/gdd/shop.md`, scoped to this story:*

- [x] AC-SH14 helper scope: affordability/result helpers reject negative amount inputs and never report a successful afford/spend result that would imply `player_scraps < 0`. Full staged Scrap mutation enforcement belongs to ECO-002 and Shop purchase transaction stories.
- [x] AC-SH15: a purchase with `player_scraps` exactly equal to `item_price` is valid and leaves `player_scraps = 0`.
- [x] AC-SH45 helper scope: with `player_scraps = 0`, `can_afford()` returns false for every positive item price passed by the caller, including all current Shop catalog prices. Real catalog iteration and purchase blocking remain Shop integration scope.
- [x] AC-SH54: underlying `player_scraps` stores exact values above 999; any display cap is UI-only.

## Implementation Notes

Create `EconomyLedger` and named `EconomyResult`/error contract types. This first story may implement read-only `get_scraps()` and `can_afford()` plus validation helpers used by spend/add stories.

## Out of Scope

- Mutating staged Scraps: Stories 002 and 003.
- Shop UI, HUD display, or `999+` rendering.
- Expedition item flag helpers.

## QA Test Cases

- **AC-1**: affordability at zero, exact price, and above price
  - Given: save snapshots with 0, exact-price, and over-price Scrap values
  - When: `can_afford()` is called
  - Then: zero cannot afford positive prices, exact price can afford, and no mutation occurs
  - Edge cases: price 0, negative price rejected
- **AC-2**: exact high balance preservation
  - Given: `player_scraps = 1000`
  - When: `get_scraps()` reads the value
  - Then: the ledger returns 1000 exactly, not 999
  - Edge cases: presentation cap remains out of scope
- **AC-3**: named result contract
  - Given: invalid amount inputs
  - When: affordability validation runs
  - Then: failures return named `EconomyResult` values instead of anonymous dictionaries
  - Edge cases: amount < 0

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/economy/test_scrap_read_affordability_and_results.gd`

**Status**: [x] Created - focused Economy Ledger unit suite passed with 6/6 tests and 65 assertions; full unit/integration suite passed with 94/94 tests and 5,802 assertions.

## Dependencies

- Depends on: SaveData Resource complete (`production/epics/save-persistence/story-001-save-data-resource.md`)
- Unlocks: Story 002, Story 003, Shop purchase stories

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None
**Test Evidence**: Unit story evidence at `tests/unit/economy/test_scrap_read_affordability_and_results.gd`; focused suite passes with 6/6 tests and 65 assertions; full unit/integration suite passes with 94/94 tests and 5,802 assertions.
**Code Review**: Complete - approved on 2026-05-27 with no blocking findings.

### Acceptance Criteria Verification

| Criterion | Evidence | Status |
|-----------|----------|--------|
| AC-SH14 helper scope: affordability/result helpers reject negative amount inputs and never report a successful afford/spend result that would imply `player_scraps < 0`. | `test_negative_amount_returns_named_failure_without_mutation`, `test_can_afford_handles_zero_exact_and_above_price_without_mutation` | Covered |
| AC-SH15: a purchase with `player_scraps` exactly equal to `item_price` is valid and leaves `player_scraps = 0`. | `test_can_afford_handles_zero_exact_and_above_price_without_mutation` | Covered |
| AC-SH45 helper scope: with `player_scraps = 0`, `can_afford()` returns false for every positive item price passed by the caller, including all current Shop catalog prices. | `test_can_afford_rejects_every_positive_catalog_price_at_zero_balance` | Covered |
| AC-SH54: underlying `player_scraps` stores exact values above 999; any display cap is UI-only. | `test_get_scraps_returns_exact_saved_balance_above_display_cap` | Covered |

### Verification Commands

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/economy -gselect=test_scrap_read_affordability_and_results.gd -gexit
godot --headless --import --path . && godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 4/4 passing
**Deviations**: None
**Test Evidence**: Logic unit test at `tests/unit/economy/test_scrap_read_affordability_and_results.gd`; focused suite passed with 6/6 tests and 65 assertions; full unit/integration suite passed with 94/94 tests and 5,802 assertions.
**Code Review**: Complete - approved with no required changes.
**Review Notes**: `check_affordability()` currently returns `RefCounted` to avoid fresh global-class parse timing issues before Godot import registers `EconomyResult`; the returned object is still an `EconomyResult`.
