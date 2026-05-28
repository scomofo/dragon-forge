# ADR-0007: Battle Runtime State Machine

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / UI Input |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/modules/input.md`; `docs/engine-reference/godot/modules/ui.md`; `docs/engine-reference/godot/breaking-changes.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Godot 4.6 dual-focus behavior through ADR-0003/0005; callable signal connections; `PackedScene.instantiate()` through Scene Flow; typed authored animation manifest Resources through ADR-0004 |
| **Verification Required** | Verify TELEGRAPH-only input acceptance, typed signal payloads, no save mutation from Battle runtime, Mirror Admin profile swaps, controller focus after entering/leaving Battle screen, and BattleAnimationManifest validation for every authored move/action. |

Battle runtime uses ordinary GDScript control flow and typed data classes. It does not depend on physics, navigation, networking, or deprecated Godot 3 scene APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0006 Dragon Data Model And Progression Services |
| **Enables** | Campaign Map Content And Reward Pipeline ADR; Economy And Shop Transaction Boundaries ADR; Singularity Boss And Ending Orchestration ADR; Battle implementation stories |
| **Blocks** | Any story implementing Battle Engine runtime, battle UI input, battle reward settlement, Defrag Patch battle use, or Mirror Admin combat integration |
| **Ordering Note** | This ADR should be Accepted before Campaign Map reward stories or Singularity boss stories rely on Battle result payloads. |

## Context

### Problem Statement

The Battle Engine GDD defines a five-phase combat loop and many formulas, but implementation stories need a runtime architecture: where battle state lives, how input is accepted, which system commits durable changes, how result payloads are shaped, and how Singularity's continuous Mirror Admin encounter can swap phase profiles without ending the battle between phases.

The cross-GDD review established that Battle Engine owns raw combat math and raw reward payloads, while Campaign Map owns final expedition XP/Scrap application and Singularity owns endgame boss milestone state. ADR-0007 turns that ownership split into a binding runtime contract.

### Constraints

- Battle must be deterministic and testable without UI/audio.
- Battle runtime must not write save files directly.
- Durable state changes must commit through Save / Persistence.
- Player input must arrive as Input Router semantic actions, not raw device constants.
- Dragon data must be read as snapshots/stats, not mutable `DragonRecord` references.
- Campaign Map owns final XP decay and Scrap balance mutation.
- Singularity owns Mirror Admin phase transitions, corruption commits, tritone windows, and Void grant settlement.
- Shop owns item catalog and purchase flags; Battle can consume the in-battle Defrag Patch runtime action and report durable consumption in settlement.

### Requirements

- Implement INIT -> TELEGRAPH -> IMPACT -> RECOIL -> RESOLUTION as an explicit finite state machine.
- Accept player semantic actions only during TELEGRAPH.
- Keep HP, active status, cooldowns, pending skips, selected actions, turn count, and Mirror Admin phase runtime-local.
- Emit named payloads for turn presentation and battle settlement.
- Return durable deltas to the caller; do not mutate SaveData directly.
- Support a continuous Mirror Admin session with phase profile swaps and final `battle_ended` suppression until final KO/player defeat.
- Keep Defrag Patch use legal even when no status exists, consuming the item with no status change.

## Decision

Battle Engine will be implemented as a scene-local/runtime controller owned by the active Battle screen or battle host. It is not an Autoload and is not persisted. Idiomatic Godot shape:

- `BattleScreen` is the active top-level scene or screen.
- `BattleScreen` owns a child `BattleEngine`/controller `Node`.
- The controller owns one `BattleSession` `RefCounted`.
- Input Router callable signal connections are established once on battle entry or `_ready()`, context-gated to TELEGRAPH, and disconnected/invalidated on screen exit.

Each encounter creates one `BattleSession` from typed input snapshots and authored content Resources.

`BattleSession` owns the runtime finite state machine:

```text
INIT -> TELEGRAPH -> IMPACT -> RECOIL -> RESOLUTION
          ^                                  |
          |                                  v
          +--------- no KO / continue -------+
```

Only TELEGRAPH accepts player action input. Other phases ignore or reject gameplay actions and may accept presentation-only skip/advance inputs if a later UX spec allows them.

Battle Engine reads:

- `DragonStats` snapshots from Dragon Progression.
- Current HP/status entry values from `SaveSnapshot` or encounter setup payload.
- Authored `BattleDefinition`, `MoveDefinition`, `StatusDefinition`, `ConsumableDefinition`, and boss/profile Resources.
- Authored `BattleAnimationManifest` Resources for battle actor/action sprite and VFX bindings.
- Input Router semantic actions from the active Battle UI context.

Authored content types such as `BattleDefinition`, `MoveDefinition`, `StatusDefinition`, `ConsumableDefinition`, `BossDefinition`, `MirrorAdminPhaseProfile`, and `BattleAnimationManifest` are typed `Resource` files. Runtime/session types are `RefCounted` unless they are the scene-owned controller `Node`. Mutable runtime state must not be stored in shared `.tres` Resources.

Battle Engine writes no save files and does not mutate `DragonRecord`. At final settlement it returns:

- `BattleEndedPayload`
- `BattleDurableDelta`
- presentation/runtime event payloads

The caller, usually Campaign Map or Singularity, is responsible for opening a `SaveTransaction`, applying battle HP/status/item-consumption deltas, applying final XP/Scrap/milestone outcomes, committing through Save / Persistence, and emitting durable-state semantic events only after commit success.

### Runtime Types

`BattleDefinition` is authored content and should be a typed `Resource`. Runtime classes below should be `RefCounted` except for the scene-owned controller `Node`.

```gdscript
enum BattleRuntimeState {
    INIT,
    TELEGRAPH,
    IMPACT,
    RECOIL,
    RESOLUTION,
    COMPLETE
}
```

```gdscript
class_name BattleSession
extends RefCounted

var session_id: StringName
var state: BattleRuntimeState
var turn_count: int
var player: CombatantBattleState
var enemy: CombatantBattleState
var definition: BattleDefinition
var pending_player_action: BattleAction
var pending_enemy_action: BattleAction
```

```gdscript
class_name CombatantBattleState
extends RefCounted

var combatant_id: StringName
var dragon_id: StringName
var element: StringName
var level: int
var is_elder: bool
var stats: DragonStats
var current_hp: int
var max_hp: int
var active_status: StatusRuntimeState
var defend_cooldown_turns: int
var pending_skip: StringName
```

```gdscript
class_name BattleAction
extends RefCounted

var action_id: StringName
var move_id: StringName
var item_id: StringName
var source: StringName
```

```gdscript
class_name BattleEndedPayload
extends RefCounted

var victory: bool
var raw_xp_awarded: int
var scraps_earned: int
var player_hp_remaining: int
var player_level_start: int
var enemy_level: int
var battle_id: StringName
var boss_id: StringName
var final_phase_id: StringName
```

The six fields required by the Battle Engine GDD remain mandatory: `victory`, `raw_xp_awarded`, `scraps_earned`, `player_hp_remaining`, `player_level_start`, and `enemy_level`. Additional IDs support boss settlement and traceability.

```gdscript
class_name BattleDurableDelta
extends RefCounted

var player_dragon_id: StringName
var player_hp_remaining: int
var player_status_id: StringName
var consumed_item_flags: Array[StringName]
var raw_xp_awarded: int
var scraps_earned: int
var active_resonance_eligible: bool
var defeated_boss_id: StringName
var phase_checkpoint: BattlePhaseCheckpointDelta
var battle_completed: bool
var victory: bool
```

`BattleDurableDelta` is not a save transaction. It is a settlement request object consumed by Campaign Map or Singularity.

Allowed durable delta fields are limited to:

- Active dragon HP/loadout HP update.
- Runtime battle status clear/remaining status outcome if the encounter owner explicitly persists status.
- Consumed in-battle item flags, currently `expedition_defrag_patch`.
- Raw reward data: `raw_xp_awarded` and `scraps_earned`.
- Active Resonance eligibility for the active dragon.
- Battle outcome and defeated boss ID.
- Mirror Admin phase checkpoint data when Singularity commits a durable phase transition.

Battle Engine must never commit this delta itself.

```gdscript
class_name BattlePhaseCheckpointDelta
extends RefCounted

var boss_id: StringName
var phase_id: StringName
var boss_hp: int
var player_hp: int
var turn_count: int
var statuses_cleared: bool
var defend_cooldowns_cleared: bool
```

```gdscript
class_name TurnResolvedPayload
extends RefCounted

var turn_count: int
var player_hp: int
var enemy_hp: int
var player_action_id: StringName
var enemy_action_id: StringName
var presentation_events: Array[PresentationEventPayload]
```

Anonymous dictionaries are forbidden for battle runtime contracts.

### Battle Animation Manifest

Battle presentation content is bound through the required schema in `docs/architecture/battle-animation-manifest-schema.md`.

`BattleAnimationManifest` is an authored typed Resource that maps stable actor/action IDs to sprite strips, VFX clips, review evidence, and reduced-motion alternatives. It is selected by `BattleDefinition.animation_manifest_id`; `MoveDefinition` contributes stable IDs such as `move_id`, `animation_action_id`, and `required_animation_class`, but does not own sprite paths.

The binding rule is:

```text
BattleDefinition + MoveDefinition + BattleAnimationManifest -> BattleActionAnimationBinding
```

Battle runtime and presentation code must look up clips by these IDs. Runtime code must not branch on move names such as `"root_spark"` or `"data_leak"` to choose sprite paths.

Content validation must fail before production content lock when:

- a `BattleDefinition.animation_manifest_id` is missing;
- an actor animation set referenced by the battle is missing;
- a move in `move_ids`, `enemy_move_ids`, `BossDefinition`, or `MirrorAdminPhaseProfile.scripted_loop` has no legal animation binding for the acting actor;
- a binding's `action_class` does not match `MoveDefinition.required_animation_class`;
- Defend, hurt, defend-hit, KO, or status-receive clips are missing for a battle-capable actor;
- a production encounter still uses a `placeholder` binding without an explicit greybox exception.

The manifest is presentation-only. Animation data must not alter damage, accuracy, status, AI choice, rewards, or durable settlement.

### Runtime API

```gdscript
class_name BattleRuntimeController
extends Node

signal turn_resolved(payload: TurnResolvedPayload)
signal battle_completed(payload: BattleEndedPayload, delta: BattleDurableDelta)
signal presentation_event(payload: PresentationEventPayload)

func start_battle(definition: BattleDefinition, setup: BattleSetupPayload) -> BattleStartResult
func submit_action(action: BattleAction) -> BattleActionResult
func advance() -> BattleAdvanceResult
func apply_profile_swap(profile: BattleProfileSwap) -> BattleProfileSwapResult
func get_state() -> BattleRuntimeState
```

`submit_action()` accepts gameplay actions only when `state == TELEGRAPH`. Disabled actions return a rejected result without mutating battle state.

Skipped TELEGRAPH cases, transition beats, and ended sessions reject or ignore semantic actions with a typed failure result. Frozen/paralyzed player turns do not accept a substitute player action.

### Phase Responsibilities

INIT:

- Build combatant runtime states from read-only setup data.
- Compute player and enemy stats from `DragonStats`.
- Clamp current HP to `[0, max_hp]`.
- Load authored move/status/reward/profile data.
- For Mirror Admin, load or copy all phase profiles needed for the continuous session, or require `apply_profile_swap()` to receive a validated immutable/copied profile.
- Enter TELEGRAPH unless battle setup is invalid.

TELEGRAPH:

- Accept exactly one legal player action.
- Select or receive exactly one enemy action unless skip state prevents action.
- Reveal enemy element signal or skip state to presentation.
- Reject raw input and disabled actions.

IMPACT:

- Apply consumable effects before simultaneous damage/status resolution.
- For Defrag Patch, clear player active status if present, mark `expedition_defrag_patch` consumed in runtime, and continue even if no status existed.
- Resolve attacks, defend, status, crit, accuracy, and simultaneous KO policy.

RECOIL:

- Tick active status effects in declared order: player DoT first, then enemy DoT.
- Update status durations and pending skips.
- Preserve the Battle GDD rule that both DoT ticks can occur before RESOLUTION determines KO.

RESOLUTION:

- Check KO and simultaneous KO policy.
- If no KO, emit `turn_resolved`, increment/settle turn state, and return to TELEGRAPH.
- If KO, create `BattleEndedPayload` and `BattleDurableDelta`, enter COMPLETE, and emit `battle_completed`.

### Reward Ownership

Battle Engine owns only the raw battle reward payload:

```text
raw_xp_awarded = max(1, floor(base_xp * float(enemy_level) / float(player_level)))
```

Battle Engine must use explicit float conversion. It must not use integer division.

Battle Engine does not:

- Apply Campaign Map over-level XP decay.
- Call `DragonProgressionService.apply_xp()`.
- Increment `battle_charges` directly.
- Add Scraps to player balance.
- Mark Campaign Map nodes cleared.
- Write Singularity defeated flags.

For active Resonance, Battle Engine reports `active_resonance_eligible = true` only for a qualifying active-dragon battle completion. Campaign Map or Singularity settlement applies the actual charge through `DragonProgressionService.add_resonance_charge()` inside the reward transaction.

### HP And Status Persistence

Battle HP/status are runtime-local during the session. Campaign Map owns carried expedition HP through `loadout_hp[]` and commits the player's final HP from `BattleDurableDelta`.

Battle statuses are runtime-only by default. They do not persist across separate Campaign Map encounters unless a later accepted ADR adds an explicit SaveData field and owner. Within a continuous boss session, statuses remain in `CombatantBattleState`; Mirror Admin phase transitions clear statuses, pending skips, and Defend cooldowns per Singularity rules.

Any stale wording that implies Save / Persistence generally stores active battle status should be read as "encounter owner may commit the final status outcome only if that owner has an accepted persistence contract." No such cross-encounter status persistence contract exists in the current MVP architecture.

### Runtime Events vs Committed Events

Battle may emit immediate runtime/presentation signals:

- `presentation_event(payload)`
- `turn_resolved(payload)`
- `battle_completed(payload, delta)`

These are pre-commit runtime settlement outputs, not durable-state authority. `battle_completed` replaces the older loose notion of `battle_ended` as an implementation signal; it is a request for the encounter owner to settle. Durable milestone signals must come only from the encounter owner after Save / Persistence commit success, including:

- reward committed
- Campaign Map node cleared
- gatekeeper defeated
- Mirror Admin phase corruption committed
- Mirror Admin defeated
- Void dragon granted
- ending resolved

Campaign Map or Singularity settlement code uses the battle payload and delta to commit final outcomes through Save / Persistence.

### Mirror Admin Continuous Session

Mirror Admin is one continuous `BattleSession`. Battle itself remains persistence-blind, but Singularity may call `apply_profile_swap()` at phase thresholds to:

- Swap `combat_profile_id`.
- Clamp Mirror Admin HP to the next threshold.
- Clear player and boss statuses.
- Clear pending skips and Defend cooldowns.
- Open or close tritone windows.
- Change scripted AI sequence for KERNEL_PANIC.

The phase profile passed to `apply_profile_swap()` must be an immutable/copied runtime profile or a validated read-only Resource projection. Battle runtime must never mutate live authored `.tres` Resources during a session.

Battle Engine must not emit final `battle_completed` / `battle_ended`, grant rewards, or return to Campaign Map between PARITY, OVERCLOCK, and KERNEL_PANIC. Phase-change presentation payloads may emit, but durable corruption-class events remain owned by Singularity and Save / Persistence.

Mirror Admin can only be KO'd after KERNEL_PANIC phase-entry settlement completes.

ADR-0007 chooses the persistent phase-checkpoint model for Mirror Admin if corruption advances are committed at phase transitions. When Singularity commits CRITICAL or BREACH during a phase transition, it must also commit enough encounter checkpoint data to reload coherently at that phase boundary. The checkpoint is represented by `BattlePhaseCheckpointDelta` and is applied by Singularity/Save settlement, not by Battle Engine.

Therefore, after a successful phase checkpoint commit, reload resumes from the latest committed Mirror Admin phase checkpoint rather than from the original pre-boss save. If Singularity later wants "always reload pre-boss" behavior, the Singularity ADR/GDD must defer CRITICAL/BREACH durable corruption commits until final encounter settlement. The hybrid model of committing corruption mid-fight while reloading only pre-boss is forbidden.

### Tritone Counter

During Singularity's `tritone_window`, the Battle UI may label the focused Defend action as Counter. Input Router still sends the canonical `battle_defend` semantic action.

If the tritone window is open:

- `battle_defend` resolves as Counter.
- Counter is legal even if Defend would otherwise be on cooldown.
- Counter applies normal Defend reduction for the turn.
- Counter applies Singularity's `tritone_counter_damage`.
- Counter then sets the standard Defend cooldown.

Battle Engine reports the counter result through a typed presentation/event payload. Singularity owns `tritone_counter_resolved` semantics and audio pitch IDs.

## Alternatives Considered

### Alternative 1: Battle Engine Commits Save State Directly

- **Description**: Battle Engine opens save transactions and applies HP, XP, Scraps, node flags, item flags, and boss flags itself.
- **Pros**: Straightforward from inside battle code.
- **Cons**: Violates ownership split; couples Battle to Campaign Map, Shop, Dragon Progression, and Singularity; increases partial-state risk.
- **Rejection Reason**: Contradicts ADR-0001 and cross-GDD reward ownership.

### Alternative 2: Battle As Pure Stateless Formula Library

- **Description**: Campaign Map/Singularity own the whole battle loop and call Battle utility functions for damage/status formulas.
- **Pros**: Keeps Battle simple and avoids scene ownership questions.
- **Cons**: Duplicates phase logic, TELEGRAPH input gating, status timing, and Mirror Admin integration in callers.
- **Rejection Reason**: Battle GDD defines an engine, not just formulas; one runtime FSM is needed.

### Alternative 3: Scene-Local Battle Session With Settlement Payloads

- **Description**: Battle owns runtime combat state and formulas, then returns typed settlement payloads/deltas for the caller to commit.
- **Pros**: Deterministic, testable, respects save/event ownership, and supports continuous Mirror Admin phases.
- **Cons**: Requires explicit settlement integration stories and more typed data contracts.
- **Rejection Reason**: Chosen.

## Consequences

### Positive

- Battle formulas and state transitions can be unit tested without Save / Persistence or UI.
- Campaign Map and Singularity remain authoritative over progression and milestone commits.
- Defrag Patch and other in-battle consumables can be represented as runtime actions plus durable deltas.
- Mirror Admin phase swaps do not require nested battle sessions or fake battle endings.
- Input behavior stays consistent with gamepad-first architecture.
- Mirror Admin corruption checkpoints have a coherent reload model instead of mixing committed phase state with pre-boss recovery.

### Negative

- Battle completion is not "done" until the caller commits settlement through Save / Persistence.
- Integration stories must test both Battle runtime and caller settlement.
- GDD wording that says Battle "writes" some fields should be read as "reports a durable delta" unless a later ADR supersedes this.

### Risks

- **Settlement gap**: A caller may forget to commit `BattleDurableDelta`.
  - **Mitigation**: Campaign Map/Singularity stories must include settlement acceptance criteria; uncommitted deltas are test failures.
- **Signal timing drift**: Implementers may emit durable milestone events directly from Battle.
  - **Mitigation**: Battle emits runtime/presentation and battle-complete payloads only; durable milestone events emit after caller save commit.
- **Mirror Admin checkpoint drift**: Singularity may commit corruption without enough encounter resume state.
  - **Mitigation**: Mid-fight CRITICAL/BREACH commits require a matching phase checkpoint commit; otherwise corruption commits must defer until final settlement.
- **Reentrant phase swaps**: Singularity may request a profile swap during phase resolution.
  - **Mitigation**: `apply_profile_swap()` is legal only at RESOLUTION/phase-threshold checkpoints or via an internal queued transition point.
- **Input leakage**: UI may forward inputs outside TELEGRAPH.
  - **Mitigation**: `submit_action()` rejects gameplay actions unless state is TELEGRAPH.
- **Shared Resource mutation**: Mutable battle state could accidentally be placed on authored Resources.
  - **Mitigation**: Authored definitions are Resources; runtime/session state is RefCounted or controller Node data.

## GDD Requirements Addressed

| GDD System | Requirement | How This ADR Addresses It |
|------------|-------------|--------------------------|
| `battle-engine.md` | Five-phase battle loop, damage/status/Defend/DoT ordering, result payload, and presentation events. | Defines explicit runtime FSM, typed state, typed action submission, turn payloads, and settlement payloads. |
| `input-router.md` | Battle TELEGRAPH consumes semantic battle actions and Defend/Counter uses `battle_defend`. | Accepts Input Router semantic actions only in TELEGRAPH; Counter remains contextual `battle_defend`. |
| `dragon-progression.md` | Battle reads stats and reports XP/active battle completion without owning progression. | Consumes `DragonStats`; returns raw XP and durable delta; does not mutate DragonRecord or battle charges directly. |
| `campaign-map.md` | Campaign Map owns final XP decay, Scrap increment, node progression, and map settlement. | Battle returns payloads; Campaign Map commits final rewards and map state. |
| `shop.md` | Defrag Patch is an in-battle TELEGRAPH action that clears current status and consumes the expedition flag. | Battle handles runtime action and returns consumed flag in `BattleDurableDelta`. |
| `singularity.md` | Mirror Admin is a continuous three-phase encounter with tritone Counter and suppressed battle end between phases. | Supports profile swaps, threshold clamps, tritone windows, and final-only battle completion. |
| `audio-director.md` | Audio subscribes to battle presentation outcomes without owning gameplay state. | Emits typed `PresentationEventPayload` values for UI/audio/VFX. |

## Performance Implications

- **CPU**: Low. Turn resolution is event-driven and formula-bound, not per-frame heavy.
- **Memory**: Low. One runtime session owns two combatant states and authored Resource references.
- **Load Time**: Minimal. Battle setup loads referenced Resources and snapshots at INIT.
- **Network**: None. MVP is local single-player.

## Migration Plan

No production Godot battle runtime exists yet. Initial implementation should:

1. Add typed battle runtime classes and result payloads.
2. Implement formula unit tests before UI wiring.
3. Implement FSM phase transition tests.
4. Add a Battle screen that owns one `BattleRuntimeController`.
5. Route TELEGRAPH actions from Input Router to `submit_action()`.
6. Implement Campaign Map settlement against `BattleEndedPayload` and `BattleDurableDelta`.
7. Implement Singularity profile swap hooks for Mirror Admin.

## Validation Criteria

- `submit_action()` rejects gameplay actions outside TELEGRAPH.
- INIT computes stats from Dragon snapshots and does not hold mutable DragonRecord references.
- Runtime state is held in a scene-owned controller/RefCounted session, not in authored `.tres` Resources.
- Mirror Admin phase swaps use preloaded/copied profiles or validated immutable profile inputs; live authored Resources are not mutated.
- Damage formula, status overwrite, DoT ordering, Defend cooldown, and simultaneous KO match the Battle GDD.
- `battle_completed` fires exactly once per normal battle.
- `battle_completed` is treated as pre-commit settlement output, not committed-state authority.
- `BattleEndedPayload` contains all six mandatory GDD fields.
- Battle Engine never calls save file APIs.
- Battle Engine never calls `DragonProgressionService.apply_xp()` or mutates `battle_charges`.
- Battle Engine reports active Resonance eligibility but does not apply charges.
- Defrag Patch use clears status before IMPACT and reports `expedition_defrag_patch` in consumed item flags.
- Defrag Patch use is legal only in TELEGRAPH, consumes the flag even with no active status, and Shop does not reset the flag.
- Failed caller save commit after battle completion does not retroactively cause Battle to emit durable-state events.
- Mirror Admin PARITY -> OVERCLOCK -> KERNEL_PANIC profile swaps occur in one continuous session.
- Mirror Admin phase swaps do not emit final battle completion.
- Mid-fight Mirror Admin corruption commits include matching phase checkpoint data, or else corruption commits are deferred to final settlement.
- Reload after a committed Mirror Admin phase checkpoint resumes from that checkpoint and not from stale pre-boss state.
- Tritone Counter is routed through `battle_defend` and is legal during the tritone window even when Defend cooldown would normally block it.

## Related Decisions

- ADR-0001: Save Transaction Boundary
- ADR-0002: Semantic Event Contracts
- ADR-0003: Input Router Semantic Actions
- ADR-0004: Authored Content Resources
- ADR-0005: Godot Scene Flow And Autoload Boundaries
- ADR-0006: Dragon Data Model And Progression Services
- `docs/architecture/architecture.md`
- `design/gdd/battle-engine.md`
- `design/gdd/singularity.md`
