# Story 002: Rarity Pity And Shiny Roll Resolution

> **Epic**: Hatchery
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.0 day
> **Manifest Version**: 2026-05-26
> **Last Updated**:

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
- Guardrail: Roll order must remain stable: spend validation -> rarity roll with pity override -> element roll -> shiny roll -> duplicate check.

---

## Acceptance Criteria

*From GDD `design/gdd/hatchery.md`, scoped to this story:*

- [ ] AC-H04: Over 10,000 simulated pulls with a fixed RNG seed, tier frequencies are within +/-2% of targets: Common 50%, Uncommon 40%, Rare 10%.
- [ ] AC-H05: Over 10,000 pulls with a fixed RNG seed, each Common element (Fire, Ice) appears between 23%-27% of pulls.
- [ ] AC-H06: Over 10,000 pulls with a fixed RNG seed, each Uncommon element (Storm, Venom, Stone) appears between 11.33%-15.33% of pulls.
- [ ] AC-H07: After exactly 9 consecutive non-Rare pulls, the 10th pull always produces Rare (Shadow).
- [ ] AC-H08: The pity counter resets to 0 after any Rare+ pull, natural or forced.
- [ ] AC-H09: The pity counter increments by 1 after each Common or Uncommon pull.
- [ ] AC-H10: If `pityCounter == 9` and the natural draw is Rare, the pull is treated as natural and the shiny roll applies normally.
- [ ] AC-H12: Over 10,000 pulls with a fixed RNG seed, the shiny rate is between 1%-3%.

## Implementation Notes

Implement a pure/testable pull resolver against validated table data and a pity-counter input. The resolver returns a typed result containing natural rarity, final rarity/element, whether pity forced the outcome, shiny result, and next pity counter. It should not open transactions, spend Scraps, mutate SaveData, create dragons, or emit events.

Performance: the resolver should be O(number of element entries) per pull and avoid allocations inside high-count simulation loops where practical.

## Out of Scope

- Element soft-pity ramp and guarantee behavior: Story 003.
- Durable persistence of pity counters: Story 004.
- Duplicate XP or dragon creation: Story 005.
- Player-facing pity display: explicitly forbidden by the GDD.

## QA Test Cases

- **AC-1**: Tier frequencies
  - Given: a fixed seed and the MVP pull table
  - When: 10,000 natural pulls are simulated without forced soft-pity
  - Then: Common, Uncommon, and Rare frequencies land within +/-2% of 50%, 40%, and 10%
  - Edge cases: deterministic repeat with same seed produces identical counts
- **AC-2**: Common element frequencies
  - Given: a fixed seed and natural pull simulation
  - When: 10,000 pulls run
  - Then: Fire and Ice each appear between 23% and 27%
  - Edge cases: tier totals and per-element totals agree
- **AC-3**: Uncommon element frequencies
  - Given: a fixed seed and natural pull simulation
  - When: 10,000 pulls run
  - Then: Storm, Venom, and Stone each appear between 11.33% and 15.33%
  - Edge cases: no Void entry can appear
- **AC-4**: Rare+ pity boundary
  - Given: `pityCounter = 9` and scripted non-Rare natural result
  - When: the pull resolves
  - Then: final element is Shadow and the counter resets to 0
  - Edge cases: `pityCounter = 8` does not force Shadow
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
  - Given: a fixed seed and 10,000 pulls
  - When: shiny rolls are counted
  - Then: shiny rate is between 1% and 3%
  - Edge cases: pity-forced pulls have no shiny penalty
- **AC-8**: Stable roll order
  - Given: scripted RNG values for rarity, element, and shiny
  - When: a pull resolves
  - Then: the resolver consumes rolls in the ADR-0012 order
  - Edge cases: pity override does not skip the shiny roll

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/hatchery/test_rarity_pity_and_shiny_rolls.gd`

**Status**: [ ] Not yet created

## Dependencies

- Depends on: Story 001
- Unlocks: Story 003, Story 004
