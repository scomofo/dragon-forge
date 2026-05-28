# ADR-0010: Singularity Boss And Ending Orchestration

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / Resources / UI Input |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/deprecated-apis.md`; `docs/engine-reference/godot/modules/input.md`; `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior through ADR-0003/0005; callable signal connections; typed Resources through ADR-0004 |
| **Verification Required** | Verify corruption monotonicity, SCAR commit atomicity, gatekeeper settlement, Mirror Admin phase checkpoints, tritone window routing, Void grant atomicity, Crown relic flow, and post-game terminal/read-only behavior. |

Singularity orchestration uses ordinary GDScript, typed Resources, SaveTransaction helpers, and Input Router semantic actions. It does not require physics, navigation servers, networking, or deprecated Godot 3 scene APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0006 Dragon Data Model And Progression Services; ADR-0007 Battle Runtime State Machine; ADR-0008 Campaign Map Content And Reward Pipeline; ADR-0009 Economy And Shop Transaction Boundaries |
| **Enables** | ADR-0011 Corruption Rendering Pipeline; Singularity boss stories; Crown ending stories; post-game terminal stories; Void grant implementation |
| **Blocks** | Any story implementing Singularity activation, corruption class mutation, gatekeeper boss settlement, Mirror Admin phase transitions, Void dragon grant, Crown ending resolution, or post-game Singularity state |
| **Ordering Note** | This ADR must be Accepted before any story writes Singularity-owned save fields or consumes Singularity boss/ending Resources. |

## Context

### Problem Statement

Singularity owns Dragon Forge's most failure-prone progression chain: Matrix activation, three gatekeeper bosses, corruption and SCAR escalation, the continuous Mirror Admin encounter, Void dragon grant, Crown relic resolution, `ending_id`, and post-game read-only behavior. Existing ADRs define shared boundaries, but no accepted decision owns the full Singularity service contract.

Without a dedicated ADR, Campaign Map, Battle Engine, Save / Persistence, Dragon Progression, Shop, Journal, Audio, and UI stories can each infer a different owner for boss flags, corruption checkpoints, Crown flow, or ending state.

### Constraints

- Save / Persistence owns disk commit and rollback.
- Durable Singularity signals publish only after commit success.
- Battle Engine owns runtime combat and returns settlement payloads; it never commits Singularity flags.
- Campaign Map owns traversal, CROWN node routing, generic boss replay state, and Matrix stabilization.
- Singularity owns corruption class, SCAR node list, gatekeeper flags, Mirror Admin flag, Void grant state, Crown flow, and `ending_id`.
- Shop is the sole normal relic flag writer; Crown cannot sell, discount, grant, reset, or consume relic flags.
- Dragon Progression owns dragon record mutation helpers, including Void creation through source-specific story grant helpers.
- Input Router owns d-pad plus confirm/cancel and contextual Defend/Counter routing.

### Requirements

- Activate idempotently from committed `matrix_stabilized`.
- Advance corruption monotonically and atomically with cumulative `scar_nodes[]`.
- Set gatekeeper defeated flags only once, after battle settlement commit succeeds.
- Preserve ADR-0007's continuous Mirror Admin session and phase checkpoint model.
- Commit Mirror Admin defeat and Void grant atomically.
- Resolve Crown endings from current relic flags without changing relic ownership.
- Write `ending_id` as the only post-game authority.
- Provide typed Resource and result contracts for implementation stories.

## Decision

Singularity will be implemented as a feature service/controller initialized by the scene/service bootstrap path from ADR-0005. It may be a long-lived service because it owns cross-screen durable endgame state, but it must expose explicit setup dependencies and must not rely on hidden Autoload side effects.

Singularity reads immutable authored data from `SingularityData` Resources and mutates only staged SaveTransaction copies through Save / Persistence and downstream helper services.

### State Ownership

Singularity owns these durable fields:

- `corruption_class`
- `scar_nodes[]`
- `gatekeeper_fire_defeated`
- `gatekeeper_ice_defeated`
- `gatekeeper_shadow_defeated`
- `mirror_admin_defeated`
- `void_dragon_granted`
- `ending_id`
- Mirror Admin phase checkpoint fields required by ADR-0007 when CRITICAL/BREACH are committed mid-fight

Singularity reads but does not own:

- `matrix_stabilized`
- `current_node_id`
- Campaign Map replay and traversal fields
- `player_scraps`
- expedition item flags
- relic ownership flags
- normal dragon roster capacity rules

### Authored Data

```gdscript
class_name SingularityData
extends Resource

@export var scar_class_definitions: Array[ScarClassDefinition]
@export var boss_definitions: Array[BossDefinition]
@export var mirror_admin_phase_profiles: Array[MirrorAdminPhaseProfile]
@export var ending_definitions: Array[EndingDefinition]
@export var protected_node_ids: Array[StringName]
```

```gdscript
class_name ScarClassDefinition
extends Resource

@export var corruption_class: StringName
@export var scar_node_ids: Array[StringName]
```

```gdscript
class_name BossDefinition
extends Resource

@export var boss_id: StringName
@export var display_name_id: StringName
@export var element: StringName
@export var level: int
@export var boss_stage_mult: float
@export var base_xp: int
@export var scrap_reward: int
@export var replay_reward_policy: StringName
@export var corruption_advance: StringName
@export var combat_profile_id: StringName
```

```gdscript
class_name MirrorAdminPhaseProfile
extends Resource

@export var combat_profile_id: StringName
@export var phase_id: StringName
@export var element_rule: StringName
@export var ai_profile_id: StringName
@export var scripted_loop: Array[StringName]
@export var target_pitch_id: StringName
@export var tritone_window_rule: StringName
@export var phase_threshold_ratio: float
```

```gdscript
class_name EndingDefinition
extends Resource

@export var ending_id: StringName
@export var relic_flag: StringName
@export var cutscene_id: StringName
@export var post_game_profile_id: StringName
@export var survivorship_profile_id: StringName
```

All required IDs must validate at boot/content-lock time. Resource arrays must initialize safely, and runtime systems must never mutate shared `.tres` Resources.

### Service API

```gdscript
class_name SingularityService
extends RefCounted

signal singularity_activated(payload: SingularityActivatedPayload)
signal corruption_class_changed(payload: CorruptionChangedPayload)
signal gatekeeper_defeated(payload: GatekeeperDefeatedPayload)
signal mirror_admin_phase_changed(payload: MirrorPhasePayload)
signal tritone_window_changed(payload: TritoneWindowPayload)
signal tritone_counter_resolved(payload: TritoneCounterPayload)
signal mirror_admin_defeated(payload: MirrorAdminDefeatedPayload)
signal ending_resolved(payload: EndingResolvedPayload)

func configure(save_service: SaveService, data: SingularityData, dragon_progression: DragonProgressionService, economy_ledger: EconomyLedger, expedition_inventory: ExpeditionInventoryLedger) -> void
func activate_from_matrix(payload: MatrixStabilizedPayload) -> SingularityResult
func get_scar_nodes_for_class(corruption_class: StringName) -> Array[StringName]
func can_access_mirror_admin(snapshot: SaveSnapshot) -> bool
func begin_gatekeeper_battle(boss_id: StringName) -> BattleStartRequest
func settle_gatekeeper_battle(payload: BattleEndedPayload, delta: BattleDurableDelta, context: SingularityBattleContext) -> SingularitySettlementResult
func begin_mirror_admin() -> BattleStartRequest
func settle_mirror_admin_phase_transition(delta: BattleDurableDelta, phase_to: StringName) -> SingularitySettlementResult
func settle_mirror_admin_final(payload: BattleEndedPayload, delta: BattleDurableDelta) -> SingularitySettlementResult
func can_attempt_ending(snapshot: SaveSnapshot) -> EndingCheckResult
func resolve_crown(snapshot: SaveSnapshot, selected_relic_flag: StringName) -> EndingResolveResult
func get_ending_denial_text(snapshot: SaveSnapshot) -> String
func get_no_relic_denial_text(snapshot: SaveSnapshot) -> String
```

Anonymous dictionaries are forbidden for Singularity runtime contracts. Named payload/result classes are required.

### Activation

Campaign Map owns `matrix_stabilized`. When Campaign Map commits the flag and emits `matrix_stabilized(payload)` after save commit success, Singularity calls `activate_from_matrix()`.

Activation is idempotent. If activation has already been applied or if Spine nodes are already available, the service returns a no-op success result and emits no duplicate first-time activation events.

### Corruption And SCAR Settlement

Corruption advances only forward:

```text
NOMINAL -> ANOMALY -> WARNING -> ALERT -> CRITICAL -> BREACH
```

Every corruption advance opens one SaveTransaction and stages:

1. New `corruption_class`
2. Cumulative `scar_nodes[]` for that class
3. Any required Singularity milestone flag
4. Mirror Admin phase checkpoint data when the advance occurs inside Mirror Admin

`corruption_class_changed(payload)` emits only after commit success. If commit fails, both corruption class and `scar_nodes[]` remain at the previous committed values and no class-change signal emits.

### Gatekeeper Settlement

Gatekeeper battles use Battle Engine runtime from ADR-0007. Battle Engine returns `BattleEndedPayload` and `BattleDurableDelta`; Singularity owns first-clear Singularity milestone settlement.

On first victory against a gatekeeper, Singularity opens a SaveTransaction and stages:

1. The specific `gatekeeper_[id]_defeated = true` flag
2. The next corruption class and cumulative `scar_nodes[]`
3. Dragon XP/Resonance through Dragon Progression helpers, if this boss settlement owns the reward path
4. Scrap reward through EconomyLedger, validated against authored `BossDefinition.scrap_reward`
5. Battle durable deltas allowed by ADR-0007

The defeated flag, reward application, corruption advance, and SCAR list commit atomically. Replay victories must not rewrite defeated flags or advance corruption.

### Mirror Admin Settlement

Mirror Admin remains one continuous BattleSession. Singularity owns phase profile decisions, phase threshold settlement, tritone windows, phase checkpoint data, and final milestone settlement.

At PARITY -> OVERCLOCK and OVERCLOCK -> KERNEL_PANIC, Singularity may commit CRITICAL/BREACH immediately only if the same transaction also stages a phase checkpoint sufficient to reload the active encounter:

- `boss_id`
- `phase_id`
- boss HP
- player HP
- turn count
- cleared transient statuses/cooldowns

Committing CRITICAL or BREACH without matching checkpoint data is invalid. A project variant that reloads only from the pre-boss save must defer CRITICAL/BREACH durable commits until final settlement; Dragon Forge does not use that variant.

On final Mirror Admin victory, Singularity opens a SaveTransaction and stages:

1. `mirror_admin_defeated = true`
2. Void dragon grant through Dragon Progression's story grant helper
3. Mirror Admin archive state, if represented separately from `mirror_admin_defeated`
4. Final battle durable deltas allowed by ADR-0007

`mirror_admin_defeated(payload)` emits only after commit success. Mirror Admin defeat does not advance corruption.

### Tritone Window

Singularity owns `tritone_window`. Battle UI may decorate Defend as Counter, but Input Router continues to emit `battle_defend`. During an open window, Singularity interprets `battle_defend` as `tritone_counter` and returns a typed `TritoneCounterPayload`.

No separate Counter input action exists in MVP.

### Crown Ending Flow

Crown flow reads relic flags from the current save snapshot:

- `relic_wrench_owned`
- `relic_lens_owned`
- `relic_blade_owned`

If zero relics are owned, Crown displays denial text, writes no save data, deducts no Scraps, and returns to Campaign Map.

If one relic is owned, Crown presents that relic automatically.

If two or three relics are owned, Crown displays only owned relics in a d-pad row and requires the player to select one.

After relic presentation and the residual Admin final line complete, Singularity opens one SaveTransaction and writes `ending_id`. It does not write `game_state`, mutate relic flags, sell relics, or alter `player_scraps`.

`ending_resolved(payload)` emits only after `ending_id` commit success.

### Post-Game

`ending_id != ""` is the only post-game persistent authority. Campaign Map derives free-roam from `ending_id`. Singularity provides post-game terminal profile IDs and prevents Crown ending UI and Mirror Admin battle from reopening.

Gatekeeper replay is permitted through Campaign Map replay policy, but replay must not advance corruption, rewrite first-clear flags, re-grant Void, or re-emit first-time milestone events.

## Architecture Diagram

```text
Campaign Map matrix_stabilized commit
        |
        v
SingularityService -> SingularityData Resources
        |
        +-> Battle Engine runtime requests/results
        +-> DragonProgressionService story grant / XP helpers
        +-> EconomyLedger reward helpers
        +-> SaveTransaction commit via Save / Persistence
        |
        v
Post-commit semantic events: corruption, gatekeeper, phase, mirror_admin, ending
```

## Alternatives Considered

### Campaign Map owns Singularity state

- **Description**: Campaign Map would write boss flags, corruption, SCAR nodes, Crown state, and post-game state.
- **Pros**: Fewer services for traversal stories.
- **Cons**: Violates domain ownership and makes Battle/Crown/Mirror Admin logic depend on a map screen.
- **Rejection Reason**: Campaign Map should route and display Singularity state, not own endgame progression.

### Battle Engine owns boss milestone commits

- **Description**: Battle Engine would write gatekeeper and Mirror Admin flags on victory.
- **Pros**: Direct from combat outcome to milestone.
- **Cons**: Violates ADR-0007, mixes runtime combat with durable world state, and duplicates reward settlement rules.
- **Rejection Reason**: Battle emits payloads; Singularity or Campaign Map commits durable outcomes.

### Crown sells emergency relics

- **Description**: Crown would let players buy or receive a relic if none are owned.
- **Pros**: Prevents backtracking after Mirror Admin.
- **Cons**: Breaks the prior-commitment ending fantasy and conflicts with ADR-0009.
- **Rejection Reason**: Shop is the sole normal relic writer; zero-relic Crown denial is intentional.

## Consequences

### Positive

- Singularity ownership becomes explicit and traceable.
- Boss milestones, corruption, Void grant, and endings are atomic and testable.
- Campaign Map, Battle, Shop, Dragon Progression, Journal, Audio, and UI receive clear contracts.
- Mirror Admin reload behavior is coherent with CRITICAL/BREACH durable commits.

### Negative

- Singularity implementation has several dependencies and cannot be built safely before foundation/core services.
- Gatekeeper settlement must coordinate reward and corruption mutations in one transaction.
- Phase checkpoint support adds test burden to Mirror Admin stories.

### Risks

- **Nested transaction risk**: corruption events may trigger subscribers that try to mutate state.
  - **Mitigation**: Durable signals emit post-commit; follow-up mutations must use deferred guarded commands.
- **Replay milestone duplication**: gatekeeper replays may re-trigger first-clear events.
  - **Mitigation**: Settlement checks defeated flags before staging first-clear mutations.
- **Crown state drift**: relic flags may change after Crown opens.
  - **Mitigation**: `resolve_crown()` re-reads a fresh snapshot immediately before commit.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `singularity.md` | Own corruption, SCAR nodes, boss sequence, Mirror Admin phases, Void grant, Crown flow, ending ID, and post-game state. | Defines SingularityService ownership, SaveTransaction settlement, typed Resources, and event contracts. |
| `campaign-map.md` | Campaign Map routes CROWN/BOSS nodes and reads Singularity state without owning it. | Keeps Campaign Map traversal/display authority separate from Singularity durable ownership. |
| `battle-engine.md` | Battle runs gatekeeper/Mirror Admin combat but does not commit durable rewards or flags. | Consumes ADR-0007 payloads and assigns settlement to Singularity. |
| `save-persistence.md` | Singularity commits corruption, Mirror Admin defeat/Void, and endings atomically. | Defines exact transaction groups and post-commit signals. |
| `shop.md` | Relic flags are prior Shop purchases and Crown cannot sell emergency relics. | Crown reads relic flags only and never mutates them. |
| `dragon-progression.md` | Void dragon is a story grant using the standard dragon schema. | Routes Void creation through Dragon Progression helper inside Singularity transaction. |
| `input-router.md` | Crown and Counter flows remain d-pad plus confirm/cancel. | Keeps Counter as contextual `battle_defend` and Crown row navigation semantic. |

## Performance Implications

- **CPU**: Low during normal play; settlement paths are event-driven. Mirror Admin phase checks run only during battle resolution.
- **Memory**: Low; authored Resources and small payload/result objects.
- **Load Time**: Startup validation of SingularityData adds content validation cost, acceptable within Technical Setup.
- **Network**: None.

## Migration Plan

No implementation migration exists yet. When implementation begins:

1. Create typed SingularityData Resources and validate IDs.
2. Implement SingularityService with explicit dependency setup.
3. Wire Campaign Map activation/CROWN routing to SingularityService.
4. Route gatekeeper and Mirror Admin Battle settlement through SingularityService.
5. Add Save failure injection tests for corruption, Mirror Admin defeat/Void, and ending commits.

## Validation Criteria

- Corruption class never regresses and cannot skip persistence rules.
- SCAR lists are cumulative and commit atomically with corruption.
- Gatekeeper first victories set exactly one flag and one corruption advance.
- Mirror Admin phase checkpoints reload to the latest committed phase.
- `battle_defend` resolves Counter only inside `tritone_window`.
- Mirror Admin defeat commits `mirror_admin_defeated` and Void grant atomically.
- Crown with zero relics writes no state; Crown with relics writes only `ending_id`.
- Post-game Crown and Mirror Admin cannot reopen ending or battle flows.

## Related Decisions

- ADR-0001 Save Transaction Boundary
- ADR-0002 Semantic Event Contracts
- ADR-0003 Input Router Semantic Actions
- ADR-0004 Authored Content Resources
- ADR-0006 Dragon Data Model And Progression Services
- ADR-0007 Battle Runtime State Machine
- ADR-0008 Campaign Map Content And Reward Pipeline
- ADR-0009 Economy And Shop Transaction Boundaries
- ADR-0011 Corruption Rendering Pipeline
