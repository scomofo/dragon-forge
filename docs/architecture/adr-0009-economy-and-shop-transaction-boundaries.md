# ADR-0009: Economy And Shop Transaction Boundaries

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / UI Input / Resources |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/breaking-changes.md`; `docs/engine-reference/godot/deprecated-apis.md`; `docs/engine-reference/godot/modules/input.md`; `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior through ADR-0003/0005; callable signal connections; typed `Resource` catalog data through ADR-0004 |
| **Verification Required** | Verify purchase atomicity, no negative Scrap balance, expedition flag source-specific mutation, post-ending relic lockout, shop focus navigation, and rollback behavior under Save failure injection. |

Economy and Shop use typed data classes, transaction helpers, and Godot Control UI. They do not require physics, navigation servers, networking, or deprecated Godot 3 APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0006 Dragon Data Model And Progression Services; ADR-0007 Battle Runtime State Machine; ADR-0008 Campaign Map Content And Reward Pipeline |
| **Enables** | Shop implementation stories; Campaign Map reward settlement; Singularity Crown ending orchestration; economy/content lock artifact |
| **Blocks** | Any story implementing Scrap balance mutation, Shop purchases, expedition item flags, relic purchase flags, post-ending shop behavior, or OQ-SH01 tuning closure |
| **Ordering Note** | ADR-0009 must be Accepted before Shop, Hatchery Scrap-spend, Campaign Map reward, or Crown relic-check stories are generated. |

## Context

### Problem Statement

Dragon Forge has one durable currency, Data Scraps, and several systems that need to touch it: Campaign Map awards Scraps from battles, Shop spends Scraps on consumables and relics, Hatchery spends Scraps on pulls, and Singularity reads relic flags for endings. The Shop GDD also defines expedition item flags that are purchased in Shop but consumed or reset by Campaign Map and Battle settlement.

The project needs one binding economy boundary before implementation. Otherwise, purchase code, reward code, and item-use code may each edit `player_scraps` and expedition flags directly, creating partial transactions and ownership conflicts.

### Constraints

- Save / Persistence owns disk commit and rollback.
- Economy Ledger owns Scrap mutation helpers.
- Shop owns catalog, price validation, purchase state machine, normal relic purchases, and purchase-to-true expedition flag writes.
- Campaign Map owns battle reward source decisions, MAP_EXPLORE item use, Bulkhead departure resets, and defeat-return resets.
- Battle Engine never commits item flags directly; it reports Defrag Patch consumption in settlement.
- Singularity reads relic flags but never sells, discounts, grants, resets, or consumes relic flags.
- Post-ending relic availability is presentation-only; unowned relics cannot be purchased after `ending_id != ""`.
- OQ-SH01 remains provisional until ADR-0008's content/economy lock artifact exists.

### Requirements

- Define typed economy and shop result contracts.
- Ensure every Scrap mutation happens inside SaveTransaction.
- Ensure purchase transactions deduct Scraps and set the relevant flag atomically.
- Enforce `player_scraps >= 0`.
- Keep Shop from validating expedition-use conditions that belong to Campaign Map or Battle.
- Keep expedition item flag mutation source-specific and auditable.
- Keep relic flags one-way and non-Crown-purchasable.
- Support Save failure injection tests for purchase rollback.

## Decision

Economy is split into two layers:

1. `EconomyLedger`: a core transaction helper for `player_scraps` mutation.
2. `ShopService` and `ExpeditionInventoryLedger`: feature/core helpers for catalog purchases and expedition item flag mutation.

None of these helpers writes save files directly. They mutate only a staged `SaveTransaction`; Save / Persistence commits or rolls back the staged result.

### State Ownership

Economy Ledger owns the mutation rules for:

- `player_scraps`

Shop owns normal purchase authority for:

- `relic_wrench_owned`
- `relic_lens_owned`
- `relic_blade_owned`
- purchase-to-true transitions for `expedition_field_kit`
- purchase-to-true transitions for `expedition_defrag_patch`
- purchase-to-true transitions for `expedition_cache_shard`
- purchase-to-true transitions for `expedition_emergency_patch`

Expedition Inventory Ledger owns source-specific mutation helpers for expedition item flags:

- Shop may set flags to `true` through `purchase_expedition_item()`.
- Campaign Map may consume/reset map-owned flags through `consume_expedition_item()` and `reset_expedition_items()`.
- Battle never calls the ledger directly; Battle reports Defrag Patch consumption in `BattleDurableDelta`, and the encounter owner commits it through the ledger.

Relic flags are one-way. Once `true`, no system resets them.

### Authored Catalog Data

```gdscript
class_name ShopCatalog
extends Resource

@export var catalog_id: StringName
@export var items: Array[ShopItemDefinition]
```

```gdscript
class_name ShopItemDefinition
extends Resource

@export var item_id: StringName
@export var category: StringName
@export var price_scraps: int
@export var save_flag: StringName
@export var availability_rule_id: StringName
@export var purchase_limit: StringName
@export var use_context: StringName
@export var display_name_id: StringName
@export var description_id: StringName
```

Required item IDs for MVP:

- `field_kit`
- `defrag_patch`
- `cache_shard`
- `emergency_patch`
- `relic_wrench`
- `relic_lens`
- `relic_blade`

Catalog IDs, prices, save flags, and ending mappings are authored content and must be validated at boot/content-lock time. Custom authored Resources must initialize arrays/default fields safely, validate required IDs, and remain immutable during runtime play. Shop and economy runtime state must never be stored by mutating shared `.tres` catalog Resources.

### Economy Ledger API

```gdscript
class_name EconomyLedger
extends RefCounted

func get_scraps(snapshot: SaveSnapshot) -> int
func can_afford(snapshot: SaveSnapshot, amount: int) -> bool
func add_scraps(tx: SaveTransaction, amount: int, source_id: StringName) -> EconomyResult
func spend_scraps(tx: SaveTransaction, amount: int, sink_id: StringName) -> EconomyResult
```

```gdscript
class_name EconomyResult
extends RefCounted

var success: bool
var reason: StringName
var scraps_before: int
var scraps_after: int
var delta: int
var source_id: StringName
```

`add_scraps()` rejects negative amounts. `spend_scraps()` rejects negative amounts and any spend that would make `player_scraps < 0`.

### Expedition Inventory API

```gdscript
class_name ExpeditionInventoryLedger
extends RefCounted

func purchase_expedition_item(tx: SaveTransaction, flag_id: StringName, source_id: StringName) -> ExpeditionItemResult
func consume_expedition_item(tx: SaveTransaction, flag_id: StringName, source_id: StringName) -> ExpeditionItemResult
func reset_expedition_items(tx: SaveTransaction, source_id: StringName) -> ExpeditionItemResult
func is_in_pack(snapshot: SaveSnapshot, flag_id: StringName) -> bool
```

```gdscript
class_name ExpeditionItemResult
extends RefCounted

var success: bool
var reason: StringName
var flag_id: StringName
var value_before: bool
var value_after: bool
var source_id: StringName
```

Valid expedition flags are:

- `expedition_field_kit`
- `expedition_defrag_patch`
- `expedition_cache_shard`
- `expedition_emergency_patch`

The ledger must reject unknown flags. Source IDs must identify the caller path, such as `shop_purchase`, `campaign_map_use`, `campaign_map_departure_reset`, `campaign_map_defeat_reset`, or `battle_settlement_defrag_patch`.

### Shop Service API

```gdscript
class_name ShopService
extends RefCounted

signal purchase_committed(payload: PurchaseResultPayload)
signal purchase_rejected(payload: PurchaseResultPayload)

func get_catalog(snapshot: SaveSnapshot) -> Array[ShopItemDefinition]
func can_purchase(snapshot: SaveSnapshot, item_id: StringName) -> PurchaseCheckResult
func purchase(item_id: StringName) -> PurchaseCommitResult
```

```gdscript
class_name PurchaseCheckResult
extends RefCounted

var can_purchase: bool
var reason: StringName
var item_id: StringName
var price_scraps: int
var scraps_available: int
var projected_scraps: int
```

```gdscript
class_name PurchaseCommitResult
extends RefCounted

var success: bool
var reason: StringName
var item_id: StringName
var save_result: SaveCommitResult
var economy_result: EconomyResult
var flag_result: PurchaseFlagResult
```

```gdscript
class_name PurchaseFlagResult
extends RefCounted

var success: bool
var reason: StringName
var flag_id: StringName
var flag_kind: StringName
var value_before: bool
var value_after: bool
```

`purchase()` owns the whole purchase transaction:

1. Read immutable SaveSnapshot.
2. Validate catalog item exists.
3. Validate item availability:
   - Consumables visible whenever Shop is open.
   - Relics visible only if `acts_unlocked` contains 2 and `ending_id == ""`.
   - Unowned relics are not purchasable after `ending_id != ""`.
4. Validate purchase limit:
   - Expedition item already in pack returns `in_pack`.
   - Owned relic returns `already_owned`.
5. Validate Scrap affordability through Economy Ledger.
6. Begin SaveTransaction.
7. Call `EconomyLedger.spend_scraps()`.
8. For consumables, call `ExpeditionInventoryLedger.purchase_expedition_item()`.
9. For relics, set the relic flag through a Shop-owned transaction helper.
10. Commit through Save / Persistence.
11. Emit `purchase_committed(payload)` only after commit success.

If any step fails, no durable state changes. Failure presentation uses `purchase_rejected(payload)` or a returned failure result, not a committed-state event.

`ShopService` receives dependencies from bootstrap composition or explicit setup. It must not perform hardcoded `/root` singleton lookups inside purchase logic.

```gdscript
func configure(
        save_service: SaveService,
        catalog: ShopCatalog,
        economy_ledger: EconomyLedger,
        expedition_inventory: ExpeditionInventoryLedger
) -> void
```

Constructor injection or a setup payload from the owning Shop screen are both acceptable if tests can provide substitutes.

### Reward Sources

Campaign Map is the primary Scrap source for battle rewards. After validating Battle's echoed reward against authored encounter reward data per ADR-0008, it calls:

```gdscript
EconomyLedger.add_scraps(tx, settled_scraps_earned, source_id)
```

inside its Campaign settlement transaction from ADR-0008. Hatchery or future systems that spend Scraps must also use `EconomyLedger.spend_scraps()` inside their own transaction flows.

Battle Engine never calls `EconomyLedger`.

### Relics And Crown

Shop is the sole normal writer of relic ownership flags. Singularity reads them at Crown arrival and must not:

- Sell relics.
- Discount relics.
- Grant emergency relics.
- Consume relics when an ending resolves.
- Reset relic flags after post-game.

After `ending_id != ""`, unowned relic slots are hidden or archived/inert according to ending presentation. This is a Shop UI presentation state, not a change to the underlying relic flag contract.

### OQ-SH01 Tuning Boundary

ADR-0009 keeps `BOSS_SCRAP_BONUS` and `HAZARD_SCRAP_BONUS` provisional. Economy implementation may carry the authored fields and default estimates, but production balance lock requires:

- ADR-0008 map node/reward data.
- `docs/balance/economy-content-lock.md`.
- A verdict on whether Act 3/4 mandatory rewards make the cheapest relic reachable without dedicated farming.

Changing `BOSS_SCRAP_BONUS`, `HAZARD_SCRAP_BONUS`, Hatchery pull price, or relic prices requires updating that lock artifact and rerunning an economy/balance check.

## Alternatives Considered

### Alternative 1: Shop Owns All Economy State

- **Description**: Shop directly edits `player_scraps`, relic flags, expedition flags, and maybe reward intake.
- **Pros**: Simple for purchase UI.
- **Cons**: Campaign Map, Hatchery, and future systems also need Scrap mutation; Shop would become a hidden global economy authority.
- **Rejection Reason**: Data Scraps are shared currency and require a transaction helper independent of Shop UI.

### Alternative 2: Every System Edits Its Own Scrap Deltas

- **Description**: Campaign Map adds Scraps directly; Shop subtracts Scraps directly; Hatchery subtracts Scraps directly.
- **Pros**: Fewer shared APIs.
- **Cons**: Inconsistent affordability checks, negative-balance risk, partial transaction risk, and no central audit trail.
- **Rejection Reason**: Violates the ownership and commit-boundary pattern established by ADR-0001.

### Alternative 3: Economy Ledger Plus Source-Specific Shop/Inventory Helpers

- **Description**: Economy Ledger owns Scrap mutation rules; Shop owns purchase flow; Expedition Inventory Ledger owns item flag helper methods; Save / Persistence owns commit.
- **Pros**: Atomic, testable, reusable, and keeps Campaign Map/Battle/Singularity boundaries clean.
- **Cons**: More helper APIs and integration tests.
- **Rejection Reason**: Chosen.

## Consequences

### Positive

- Every Scrap mutation has one validation path.
- Shop purchases are atomic and rollback-safe.
- Expedition item flags no longer have ambiguous direct writers.
- Singularity Crown cannot accidentally create last-minute relic purchases.
- OQ-SH01 has a clear lock artifact and balance-review trigger.

### Negative

- Shop implementation depends on Economy Ledger and Expedition Inventory Ledger scaffolding.
- Existing GDD wording that says Campaign Map or Battle "writes" flags directly should be read as "requests a source-specific staged mutation through the owning helper."
- Additional result types are required for purchase and inventory state.

### Risks

- **Helper bypass**: A story may directly mutate `player_scraps` or an expedition flag.
  - **Mitigation**: Control manifest forbids direct currency/flag writes outside approved helpers; code review checks for this.
- **Post-ending relic drift**: Shop UI may hide relics by mutating flags.
  - **Mitigation**: Post-ending relic availability is presentation-only; flags remain unchanged.
- **Balance premature lock**: OQ-SH01 may be treated as solved by default bonus values.
  - **Mitigation**: Defaults remain provisional until economy-content lock and balance check.
- **Purchase event timing**: UI/audio may react to a purchase before commit success.
  - **Mitigation**: `purchase_committed` emits only after Save commit success; pre-commit UI uses local pending state only.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `shop.md` | Atomic purchases, fixed catalog, expedition flags, relic flags, insufficient funds, already-owned, post-ending relic behavior, and OQ-SH01. | Defines Shop catalog Resources, purchase API, Economy Ledger use, Expedition Inventory helpers, relic lockout, and OQ-SH01 balance boundary. |
| `campaign-map.md` | Campaign Map awards Scraps, consumes map items, resets expedition flags, and reads post-ending state. | Routes Scrap rewards through Economy Ledger and expedition item use/reset through source-specific helpers. |
| `battle-engine.md` | Defrag Patch is used during Battle TELEGRAPH but Battle must not commit durable state. | Battle reports consumption in settlement; encounter owner commits flag clear through Expedition Inventory Ledger. |
| `singularity.md` | Crown reads relic flags but cannot create emergency purchases or consume relics. | Makes Shop the sole normal relic writer and locks unowned relic purchase after `ending_id != ""`. |
| `save-persistence.md` | Purchases and reward changes must be atomic and rollback-safe. | Requires staged transaction mutation and post-commit purchase events. |
| `input-router.md` | Shop is gamepad-first with d-pad navigation, confirm/cancel, and no hover-only path. | Keeps ShopService separate from Control UI while requiring semantic input and SceneFlow focus behavior. |

## Performance Implications

- **CPU**: Low. Purchase checks and reward mutation are event-driven integer operations.
- **Memory**: Low. Catalog Resource and result payloads are small.
- **Load Time**: Minimal. Catalog validation runs during content validation.
- **Network**: None. MVP is local single-player.

## Migration Plan

No production economy implementation exists yet. Initial implementation should:

1. Add `EconomyLedger`, `ExpeditionInventoryLedger`, and named result classes.
2. Add typed `ShopCatalog` and `ShopItemDefinition` Resources with all seven MVP items.
3. Add Shop purchase transaction tests for consumables, relics, insufficient funds, in-pack, already-owned, and post-ending lockout.
4. Route Campaign Map reward settlement through `EconomyLedger.add_scraps()`.
5. Route Campaign Map item use/reset and Battle Defrag Patch settlement through `ExpeditionInventoryLedger`.
6. Add Save failure injection tests for `shop_purchase_commit`.
7. Create/update `docs/balance/economy-content-lock.md` when map node data exists.

## Validation Criteria

- `player_scraps` cannot become negative.
- `add_scraps()` rejects negative reward amounts.
- Purchase with exact balance succeeds and leaves `player_scraps = 0`.
- Purchase failure leaves both `player_scraps` and item/relic flags unchanged.
- Force-quit/failure injection during purchase cannot persist a partial purchase.
- Shop sets expedition flags only to `true` through purchase helper.
- Authored catalog Resource arrays/default values initialize safely and are not mutated at runtime.
- ShopService receives SaveService, catalog, EconomyLedger, and ExpeditionInventoryLedger through explicit setup or dependency injection.
- Campaign Map consumes Field Kit, Cache Shard, and Emergency Patch through expedition helper.
- Battle Defrag Patch consumption is committed by Campaign Map/Singularity settlement, not by Battle.
- Bulkhead departure and defeat-return reset all expedition item flags through expedition helper.
- Owned relic flags are never reset or consumed.
- Singularity Crown cannot create or discount relics.
- Unowned relics are not purchasable after `ending_id != ""`.
- Purchase semantic events emit only after Save commit success.
- OQ-SH01 remains open until the economy-content lock artifact and balance evidence exist.

## Related Decisions

- ADR-0001: Save Transaction Boundary
- ADR-0002: Semantic Event Contracts
- ADR-0003: Input Router Semantic Actions
- ADR-0004: Authored Content Resources
- ADR-0005: Godot Scene Flow And Autoload Boundaries
- ADR-0006: Dragon Data Model And Progression Services
- ADR-0007: Battle Runtime State Machine
- ADR-0008: Campaign Map Content And Reward Pipeline
- `docs/architecture/architecture.md`
- `design/gdd/shop.md`
- `design/gdd/campaign-map.md`
- `design/gdd/battle-engine.md`
- `design/gdd/singularity.md`
