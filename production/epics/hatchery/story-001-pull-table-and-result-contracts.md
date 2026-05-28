# Story 001: Pull Table And Result Contracts

> **Epic**: Hatchery
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 0.75 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0004: Authored Content Resources; ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery pull tables are immutable authored content with stable IDs, named result contracts, explicit pity/shiny configuration, and deterministic RNG seams for tests.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Use typed Resources and RefCounted result classes; no new engine-specific APIs beyond Godot 4.6 typed Resources.

**Control Manifest Rules (this layer)**:
- Required: CM-DATA-07, CM-HATCH-02
- Forbidden: Hardcoded pull weights scattered through UI scripts or global `randi()` / `randf()` calls
- Guardrail: Runtime code must not mutate shared `.tres` pull table Resources.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [x] A typed Hatchery pull table defines `PULL_COST = 50`, rarity weights, element weights, pity thresholds, shiny rate, and element drought thresholds from the GDD.
- [x] Void is not present in the standard Hatchery pull pool.
- [x] Pull tables validate required element IDs, probability totals, positive cost, pity threshold, soft-pity onset/guarantee ordering, and shiny rate bounds.
- [x] Hatchery result/preview contracts are named typed classes, not anonymous Dictionaries.
- [x] Runtime code uses copied/snapshotted pull table data or read-only access and does not mutate authored pull table Resources.
- [x] Test seams exist for deterministic scripted or seeded RNG without global random calls.

## Implementation Notes

Create the typed content/result surface needed by later stories before implementing pull resolution. ADR-0012 names `HatcheryPullTable`, `HatcheryPityRules`, `HatcheryPreviewResult`, and `HatcheryPullResult` concepts; keep contracts small and explicit. Validation failures should return named result values or validator objects rather than relying on assertions.

Performance: validation is content-load/test-time work. Pull execution must use already validated data and remain O(number of standard elements).

## Out of Scope

- Rarity, pity, soft-pity, and shiny roll behavior: Stories 002-003.
- SaveTransaction and Scrap spend behavior: Story 004.
- Dragon creation, duplicate XP, and shiny upgrades: Story 005.
- UI reveal screens and animation: Story 007.

## QA Test Cases

- **AC-1**: Pull table values
  - Given: the MVP Hatchery pull table
  - When: validation reads cost, rarity weights, element weights, pity rules, and shiny rate
  - Then: values match the GDD exactly: 50 Scrap cost, Common 50%, Uncommon 40%, Rare 10%, shiny 2%, Rare+ threshold 10, soft-pity onset 20, guarantee 40
  - Edge cases: no missing Fire/Ice/Storm/Venom/Stone/Shadow entries
- **AC-2**: Void excluded
  - Given: the standard pull table
  - When: element entries are inspected
  - Then: Void is absent and validation rejects any standard table that includes Void
  - Edge cases: story-gated Void unlock remains out of scope
- **AC-3**: Invalid table validation
  - Given: invalid weights, zero/negative cost, duplicate element IDs, missing Shadow, or guarantee <= onset
  - When: validation runs
  - Then: a named failure identifies the offending field
  - Edge cases: probability rounding tolerance for Uncommon per-element thirds
- **AC-4**: Named contracts
  - Given: preview and pull APIs
  - When: return types are inspected in tests
  - Then: they are typed result classes with stable fields and no anonymous Dictionary contracts
  - Edge cases: failures still return named result objects
- **AC-5**: Immutable authored data
  - Given: a configured pull table Resource
  - When: later code previews or executes a pull
  - Then: authored Resource arrays and nested Resources are not mutated
  - Edge cases: copied runtime tables can mutate safely if needed
- **AC-6**: RNG seam
  - Given: tests configure a scripted or seeded RNG provider
  - When: pull resolution asks for rolls in later stories
  - Then: no code path requires global random calls
  - Edge cases: production RNG can still be transaction-scoped

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/hatchery/test_pull_table_and_result_contracts.gd`

**Status**: [x] Created - focused Hatchery unit suite passed with 8/8 tests and 109 assertions; full unit/integration suite passed with 165/165 tests and 7,791 assertions.

## Dependencies

- Depends on: Authored Content Registry foundation stories
- Unlocks: Story 002, Story 003, Story 004, Story 006

## Completion Notes

**Completed**: 2026-05-28
**Criteria**: 6/6 passing.
**Deviations**: None.
**Test Evidence**: Logic evidence at `tests/unit/hatchery/test_pull_table_and_result_contracts.gd`; focused Hatchery unit suite passed with 8/8 tests and 109 assertions; full unit/integration suite passed with 165/165 tests and 7,791 assertions.
**Code Review**: Complete. Local `/code-review` approved after the required per-rarity element-total validation fix. Full-mode QA and lead-programmer sidecars returned APPROVED WITH NOTES with no blockers; QA's authored `.tres` drift note was addressed before close-out.
