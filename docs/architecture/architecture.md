# Dragon Forge - Master Architecture

## Document Status

- Version: 1.0
- Last Updated: 2026-05-26
- Engine: Godot 4.6
- Language: GDScript
- Target Platforms: PC desktop (Windows, macOS, Linux)
- Primary Input: Gamepad, with keyboard/mouse fallback
- Status: Technical Setup handoff draft - feasible with conditions
- Technical Director Sign-Off: 2026-05-26 - APPROVED WITH CONDITIONS
- Lead Programmer Feasibility: 2026-05-26 - FEASIBLE WITH CONDITIONS

## GDDs Covered

- `design/gdd/game-concept.md`
- `design/gdd/systems-index.md`
- `design/gdd/battle-engine.md`
- `design/gdd/campaign-map.md`
- `design/gdd/dragon-forge-hub.md`
- `design/gdd/dragon-progression.md`
- `design/gdd/fusion-engine.md`
- `design/gdd/hatchery.md`
- `design/gdd/shop.md`
- `design/gdd/singularity.md`
- `design/gdd/save-persistence.md`
- `design/gdd/input-router.md`
- `design/gdd/audio-director.md`
- `design/gdd/journal.md`

Armor System is listed in the systems index as Supporting / Not Started. It is excluded from binding MVP implementation architecture until its GDD exists.

## ADRs Referenced

- ADR-0001: Save Transaction Boundary
- ADR-0002: Semantic Event Contracts
- ADR-0003: Input Router Semantic Actions
- ADR-0004: Authored Content Resources
- ADR-0005: Godot Scene Flow And Autoload Boundaries
- ADR-0006: Dragon Data Model And Progression Services
- ADR-0007: Battle Runtime State Machine
- ADR-0008: Campaign Map Content And Reward Pipeline
- ADR-0009: Economy And Shop Transaction Boundaries
- ADR-0010: Singularity Boss And Ending Orchestration
- ADR-0011: Corruption Rendering Pipeline
- ADR-0012: Hatchery Pull Transaction And RNG Boundaries
- ADR-0013: Fusion Anvil Transaction Boundaries
- ADR-0014: Journal Console And Lore Delivery Resources
- ADR-0015: Audio Event Routing And Mix Ownership

## Engine Knowledge Gap Summary

Godot 4.6 is post-cutoff relative to the local LLM knowledge warning. Architecture and implementation agents must cross-reference `docs/engine-reference/godot/` before using affected APIs.

| Domain | Risk | Architecture Implication |
|---|---|---|
| UI / Input | HIGH | Godot 4.6 has separate mouse/touch focus and keyboard/gamepad focus. All custom Control focus behavior must be tested with gamepad and mouse separately. |
| Rendering | HIGH | Windows defaults to D3D12; glow occurs before tonemapping. Corruption/glitch effects must use verified 4.6 rendering settings and avoid manual viewport post-process chains where Compositor is appropriate. |
| Physics | HIGH | Jolt is the default 3D physics engine. Dragon Forge is primarily menu/map/combat driven, but any 3D hub or encounter movement must test collision edge cases against Jolt. |
| Resources | HIGH | Use `duplicate_deep()` for staged nested Resource copies in save transactions. Do not rely on shallow `duplicate()` for transactional `SaveData`. |
| Accessibility | MEDIUM | AccessKit screen-reader support and 4.6 Control behavior should inform UX and accessibility docs before sprint planning. |
| Audio | LOW | No major 4.4-4.6 API breaks; still use pooled players and buses. |
| Networking | LOW | No multiplayer architecture in MVP. |

## Technical Requirements Baseline

These TR IDs are provisional architecture IDs. `/architecture-review` should register stable IDs in `docs/architecture/tr-registry.yaml`.

| Req ID | GDD | System | Requirement | Domain |
|---|---|---|---|---|
| TR-save-001 | save-persistence.md | Save / Persistence | Persist all durable gameplay state through typed `SaveData` Resource. | Save |
| TR-save-002 | save-persistence.md | Save / Persistence | Multi-field durable changes use staged transactions with temp, backup, reload validation, and rollback. | Save |
| TR-save-003 | save-persistence.md | Save / Persistence | Commit-state signals fire only after save commit success. | Events |
| TR-input-001 | input-router.md | Input Router | Route hardware input into semantic actions; feature systems do not branch on raw device constants. | Input |
| TR-input-002 | input-router.md | Input Router | Hub, Shop, Campaign Map, Battle TELEGRAPH, Crown, and terminals are completable by d-pad plus confirm/cancel. | UX |
| TR-input-003 | input-router.md | Input Router | Preserve separate gamepad/keyboard focus and mouse hover behavior under Godot 4.6 dual focus. | UI |
| TR-data-001 | systems-index.md | Authored Data | Cross-system content with stable IDs is implemented as typed Resources or approved tables. | Data |
| TR-data-002 | campaign-map.md | Campaign Map | Fixed directed graph of about 40-46 authored nodes with node IDs, node types, connections, rewards, and gates. | Content |
| TR-data-003 | singularity.md | Singularity | SCAR nodes, protected nodes, boss definitions, phase profiles, and endings use stable IDs. | Content |
| TR-dragon-001 | dragon-progression.md | Dragon Progression | Own canonical dragon record schema, level progression, stat calculation, stages, shiny, `battle_charges`, and `is_elder`. | Simulation |
| TR-dragon-002 | dragon-progression.md | Dragon Progression | Expose `apply_xp()` and stat calculation APIs for Battle, Hatchery, Campaign Map, Fusion, and UI. | Simulation |
| TR-hatch-001 | hatchery.md | Hatchery | Implement egg pulls, pity counters, rarity, element soft pity, shiny protocol, and duplicate-dragon XP grants. | Simulation |
| TR-fusion-001 | fusion-engine.md | Fusion Engine | Fuse two dragons through inherited base stats, same-element bonus, cross-element HP penalty, and Elder flag generation. | Simulation |
| TR-fusion-002 | fusion-engine.md | Fusion Engine | Child creation is atomic with parent removal/retention rules and Save / Persistence transaction support. | Save |
| TR-battle-001 | battle-engine.md | Battle Engine | Implement five-phase 1v1 battle loop: INIT, TELEGRAPH, IMPACT, RECOIL, RESOLUTION. | Simulation |
| TR-battle-002 | battle-engine.md | Battle Engine | Implement canonical damage, type effectiveness, status, crit, defend, and Elder Stage IV multiplier formulas. | Simulation |
| TR-battle-003 | battle-engine.md | Battle Engine | Emit semantic battle result and presentation signals, including `raw_xp_awarded` and `scraps_earned`. | Events |
| TR-map-001 | campaign-map.md | Campaign Map | Own expedition party, current node, cleared nodes, act gates, map traversal, final XP decay, and Scrap increment. | Progression |
| TR-map-002 | campaign-map.md | Campaign Map | Handle REST recovery, defeat return, replay prompts, HAZARD behavior, and MAP_EXPLORE consumable use. | Progression |
| TR-shop-001 | shop.md | Shop | Own normal shop purchases, prices, item catalog, relic flags, and Unit 01 transaction flow. | Economy |
| TR-shop-002 | shop.md | Shop | Keep OQ-SH01 Scrap bonus tuning provisional until Campaign Map node/playtest data exists. | Economy |
| TR-sing-001 | singularity.md | Singularity | Own corruption class, SCAR nodes, gatekeeper flags, Mirror Admin phase state, Void grant, and `ending_id`. | Progression |
| TR-sing-002 | singularity.md | Singularity | Run Crown ending flow from relic ownership without emergency Crown purchases. | Progression |
| TR-journal-001 | journal.md | Journal / Console | Unlock and persist lore fragments and terminal read state from semantic milestones. | Narrative |
| TR-audio-001 | audio-director.md | Audio Director | Subscribe to semantic events and own buses, music, SFX, corruption mix, and tritone cues without gameplay authority. | Presentation |
| TR-hub-001 | dragon-forge-hub.md | Dragon Forge Hub | Own hub station navigation, presentation, roster display, Felix ambient behavior, Save Lantern entry, and Bulkhead departure. | Presentation |

## System Layer Map

| Layer | Modules | Rationale |
|---|---|---|
| Platform | Godot 4.6 runtime, OS file system, input devices, audio/rendering backends | External engine and platform APIs. Feature code must isolate direct dependency behind project modules where practical. |
| Foundation | Save / Persistence, Input Router, Semantic Events, Authored Content Loader, Scene Flow | Shared services and boundary rules used by every feature. |
| Core | Dragon Progression, Battle Engine, Hatchery, Fusion Engine, Economy Ledger | Deterministic simulation modules that own formulas and data mutations. |
| Feature | Campaign Map, Singularity, Shop, Journal / Console | Player-facing game systems that coordinate core modules and durable progression. |
| Presentation | Dragon Forge Hub, UI Screens, Audio Director, VFX/Corruption Rendering | Visual/audio/interaction layer that reflects state but does not own durable rules. |

### Layer Rules

- Dependencies point downward where possible: Presentation and Feature consume Core and Foundation services.
- Core modules must be deterministic and testable without scene presentation.
- Feature modules may orchestrate transactions and scenes, but durable writes go through Save / Persistence.
- Presentation modules may subscribe to events and call read APIs; they must not become hidden authorities for gameplay state.

## Module Ownership

### Foundation Layer

| Module | Owns | Exposes | Consumes | Godot APIs |
|---|---|---|---|---|
| Save / Persistence | `SaveData`, save slots, migrations, transaction staging, commit/rollback, backup files | `begin_transaction()`, `commit_transaction(tx)`, `load_slot()`, committed-state signals | Durable field mutation requests from feature/core systems | `Resource`, `ResourceSaver`, `ResourceLoader`, file/rename APIs, `duplicate_deep()` |
| Input Router | InputMap action definitions, active input mode, semantic action dispatch | `semantic_action(action_id)`, current input mode, focus utilities | Godot hardware input events | `InputMap`, `InputEvent`, `Control.grab_focus()`, `Input.start_joy_vibration()` |
| Semantic Events | Shared signal contract names and payload conventions | Typed signal signatures, stable payload schemas | Emitters from feature/core modules | Godot signals with callable connections |
| Authored Content Loader | Resource validation and ID registry for content tables | `get_*_definition(id)`, startup validation report | `.tres` Resources, approved GDD tables | `Resource`, typed arrays, preload/load |
| Scene Flow | Top-level scene transitions and boot order | `change_screen(screen_id)`, boot milestones | Save state, input mode, content validation | `SceneTree`, `PackedScene.instantiate()` |

### Core Layer

| Module | Owns | Exposes | Consumes | Godot APIs |
|---|---|---|---|---|
| Dragon Progression | Dragon schema, base stats, level/stage progression, `battle_charges`, `is_elder` schema | `calculate_stats(dragon)`, `apply_xp(dragon_id, amount)` | Save transaction access, Fusion child data, Campaign Map XP application | Plain GDScript Resources/data objects |
| Battle Engine | Turn state machine, damage/status formulas, NPC action selection, raw rewards, battle animation manifest lookup | `start_battle(definition)`, `turn_resolved`, `battle_ended` | Dragon stats, Shop consumable definitions, Input Router actions, Singularity boss profiles, `BattleAnimationManifest` | Scene-local Nodes, signals, timers, typed Resources |
| Hatchery | Pull rates, pity counters, element soft pity, duplicate handling, shiny roll | `pull_egg(count)`, result signals | Save transactions, Dragon Progression `apply_xp()` | RandomNumberGenerator, Resources |
| Fusion Engine | Parent validation, inherited base stats, same/cross-element modifiers, Elder creation | `can_fuse()`, `preview_fusion()`, `commit_fusion()` | Dragon Progression base stats, Save transaction, Audio events | Resources, signals |
| Economy Ledger | Shared Scrap balance mutation rules | `add_scraps()`, `spend_scraps()` via transaction helpers | Campaign Map rewards, Shop purchase requests | Save transaction helpers |

### Feature Layer

| Module | Owns | Exposes | Consumes | Godot APIs |
|---|---|---|---|---|
| Campaign Map | Node traversal, expedition party, cleared nodes, gate checks, final XP decay, Scrap reward application | `enter_node(node_id)`, `return_to_hub()`, map state signals | Battle Engine, Dragon Progression, Shop consumables, Singularity read APIs | Control/Node2D map scene, typed node Resources |
| Singularity | Corruption class, SCAR nodes, gatekeeper flags, Mirror Admin phases, Void grant, Crown flow, `ending_id` | `can_access_mirror_admin()`, `can_attempt_ending()`, corruption/ending signals | Campaign Map, Battle Engine, Shop relic flags, Save transactions | Resources, signals, timers |
| Shop | Catalog, prices, normal relic purchase flags, Unit 01 shop flow | `open_shop()`, `purchase(item_id)`, purchase result signals | Economy Ledger, Save transactions, Campaign Map item-use flags | Control UI, Resources |
| Journal / Console | Fragment unlocks, read state, terminal routing | `unlock_fragment(fragment_id)`, `mark_read(id)` | Singularity/Campaign milestones, Save transactions | Control UI, Resources |

### Presentation Layer

| Module | Owns | Exposes | Consumes | Godot APIs |
|---|---|---|---|---|
| Dragon Forge Hub | Station row, roster display, Save Lantern presentation, Felix ambient state, Bulkhead entry | Screen navigation signals and presentation readouts | Save read APIs, Input Router, Campaign Map entry | Control, Node2D/3D, AnimationPlayer |
| Audio Director | Buses, music, SFX pools, corruption mix, voice processing, tritone cue playback | Audio event completion signals | Semantic events from all systems | `AudioServer`, `AudioStreamPlayer`, Tweens |
| UI Screens | Battle UI, Shop UI, Map UI, Crown UI, Journal UI | Focus maps, disabled states, confirmation dialogs | Input Router, feature read APIs | Godot `Control`, themes, localization |
| VFX / Corruption Rendering | Pixel/CRT/corruption visual profiles | Presentation profiles by corruption class | Singularity/Campaign events | WorldEnvironment, Compositor, shaders |

## Dependency Diagram

```text
Platform: Godot 4.6 / OS / devices
        |
Foundation: Save + Input + Events + Content + Scene Flow
        |
Core: Dragon Progression + Battle + Hatchery + Fusion + Economy
        |
Feature: Campaign Map + Singularity + Shop + Journal
        |
Presentation: Hub + UI + Audio + VFX
```

Important cross-layer exceptions:

- Input Router sends semantic actions upward to active screens.
- Save / Persistence emits committed-state signals upward after successful commits.
- Audio Director and UI subscribe to semantic events from Core and Feature layers but do not feed authority back into gameplay.

## Data Flow

### Boot And Initialization

```text
Game boot
  -> Engine loads project settings and InputMap
  -> Authored Content Loader validates Resources and stable IDs
  -> Save / Persistence loads selected SaveData or creates a new default SaveData
  -> Scene Flow opens Dragon Forge Hub
  -> Input Router establishes active input mode and first focused Control
  -> Hub renders stations, roster, Felix ambient state, and Save Lantern availability
```

Blocking startup errors:

- Missing required content IDs referenced by save data or approved GDD contracts.
- Invalid `SaveData` migration that cannot repair required fields.

Non-blocking startup warnings:

- Missing optional audio cue.
- Draft prose content for non-critical lore entries.

### Frame/Input Path

```text
Hardware input
  -> Godot InputEvent/InputMap
  -> Input Router maps to semantic action
  -> Active screen or feature state consumes action
  -> Feature/Core module validates state transition
  -> Presentation updates from returned result or semantic event
```

Feature systems must never branch on raw controller button constants. `battle_defend` is the canonical action for Singularity Counter during a `tritone_window`.

### Battle Path

```text
Campaign Map or Singularity requests battle
  -> Battle Engine initializes combatants from Dragon Progression stats and battle definition
  -> Battle UI resolves actor/action clips through BattleAnimationManifest
  -> Input Router supplies TELEGRAPH action
  -> Battle Engine resolves IMPACT/RECOIL/RESOLUTION
  -> Battle Engine emits presentation signals during turn resolution
  -> Battle Engine emits battle_ended(victory, raw_xp_awarded, scraps_earned, player_hp_remaining, player_level_start, enemy_level)
  -> Campaign Map or Singularity applies authoritative post-battle progression in a SaveTransaction
```

Battle Engine owns raw combat math. Campaign Map owns final expedition XP decay and Scrap increment for map encounters. Singularity owns gatekeeper/Mirror Admin milestone state.

### Save/Commit Path

```text
Feature/Core module requests durable change
  -> Save / Persistence begins SaveTransaction from deep duplicate of SaveData
  -> Requesting module mutates staged copy through approved transaction interface
  -> Save / Persistence validates schema and ownership rules
  -> Save / Persistence writes temp file, verifies, backs up previous canonical save, renames, reload-validates
  -> On success: committed-state signals fire
  -> On failure: pre-transaction save remains authoritative and failure result returns
```

Durable-state signals must not fire before commit success.

### Crown Ending Path

```text
Campaign Map enters CROWN node
  -> Singularity checks mirror_admin_defeated and Shop-owned relic flags
  -> Zero relics: denial text, return to MAP_EXPLORE, no ending_id write
  -> One relic: auto-select matching ending
  -> Multiple relics: Crown UI presents owned relic choices
  -> Singularity commits ending_id through Save / Persistence
  -> ending_resolved(ending_id) fires after commit
  -> Campaign Map derives MAP_FREE_ROAM from ending_id
  -> Journal / Console and Audio Director update presentation
```

No module other than Singularity writes `ending_id`.

## API Boundaries

All APIs below are architecture contracts, not final implementation signatures. Implementation stories may split classes, but must preserve ownership and invariants.

### Named Payload Schemas

Semantic signals must use named payload schemas even if the first implementation stores them as typed Resources or typed GDScript classes wrapping dictionaries. Raw anonymous `Dictionary` payloads are not sufficient for story handoff.

| Payload | Required Fields | Producer | Consumers |
|---|---|---|---|
| `SemanticActionPayload` | `action_id: StringName`, `context_id: StringName`, `source_mode: StringName`, `pressed: bool` | Input Router | Active screen/feature |
| `SaveCommitResult` | `success: bool`, `reason: StringName`, `slot_id: int`, `changed_fields: Array[StringName]`, `error_message: String` | Save / Persistence | All transaction callers |
| `BattleEndedPayload` | `victory: bool`, `raw_xp_awarded: int`, `scraps_earned: int`, `player_hp_remaining: int`, `player_level_start: int`, `enemy_level: int` | Battle Engine | Campaign Map, Singularity |
| `TurnResolvedPayload` | `turn_index: int`, `player_action: StringName`, `enemy_action: StringName`, `damage_to_player: int`, `damage_to_enemy: int`, `status_events: Array[StringName]` | Battle Engine | Battle UI, Audio Director |
| `CorruptionChangedPayload` | `old_class: StringName`, `new_class: StringName`, `trigger_source: StringName`, `boss_id: StringName`, `phase_from: StringName`, `phase_to: StringName`, `is_phase_skip: bool`, `transition_beat_id: StringName` | Singularity | Campaign Map, Audio Director, UI |
| `MirrorPhasePayload` | `phase_from: StringName`, `phase_to: StringName`, `current_hp: int`, `threshold_hp: int`, `is_phase_skip: bool` | Singularity | Battle UI, Audio Director |
| `TritoneCounterPayload` | `target_pitch_id: StringName`, `counter_pitch_id: StringName`, `damage: int`, `skipped_admin_action: StringName` | Singularity | Battle UI, Audio Director |
| `NodeEnteredPayload` | `node_id: StringName`, `node_type: StringName`, `act_id: StringName`, `first_visit: bool`, `corruption_class: StringName` | Campaign Map | UI, Audio Director, Journal / Console |
| `ExpeditionCompletedPayload` | `outcome: StringName`, `current_node_id: StringName`, `scraps_delta: int`, `xp_delta: int`, `return_reason: StringName` | Campaign Map | Hub, Save / Persistence, UI |
| `PurchaseResultPayload` | `item_id: StringName`, `success: bool`, `reason: StringName`, `scraps_before: int`, `scraps_after: int` | Shop | Shop UI, Audio Director |
| `PresentationEventPayload` | `event_id: StringName`, `source_system: StringName`, `subject_id: StringName`, `tags: Array[StringName]` | Core/Feature systems | UI, Audio Director, VFX |

Story authors should reference these payload names directly. If a payload needs a new field, update this architecture or its owning ADR before stories rely on it.

### Save / Persistence

```gdscript
class_name SaveService

signal save_committed(result: SaveCommitResult)
signal save_failed(result: SaveCommitResult)

func begin_transaction(reason: StringName) -> SaveTransaction
func commit_transaction(tx: SaveTransaction) -> SaveCommitResult
func get_snapshot() -> SaveSnapshot
func load_slot(slot_id: int) -> SaveLoadResult
func migrate_save_data(data: SaveData, from_version: int, to_version: int) -> SaveMigrationResult
func validate_transaction(tx: SaveTransaction) -> SaveValidationResult
```

Invariants:

- `SaveData` is the only durable schema.
- Transaction staging must use deep duplication for nested Resource data.
- `get_snapshot()` returns immutable/read-only projection data, not a mutable `SaveData` Resource reference.
- Only `SaveTransaction` may expose staged mutable `SaveData`, and only before commit.
- Transaction validation must check field ownership before disk write.
- Migration hooks must run before gameplay systems observe loaded save data.
- Failed commits must not mutate the canonical save.
- File failure results must distinguish serialization, temp write, backup rename, canonical rename, and reload validation failures.
- Release exports must exclude debug failure injection hooks.

### Input Router

```gdscript
class_name InputRouter

signal semantic_action(payload: SemanticActionPayload)
signal input_mode_changed(mode: StringName)

func is_action_enabled(action_id: StringName) -> bool
func set_context(context_id: StringName) -> void
func request_focus(control: Control) -> void
```

Invariants:

- Public action IDs are `StringName`.
- Screens consume semantic actions, not device buttons.
- Gamepad/keyboard focus and mouse hover are tested separately under Godot 4.6.

### Scene Flow

```gdscript
class_name SceneFlowService

signal screen_changed(screen_id: StringName)
signal boot_step_completed(step_id: StringName)

func boot() -> BootResult
func change_screen(screen_id: StringName, payload: Variant = null) -> SceneChangeResult
func get_active_screen_id() -> StringName
func register_screen(screen_id: StringName, scene: PackedScene) -> void
```

Invariants:

- Scene Flow owns top-level screen changes; feature systems request transitions instead of instantiating arbitrary root scenes.
- Foundation services boot before feature screens: content validation, save load/migration, input context, then first screen.
- Autoload services must be limited to foundation services or intentionally global read-only registries.
- Feature scenes receive dependencies through service references or scene setup payloads, not hardcoded child-path lookups into unrelated modules.

### Authored Content Loader

```gdscript
class_name ContentRegistry

signal content_validation_failed(report: ContentValidationReport)

func load_all() -> ContentValidationReport
func get_definition(collection_id: StringName, item_id: StringName) -> Resource
func has_definition(collection_id: StringName, item_id: StringName) -> bool
func validate_required_ids(required_ids: Array[StringName]) -> ContentValidationReport
```

Invariants:

- Runtime logic references stable IDs, not display text.
- Required content IDs must be validated before the first playable screen.
- Missing required IDs are startup blockers; missing optional presentation assets are warnings with fallbacks.
- Stable IDs used in save data cannot be renamed without a migration.

### Economy Ledger

```gdscript
class_name EconomyLedger

func get_scraps(snapshot: SaveSnapshot) -> int
func add_scraps(tx: SaveTransaction, amount: int, source_id: StringName) -> EconomyResult
func spend_scraps(tx: SaveTransaction, amount: int, sink_id: StringName) -> EconomyResult
func can_afford(snapshot: SaveSnapshot, amount: int) -> bool
```

Invariants:

- Economy Ledger is a transaction helper, not an independent save writer.
- All Scrap mutations occur inside Save / Persistence transactions.
- Shop owns purchase sinks; Campaign Map owns battle reward sources.
- OQ-SH01 boss/hazard bonus tuning remains provisional until the economy/content lock artifact exists.

### Dragon Progression

```gdscript
class_name DragonProgressionService

signal stats_updated(dragon_id: StringName)
signal stage_advanced(dragon_id: StringName, from_stage: int, to_stage: int)

func calculate_stats(dragon: DragonRecord) -> DragonStats
func apply_xp(tx: SaveTransaction, dragon_id: StringName, amount: int) -> XPApplyResult
func xp_threshold_for(level: int) -> int
```

Invariants:

- `battle_charges` is the canonical Resonance field.
- `is_elder` is schema state set by Fusion Engine and consumed by Battle Engine.
- Void uses story-roster rules and cannot be generated by Hatchery or Fusion.

### Battle Engine

```gdscript
class_name BattleEngine

signal turn_resolved(payload: TurnResolvedPayload)
signal battle_ended(payload: BattleEndedPayload)
signal presentation_event(payload: PresentationEventPayload)

func start_battle(definition: BattleDefinition) -> void
func submit_action(action_id: StringName) -> BattleActionResult
```

`battle_ended` payload must include:

- `victory: bool`
- `raw_xp_awarded: int`
- `scraps_earned: int`
- `player_hp_remaining: int`
- `player_level_start: int`
- `enemy_level: int`

Invariants:

- Battle Engine does not apply Campaign Map over-level XP decay.
- Battle Engine does not finalize expedition Scrap balance.
- Elder Stage IV multiplier uses `ELDER_STAGE_MULT` when `is_elder == true` and level is 50+.
- Story handoff must use `BattleEndedPayload`, `TurnResolvedPayload`, and named presentation payload schemas.
- `BattleDefinition.animation_manifest_id` plus `MoveDefinition` IDs must resolve through `BattleAnimationManifest`; runtime code must not branch on move names to choose sprite paths.

### Campaign Map

```gdscript
class_name CampaignMapService

signal node_entered(node_id: StringName)
signal expedition_completed(payload: ExpeditionCompletedPayload)
signal matrix_stabilized()

func enter_node(node_id: StringName) -> NodeEnterResult
func apply_battle_result(payload: BattleEndedPayload) -> SaveCommitResult
func use_map_consumable(item_id: StringName) -> ConsumableUseResult
```

Invariants:

- `current_node_id`, expedition flags, cleared combat nodes, and final map rewards are Campaign Map-owned.
- `ending_id` and `scar_nodes[]` are read from Singularity-owned state.
- Field Kit, Cache Shard, and Emergency Patch MAP_EXPLORE use is Campaign Map-owned; Defrag Patch battle use is Battle Engine-owned.
- Story handoff must use named Campaign Map payload schemas for expedition results and node-entry presentation.

### Singularity

```gdscript
class_name SingularityService

signal corruption_class_changed(payload: CorruptionChangedPayload)
signal gatekeeper_defeated(boss_id: StringName)
signal mirror_admin_phase_changed(payload: MirrorPhasePayload)
signal mirror_admin_defeated()
signal ending_resolved(ending_id: StringName)
signal tritone_window_changed(is_open: bool, reason: StringName)
signal tritone_counter_resolved(payload: TritoneCounterPayload)

func can_access_mirror_admin() -> bool
func can_attempt_ending() -> bool
func resolve_ending(relic_id: StringName) -> SaveCommitResult
func get_scar_nodes_for_class(corruption_class: StringName) -> Array[StringName]
```

Invariants:

- Singularity is the only writer of `ending_id`.
- Shop is the only normal writer of relic ownership flags.
- Mirror Admin is a continuous encounter; phase changes must not emit final `battle_ended` until final KO or player defeat.
- Corruption, phase, and tritone signals must use the named payload schemas above.

### Shop

```gdscript
class_name ShopService

signal purchase_committed(item_id: StringName)
signal purchase_rejected(item_id: StringName, reason: StringName)

func get_catalog() -> Array[ShopItemDefinition]
func can_purchase(item_id: StringName) -> PurchaseCheck
func purchase(item_id: StringName) -> SaveCommitResult
```

Invariants:

- Shop owns catalog prices and normal relic purchase flags.
- Post-ending relic availability is presentation-only unless a later ADR changes it.
- OQ-SH01 tuning cannot be finalized from provisional estimates.
- Purchase result UI/audio should consume `PurchaseResultPayload`.

### Audio Director

```gdscript
class_name AudioDirector

signal audio_event_complete(event_id: StringName)

func handle_event(payload: PresentationEventPayload) -> void
func set_bus_volume(bus_id: StringName, volume_db: float) -> void
func apply_corruption_mix(corruption_class: StringName) -> void
```

Invariants:

- Audio may reflect state but never author gameplay state.
- Muted buses or missing cue assets must not block progression.
- SFX players are pooled.

## ADR Audit

| ADR | Engine Compatibility | Version Recorded | GDD Linkage | Conflict With This Architecture | Valid |
|---|---|---|---|---|---|
| ADR-0001 Save Transaction Boundary | Partial | Context references Godot 4.6 and `duplicate_deep()` | Yes | None | Yes |
| ADR-0002 Semantic Event Contracts | Partial | Context references approved GDDs; engine version implicit | Yes | None | Yes |
| ADR-0003 Input Router Semantic Actions | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0004 Authored Content Resources | Partial | Godot Resource explicit; version implicit | Yes | None | Yes |
| ADR-0005 Godot Scene Flow And Autoload Boundaries | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0006 Dragon Data Model And Progression Services | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0007 Battle Runtime State Machine | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0008 Campaign Map Content And Reward Pipeline | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0009 Economy And Shop Transaction Boundaries | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0010 Singularity Boss And Ending Orchestration | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0011 Corruption Rendering Pipeline | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0012 Hatchery Pull Transaction And RNG Boundaries | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0013 Fusion Anvil Transaction Boundaries | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0014 Journal Console And Lore Delivery Resources | Yes | Godot 4.6 explicit | Yes | None | Yes |
| ADR-0015 Audio Event Routing And Mix Ownership | Yes | Godot 4.6 explicit | Yes | None | Yes |

Audit notes:

- ADRs are Accepted and align with the current control manifest through ADR-0015.
- ADR-0001 through ADR-0004 have been retrofitted with explicit "Engine Compatibility" and "ADR Dependencies" sections after the initial technical-setup gate.
- The architecture registry now covers the required Foundation/Core Campaign/Economy/Singularity/Rendering/Hatchery/Fusion/Journal/Audio ADRs through ADR-0015.
- Lead Programmer feasibility review found the blueprint implementable only after the blocking ADRs below are accepted and stable TR IDs are registered; the ADR acceptance portion is complete through ADR-0015.

## Required ADRs

Must have before coding starts:

1. `/architecture-decision "Godot Scene Flow And Autoload Boundaries"` - Accepted as ADR-0005
   - Defines scene root, Autoload services, startup validation, screen transition ownership, and service access pattern.
   - Covers TR-save-001, TR-input-001, TR-data-001, TR-hub-001.

2. `/architecture-decision "Dragon Data Model And Progression Services"` - Accepted as ADR-0006
   - Defines `DragonRecord`, `DragonStats`, roster ownership, stat calculation, XP application, `battle_charges`, and `is_elder` service boundaries.
   - Covers TR-dragon-001, TR-dragon-002, TR-hatch-001, TR-fusion-001, TR-battle-002.

3. `/architecture-decision "Battle Runtime State Machine"` - Accepted as ADR-0007
   - Defines how Battle Engine represents INIT/TELEGRAPH/IMPACT/RECOIL/RESOLUTION, input handoff, timers, result payloads, and Singularity continuous-boss integration.
   - Covers TR-battle-001, TR-battle-002, TR-battle-003, TR-sing-001.

4. `/architecture-decision "Campaign Map Content And Reward Pipeline"` - Accepted as ADR-0008
   - Defines authored node Resource schema, map traversal service, reward application, replay policy, HAZARD data, and Shop OQ-SH01 blocked tuning data needs.
   - Covers TR-data-002, TR-map-001, TR-map-002, TR-shop-002.

5. `/architecture-decision "Economy And Shop Transaction Boundaries"` - Accepted as ADR-0009
   - Defines Data Scrap ledger, Shop purchase transaction flow, item-use ownership, relic flags, and post-ending shop presentation constraints.
   - Covers TR-shop-001, TR-shop-002, TR-sing-002.

6. `/architecture-decision "Singularity Boss And Ending Orchestration"` - Accepted as ADR-0010
   - Defines activation from Matrix stabilization, corruption/SCAR settlement, gatekeeper settlement, Mirror Admin phase checkpoints, Void grant, Crown ending resolution, and `ending_id` ownership.
   - Covers TR-sing-001, TR-sing-002, TR-data-003, TR-battle-003.

7. `/architecture-decision "Corruption Rendering Pipeline"` - Accepted as ADR-0011
   - Defines presentation-only corruption profiles, renderer fallback rules, HUD layering, SCAR visuals, restored gold-code overlays, and accessibility/performance validation.
   - Covers TR-sing-005.

8. `/architecture-decision "Hatchery Pull Transaction And RNG Boundaries"` - Accepted as ADR-0012
   - Defines HatcheryService, authored pull tables, transaction-scoped RNG, pity mutation, EconomyLedger spend, and Dragon Progression creation/duplicate XP boundaries.
   - Covers TR-hatch-001 and TR-hatch-002.

9. `/architecture-decision "Fusion Anvil Transaction Boundaries"` - Accepted as ADR-0013
   - Defines FusionService preview/commit boundaries, shared formula path, child creation, and parent retention/removal transaction rules.
   - Covers TR-fusion-001 and TR-fusion-002.

10. `/architecture-decision "Journal Console And Lore Delivery Resources"` - Accepted as ADR-0014
   - Defines JournalService, JournalLibrary Resources, fragment/terminal IDs, milestone unlocks, and read-state ownership.
   - Covers TR-journal-001 and TR-journal-002.

11. `/architecture-decision "Audio Event Routing And Mix Ownership"` - Accepted as ADR-0015
   - Defines AudioDirectorService, AudioLibrary Resources, cue pools, bus/mix ownership, tritone cue routing, and non-blocking audio behavior.
   - Covers TR-audio-001 and TR-audio-002.

Should have before the relevant system is built:

- `/architecture-decision "Testing Architecture For Godot GUT"`
- `/architecture-decision "Accessibility And Localization Baseline"`

Can defer until the GDD exists:

- `/architecture-decision "Armor System Runtime Boundaries"`

## Architecture Principles

1. Durable state has one authority.
   Systems may request state changes, but Save / Persistence owns commit semantics and disk writes.

2. Simulation stays deterministic and presentation-light.
   Battle, Dragon Progression, Hatchery, Fusion, and economy rules should be unit-testable without UI or audio.

3. Events carry game meaning, not implementation accidents.
   Signals use stable IDs and semantic payloads. UI widget names, localized strings, and raw input devices are not gameplay contracts.

4. Authored content is data, not scattered code.
   Cross-system IDs, node definitions, item catalogs, boss profiles, endings, and lore fragments need typed Resources or approved generated tables.

5. Gamepad-first means every required path has an explicit focus path.
   Mouse hover may enrich UI, but it cannot be the only way to complete gameplay.

## Open Questions

| ID | Summary | Priority | Resolution Path |
|---|---|---|---|
| AQ-01 | `production/stage.txt` has been corrected to Pre-Production; epics/stories/sprint tracker are still absent. | Medium | Complete vertical slice validation before creating epics/stories and sprint plan. |
| AQ-02 | Shop OQ-SH01 needs authored Campaign Map node distribution and playtest/simulation economy data. | High | Campaign Map content/reward ADR plus economy/content lock artifact. |
| AQ-03 | Single-active-dragon carry may dominate roster play. | Medium | Balance simulation/playtest after Dragon Data and Campaign Map reward architecture exists. |
| AQ-04 | Cross-element Fusion may be dominated by same-element Fusion. | Medium | Fusion/battle simulation or tuning ADR before Fusion implementation lock. |
| AQ-05 | Armor System lacks a GDD. | Low | Run `/design-system retrofit design/gdd/armor-system.md` before including Armor in MVP architecture or stories. |

## Lead Programmer Feasibility Review

Verdict: FEASIBLE WITH CONDITIONS.

Required conditions before pre-production story generation:

- Accept the seven "Must have before coding starts" ADRs listed in Required ADRs. Completed: ADR-0005 through ADR-0011 are Accepted.
- Rerun `/architecture-review` to refresh stable TR IDs in `docs/architecture/tr-registry.yaml` after ADR-0010/0011 and GDD wording remediations.
- Define Scene Flow / Autoload / dependency-injection rules through the Scene Flow ADR.
- Preserve the hardened Save API contract: immutable snapshots for reads, staged transaction mutation for writes, ownership validation, migration hooks, and explicit file failure results.
- Use named event payload schemas instead of anonymous `Dictionary` contracts at story handoff.
- Keep explicit API boundaries for Authored Content Loader and Economy Ledger.

Advisory notes:

- Godot 4.6 assumptions are aligned with local engine references.
- Existing accepted ADRs are consistent with the control manifest, and ADR-0001 through ADR-0004 now include explicit Engine Compatibility and ADR Dependencies sections.
- Armor exclusion is acceptable for MVP until its GDD exists.
- `production/stage.txt` now reflects Pre-Production readiness after the technical setup gate passed; it should not be advanced to Production until the Pre-Production gate passes.

## Technical Director Self-Review

Gate: TD-ARCHITECTURE

| Criterion | Result | Notes |
|---|---|---|
| Covers approved MVP GDD systems | PASS | All approved MVP/supporting systems are mapped; Armor excluded as Not Started. |
| Defines ownership and cross-system boundaries | PASS | Layer map, ownership tables, data flows, and API boundaries are present. |
| Respects accepted ADRs | PASS | Save transactions, semantic events, input routing, and authored Resources are adopted as foundation rules. |
| Flags engine and production risks | PASS WITH CONDITIONS | Godot 4.6 risk domains, OQ-SH01, test setup, UX/accessibility, and missing core ADRs are explicitly tracked. |

Verdict: APPROVED WITH CONDITIONS. Architecture is fit to proceed into ADR completion and architecture review, but not directly into production coding.
