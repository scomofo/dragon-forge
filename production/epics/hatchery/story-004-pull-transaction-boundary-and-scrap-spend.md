# Story 004: Pull Transaction Boundary And Scrap Spend

> **Epic**: Hatchery
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0001: Save Transaction Boundary; ADR-0009: Economy And Shop Transaction Boundaries; ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: `HatcheryService.execute_pull()` opens one SaveTransaction, spends Scraps through EconomyLedger, stages pull result and pity data, and commits or rolls back as one unit.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Verify transaction staging, rollback under save failure injection, and no direct file or SaveData mutation from Hatchery.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-01, CM-HATCH-03, CM-GLOB-01, CM-GLOB-10
- Forbidden: UI code spending Scraps, rolling RNG, mutating pity counters, or writing save files directly
- Guardrail: Pull execution is transaction-bound and must not leave partial spend/outcome state.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [ ] AC-H01: A pull with balance >=50 Scraps deducts exactly 50 Scraps and produces an outcome.
- [ ] AC-H02: A pull with balance <50 Scraps neither deducts Scraps nor produces any outcome.
- [ ] AC-H03: Post-pull balance equals pre-pull balance minus 50.
- [ ] AC-H11: The Rare+ pity counter is written to save data after each pull and reloads with the exact saved value.
- [ ] AC-H27: If save fails after Scrap deduction but before outcome commit, the player's balance is restored and no outcome is recorded on next load.
- [ ] AC-H37: All six element drought counters are written to save data atomically with each pull and reload exactly.
- [ ] Hatchery never mutates `player_scraps` directly; it uses EconomyLedger inside a SaveTransaction.

## Implementation Notes

Implement `HatcheryService.execute_pull()` as the transaction boundary for pull settlement. This story can stage the selected outcome and pity/drought counters but does not need to create or update dragons yet; Story 005 completes outcome application. Keep failed affordability checks outside transaction mutation and return named result failures.

Performance: no repeated save I/O during simulation; production execution opens exactly one transaction per confirmed pull.

## Out of Scope

- Dragon creation and duplicate XP application: Story 005.
- Post-commit event publication: Story 006.
- UI button state and confirmation flow: Story 007.

## QA Test Cases

- **AC-1**: Successful exact spend
  - Given: a save with 50 Scraps and deterministic pull outcome
  - When: `execute_pull()` runs
  - Then: staged/committed balance is 0 and one outcome result exists
  - Edge cases: balance above 50 preserves exact remainder
- **AC-2**: Insufficient Scraps
  - Given: a save with 49 Scraps
  - When: `execute_pull()` runs
  - Then: no Scrap deduction, no RNG outcome, no pity/drought mutation, and a named insufficient-funds result returns
  - Edge cases: balance 0 behaves the same way
- **AC-3**: Balance arithmetic
  - Given: balances 50, 51, and 999+
  - When: pulls succeed
  - Then: post-pull balance is exactly pre-pull minus 50
  - Edge cases: no display cap changes underlying balance
- **AC-4**: Pity counter persistence
  - Given: a pull that sets pity counter to 7
  - When: save commits and reloads
  - Then: loaded pity counter is exactly 7
  - Edge cases: Rare result reloads counter at 0
- **AC-5**: Save failure rollback
  - Given: failure injection after staged Scrap spend
  - When: commit fails
  - Then: canonical save reloads with pre-pull balance, pre-pull pity/drought counters, and no recorded outcome
  - Edge cases: temp/backup artifacts do not become canonical state
- **AC-6**: Drought counter persistence
  - Given: staged counters such as Fire 7 and Stone 19
  - When: save commits and reloads
  - Then: all six counters match exactly
  - Edge cases: missing one counter rejects or repairs before commit, according to Save contract
- **AC-7**: Economy boundary
  - Given: Hatchery executes a pull
  - When: code path is inspected in tests/review
  - Then: `player_scraps` mutation happens through EconomyLedger in the staged transaction only
  - Edge cases: preview does not mutate Scraps

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- `tests/integration/hatchery/test_pull_transaction_boundary_and_scrap_spend.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001, Story 002, Story 003, Economy Ledger Story 002, Save / Persistence transaction foundation
- Unlocks: Story 005, Story 006
