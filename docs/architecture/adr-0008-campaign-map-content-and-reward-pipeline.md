# ADR-0008: Campaign Map Content And Reward Pipeline

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
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md`; `docs/engine-reference/godot/deprecated-apis.md`; `docs/engine-reference/godot/modules/input.md`; `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior through ADR-0003/0005; callable signal connections; typed `Resource` content through ADR-0004 |
| **Verification Required** | Validate authored node graph IDs, d-pad traversal/focus, Battle settlement commit ordering, map consumable transactions, Matrix stabilization latching, replay policy, and OQ-SH01 economy-data coverage before balance lock. |

Campaign Map uses ordinary GDScript control flow, typed Resources, and transaction helpers. It does not require physics, navigation servers, networking, or deprecated Godot 3 APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0006 Dragon Data Model And Progression Services; ADR-0007 Battle Runtime State Machine |
| **Enables** | ADR-0009 Economy And Shop Transaction Boundaries; Singularity Boss And Ending Orchestration ADR; Campaign Map implementation stories; economy/content lock artifact |
| **Blocks** | Any story implementing Campaign Map traversal, authored map data, expedition settlement, map consumables, Matrix stabilization, replay policy, or Campaign-to-Battle integration |
| **Ordering Note** | ADR-0008 must be Accepted before ADR-0009 finalizes economy ownership, because Shop OQ-SH01 depends on Campaign Map authored-node and reward-data boundaries. |

## Context

### Problem Statement

The Campaign Map GDD defines a fixed directed graph, expedition loadouts, battle rewards, node clearing, gates, map consumables, Matrix stabilization, Singularity handoffs, replay behavior, and an unresolved economy-tuning dependency for Shop OQ-SH01. Implementation needs one binding contract for authored node data, runtime traversal, battle settlement, durable map fields, and reward application.

Without this ADR, implementation stories may let Battle, Shop, Campaign Map, Dragon Progression, and Singularity each write parts of the same expedition result. That would violate the accepted save boundary, make reward failure cases hard to test, and leave the Scrap economy unable to produce reliable tuning data.

### Constraints

- Campaign Map must use Input Router semantic actions and SceneFlow transitions.
- Required node IDs, boss IDs, CROWN IDs, and resource references must be authored and startup-validated.
- Campaign Map owns map traversal, expedition party state, map-owned durable fields, final map rewards, and MAP_EXPLORE consumable use.
- Battle Engine owns raw combat math and emits settlement payloads; it does not commit rewards.
- Dragon Progression owns dragon XP, stage derivation, stats, and Resonance mutation helpers.
- Economy Ledger owns Scrap mutation helpers and must be used for all Scrap balance changes.
- Singularity owns `scar_nodes[]`, corruption class, gatekeeper flags, Mirror Admin flags, Void grant, and `ending_id`.
- Shop OQ-SH01 remains blocked until authored Act 3/4 node distribution and economy playtest or simulation data exist.

### Requirements

- Represent the Campaign Map as typed authored Resources or approved generated tables.
- Validate graph reachability, direction links, required node IDs, boss references, and protected Singularity IDs at boot/content-lock time.
- Keep traversal runtime state separate from authored node data.
- Settle battle results through a single SaveTransaction owned by Campaign Map or Singularity, not Battle.
- Apply over-level XP decay before calling Dragon Progression.
- Apply Scrap rewards through Economy Ledger.
- Apply map consumables through Campaign Map transaction helpers.
- Preserve replay policy and avoid first-clear milestone re-emission on replay.
- Produce a content/economy lock artifact before finalizing OQ-SH01 tuning.

## Decision

Campaign Map will be implemented as a feature-layer map screen/controller plus deterministic service logic. It is not a broad Autoload. The active map screen owns presentation and focus; the Campaign Map service/controller owns runtime traversal decisions and creates settlement transactions through Save / Persistence.

Authored map data is a typed Resource graph. Custom authored Resources must initialize arrays/default fields safely, validate required IDs through content validation, and remain immutable during runtime play. Runtime systems must never mutate shared `.tres` map Resources; all mutable traversal, reward, and presentation state lives in runtime objects or SaveTransaction staging.

```gdscript
class_name CampaignMapDefinition
extends Resource

@export var map_id: StringName
@export var start_node_id: StringName
@export var hub_return_node_id: StringName
@export var spine_access_node_id: StringName
@export var crown_node_id: StringName
@export var nodes: Array[CampaignNodeDefinition]
```

```gdscript
class_name CampaignNodeDefinition
extends Resource

@export var node_id: StringName
@export var act_id: int
@export var node_type: StringName
@export var display_name_id: StringName
@export var connections: Array[MapConnectionDefinition]
@export var enemy_element: StringName
@export var enemy_level: int
@export var battle_definition_id: StringName
@export var boss_id: StringName
@export var base_xp: int
@export var scrap_reward: int
@export var hazard_status_effect: StringName
@export var lore_fragment_id: StringName
@export var gate_requirement_id: StringName
@export var replay_reward_policy: StringName
```

```gdscript
class_name MapConnectionDefinition
extends Resource

@export var direction: StringName
@export var target_node_id: StringName
```

Node definitions are immutable authored content at runtime. Campaign Map runtime state is stored in typed runtime objects or SaveData fields, never by mutating node Resources.

Campaign Map owns these durable map fields through SaveTransaction:

- `current_node_id`
- `acts_unlocked[]`
- `unlocked_gates[]`
- `matrix_stabilized`
- `visited_nodes[]`
- `cleared_combat_nodes[]`
- `cleared_bosses[]` for non-Singularity map boss replay state only
- `loadout_hp[]`
- `previous_node_id`
- `expedition_xp_earned`
- `gate_denial_count{}`

Campaign Map reads but does not own:

- `scar_nodes[]`
- `corruption_class`
- `ending_id`
- Singularity gatekeeper and Mirror Admin milestone flags
- Shop relic ownership flags

### Runtime API

```gdscript
class_name CampaignMapController
extends Node

signal node_entered(payload: NodeEnteredPayload)
signal expedition_completed(payload: ExpeditionCompletedPayload)
signal matrix_stabilized(payload: MatrixStabilizedPayload)
signal map_reward_committed(payload: MapRewardCommittedPayload)

func enter_node(node_id: StringName) -> NodeEnterResult
func travel(direction: StringName) -> MapTravelResult
func begin_battle_for_node(node_id: StringName) -> BattleStartRequest
func settle_battle(payload: BattleEndedPayload, delta: BattleDurableDelta, context: CampaignBattleContext) -> CampaignSettlementResult
func use_map_consumable(item_id: StringName) -> ConsumableUseResult
func evaluate_matrix_stabilization(source_event: DragonProgressionEvent) -> MatrixStabilizationResult
```

```gdscript
class_name CampaignBattleContext
extends RefCounted

var node_id: StringName
var node_type: StringName
var battle_definition_id: StringName
var boss_id: StringName
var replay: bool
var source_screen_id: StringName
```

```gdscript
class_name CampaignSettlementResult
extends RefCounted

var success: bool
var reason: StringName
var save_result: SaveCommitResult
var xp_applied: int
var scraps_applied: int
var cleared_node_id: StringName
var returned_node_id: StringName
var emitted_payloads: Array[CampaignSettlementEventPayload]
```

```gdscript
class_name CampaignSettlementEventPayload
extends RefCounted

var event_id: StringName
var node_id: StringName
var boss_id: StringName
var source_system: StringName
var presentation_tags: Array[StringName]
```

Anonymous dictionaries are forbidden for Campaign Map runtime contracts.

### Battle Settlement

Campaign Map consumes `BattleEndedPayload` and `BattleDurableDelta` from ADR-0007. Battle completion is pre-commit runtime output. Campaign Map opens a SaveTransaction and applies the final outcome atomically:

On victory for COMBAT or HAZARD:

1. Apply `delta.player_hp_remaining` to `loadout_hp[0]`.
2. Compute final XP:

```text
xp_raw = payload.raw_xp_awarded
decay_mult = XP_DECAY_MULT if player_level > enemy_level + XP_DECAY_BAND else 1.0
xp_earned = max(1, floor(float(xp_raw) * decay_mult))
```

3. Call `DragonProgressionService.apply_xp(tx, active_dragon_id, xp_earned, source_id)`.
4. Call `DragonProgressionService.add_resonance_charge(tx, active_dragon_id, source_id)` only if `delta.active_resonance_eligible == true`.
5. Add passive bench Resonance through `DragonProgressionService.add_resonance_charge()` for loadout slots 2-3, subject to ADR-0006 caps.
6. Resolve `settled_scraps_earned` from authored node/boss reward data, validating any Battle echo against that value, then call `EconomyLedger.add_scraps(tx, settled_scraps_earned, source_id)`.
7. Add `node_id` to `cleared_combat_nodes[]` on first victory only.
8. Increment `expedition_xp_earned` by `xp_earned`.
9. Commit through Save / Persistence.
10. Emit map reward and node-clear semantic events only after commit success.

Scrap reward authority remains Campaign Map or Singularity authored encounter data. Battle may echo `payload.scraps_earned` from the `BattleDefinition` for presentation and traceability, but Campaign Map settlement must validate the value against the current node's authored `scrap_reward` or reward profile before applying it. If the Battle payload and authored encounter reward disagree, settlement fails with a typed mismatch result and no Scrap mutation occurs. Campaign Map must not accept an arbitrary Battle-provided Scrap amount as authoritative.

On victory for BOSS:

- Campaign Map may mark map-level replay state for generic BOSS nodes, but Singularity-owned gatekeeper/Mirror Admin flags remain Singularity-owned.
- Gatekeeper and Mirror Admin milestone settlement must go through Singularity's owning service, using the same Battle payload/delta and SaveTransaction rules.

On defeat:

1. Return `current_node_id` to `previous_node_id`.
2. Restore all `loadout_hp[]` entries to full HP derived from Dragon Progression stats.
3. Add passive bench Resonance through `DragonProgressionService.add_resonance_charge()` for loadout slots 2-3, because Campaign Map awards bench Resonance on every expedition battle, win or loss.
4. Reset `expedition_xp_earned` to 0 after applying the defeat penalty.
5. Reset all expedition item flags through the Economy/Expedition Inventory helper defined by ADR-0009.
6. Apply the XP defeat penalty through a Dragon Progression transaction helper, not direct `DragonRecord` mutation.
7. Commit through Save / Persistence before emitting defeat/return presentation events.

ADR-0008 requires Dragon Progression implementation stories to add a named penalty helper, such as:

```gdscript
func apply_xp_penalty(tx: SaveTransaction, dragon_id: StringName, xp_amount: int, source_id: StringName) -> XPApplyResult
```

The helper must never de-level a dragon and must clamp within-level XP at zero.

### Map Consumables

Campaign Map owns MAP_EXPLORE use for:

- Field Kit: full HP restore for all non-null loadout slots, identical to REST node recovery.
- Cache Shard: evaluate Shop-owned formula, call Dragon Progression only when `actual_xp > 0`, then consume the flag.
- Emergency Patch: restore slot-1 dragon to `max(1, floor(max_hp * EMERGENCY_PATCH_FACTOR))` if below that threshold.

Campaign Map must not directly set expedition flags. It calls the source-specific expedition inventory helper from ADR-0009:

- `consume_expedition_item(tx, &"expedition_field_kit", source_id)`
- `consume_expedition_item(tx, &"expedition_cache_shard", source_id)`
- `consume_expedition_item(tx, &"expedition_emergency_patch", source_id)`
- `reset_expedition_items(tx, source_id)` on Bulkhead departure and defeat-return

Defrag Patch remains a Battle TELEGRAPH action. Battle reports consumption in `BattleDurableDelta`; Campaign Map or Singularity commits the flag clear through ADR-0009 settlement helpers.

### Matrix Stabilization

Campaign Map owns `matrix_stabilized` and the Act 3 -> 4 Spine Access unlock. It listens to committed dragon acquisition/progression events, then evaluates whether the full roster contains at least one Fire, Ice, Storm, Stone, Venom, and Shadow dragon.

Godot signals are synchronous by default, so Matrix stabilization must not open a nested SaveTransaction directly from a post-commit signal handler. Preferred implementation folds Matrix stabilization evaluation into the same transaction as the dragon acquisition whenever the acquiring system can know the roster outcome. If evaluation must happen after a committed acquisition event, Campaign Map queues a guarded post-commit command with `call_deferred()` or an equivalent command queue, then opens a new transaction outside the original signal stack.

If the matrix changes from false to true in a normal gameplay transaction:

1. Set `matrix_stabilized = true`.
2. Add the Spine Access gate node ID to `unlocked_gates[]`.
3. Commit through Save / Persistence.
4. Emit `matrix_stabilized(payload)` after commit success.

Migration repairs may set `matrix_stabilized` silently without emitting presentation signals.

### Replay Policy

Replay battles are allowed for cleared COMBAT, HAZARD, and generic BOSS nodes according to Campaign Map GDD rules. Replay settlement must not:

- Remove existing cleared flags.
- Re-emit first-clear node-clear milestones.
- Re-advance Singularity corruption.
- Rewrite Singularity defeated flags.
- Re-open ending choice screens.

Replay rewards must be authored explicitly via `replay_reward_policy`. If no policy is authored, replay uses standard Battle raw payload but still passes through Campaign Map reward settlement and Economy Ledger.

### OQ-SH01 And Economy Lock

ADR-0008 does not finalize `BOSS_SCRAP_BONUS` or `HAZARD_SCRAP_BONUS`. It defines the data required to close OQ-SH01:

- Authored Act 3 and Act 4 mandatory-node distribution.
- Per-node `scrap_reward`, `base_xp`, `node_type`, and `boss_id`.
- Expected critical-path consumable spend.
- Expected Hatchery spend range before Act 3.
- Simulation or playtest report showing whether the cheapest relic is reachable without dedicated farming.
- Explicit pass threshold from Shop GDD: the Act 3 critical path must yield at least 200 Scraps surplus above normal consumable expenditure, validating that the cheapest relic is reachable without dedicated farming.

The required lock artifact is:

```text
docs/balance/economy-content-lock.md
```

The artifact must include an `ActRewardBudget` table and an OQ-SH01 verdict before production balance lock.

## Alternatives Considered

### Alternative 1: Campaign Map Applies All Outcomes Directly

- **Description**: Campaign Map edits `SaveData`, dragon XP, item flags, and Scrap fields directly after Battle.
- **Pros**: Fewer helper classes.
- **Cons**: Violates ADR-0001/0006/0009 boundaries; makes commit rollback and event timing fragile.
- **Rejection Reason**: Cross-system durable state must be staged through owners and transaction helpers.

### Alternative 2: Battle Engine Owns Post-Battle Rewards

- **Description**: Battle applies XP, Scraps, node clears, and boss flags after KO.
- **Pros**: Simple battle screen integration.
- **Cons**: Contradicts ADR-0007; Battle would need map, economy, progression, and Singularity authority.
- **Rejection Reason**: Battle owns raw math and runtime settlement only.

### Alternative 3: Authored Resource Graph With Campaign Settlement Orchestrator

- **Description**: Campaign Map owns authored node graph and final map settlement, while calling Dragon Progression, Economy Ledger, and Singularity helpers for owned state.
- **Pros**: Clear ownership, startup validation, deterministic tests, coherent reward commits, and explicit OQ-SH01 data path.
- **Cons**: Requires more named payloads and integration tests.
- **Rejection Reason**: Chosen.

## Consequences

### Positive

- Campaign Map stories have one authoritative graph schema and settlement path.
- OQ-SH01 now has a concrete data artifact instead of an open-ended tuning note.
- Battle, Dragon Progression, Economy, and Singularity boundaries remain intact.
- Replay behavior cannot accidentally re-fire first-clear or corruption milestones.
- Map traversal and focus behavior can be tested separately from reward settlement.

### Negative

- Campaign Map implementation must wait for transaction helpers from ADR-0006/0009.
- Graph validation tooling or tests are required before balance lock.
- Some approved GDD wording that says Campaign/Battle "writes" flags directly should be read as "requests the owning helper to mutate the staged transaction."

### Risks

- **Settlement omissions**: A map story may forget passive Resonance, HP carry, or expedition XP updates.
  - **Mitigation**: Campaign settlement tests must assert the full transaction delta for win, defeat, replay, and boss cases.
- **OQ-SH01 drift**: Designers may tune bonuses before authored node data exists.
  - **Mitigation**: Keep `BOSS_SCRAP_BONUS` and `HAZARD_SCRAP_BONUS` provisional until `docs/balance/economy-content-lock.md` exists.
- **Singularity ownership leak**: Campaign Map may try to write `scar_nodes[]`, `ending_id`, or gatekeeper flags.
  - **Mitigation**: Registry and control manifest ban these writes from Campaign Map.
- **Graph shortcut exploit**: Authored connections may let underleveled players reach high-level nodes.
  - **Mitigation**: Graph validation must check required progression ordering and report level-range shortcut risks.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `campaign-map.md` | Fixed directed node graph, node types, traversal, gates, replay prompts, loadout HP, expedition XP, Matrix stabilization, and map consumables. | Defines typed map Resources, runtime APIs, durable field ownership, settlement rules, replay rules, and map consumable transaction boundaries. |
| `battle-engine.md` | Battle emits raw result payload and leaves final rewards to Campaign Map/Singularity. | Consumes `BattleEndedPayload`/`BattleDurableDelta` and commits final map settlement after Save success. |
| `dragon-progression.md` | Campaign Map applies final XP and active/passive Resonance through Dragon Progression helpers. | Requires transaction helpers for XP grant, XP penalty, active Resonance, and passive bench Resonance. |
| `shop.md` | Field Kit, Cache Shard, Emergency Patch, Defrag Patch, and OQ-SH01 require clear use/reset ownership. | Defines map-owned consumable use, Defrag Patch settlement handoff, Bulkhead/defeat reset, and economy-content lock artifact. |
| `singularity.md` | Campaign Map hosts Spine BOSS and CROWN nodes but must not own Singularity milestones. | Separates map replay/node state from Singularity corruption, boss flags, Void grant, and ending ownership. |
| `save-persistence.md` | Durable map changes must be atomic and emit after commit. | Requires SaveTransaction settlement and post-commit semantic events. |
| `input-router.md` | Map traversal must support d-pad/confirm/cancel and no hover-only paths. | Keeps traversal through semantic directions/actions and SceneFlow focus rules. |

## Performance Implications

- **CPU**: Low. Traversal and settlement are event-driven; graph validation runs at boot/editor/content-lock time.
- **Memory**: Low to moderate. One authored map Resource graph of about 40-46 nodes plus runtime state.
- **Load Time**: Slightly higher due to graph/content validation; this is intentional and bounded.
- **Network**: None. MVP is local single-player.

## Migration Plan

No production Campaign Map runtime exists yet. Initial implementation should:

1. Add typed map Resources and graph validation tests.
2. Add Campaign Map runtime/controller classes with semantic input traversal.
3. Implement Battle start request generation from node definitions.
4. Implement Campaign battle settlement tests for victory, defeat, replay, and boss handoff.
5. Implement MAP_EXPLORE consumable use through ADR-0009 expedition inventory helpers.
6. Implement Matrix stabilization evaluation from committed dragon acquisition events.
7. Create `docs/balance/economy-content-lock.md` once authored Act 3/4 node distribution exists.

## Validation Criteria

- Required node IDs are unique and present.
- Authored map Resource arrays/default values initialize safely and are not mutated at runtime.
- Every connection targets an existing node and has a valid direction.
- Required BOSS and CROWN IDs match Singularity contracts.
- Protected Singularity node IDs are never added to Campaign-owned scar/write lists.
- Higher-level shortcut risks are detected by graph validation.
- First COMBAT/HAZARD victory marks `cleared_combat_nodes[]`; replay does not remove or re-emit first-clear events.
- Battle victory applies HP carry, XP decay, Dragon Progression XP, active Resonance, passive bench Resonance, Scrap addition, node clear, and `expedition_xp_earned` in one transaction.
- Battle settlement rejects mismatched Scrap rewards when Battle payload value disagrees with authored node/boss reward data.
- Battle defeat restores loadout HP, awards passive bench Resonance, applies non-deleveling XP penalty, resets expedition items, updates `current_node_id`, and emits defeat presentation only after commit.
- Passive bench Resonance is tested for win, loss, and mixed win/loss expedition sequences.
- Field Kit, Cache Shard, and Emergency Patch use cannot bypass transaction helpers.
- Defrag Patch consumption from Battle is committed by the encounter owner, not Battle.
- Matrix stabilization latches once, unlocks Spine Access, and emits after commit success.
- Matrix stabilization does not open a nested transaction synchronously inside a post-commit signal handler.
- Migration repair can set Matrix stabilization silently without presentation signals.
- OQ-SH01 remains open until the economy-content lock artifact exists.

## Related Decisions

- ADR-0001: Save Transaction Boundary
- ADR-0002: Semantic Event Contracts
- ADR-0003: Input Router Semantic Actions
- ADR-0004: Authored Content Resources
- ADR-0005: Godot Scene Flow And Autoload Boundaries
- ADR-0006: Dragon Data Model And Progression Services
- ADR-0007: Battle Runtime State Machine
- `docs/architecture/architecture.md`
- `design/gdd/campaign-map.md`
- `design/gdd/shop.md`
- `design/gdd/battle-engine.md`
- `design/gdd/singularity.md`
