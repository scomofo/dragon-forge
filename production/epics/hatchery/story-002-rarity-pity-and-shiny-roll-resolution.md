# Story 002: Rarity Pity And Shiny Roll Resolution

> **Epic**: Hatchery
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/hatchery.md`
**Requirement**: `TR-hatch-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*

**ADR Governing Implementation**: ADR-0012: Hatchery Pull Transaction And RNG Boundaries
**ADR Decision Summary**: Hatchery owns pull outcome resolution with stable roll order, injected or transaction-scoped RNG, and captured roll results for QA evidence.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Use `RandomNumberGenerator` only behind an injectable/testable seam; no global RNG leakage.

**Control Manifest Rules (this layer)**:
- Required: CM-HATCH-02
- Forbidden: Global `randi()`, `randf()`, or scattered random calls
- Guardrail: Story 002 resolver roll order must remain stable: rarity roll -> Rare+ pity override -> element selection when needed -> shiny roll. When Rare+ pity forces Shadow, the resolver must not consume an element-selection RNG roll; it still consumes the shiny roll.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [x] AC-H04: Over 10,000 natural pre-pity resolver trials with canonical seed `1337`, `pityCounter = 0` for each trial, and element soft-pity disabled/not applied, `natural_rarity` frequencies are within +/-2% of targets: Common 50%, Uncommon 40%, Rare 10%; repeating the same seed produces identical counts.
- [x] AC-H05: Over the same 10,000 natural pre-pity resolver trials, `natural_element` frequencies for Common elements Fire and Ice each appear between 23%-27% of pulls.
- [x] AC-H06: Over the same 10,000 natural pre-pity resolver trials, `natural_element` frequencies for Uncommon elements Storm, Venom, and Stone each appear between 11.33%-15.33% of pulls.
- [x] AC-H07: After exactly 9 consecutive non-Rare pulls, the 10th pull always produces Rare (Shadow).
- [x] AC-H08: The pity counter resets to 0 after any Rare+ pull, natural or forced.
- [x] AC-H09: The pity counter increments by 1 after each Common or Uncommon pull.
- [x] AC-H10: If `pityCounter == 9` and the natural draw is Rare, the pull is treated as natural, `pity_forced = false`, and the shiny roll applies normally.
- [x] AC-H12: Over 10,000 resolver trials with canonical seed `1337`, the shiny rate is between 1%-3%; repeating the same seed produces identical shiny counts.

## Implementation Notes

Implement a pure/testable pull resolver against validated table data and a pity-counter input. The resolver returns a typed result containing `natural_rarity`, `natural_element` when an element-selection roll is consumed, `final_rarity`, `final_element`, whether pity forced the outcome, shiny result, captured roll values, and next pity counter. It should not open transactions, spend Scraps, mutate SaveData, create dragons, emit events, or apply element soft-pity/drought counters.

Performance: the resolver should be O(number of element entries) per pull and avoid allocations inside high-count simulation loops where practical.

## Out of Scope

- Element soft-pity ramp, drought counters, and guarantee behavior: Story 003. Story 002 tests must not apply element soft-pity or depend on drought-counter state.
- Durable persistence of pity counters: Story 004.
- Duplicate XP or dragon creation: Story 005.
- Player-facing pity display: explicitly forbidden by the GDD.

## QA Test Cases

- **AC-1**: Tier frequencies
  - Given: canonical seed `1337`, the MVP pull table, and each trial started with `pityCounter = 0`
  - When: 10,000 resolver trials count `natural_rarity` before any Rare+ pity override
  - Then: Common, Uncommon, and Rare frequencies land within +/-2% of 50%, 40%, and 10%
  - Edge cases: deterministic repeat with seed `1337` produces identical counts; element soft-pity/drought counters are not applied in this story
- **AC-2**: Common element frequencies
  - Given: canonical seed `1337`, the MVP pull table, and each trial started with `pityCounter = 0`
  - When: 10,000 resolver trials count `natural_element` before any Rare+ pity override
  - Then: Fire and Ice each appear between 23% and 27%
  - Edge cases: tier totals and per-element totals agree
- **AC-3**: Uncommon element frequencies
  - Given: canonical seed `1337`, the MVP pull table, and each trial started with `pityCounter = 0`
  - When: 10,000 resolver trials count `natural_element` before any Rare+ pity override
  - Then: Storm, Venom, and Stone each appear between 11.33% and 15.33%
  - Edge cases: no Void entry can appear
- **AC-4**: Rare+ pity boundary
  - Given: `pityCounter = 9` and scripted non-Rare natural result
  - When: the pull resolves
  - Then: final element is Shadow, `pity_forced = true`, the counter resets to 0, the non-Rare natural element roll is not consumed, and the shiny roll is still consumed
  - Edge cases: `pityCounter = 8` does not force Shadow and consumes the normal element-selection roll
- **AC-5**: Natural Shadow at pity 9
  - Given: `pityCounter = 9` and scripted natural Shadow
  - When: the pull resolves
  - Then: result is marked natural, pity force is false, shiny roll still runs, and counter resets to 0
  - Edge cases: shiny true and shiny false both preserve the natural flag
- **AC-6**: Pity increment/reset
  - Given: scripted Common, Uncommon, and Rare outcomes
  - When: each resolves
  - Then: Common/Uncommon increment by 1 and Rare resets to 0
  - Edge cases: forced Rare and natural Rare both reset
- **AC-7**: Shiny rate
  - Given: canonical seed `1337` and 10,000 resolver trials
  - When: shiny rolls are counted
  - Then: shiny rate is between 1% and 3%
  - Edge cases: pity-forced pulls have no shiny penalty and same-seed repeats produce identical shiny counts
- **AC-8**: Stable roll order
  - Given: scripted RNG values for rarity, element, and shiny
  - When: a pull resolves
  - Then: the resolver consumes rolls in this Story 002 order: rarity roll -> Rare+ pity override -> element-selection roll only if the final element is not already forced/uniquely determined -> shiny roll
  - Edge cases: pity override skips the element-selection roll because Shadow is forced, but does not skip the shiny roll

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/hatchery/test_rarity_pity_and_shiny_rolls.gd`

**Status**: [x] Created - focused HATCHERY-002 unit suite passed with 7/7 tests and 141 assertions; Hatchery unit slice passed with 15/15 tests and 250 assertions; full unit/integration suite passed with 172/172 tests and 7,932 assertions.

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, Story 004

## Completion Notes

**Completed**: 2026-05-28
**Criteria**: 8/8 passing.
**Deviations**: No blocking deviations. Advisory follow-ups: add explicit tier-to-element reconciliation assertions, add a natural-Rare shiny-false edge assertion, and add public method doc comments where the next Hatchery cleanup touches these files.
**Test Evidence**: Logic unit test at `tests/unit/hatchery/test_rarity_pity_and_shiny_rolls.gd`; focused HATCHERY-002 suite passed with 7/7 tests and 141 assertions; Hatchery unit slice passed with 15/15 tests and 250 assertions; full unit/integration suite passed with 172/172 tests and 7,932 assertions.
**QA Coverage**: Full-mode QL-TEST-COVERAGE returned GAPS with no blockers; all story acceptance criteria are covered, with the advisory edge-case gaps listed above.
**Code Review**: Complete. `/code-review` approved with suggestions; full-mode LP-CODE-REVIEW returned CONCERNS with no blockers.
