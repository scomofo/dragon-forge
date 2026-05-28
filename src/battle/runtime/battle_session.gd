class_name BattleSession
extends RefCounted

const BattleActionResultResource = preload("res://src/battle/runtime/battle_action_result.gd")
const BattleAdvanceResultResource = preload("res://src/battle/runtime/battle_advance_result.gd")
const BattleDurableDeltaResource = preload("res://src/battle/runtime/battle_durable_delta.gd")
const BattleEndedPayloadResource = preload("res://src/battle/runtime/battle_ended_payload.gd")
const BattleAnimationLookupResultResource = preload("res://src/battle/runtime/battle_animation_lookup_result.gd")
const BattleAnimationManifestValidatorResource = preload("res://src/battle/animation/battle_animation_manifest_validator.gd")
const BattleFormulaServiceResource = preload("res://src/battle/formulas/battle_formula_service.gd")
const PresentationEventPayloadResource = preload("res://src/battle/runtime/presentation_event_payload.gd")
const BattleRecoilResultResource = preload("res://src/battle/runtime/battle_recoil_result.gd")
const BattleStatusApplyResultResource = preload("res://src/battle/runtime/battle_status_apply_result.gd")
const StatusRuntimeStateResource = preload("res://src/battle/runtime/status_runtime_state.gd")
const TurnResolvedPayloadResource = preload("res://src/battle/runtime/turn_resolved_payload.gd")

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
const ACTION_DEFEND: StringName = &"battle_defend"
const ACTION_ATTACK: StringName = &"battle_attack"
const ACTION_STATUS: StringName = &"battle_status"
const ACTION_CONSUMABLE: StringName = &"battle_consumable"
const DEFRAG_PATCH_ITEM_ID: StringName = &"defrag_patch"
const DEFRAG_PATCH_FLAG: StringName = &"expedition_defrag_patch"
const NPC_SUPER_EFFECTIVE_PREFERENCE: float = 0.70
const NPC_STATUS_PREFERENCE: float = 0.40
const NPC_HIGH_POWER_PREFERENCE: float = 0.60

signal battle_completed(payload: BattleEndedPayload, delta: BattleDurableDelta)
signal presentation_event(payload: PresentationEventPayload)
signal turn_resolved(payload: TurnResolvedPayload)

## Runtime-only finite state machine for one battle encounter.

var session_id: StringName = &""
var state: StringName = BattleRuntimeState.INIT
var turn_count: int = 0
var player: CombatantBattleState = null
var enemy: CombatantBattleState = null
var pending_player_action: BattleAction = null
var pending_enemy_action: BattleAction = null
var last_turn_payload: TurnResolvedPayload = null
var last_completed_payload: BattleEndedPayload = null
var last_completed_delta: BattleDurableDelta = null
var _completed_payload_emitted: bool = false
var _battle_completed_signal_emitted: bool = false
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
var _expedition_defrag_patch_available: bool = false
var _consumed_item_flags: Array[StringName] = []
var _pending_presentation_events: Array[PresentationEventPayload] = []
var _last_ko_phase: StringName = &""
var _last_recoil_first_ko_actor: StringName = &""
var _battle_definition: BattleDefinition = null
var _animation_manifest: BattleAnimationManifest = null
var _move_definitions: Dictionary = {}
var _actor_sets_by_id: Dictionary = {}
var _clips_by_id: Dictionary = {}
var _bindings_by_actor_move: Dictionary = {}
var _bindings_by_actor_action: Dictionary = {}
var _bindings_by_move_id: Dictionary = {}
var _formula_service: BattleFormulaService = BattleFormulaServiceResource.new()


## Configures the runtime session from read-only setup data.
func configure(setup: BattleSetupPayload) -> void:
	_snapshot_setup(setup)
	_snapshot_animation_setup(setup)
	session_id = &""
	if setup != null:
		session_id = setup.battle_id
	state = BattleRuntimeState.INIT
	turn_count = 0
	pending_player_action = null
	pending_enemy_action = null
	last_turn_payload = null
	last_completed_payload = null
	last_completed_delta = null
	_completed_payload_emitted = false
	_battle_completed_signal_emitted = false
	_pending_presentation_events = []
	_last_ko_phase = &""
	_last_recoil_first_ko_actor = &""


## Accepts gameplay actions only during TELEGRAPH.
func submit_action(action: BattleAction) -> BattleActionResult:
	return _submit_action_for_combatant(action, player, true)


## Accepts enemy/NPC gameplay actions through the same runtime legality as player actions.
func submit_enemy_action(action: BattleAction) -> BattleActionResult:
	return _submit_action_for_combatant(action, enemy, false)


## Returns whether the combatant may choose Defend in the current TELEGRAPH.
func can_select_defend(combatant: CombatantBattleState) -> bool:
	return combatant == null or combatant.defend_cooldown_turns <= 0


## Lists in-battle consumable flags available to the player for the current TELEGRAPH.
func available_telegraph_item_flags() -> Array[StringName]:
	var item_flags: Array[StringName] = []
	if state == BattleRuntimeState.TELEGRAPH and _expedition_defrag_patch_available:
		item_flags.append(DEFRAG_PATCH_FLAG)
	return item_flags


## Returns a defensive copy of item flags consumed by this runtime session.
func get_consumed_item_flags() -> Array[StringName]:
	var item_flags: Array[StringName] = []
	item_flags.assign(_consumed_item_flags)
	return item_flags


func _submit_action_for_combatant(action: BattleAction, combatant: CombatantBattleState, is_player_action: bool) -> BattleActionResult:
	var result: BattleActionResult = _make_action_result(action)
	if state != BattleRuntimeState.TELEGRAPH:
		return _fail_action_result(result, &"action_not_allowed", "Gameplay actions are only accepted during TELEGRAPH.")
	if action != null and action.action_id == &"battle_disabled":
		return _fail_action_result(result, &"action_disabled", "Battle action is disabled.")
	if action == null or not ALLOWED_ACTION_IDS.has(action.action_id):
		return _fail_action_result(result, &"unknown_action", "Unknown battle action.")
	if not is_player_action and action.action_id == ACTION_CONSUMABLE:
		return _fail_action_result(result, &"item_unavailable", "Enemy consumable actions are not available in this battle state.")
	if action.action_id == ACTION_DEFEND and not can_select_defend(combatant):
		return _fail_action_result(result, &"defend_on_cooldown", "Defend is on cooldown for this combatant.")
	if action.action_id == ACTION_CONSUMABLE and not _is_legal_consumable_action(action):
		return _fail_action_result(result, &"item_unavailable", "Consumable action is not available in this battle state.")
	if _has_pending_action(is_player_action):
		return _fail_action_result(result, &"action_already_submitted", "This combatant already submitted an action for the current TELEGRAPH.")

	apply_action_cooldown(combatant, action)
	if is_player_action:
		pending_player_action = action
	else:
		pending_enemy_action = action
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
	if state == BattleRuntimeState.IMPACT:
		_apply_impact_entry_effects()
	elif state == BattleRuntimeState.TELEGRAPH:
		_begin_next_telegraph_turn()
	elif state == BattleRuntimeState.RESOLUTION:
		if _should_complete_battle():
			_finish_battle(_determine_victory(), result)
		else:
			_emit_turn_resolved(result)
	result.success = true
	result.reason = &"ok"
	result.state_after = state
	if state == BattleRuntimeState.COMPLETE:
		_finish_battle(_victory, result)
	return result


## Marks the pending completion payload/delta as emitted and returns true once.
func consume_completion_event() -> bool:
	if last_completed_payload == null or last_completed_delta == null or _completed_payload_emitted:
		return false
	_completed_payload_emitted = true
	return true


## Applies a status using a deterministic 0.0-1.0 roll. New status overwrites the old single slot.
func try_apply_status(target: CombatantBattleState, status_id: StringName, apply_roll: float) -> BattleStatusApplyResult:
	var result: BattleStatusApplyResult = BattleStatusApplyResultResource.new()
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

	var status: StatusRuntimeState = StatusRuntimeStateResource.new()
	status.status_id = status_id
	status.duration_turns = _duration_for_status(status_id)
	target.active_status = status
	target.pending_skip = &""
	if status_id == STATUS_FREEZE:
		target.pending_skip = STATUS_FREEZE
	result.applied = true
	result.duration_turns = status.duration_turns
	return result


## Emits one typed presentation event payload without requiring any listener.
func emit_presentation_event_id(
		event_id: StringName,
		subject_id: StringName = &"",
		tags: Array[StringName] = []
) -> PresentationEventPayload:
	var payload: PresentationEventPayload = PresentationEventPayloadResource.new()
	payload.event_id = event_id
	payload.subject_id = subject_id
	payload.tags.assign(tags)
	_pending_presentation_events.append(payload)
	presentation_event.emit(payload)
	return payload


## Applies IMPACT heals before simultaneous damage and records the KO phase.
func resolve_impact_effects(
		player_damage_to_enemy: int,
		enemy_damage_to_player: int,
		player_heal_before_damage: int = 0,
		enemy_heal_before_damage: int = 0
) -> void:
	_apply_impact_entry_effects()
	_heal_combatant(player, player_heal_before_damage)
	_heal_combatant(enemy, enemy_heal_before_damage)
	_damage_combatant(enemy, player_damage_to_enemy)
	_damage_combatant(player, enemy_damage_to_player)
	if _combatant_ko(player) or _combatant_ko(enemy):
		_last_ko_phase = BattleRuntimeState.IMPACT
		_last_recoil_first_ko_actor = &""


## Resolves TELEGRAPH action skips from Freeze and Paralysis without mutating status duration.
func should_skip_telegraph_action(combatant: CombatantBattleState, paralysis_roll: float) -> bool:
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
func resolve_recoil(player: CombatantBattleState, enemy: CombatantBattleState) -> BattleRecoilResult:
	var result: BattleRecoilResult = BattleRecoilResultResource.new()
	result.player_dot_damage = _tick_recoil_status(player, result, &"player")
	if player != null and player.current_hp <= 0:
		result.first_ko_actor = &"player"
	result.enemy_dot_damage = _tick_recoil_status(enemy, result, &"enemy")
	if enemy != null and enemy.current_hp <= 0 and result.first_ko_actor == &"":
		result.first_ko_actor = &"enemy"
	result.player_ko = player != null and player.current_hp <= 0
	result.enemy_ko = enemy != null and enemy.current_hp <= 0
	result.resolution_required = result.player_ko or result.enemy_ko
	if result.resolution_required:
		_last_ko_phase = BattleRuntimeState.RECOIL
		_last_recoil_first_ko_actor = result.first_ko_actor
	return result


## Selects one deterministic NPC action from authored moves and runtime cooldown/status state.
func select_npc_action(player_element: StringName, preference_roll: float, fallback_index: int = 0) -> BattleAction:
	var attack_moves: Array[MoveDefinition] = _npc_attack_moves()
	var super_effective_moves: Array[MoveDefinition] = _super_effective_moves(attack_moves, player_element)
	if not super_effective_moves.is_empty():
		if preference_roll < NPC_SUPER_EFFECTIVE_PREFERENCE:
			return _make_move_action(super_effective_moves[0])
		return _make_move_action(_highest_power_move(attack_moves))

	var status_moves: Array[MoveDefinition] = _npc_status_moves()
	if _player_has_no_active_status() and not status_moves.is_empty():
		if preference_roll < NPC_STATUS_PREFERENCE:
			return _make_move_action(status_moves[0])
		if not attack_moves.is_empty():
			return _make_move_action(_highest_power_move(attack_moves))

	if not attack_moves.is_empty() and preference_roll < NPC_HIGH_POWER_PREFERENCE:
		return _make_move_action(_highest_power_move(attack_moves))

	return _fallback_npc_action(fallback_index)


## Returns the combatant defense after runtime status modifiers.
func effective_defense(combatant: CombatantBattleState) -> int:
	if combatant == null:
		return 0
	if combatant.active_status != null and combatant.active_status.status_id == STATUS_GUARD_BREAK:
		return int(floor(float(combatant.base_defense) * GUARD_BREAK_DEFENSE_MULTIPLIER))
	return combatant.base_defense


## Resolves action, VFX, and receive clips for one actor/move pair through the configured manifest.
func resolve_action_animation(actor_set_id: StringName, move_id: StringName) -> BattleAnimationLookupResult:
	var result: BattleAnimationLookupResult = _make_animation_lookup_result(actor_set_id, move_id)
	if not _ensure_animation_context(result):
		return result

	var actor_set: BattleActorAnimationSet = _actor_sets_by_id.get(actor_set_id)
	if actor_set == null:
		return _fail_animation_lookup(result, &"missing_actor_set", "Animation manifest %s has no actor set '%s'." % [_animation_manifest.manifest_id, actor_set_id])

	var move: MoveDefinition = _move_definitions.get(move_id)
	if move == null:
		return _fail_animation_lookup(result, &"missing_move_definition", "Battle %s has no MoveDefinition for '%s'." % [_battle_definition.battle_id, move_id])

	var binding: BattleActionAnimationBinding = _bindings_by_actor_move.get(_binding_key(actor_set.actor_id, move.move_id))
	if binding == null and move.animation_action_id != &"":
		binding = _bindings_by_actor_action.get(_binding_key(actor_set.actor_id, move.animation_action_id))
	if binding == null:
		return _fail_animation_lookup(result, &"missing_action_binding", "Actor set '%s' has no animation binding for move '%s'." % [actor_set.actor_id, move.move_id])
	if binding.action_class != move.required_animation_class:
		return _fail_animation_lookup(result, &"wrong_action_class", "Binding '%s' has action class '%s' but move '%s' requires '%s'." % [binding.binding_id, binding.action_class, move.move_id, move.required_animation_class])

	result.binding = binding
	result.animation_action_id = move.animation_action_id
	result.action_class = binding.action_class
	result.action_clip = _clips_by_id.get(binding.clip_id)
	result.vfx_clip = _clips_by_id.get(binding.vfx_clip_id)
	result.receive_clip = _clips_by_id.get(binding.receive_clip_id)
	if binding.clip_id != &"" and result.action_clip == null:
		return _fail_animation_lookup(result, &"missing_action_clip", "Binding '%s' references missing action clip '%s'." % [binding.binding_id, binding.clip_id])
	if binding.vfx_clip_id != &"" and result.vfx_clip == null:
		return _fail_animation_lookup(result, &"missing_vfx_clip", "Binding '%s' references missing VFX clip '%s'." % [binding.binding_id, binding.vfx_clip_id])
	if binding.receive_clip_id != &"" and result.receive_clip == null:
		return _fail_animation_lookup(result, &"missing_receive_clip", "Binding '%s' references missing receive clip '%s'." % [binding.binding_id, binding.receive_clip_id])

	result.success = true
	result.reason = &"ok"
	return result


## Resolves a required base reaction clip, such as hurt, defend_hit, or ko.
func resolve_base_animation(actor_set_id: StringName, slot_id: StringName) -> BattleAnimationLookupResult:
	var result: BattleAnimationLookupResult = _make_animation_lookup_result(actor_set_id, &"")
	result.slot_id = slot_id
	if not _ensure_animation_context(result):
		return result

	var actor_set: BattleActorAnimationSet = _actor_sets_by_id.get(actor_set_id)
	if actor_set == null:
		return _fail_animation_lookup(result, &"missing_actor_set", "Animation manifest %s has no actor set '%s'." % [_animation_manifest.manifest_id, actor_set_id])

	var slots := actor_set.required_base_clip_slots()
	if not slots.has(slot_id):
		return _fail_animation_lookup(result, &"unknown_base_slot", "Actor set '%s' has no required base animation slot '%s'." % [actor_set.actor_id, slot_id])

	var clip_id: StringName = slots[slot_id]
	if clip_id == &"":
		return _fail_animation_lookup(result, &"missing_base_clip", "Actor set '%s' has no clip ID for base slot '%s'." % [actor_set.actor_id, slot_id])

	result.base_clip = _clips_by_id.get(clip_id)
	if result.base_clip == null:
		return _fail_animation_lookup(result, &"missing_base_clip", "Actor set '%s' base slot '%s' references missing clip '%s'." % [actor_set.actor_id, slot_id, clip_id])

	result.success = true
	result.reason = &"ok"
	return result


## Resolves the target actor receive clip for an incoming move binding.
func resolve_receive_animation(
		actor_set_id: StringName,
		source_move_id: StringName,
		source_actor_set_id: StringName = &""
) -> BattleAnimationLookupResult:
	var result: BattleAnimationLookupResult = _make_animation_lookup_result(actor_set_id, source_move_id)
	result.source_actor_set_id = source_actor_set_id
	if not _ensure_animation_context(result):
		return result

	var actor_set: BattleActorAnimationSet = _actor_sets_by_id.get(actor_set_id)
	if actor_set == null:
		return _fail_animation_lookup(result, &"missing_actor_set", "Animation manifest %s has no actor set '%s'." % [_animation_manifest.manifest_id, actor_set_id])
	if not _move_definitions.has(source_move_id):
		return _fail_animation_lookup(result, &"missing_move_definition", "Battle %s has no MoveDefinition for '%s'." % [_battle_definition.battle_id, source_move_id])

	if source_actor_set_id != &"":
		if not _actor_sets_by_id.has(source_actor_set_id):
			return _fail_animation_lookup(result, &"missing_source_actor_set", "Animation manifest %s has no source actor set '%s'." % [_animation_manifest.manifest_id, source_actor_set_id])
		var source_binding: BattleActionAnimationBinding = _bindings_by_actor_move.get(_binding_key(source_actor_set_id, source_move_id))
		if source_binding == null:
			return _fail_animation_lookup(result, &"missing_action_binding", "Source actor set '%s' has no animation binding for move '%s'." % [source_actor_set_id, source_move_id])
		return _resolve_receive_clip_for_binding(result, actor_set, source_binding, source_move_id)

	for binding in _bindings_by_move_id.get(source_move_id, []):
		if binding == null or binding.receive_clip_id == &"":
			continue
		if not actor_set.required_base_clip_ids().has(binding.receive_clip_id):
			continue
		return _resolve_receive_clip_for_binding(result, actor_set, binding, source_move_id)

	return _fail_animation_lookup(result, &"missing_receive_clip", "Actor set '%s' has no receive clip for incoming move '%s'." % [actor_set.actor_id, source_move_id])


## Runs production-lock validation against the configured manifest inputs.
func validate_animation_manifest(production_lock: bool = true) -> BattleAnimationValidationResult:
	return BattleAnimationManifestValidatorResource.new().validate(_animation_manifest, _battle_definition, _move_definitions, production_lock)


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
	delta.consumed_item_flags.assign(_consumed_item_flags)
	delta.raw_xp_awarded = payload.raw_xp_awarded
	delta.scraps_earned = payload.scraps_earned
	delta.defeated_boss_id = payload.boss_id
	delta.battle_completed = true
	delta.victory = payload.victory
	return delta


func _make_turn_payload() -> TurnResolvedPayload:
	var payload: TurnResolvedPayload = TurnResolvedPayloadResource.new()
	payload.turn_count = turn_count
	payload.player_hp = player.current_hp if player != null else 0
	payload.enemy_hp = enemy.current_hp if enemy != null else 0
	payload.player_action_id = pending_player_action.action_id if pending_player_action != null else &""
	payload.enemy_action_id = pending_enemy_action.action_id if pending_enemy_action != null else &""
	payload.presentation_events.assign(_pending_presentation_events)
	return payload


func _emit_turn_resolved(result: BattleAdvanceResult) -> void:
	last_turn_payload = _make_turn_payload()
	result.turn_payload = last_turn_payload
	turn_resolved.emit(last_turn_payload)
	_pending_presentation_events = []


func _finish_battle(victory: bool, result: BattleAdvanceResult) -> void:
	_victory = victory
	_sync_player_hp_remaining()
	state = BattleRuntimeState.COMPLETE
	result.completed = true
	if last_completed_payload == null:
		last_completed_payload = _make_ended_payload()
		last_completed_delta = _make_durable_delta(last_completed_payload)
	result.payload = last_completed_payload
	result.delta = last_completed_delta
	if not _battle_completed_signal_emitted:
		_battle_completed_signal_emitted = true
		battle_completed.emit(last_completed_payload, last_completed_delta)


func _should_complete_battle() -> bool:
	return _combatant_ko(player) or _combatant_ko(enemy)


func _determine_victory() -> bool:
	if _last_ko_phase == BattleRuntimeState.RECOIL and _last_recoil_first_ko_actor != &"":
		return _last_recoil_first_ko_actor == &"enemy"
	if _combatant_ko(enemy):
		return true
	if _combatant_ko(player):
		return false
	return _victory


func _sync_player_hp_remaining() -> void:
	if player != null:
		_player_hp_remaining = player.current_hp


func _combatant_ko(combatant: CombatantBattleState) -> bool:
	return combatant != null and combatant.current_hp <= 0


func _heal_combatant(combatant: CombatantBattleState, amount: int) -> void:
	if combatant == null or amount <= 0 or combatant.current_hp <= 0:
		return
	combatant.current_hp = min(combatant.max_hp, combatant.current_hp + amount)


func _damage_combatant(combatant: CombatantBattleState, amount: int) -> void:
	if combatant == null or amount <= 0:
		return
	combatant.current_hp = max(0, combatant.current_hp - amount)


func _npc_attack_moves() -> Array[MoveDefinition]:
	var moves: Array[MoveDefinition] = []
	for move in _move_definitions.values():
		if _is_npc_attack_move(move):
			moves.append(move)
	return moves


func _npc_status_moves() -> Array[MoveDefinition]:
	var moves: Array[MoveDefinition] = []
	for move in _move_definitions.values():
		if move != null and move.move_kind == &"status" and not move.is_reflect:
			moves.append(move)
	return moves


func _is_npc_attack_move(move: MoveDefinition) -> bool:
	return move != null and move.move_kind == &"attack" and not move.is_reflect


func _super_effective_moves(moves: Array[MoveDefinition], player_element: StringName) -> Array[MoveDefinition]:
	var preferred: Array[MoveDefinition] = []
	for move in moves:
		if _formula_service.type_effectiveness(move.element, player_element) >= 2.0:
			preferred.append(move)
	return preferred


func _highest_power_move(moves: Array[MoveDefinition]) -> MoveDefinition:
	var highest: MoveDefinition = null
	for move in moves:
		if highest == null or move.power > highest.power:
			highest = move
	return highest


func _player_has_no_active_status() -> bool:
	return player == null or player.active_status == null


func _fallback_npc_action(fallback_index: int) -> BattleAction:
	var actions: Array[BattleAction] = []
	for move in _move_definitions.values():
		if move == null or move.is_reflect:
			continue
		actions.append(_make_move_action(move))
	if can_select_defend(enemy):
		var defend: BattleAction = BattleAction.new()
		defend.action_id = ACTION_DEFEND
		defend.source = &"npc_ai"
		actions.append(defend)
	if actions.is_empty():
		var disabled: BattleAction = BattleAction.new()
		disabled.action_id = &"battle_disabled"
		disabled.source = &"npc_ai"
		return disabled
	return actions[abs(fallback_index) % actions.size()]


func _make_move_action(move: MoveDefinition) -> BattleAction:
	var action: BattleAction = BattleAction.new()
	action.action_id = ACTION_STATUS if move.move_kind == &"status" else ACTION_ATTACK
	action.move_id = move.move_id
	action.source = &"npc_ai"
	return action


func _tick_recoil_status(combatant: CombatantBattleState, result: BattleRecoilResult, actor_id: StringName) -> int:
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


func _dot_damage_for_status(combatant: CombatantBattleState, status_id: StringName) -> int:
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
	_expedition_defrag_patch_available = false
	_consumed_item_flags = []
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
	_expedition_defrag_patch_available = setup.expedition_defrag_patch


## Applies Defend cooldown changes after a legal TELEGRAPH action is accepted.
func apply_action_cooldown(combatant: CombatantBattleState, action: BattleAction) -> void:
	if combatant == null or action == null:
		return
	if action.action_id == ACTION_DEFEND:
		combatant.defend_cooldown_turns = 1
	elif combatant.defend_cooldown_turns > 0:
		combatant.defend_cooldown_turns = 0


func _has_pending_action(is_player_action: bool) -> bool:
	if is_player_action:
		return pending_player_action != null
	return pending_enemy_action != null


func _begin_next_telegraph_turn() -> void:
	turn_count += 1
	pending_player_action = null
	pending_enemy_action = null


func _is_legal_consumable_action(action: BattleAction) -> bool:
	if action.item_id != DEFRAG_PATCH_FLAG and action.item_id != DEFRAG_PATCH_ITEM_ID:
		return false
	return _expedition_defrag_patch_available


func _apply_impact_entry_effects() -> void:
	if pending_player_action == null:
		return
	if pending_player_action.action_id != ACTION_CONSUMABLE:
		return
	if not _is_defrag_patch_action(pending_player_action):
		return

	if player != null:
		player.clear_status()
	_expedition_defrag_patch_available = false
	if not _consumed_item_flags.has(DEFRAG_PATCH_FLAG):
		_consumed_item_flags.append(DEFRAG_PATCH_FLAG)


func _is_defrag_patch_action(action: BattleAction) -> bool:
	return action != null and action.action_id == ACTION_CONSUMABLE and (
		action.item_id == DEFRAG_PATCH_FLAG or action.item_id == DEFRAG_PATCH_ITEM_ID
	)


func _snapshot_animation_setup(setup: BattleSetupPayload) -> void:
	_battle_definition = null
	_animation_manifest = null
	_move_definitions = {}
	_actor_sets_by_id = {}
	_clips_by_id = {}
	_bindings_by_actor_move = {}
	_bindings_by_actor_action = {}
	_bindings_by_move_id = {}
	if setup == null:
		return

	if setup.battle_definition != null:
		_battle_definition = setup.battle_definition.duplicate()
	_animation_manifest = setup.animation_manifest
	_move_definitions = setup.move_definitions.duplicate()
	if _animation_manifest == null:
		return

	for clip in _animation_manifest.global_clips:
		if clip == null or clip.clip_id == &"":
			continue
		_clips_by_id[clip.clip_id] = clip

	for actor_set in _animation_manifest.actor_sets:
		if actor_set == null or actor_set.actor_id == &"":
			continue
		_actor_sets_by_id[actor_set.actor_id] = actor_set
		for binding in actor_set.action_bindings:
			if binding == null:
				continue
			if binding.move_id != &"":
				_bindings_by_actor_move[_binding_key(actor_set.actor_id, binding.move_id)] = binding
				if not _bindings_by_move_id.has(binding.move_id):
					_bindings_by_move_id[binding.move_id] = []
				_bindings_by_move_id[binding.move_id].append(binding)
			if binding.animation_action_id != &"":
				_bindings_by_actor_action[_binding_key(actor_set.actor_id, binding.animation_action_id)] = binding


func _make_animation_lookup_result(actor_set_id: StringName, move_id: StringName) -> BattleAnimationLookupResult:
	var result: BattleAnimationLookupResult = BattleAnimationLookupResultResource.new()
	result.actor_set_id = actor_set_id
	result.move_id = move_id
	if _battle_definition != null:
		result.battle_id = _battle_definition.battle_id
	if _animation_manifest != null:
		result.manifest_id = _animation_manifest.manifest_id
	return result


func _ensure_animation_context(result: BattleAnimationLookupResult) -> bool:
	if _battle_definition == null:
		_fail_animation_lookup(result, &"missing_battle_definition", "Battle animation lookup requires a BattleDefinition.")
		return false
	if _animation_manifest == null:
		_fail_animation_lookup(result, &"missing_animation_manifest", "Battle animation lookup requires a BattleAnimationManifest.")
		return false
	if _battle_definition.animation_manifest_id != _animation_manifest.manifest_id:
		_fail_animation_lookup(result, &"manifest_id_mismatch", "BattleDefinition expects animation manifest '%s' but setup provided '%s'." % [_battle_definition.animation_manifest_id, _animation_manifest.manifest_id])
		return false
	return true


func _binding_key(actor_set_id: StringName, key_id: StringName) -> StringName:
	return StringName("%s:%s" % [actor_set_id, key_id])


func _resolve_receive_clip_for_binding(
		result: BattleAnimationLookupResult,
		target_actor_set: BattleActorAnimationSet,
		binding: BattleActionAnimationBinding,
		source_move_id: StringName
) -> BattleAnimationLookupResult:
	if binding.receive_clip_id == &"":
		return _fail_animation_lookup(result, &"missing_receive_clip", "Binding '%s' has no receive clip for incoming move '%s'." % [binding.binding_id, source_move_id])
	if not target_actor_set.required_base_clip_ids().has(binding.receive_clip_id):
		return _fail_animation_lookup(result, &"missing_receive_clip", "Binding '%s' receive clip '%s' is not a required base clip for target actor set '%s'." % [binding.binding_id, binding.receive_clip_id, target_actor_set.actor_id])
	result.binding = binding
	result.receive_clip = _clips_by_id.get(binding.receive_clip_id)
	if result.receive_clip == null:
		return _fail_animation_lookup(result, &"missing_receive_clip", "Binding '%s' references missing receive clip '%s'." % [binding.binding_id, binding.receive_clip_id])
	result.success = true
	result.reason = &"ok"
	return result


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


func _fail_status_result(result: BattleStatusApplyResult, reason: StringName, error_message: String) -> BattleStatusApplyResult:
	result.success = false
	result.applied = false
	result.reason = reason
	result.error_message = error_message
	return result


func _fail_animation_lookup(result: BattleAnimationLookupResult, reason: StringName, error_message: String) -> BattleAnimationLookupResult:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	return result
