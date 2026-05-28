# ADR-0006: Dragon Data Model And Progression Services

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / Resources |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md`; `docs/engine-reference/godot/deprecated-apis.md`; `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | `duplicate_deep()` for nested Resource transaction staging through ADR-0001 |
| **Verification Required** | Verify staged dragon mutations do not leak into read snapshots before commit; verify progression events publish only after commit success; verify nested dragon Resources deep-copy correctly. |

Godot `Resource` fields are mutable unless the project enforces read-only projections. This ADR requires Save / Persistence read APIs to return copied records, getter-only projections, or explicit snapshots rather than live mutable nested `DragonRecord` Resources.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries |
| **Enables** | ADR-0007 Battle Runtime State Machine; Hatchery implementation stories; Fusion implementation stories; Campaign Map reward stories; Singularity Void grant stories |
| **Blocks** | Any story that creates, mutates, saves, displays, battles with, fuses, levels, or grants a dragon record |
| **Ordering Note** | This ADR should be Accepted before Battle, Hatchery, Fusion, Campaign Map reward, or Singularity Void implementation stories are generated. |

## Context

### Problem Statement

Dragon Forge's approved GDDs rely on a shared dragon record across Dragon Progression, Battle Engine, Hatchery, Fusion Engine, Campaign Map, Singularity, Save / Persistence, Journal / Console, and Hub roster UI. The same data carries level, XP, base stats, shiny status, resonance charges, Elder flag, and story-only Void identity.

The GDDs currently mix element-only signals, a registry `id` field, and architecture APIs that use `dragon_id: StringName`. Fused dragons and the Void story dragon make identity matter beyond element. The project needs one binding model before implementation stories can safely reference dragon records.

### Constraints

- Durable mutation must occur only through Save / Persistence transactions.
- Dragon Progression must own stat calculation, stage lookup, XP thresholds, XP application, resonance consumption, and the canonical dragon schema.
- Battle Engine owns raw XP formula and combat state; Campaign Map may apply XP decay and final reward application.
- Fusion owns `is_elder` creation semantics and `ELDER_STAGE_MULT`; Battle applies the Elder Stage IV multiplier branch.
- Hatchery and Fusion must not create Void.
- Void is story-only, non-shiny, and uses reserved identity `void_dragon`.
- Durable-state events must publish only after save commit success.

### Requirements

- Define typed dragon data/result contracts.
- Make `stage` a derived snapshot field, not durable storage.
- Use `dragon_id: StringName` as the primary runtime/save identity.
- Preserve `element: StringName` for gameplay, Journal, and UI.
- Accumulate progression events during transaction mutation and publish them only after commit.
- Provide source-specific creation helpers for Hatchery, Fusion, and Singularity.
- Keep Battle HP/status ownership separate from Dragon Progression stat/XP ownership.

## Decision

Dragon Progression is the canonical owner of the dragon record schema, stat calculation, stage lookup, XP threshold lookup, XP application loop, resonance charge mutation, max-level cleanup, and stage/progression event payloads.

Dragon records are typed GDScript data/Resource classes stored inside `SaveData`. Durable mutation happens only through `SaveTransaction`. Runtime systems read dragons through `SaveSnapshot` projections or copied records, not through live mutable `SaveData` nested Resources.

`DragonProgressionService` is a core service, not a saved/content `Resource` and not a broad gameplay Autoload. It should be a `RefCounted` service or a limited Node/service reference created by the bootstrap/service composition established by ADR-0005. Feature systems receive it through explicit service references or setup payloads.

### Durable Dragon Record

`DragonRecord` stores durable identity and progression fields:

```gdscript
class_name DragonRecord
extends Resource

@export var dragon_id: StringName
@export var element: StringName
@export var base_hp: int
@export var base_atk: int
@export var base_def: int
@export var base_spd: int
@export var level: int = 1
@export var xp: int = 0
@export var shiny: bool = false
@export var battle_charges: int = 0
@export var is_elder: bool = false
```

`stage` is not persisted. `stage` is derived from `level` in `DragonStats` or a stage snapshot. Any older registry/schema reference that lists durable `stage` should be treated as stale until revised.

Battle runtime fields such as current HP and active status are not owned by Dragon Progression. If durable HP/status fields live near dragon records in `SaveData`, Dragon Progression may validate/clamp derived max HP after level-up, but Battle Engine/Campaign Map/Save ownership rules determine when current HP/status changes.

When max HP increases after level-up, current HP does not automatically heal unless the calling system has an explicit healing rule. The max HP snapshot increases immediately after commit; current HP is clamped only if it exceeds the new max, which should not occur on normal level-up.

### Derived Snapshot Types

```gdscript
class_name DragonStats
extends RefCounted

var dragon_id: StringName
var element: StringName
var level: int
var stage: int
var hp: int
var atk: int
var def: int
var spd: int
var shiny: bool
var is_elder: bool
```

```gdscript
class_name DragonProgressionEvent
extends RefCounted

var event_id: StringName
var dragon_id: StringName
var element: StringName
var from_stage: int
var to_stage: int
var old_level: int
var new_level: int
```

Named result types are mandatory. Anonymous dictionaries are forbidden for dragon progression contracts.

Required result contracts:

- `XPApplyResult`
- `DragonCreationResult`
- `ResonanceChargeResult`
- `DragonValidationResult`
- `DragonStats`
- `DragonProgressionEvent`

### Service Interface

```gdscript
class_name DragonProgressionService
extends RefCounted

func calculate_stats(record: DragonRecord) -> DragonStats
func stage_for_level(level: int) -> int
func xp_threshold_for(level: int) -> int
func apply_xp(tx: SaveTransaction, dragon_id: StringName, xp_amount: int, source_id: StringName) -> XPApplyResult
func add_resonance_charge(tx: SaveTransaction, dragon_id: StringName, source_id: StringName) -> ResonanceChargeResult
func create_from_hatchery(tx: SaveTransaction, element: StringName, shiny: bool) -> DragonCreationResult
func create_from_fusion(tx: SaveTransaction, primary_id: StringName, secondary_id: StringName, child_data: FusionChildData) -> DragonCreationResult
func grant_void_dragon(tx: SaveTransaction) -> DragonCreationResult
func validate_record(record: DragonRecord) -> DragonValidationResult
```

`apply_xp()` mutates only the staged transaction copy and returns pending `DragonProgressionEvent` values. It must not emit `stats_updated`, `stage_advanced`, or `stage_iv_reached` inside the XP loop. Save / Persistence or the transaction caller publishes semantic progression events only after `commit_transaction(tx)` succeeds.

Release code must use explicit guards and failure results. It must not rely on `assert()` for validation such as negative XP rejection.

### Creation Paths

Hatchery creation:

- Creates only Fire, Ice, Storm, Stone, Venom, or Shadow.
- Uses canonical element base stats from Dragon Progression.
- Sets `level = 1`, `xp = 0`, `battle_charges = 0`, `is_elder = false`.
- Sets `shiny` from Hatchery pull result.
- Does not create Void.

Fusion creation:

- Consumes two parent records atomically through SaveTransaction.
- Writes inherited `base_hp`, `base_atk`, `base_def`, and `base_spd`.
- Sets `level = 1`, `xp = 0`, `shiny = false`, `battle_charges = 0`.
- Stores `is_elder` as computed by Fusion Engine.
- Does not own or apply `ELDER_STAGE_MULT`.

Singularity Void grant:

- Uses reserved `dragon_id = &"void_dragon"`.
- Uses `element = &"Void"`.
- Forces `shiny = false`.
- Uses story-roster capacity outside normal Hatchery/Fusion roster creation.
- Is not available through Hatchery or Fusion.

### Resonance Ownership

Battle Engine does not directly increment `dragon.battle_charges`. Battle Engine reports a qualifying active-battle completion to the system applying battle results. Dragon Progression mutates `battle_charges` through `add_resonance_charge(tx, dragon_id, source_id)` inside a transaction.

Campaign Map remains owner of passive bench charge awards and also applies them through `add_resonance_charge()`.

`battle_charges` is capped at `BATTLE_MAX_CHARGES`. At `MAX_LEVEL`, XP is set to 0 and `battle_charges` is cleared to 0.

### Elder Authority

Fusion Engine owns Elder creation semantics and the tuning constant `ELDER_STAGE_MULT = 1.75`. Dragon Progression stores the `is_elder` flag on `DragonRecord`. Battle Engine applies the Elder Stage IV multiplier branch when `is_elder == true` and `level >= 50`.

Dragon Progression does not compute or apply Elder combat multipliers.

### Architecture Diagram

```text
Hatchery / Fusion / Singularity
        |
        v
DragonProgressionService creation helpers
        |
        v
SaveTransaction staged DragonRecord mutation
        |
        v
SaveService.commit_transaction()
        |
        v
Commit succeeds
        |
        v
Publish DragonProgressionEvent payloads

Battle / Hub / Campaign Map / Journal
        |
        v
Read SaveSnapshot / DragonStats only
```

## Alternatives Considered

### Alternative 1: Element-Keyed Singleton Records

- **Description**: Store one dragon per element and use element as identity.
- **Pros**: Matches early GDD signal wording and simple Hatchery ownership.
- **Cons**: Fails for fused dragons, duplicate dragons, story Void identity, and roster ordering.
- **Rejection Reason**: Fused and story dragons require identity separate from element.

### Alternative 2: Anonymous Dictionary Records

- **Description**: Store dragon data in untyped dictionaries inside SaveData.
- **Pros**: Fast to write and flexible.
- **Cons**: Hard to validate, easy to miss migration fields, weak story handoff, and contrary to ADR-0001/0004 typed data direction.
- **Rejection Reason**: Too risky for a shared cross-system schema.

### Alternative 3: Typed DragonRecord With Transactional Service Helpers

- **Description**: Store typed dragon records in SaveData, mutate only through SaveTransaction, and expose read-only snapshots/stats.
- **Pros**: Clear ownership, testable XP loop, safe save integration, and direct support for Hatchery, Fusion, Singularity, and Battle contracts.
- **Cons**: Requires early service/scaffold work and GDD/registry sync for `dragon_id` and derived `stage`.
- **Rejection Reason**: Chosen.

## Consequences

### Positive

- All systems share one canonical dragon schema.
- Battle, Hub, Journal, and Campaign Map can consume stable snapshots without mutating save data.
- XP and stage events respect ADR-0001/0002 commit-before-emit ordering.
- Fused dragons and Void can coexist with Hatchery dragons without overloading element identity.
- GUT tests can target deterministic XP, stats, creation, and migration behavior.

### Negative

- Existing GDD/registry wording that refers to persisted `stage` or `id: int` needs cleanup after acceptance.
- Dragon-related stories depend on this service existing before feature implementation.
- Feature systems must call creation/mutation helpers instead of editing DragonRecord fields ad hoc.

### Risks

- **Signal timing drift**: Implementers may emit stage signals inside the XP loop because the GDD pseudocode does.
  - **Mitigation**: `XPApplyResult` carries pending events; commit pipeline emits after success.
- **Mutable snapshot leak**: Godot Resources are mutable by default.
  - **Mitigation**: `SaveSnapshot` must return copied records or read-only projections, never live nested Resources.
- **Identity mismatch**: Older docs may imply element-only identity.
  - **Mitigation**: ADR uses `dragon_id` as primary key and carries `element` in all event payloads.
- **Service over-globalization**: DragonProgressionService could become a broad Autoload.
  - **Mitigation**: ADR-0005 service access rules apply; DragonProgressionService is injected/referenced explicitly.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `dragon-progression.md` | Dragon data contract, stat scaling, stage thresholds, XP loop, Resonance, `is_elder`, and Void story dragon support. | Makes Dragon Progression the canonical owner of schema, formulas, stage lookup, XP application, and progression events. |
| `battle-engine.md` | Battle reads stats, level, shiny, `is_elder`, and receives XP application results without owning progression. | Battle consumes `DragonStats`/snapshots and reports battle completion; Dragon Progression mutates charges/XP through transactions. |
| `hatchery.md` | Hatchery creates core dragons and delegates duplicate XP to Dragon Progression. | Defines `create_from_hatchery()` and `apply_xp()` as the required paths. |
| `fusion-engine.md` | Fusion creates inherited-stat child records and sets `is_elder`; child starts at level 1. | Defines `create_from_fusion()` and clarifies Fusion owns Elder semantics while Dragon Progression stores the flag. |
| `campaign-map.md` | Campaign Map applies final XP rewards, evaluates gates, and awards passive bench Resonance. | Uses `apply_xp()` and `add_resonance_charge()` through transaction helpers; `stage` is derived from `level`. |
| `singularity.md` | Singularity grants Void story dragon and Battle reads Void as neutral type. | Defines `grant_void_dragon()` with reserved ID, Void element, non-shiny flag, and story-roster placement. |
| `save-persistence.md` | SaveData serializes dragon fields and migrates optional legacy fields. | Keeps DragonRecord inside SaveData and requires transaction staging, validation, and migration defaults. |

## Performance Implications

- **CPU**: Low. Stat calculation and XP loops are deterministic and bounded; XP loop cannot exceed 59 level increments.
- **Memory**: Low to moderate depending on roster size. Typed Resources add structure but roster is small for MVP.
- **Load Time**: Slightly higher due to validation/migration of each dragon record.
- **Network**: None. MVP is local single-player.

## Migration Plan

No stable Godot implementation exists yet. Initial implementation should:

1. Add typed classes for `DragonRecord`, `DragonStats`, `XPApplyResult`, `DragonCreationResult`, `ResonanceChargeResult`, `DragonValidationResult`, and `DragonProgressionEvent`.
2. Store dragons as `Array[DragonRecord]` inside `SaveData`.
3. Validate unique `dragon_id` values on load.
4. Default missing `battle_charges` to 0 and missing `is_elder` to false.
5. For legacy records with only numeric `id`, migrate to generated `dragon_id` values and reserve `void_dragon` for Singularity.
6. Treat any durable `stage` field as derived/stale; recompute from `level`.
7. Run XP consistency repair through Dragon Progression with `battle_charges` reset to 0 before repair.
8. Clamp max-level records to `xp = 0` and `battle_charges = 0`.

## Validation Criteria

- Staged `apply_xp()` followed by failed commit emits no progression signals and leaves canonical save unchanged.
- Staged mutation of a nested `DragonRecord` cannot leak into `SaveSnapshot` before commit.
- Multi-level XP awards produce pending stage events in ascending order, then publish them only after commit success.
- `stage_for_level()` returns correct stages for levels 1, 9, 10, 24, 25, 49, 50, and 60.
- Negative XP returns a failure result and does not mutate the staged record.
- `MAX_LEVEL` cleanup sets `xp = 0` and `battle_charges = 0`.
- Hatchery creation cannot create Void.
- Fusion creation resets level, XP, shiny, and charges, and writes inherited base stats plus `is_elder`.
- Void grant validates `dragon_id = &"void_dragon"`, `element = &"Void"`, and `shiny = false`.
- Battle Engine projections contain stats/snapshot data only and cannot mutate `SaveData`.
- `ELDER_STAGE_MULT` is not applied by Dragon Progression.

## Related Decisions

- ADR-0001: Save Transaction Boundary
- ADR-0002: Semantic Event Contracts
- ADR-0004: Authored Content Resources
- ADR-0005: Godot Scene Flow And Autoload Boundaries
- `docs/architecture/architecture.md`
- `design/gdd/dragon-progression.md`
- `design/gdd/fusion-engine.md`
- `design/gdd/hatchery.md`
- `design/gdd/battle-engine.md`
