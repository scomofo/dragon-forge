# Story 002: Damage, Type, Crit, And Stage Formulas

> **Epic**: Battle Engine
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: 1.5 days
> **Manifest Version**: 2026-05-26
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/battle-engine.md`
**Requirement**: `TR-battle-002`
**Requirement Text**: Implement canonical damage, type effectiveness, status, crit, defend cooldown, simultaneous KO, and Elder Stage IV multiplier formulas.
*(Requirement text lives in `docs/architecture/tr-registry.yaml` - read fresh at review time)*
**Scope Note**: This story partially covers `TR-battle-002`: damage, type effectiveness, crit, Defend damage reduction/order, stage/Elder multiplier lookup, accuracy/Blind accuracy, stat scaling inputs, and raw Battle XP formula only. Status lifecycle, status apply chance, status tick effects, Defend cooldown turn legality, simultaneous KO resolution, runtime phase transitions, reward settlement, and payload emission are covered by later Battle stories.

**ADR Governing Implementation**: ADR-0006: Dragon Data Model And Progression Services; ADR-0007: Battle Runtime State Machine
**ADR Decision Summary**: Battle consumes DragonStats snapshots and owns combat formulas, including Elder Stage IV multiplier branch, without mutating Dragon records.

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Use explicit float conversion for XP scaling and formula divisions where GDScript integer division would alter results.
**Performance**: No per-frame work expected. Formula helpers must be O(1), deterministic, and covered by unit tests without scene/runtime simulation. Public damage calls may return a named result object for `damage`/`hit`/`crit` data.

**Control Manifest Rules (this layer)**:
- Required: CM-BATTLE-04, CM-DRAGON-01
- Forbidden: Battle applying progression, rewards, or `battle_charges` directly
- Guardrail: Elder multiplier reads `is_elder` state and the Fusion-owned multiplier constant; avoid duplicate hardcoded literals where possible.

---

## Acceptance Criteria

*From GDD `design/gdd/battle-engine.md`, scoped to this story:*

- [x] Damage formula order matches: accuracy check first; `baseDamage = (ATK * stageMult * 1.5) - (DEF * 0.5)`; `typedDamage = baseDamage * typeEff`; Defend multiplies `typedDamage` by `0.5` before variance; `preCritDamage = max(1, floor(typedDamage * roll))`; crit result is `floor(preCritDamage * CRIT_MULTIPLIER)`.
- [x] Negative base damage floors to 1.
- [x] Crit constants, crit-after-Defend order, crit rate, and Defend reduction use `CRIT_CHANCE = 0.10`, `CRIT_MULTIPLIER = 1.5`, and `DEFEND_MULTIPLIER = 0.5`.
- [x] Full 7x7 type matrix below returns correct multipliers, including `Shadow -> Shadow = 2.0` and all Void row/column values as `1.0`.
- [x] Stage multipliers and stage thresholds below apply correctly, including Elder Stage IV multiplier only when `is_elder == true` and `level >= 50`.
- [x] Accuracy miss, Blind accuracy, stat scaling, and raw Battle XP formulas below are implemented without mutating dragon records or applying durable progression.

## Formula Contract

### Constants

| Name | Value |
| --- | --- |
| `DAMAGE_STAGE_FACTOR` | `1.5` |
| `DEFENSE_FACTOR` | `0.5` |
| `DEFEND_MULTIPLIER` | `0.5` |
| `CRIT_CHANCE` | `0.10` |
| `CRIT_MULTIPLIER` | `1.5` |
| `ROLL_MIN` / `ROLL_MAX` | `0.85` / `1.0` |
| `BLIND_ACCURACY_PENALTY` | `30` |
| `SHINY_MULTIPLIER` | `1.2` |
| `ELDER_STAGE_MULT` | `1.75` |

### Stage Multipliers

| Stage | Level Range | `stageMult` |
| --- | --- | --- |
| I | 1-9 | `0.5` |
| II | 10-24 | `0.75` |
| III | 25-49 | `1.0` |
| IV | 50+ | `1.4` |
| Elder IV | 50+ and `is_elder == true` | `1.75` |

`ELDER_STAGE_MULT = 1.75` is the accepted ADR-0006 Elder Authority contract. Until Fusion implementation exists, Battle may define or adapt this value locally in the formula module; do not require `FusionService` to exist for this story. Battle applies the Elder branch only when `is_elder == true` and `level >= 50`; Elder dragons below level 50 use the normal stage row.

### Type Effectiveness Matrix

`type_chart[attacker][defender]`:

| Attacker / Defender | Fire | Ice | Storm | Stone | Venom | Shadow | Void |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Fire | `0.5` | `2.0` | `1.0` | `0.5` | `2.0` | `1.0` | `1.0` |
| Ice | `0.5` | `0.5` | `2.0` | `1.0` | `1.0` | `2.0` | `1.0` |
| Storm | `1.0` | `0.5` | `0.5` | `2.0` | `1.0` | `2.0` | `1.0` |
| Stone | `2.0` | `1.0` | `0.5` | `0.5` | `2.0` | `1.0` | `1.0` |
| Venom | `0.5` | `1.0` | `1.0` | `0.5` | `0.5` | `2.0` | `1.0` |
| Shadow | `1.0` | `0.5` | `0.5` | `1.0` | `0.5` | `2.0` | `1.0` |
| Void | `1.0` | `1.0` | `1.0` | `1.0` | `1.0` | `1.0` | `1.0` |

### Formula Details

- Accuracy: `accuracyRoll = random(0, 100)`; miss when `accuracyRoll > effectiveAccuracy`; miss returns `damage = 0` and `hit = false`.
- Blind: `effectiveAccuracy = max(0, move_accuracy - 30)`.
- Damage: `baseDamage = (ATK * stageMult * 1.5) - (DEF * 0.5)`.
- Type: `typedDamage = baseDamage * typeEff`.
- Defend: if defending, `typedDamage = typedDamage * 0.5`, after type/stage calculation and before variance roll.
- Variance: `roll` is in `[0.85, 1.0]`.
- Pre-crit damage: `preCritDamage = max(1, floor(typedDamage * roll))`.
- Crit: if `critRoll < 0.10`, `finalDamage = floor(preCritDamage * 1.5)`; otherwise `finalDamage = preCritDamage`.
- Stat scaling: `stat_at_level = floor((baseStat + (level - 1) * 3) * shinyMult)`, where `shinyMult = 1.2` if shiny else `1.0`.
- Raw Battle XP: `raw_xp_awarded = max(1, floor(base_xp * float(enemy_level) / float(player_level)))`; precondition `player_level >= 1`; Battle does not apply Campaign Map XP decay or call `DragonProgressionService.apply_xp()`.

### Required Numeric Fixtures

- Base damage fixture: `ATK=70`, `DEF=44`, `stageMult=1.0`, `typeEff=2.0`, `defending=false`, `roll=0.90`, no crit -> `149`.
- Negative floor fixture: `ATK=10`, `DEF=100`, `stageMult=0.5`, `typeEff=0.5`, `defending=false`, `roll=1.0`, no crit -> `1`.
- Defended crit fixture: `ATK=70`, `DEF=44`, `stageMult=1.0`, `typeEff=2.0`, `defending=true`, `roll=0.90`, crit -> `111` (`floor(max(1, floor(83 * 2.0 * 0.5 * 0.90)) * 1.5)`).
- Accuracy fixture: move accuracy `85`, `accuracyRoll=86` -> miss with `damage=0`, `hit=false`.
- Blind fixture: move accuracy `100`, Blind active -> `effectiveAccuracy=70`; `accuracyRoll=71` misses and `accuracyRoll=70` hits.
- XP fixture: `base_xp=25`, `enemy_level=5`, `player_level=10` -> `12`; `base_xp=25`, `enemy_level=1`, `player_level=60` -> `1`.
- Stage/Elder fixtures: level `9 -> 0.5`, level `10 -> 0.75`, level `24 -> 0.75`, level `25 -> 1.0`, level `49 -> 1.0`, level `50 non-Elder -> 1.4`, level `50 Elder -> 1.75`.

## Implementation Notes

Keep formula code unit-testable without a scene. Inputs should be immutable DragonStats/combat snapshots. Do not resolve BattleSession phase transitions here except where needed for formula fixtures.
Use named result/value objects for any public formula outputs that need more than a single scalar, for example damage plus `hit`/`crit` flags. Do not use anonymous Dictionary contracts.

## Out of Scope

- Status apply chance, duration, tick logic, skip logic, overwrite behavior, and Guard Break defense mutation: Story 003.
- Defend cooldown turn legality and simultaneous KO runtime resolution: later Battle runtime/turn stories.
- Runtime turn loop and payload emission: Story 001 and Story 005.
- Reward settlement, XP application, Scrap application, and Resonance charges: Campaign Map / Dragon Progression stories.
- NPC AI decision weighting: Story 006.

## QA Test Cases

- **AC-1**: base damage and floor
  - Given: `ATK=70`, `DEF=44`, `stageMult=1.0`, `typeEff=2.0`, `roll=0.90`, no defend, no crit
  - When: damage is calculated
  - Then: output is `149`
  - Edge cases: `ATK=10`, `DEF=100`, `stageMult=0.5`, `typeEff=0.5`, `roll=1.0` returns minimum damage `1`
- **AC-2**: crit and Defend ordering
  - Given: `ATK=70`, `DEF=44`, `stageMult=1.0`, `typeEff=2.0`, defending target, `roll=0.90`, forced crit
  - When: damage is calculated
  - Then: output is `111`, proving Defend applies before variance and crit applies after pre-crit floor
  - Edge cases: crit rate harness verifies 10% +/- 2% over 10,000 deterministic-seeded trials
- **AC-3**: type/stage/Elder matrix
  - Given: all core element pairs plus Void and Elder/non-Elder stage cases
  - When: multipliers are requested
  - Then: matrix values, stage thresholds, and Elder branch match expected values
  - Edge cases: Shadow -> Shadow = `2.0`; all Void row/column values are `1.0`; level 50 Elder returns `1.75`
- **AC-4**: accuracy and XP formula
  - Given: move accuracy `85` with `accuracyRoll=86`, move accuracy `100` under Blind, and XP level pairs from Required Numeric Fixtures
  - When: accuracy/XP formulas run
  - Then: miss returns `damage=0`, `hit=false`; Blind effective accuracy is `70`; XP fixture returns `12`; XP floor fixture returns `1`
  - Edge cases: extreme level gap floors to at least 1

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- `tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd`

**Status**: [x] Created and passing

**Evidence**:
- Focused: `tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd` passed with 5/5 tests and 90 assertions.
- Full: unit + integration suite passed with 111/111 tests and 6,708 assertions.

## Dev Notes

**Implemented**: 2026-05-27
**Deviations**: None.
**Code Review**: Complete - approved with suggestions; story-done lead programmer gate approved.

**Implementation Summary**:
- Added `BattleFormulaService` as a pure RefCounted helper under `src/battle/formulas/`.
- Added `BattleDamageResult` as the named damage result shell for `damage`, `hit`, `crit`, and `reason`.
- Covered deterministic damage, negative floor, crit/Defend ordering, crit threshold, the full 7x7 type chart, stage/Elder multipliers, accuracy/Blind, stat scaling, and raw Battle XP.
- Formula helpers do not call Save, Dragon Progression XP application, or mutate Resonance charges.

**Acceptance Criteria Verification**:

| AC | Coverage |
| --- | --- |
| Damage formula order and base fixture | `test_damage_formula_order_base_damage_and_negative_floor` |
| Negative base damage floors to 1 | `test_damage_formula_order_base_damage_and_negative_floor` |
| Crit constants, rate, Defend order | `test_crit_defend_order_rate_and_constants` |
| Full 7x7 type matrix | `test_full_type_matrix_including_void_and_shadow_mirror` |
| Stage thresholds and Elder multiplier | `test_stage_thresholds_and_elder_stage_multiplier` |
| Accuracy, Blind, stat scaling, raw XP, no durable progression | `test_accuracy_blind_stat_scaling_and_raw_xp_are_pure_formula_helpers` |

**Verification Commands**:

```bash
godot --headless --import --path .
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit/battle_engine -ginclude_subdirs -gexit
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

## Dependencies

- Depends on: Battle Story 001 complete (`production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md`), Dragon Progression Story 001 complete (`production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md`), and ADR-0006 Elder Authority / Fusion-owned `ELDER_STAGE_MULT = 1.75` contract accepted. No separate Fusion implementation story is required for this formula helper.
- Unlocks: Status, turn resolution, and Battle balance stories

## Completion Notes

**Completed**: 2026-05-27
**Criteria**: 6/6 passing
**Deviations**: None. Non-blocking review notes: consider stronger typed dictionary/test annotations, public helper doc comments, and direct `ROLL_MIN` / `ROLL_MAX` assertions in a later hardening pass.
**Test Evidence**: Logic unit test at `tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd`; focused suite passed with 5/5 tests and 90 assertions; full unit + integration suite passed with 111/111 tests and 6,708 assertions.
**Code Review**: Complete - `/code-review` approved with suggestions; QA coverage gate ADEQUATE; lead programmer story-done gate APPROVE.
