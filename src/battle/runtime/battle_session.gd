class_name BattleSession
extends RefCounted

const BattleActionResultResource = preload("res://src/battle/runtime/battle_action_result.gd")
const BattleAdvanceResultResource = preload("res://src/battle/runtime/battle_advance_result.gd")
const BattleDurableDeltaResource = preload("res://src/battle/runtime/battle_durable_delta.gd")
const BattleEndedPayloadResource = preload("res://src/battle/runtime/battle_ended_payload.gd")
const BattleRecoilResultResource = preload("res://src/battle/runtime/battle_recoil_result.gd")
const BattleStatusApplyResultResource = preload("res://src/battle/runtime/battle_status_apply_result.gd")
const StatusRuntimeStateResource = preload("res://src/battle/runtime/status_runtime_state.gd")

const ALLOWED_ACTION_IDS: Array[StringName] = [
	&"battle_attack",
	&"battle_defend",
	&"battle_status",
	&"battle_consumable",
]
const STATUS_APPLY_CHANCE: float = 0.30
const PARALYSIS_SKIP_CHANCE: float = 0.50
const GUARD_BREAK_DEFENSE_MULTIPLIER: float = 0.60
const BURN_DOT_MAX_HP_RATIO: float = 0.08
const POISON_DOT_MAX_HP_RATIO: float = 0.06
const STATUS_BURN: StringName = &"burn"
const STATUS_FREEZE: StringName = &"freeze"
const STATUS_PARALYSIS: StringName = &"paralysis"
const STATUS_GUARD_BREAK: StringName = &"guard_break"
const STATUS_POISON: StringName = &"poison"
const STATUS_BLIND: StringName = &"blind"

## Runtime-only finite state machine for one battle encounter.

var session_id: StringName = &""
var state: StringName = BattleRuntimeState.INIT
var turn_count: int = 0
var player: RefCounted = null
var enemy: RefCounted = null
var pending_player_action: BattleAction = null
var last_completed_payload: BattleEndedPayload = null
var last_completed_delta: BattleDurableDelta = null
var _completed_payload_emitted: bool = false
var _complete_on_resolution: bool = false
var _victory: bool = false
var _raw_xp_awarded: int = 0
var _scraps_earned: int = 0
var _player_hp_remaining: int = 0
var _player_level_start: int = 1
var _enemy_level: int = 1
var _player_dragon_id: StringName = &""
var _boss_id: StringName = &""
var _final_phase_id: StringName = &""


## Configures the runtime session from read-only setup data.
func configure(setup: BattleSetupPayload) -> void:
	_snapshot_setup(setup)
	session_id = &""
	if setup != null:
		session_id = setup.battle_id
	state = BattleRuntimeState.INIT
	turn_count = 0
	pending_player_action = null
	last_completed_payload = null
	last_completed_delta = null
	_completed_payload_emitted = false


## Accepts gameplay actions only during TELEGRAPH.
func submit_action(action: BattleAction) -> BattleActionResult:
	var result: BattleActionResult = _make_action_result(action)
	if state != BattleRuntimeState.TELEGRAPH:
		return _fail_action_result(result, &"action_not_allowed", "Gameplay actions are only accepted during TELEGRAPH.")
	if action != null and action.action_id == &"battle_disabled":
		return _fail_action_result(result, &"action_disabled", "Battle action is disabled.")
	if action == null or not ALLOWED_ACTION_IDS.has(action.action_id):
		return _fail_action_result(result, &"unknown_action", "Unknown battle action.")

	pending_player_action = action
	result.success = true
	result.accepted = true
	result.reason = &"ok"
	result.state_after = state
	return result


## Advances by one legal phase transition.
func advance() -> BattleAdvanceResult:
	if state == BattleRuntimeState.COMPLETE:
		return _fail_advance_result(_make_advance_result(), &"session_complete", "BattleSession is already complete.")

	var next_state: StringName = _next_state()
	return transition_to(next_state)


## Applies a legal transition or returns a named failure without mutation.
func transition_to(next_state: StringName) -> BattleAdvanceResult:
	var result: BattleAdvanceResult = _make_advance_result()
	if not _is_legal_transition(state, next_state):
		return _fail_advance_result(result, &"illegal_transition", "Illegal battle phase transition.")

	state = next_state
	result.success = true
	result.reason = &"ok"
	result.state_after = state
	if state == BattleRuntimeState.COMPLETE:
		result.completed = true
		last_completed_payload = _make_ended_payload()
		last_completed_delta = _make_durable_delta(last_completed_payload)
		result.payload = last_completed_payload
		result.delta = last_completed_delta
	return result


func consume_completion_event() -> bool:
	if last_completed_payload == null or last_completed_delta == null or _completed_payload_emitted:
		return false
	_completed_payload_emitted = true
	return true


## Applies a status using a deterministic 0.0-1.0 roll. New status overwrites the old single slot.
func try_apply_status(target: RefCounted, status_id: StringName, apply_roll: float) -> RefCounted:
	var result: RefCounted = BattleStatusApplyResultResource.new()
	result.status_id = status_id
	result.roll = apply_roll
	if target == null:
		return _fail_status_result(result, &"missing_target", "Status application requires a target.")
	if not _is_known_status(status_id):
		return _fail_status_result(result, &"unknown_status", "Unknown battle status.")

	if apply_roll >= STATUS_APPLY_CHANCE:
		result.applied = false
		result.reason = &"miss"
		return result

	var status: RefCounted = StatusRuntimeStateResource.new()
	status.status_id = status_id
	status.duration_turns = _duration_for_status(status_id)
	target.active_status = status
	target.pending_skip = &""
	if status_id == STATUS_FREEZE:
		target.pending_skip = STATUS_FREEZE
	result.applied = true
	result.duration_turns = status.duration_turns
	return result


## Resolves TELEGRAPH action skips from Freeze and Paralysis without mutating status duration.
func should_skip_telegraph_action(combatant: RefCounted, paralysis_roll: float) -> bool:
	if combatant == null:
		return false
	if combatant.pending_skip == STATUS_FREEZE:
		combatant.pending_skip = &""
		return true
	if combatant.active_status == null:
		return false
	if combatant.active_status.status_id == STATUS_PARALYSIS:
		return paralysis_roll < PARALYSIS_SKIP_CHANCE
	return false


## Runs one deterministic RECOIL pass. Player status ticks before enemy status.
func resolve_recoil(player: RefCounted, enemy: RefCounted) -> RefCounted:
	var result: RefCounted = BattleRecoilResultResource.new()
	result.player_dot_damage = _tick_recoil_status(player, result, &"player")
	result.enemy_dot_damage = _tick_recoil_status(enemy, result, &"enemy")
	result.player_ko = player != null and player.current_hp <= 0
	result.enemy_ko = enemy != null and enemy.current_hp <= 0
	result.resolution_required = result.player_ko or result.enemy_ko
	return result


func effective_defense(combatant: RefCounted) -> int:
	if combatant == null:
		return 0
	if combatant.active_status != null and combatant.active_status.status_id == STATUS_GUARD_BREAK:
		return int(floor(float(combatant.base_defense) * GUARD_BREAK_DEFENSE_MULTIPLIER))
	return combatant.base_defense


func _next_state() -> StringName:
	match state:
		BattleRuntimeState.INIT:
			return BattleRuntimeState.TELEGRAPH
		BattleRuntimeState.TELEGRAPH:
			return BattleRuntimeState.IMPACT
		BattleRuntimeState.IMPACT:
			return BattleRuntimeState.RECOIL
		BattleRuntimeState.RECOIL:
			return BattleRuntimeState.RESOLUTION
		BattleRuntimeState.RESOLUTION:
			return BattleRuntimeState.COMPLETE if _complete_on_resolution else BattleRuntimeState.TELEGRAPH
	return BattleRuntimeState.COMPLETE


func _is_legal_transition(from_state: StringName, to_state: StringName) -> bool:
	match from_state:
		BattleRuntimeState.INIT:
			return to_state == BattleRuntimeState.TELEGRAPH
		BattleRuntimeState.TELEGRAPH:
			return to_state == BattleRuntimeState.IMPACT
		BattleRuntimeState.IMPACT:
			return to_state == BattleRuntimeState.RECOIL
		BattleRuntimeState.RECOIL:
			return to_state == BattleRuntimeState.RESOLUTION
		BattleRuntimeState.RESOLUTION:
			return to_state == BattleRuntimeState.TELEGRAPH or (to_state == BattleRuntimeState.COMPLETE and _complete_on_resolution)
	return false


func _make_ended_payload() -> BattleEndedPayload:
	var payload: BattleEndedPayload = BattleEndedPayloadResource.new()
	payload.victory = _victory
	payload.raw_xp_awarded = _raw_xp_awarded
	payload.scraps_earned = _scraps_earned
	payload.player_hp_remaining = _player_hp_remaining
	payload.player_level_start = _player_level_start
	payload.enemy_level = _enemy_level
	payload.battle_id = session_id
	payload.boss_id = _boss_id
	payload.final_phase_id = _final_phase_id
	return payload


func _make_durable_delta(payload: BattleEndedPayload) -> BattleDurableDelta:
	var delta: BattleDurableDelta = BattleDurableDeltaResource.new()
	delta.player_dragon_id = _player_dragon_id
	delta.player_hp_remaining = payload.player_hp_remaining
	delta.raw_xp_awarded = payload.raw_xp_awarded
	delta.scraps_earned = payload.scraps_earned
	delta.defeated_boss_id = payload.boss_id
	delta.battle_completed = true
	delta.victory = payload.victory
	return delta


func _tick_recoil_status(combatant: RefCounted, result: RefCounted, actor_id: StringName) -> int:
	if combatant == null or combatant.active_status == null:
		return 0

	result.tick_order.append(actor_id)
	var status_id: StringName = combatant.active_status.status_id
	var dot_damage: int = _dot_damage_for_status(combatant, status_id)
	if dot_damage > 0:
		combatant.current_hp = max(0, combatant.current_hp - dot_damage)

	combatant.active_status.duration_turns -= 1
	if combatant.active_status.duration_turns <= 0:
		combatant.active_status = null
	return dot_damage


func _dot_damage_for_status(combatant: RefCounted, status_id: StringName) -> int:
	match status_id:
		STATUS_BURN:
			return max(1, int(floor(float(combatant.max_hp) * BURN_DOT_MAX_HP_RATIO)))
		STATUS_POISON:
			return max(1, int(floor(float(combatant.max_hp) * POISON_DOT_MAX_HP_RATIO)))
	return 0


func _duration_for_status(status_id: StringName) -> int:
	match status_id:
		STATUS_FREEZE:
			return 1
		STATUS_BURN, STATUS_PARALYSIS, STATUS_GUARD_BREAK, STATUS_POISON, STATUS_BLIND:
			return 2
	return 0


func _is_known_status(status_id: StringName) -> bool:
	return [
		STATUS_BURN,
		STATUS_FREEZE,
		STATUS_PARALYSIS,
		STATUS_GUARD_BREAK,
		STATUS_POISON,
		STATUS_BLIND,
	].has(status_id)


func _make_action_result(action: BattleAction) -> BattleActionResult:
	var result: BattleActionResult = BattleActionResultResource.new()
	result.state_before = state
	result.state_after = state
	result.action_id = action.action_id if action != null else &""
	return result


func _make_advance_result() -> BattleAdvanceResult:
	var result: BattleAdvanceResult = BattleAdvanceResultResource.new()
	result.state_before = state
	result.state_after = state
	return result


func _snapshot_setup(setup: BattleSetupPayload) -> void:
	_complete_on_resolution = false
	_victory = false
	_raw_xp_awarded = 0
	_scraps_earned = 0
	_player_hp_remaining = 0
	_player_level_start = 1
	_enemy_level = 1
	_player_dragon_id = &""
	_boss_id = &""
	_final_phase_id = &""
	if setup == null:
		return
	_complete_on_resolution = setup.complete_on_resolution
	_victory = setup.victory
	_raw_xp_awarded = setup.raw_xp_awarded
	_scraps_earned = setup.scraps_earned
	_player_hp_remaining = setup.player_hp_remaining
	_player_level_start = setup.player_level_start
	_enemy_level = setup.enemy_level
	_player_dragon_id = setup.player_dragon_id
	_boss_id = setup.boss_id
	_final_phase_id = setup.final_phase_id


func _fail_action_result(result: BattleActionResult, reason: StringName, error_message: String) -> BattleActionResult:
	result.success = false
	result.accepted = false
	result.reason = reason
	result.error_message = error_message
	result.state_after = state
	return result


func _fail_advance_result(result: BattleAdvanceResult, reason: StringName, error_message: String) -> BattleAdvanceResult:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	result.state_after = state
	return result


func _fail_status_result(result: RefCounted, reason: StringName, error_message: String) -> RefCounted:
	result.success = false
	result.applied = false
	result.reason = reason
	result.error_message = error_message
	return result
