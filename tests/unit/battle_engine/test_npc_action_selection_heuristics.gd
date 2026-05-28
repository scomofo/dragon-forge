extends GutTest

const BattleActionScript = preload("res://src/battle/runtime/battle_action.gd")
const BattleRuntimeStateScript = preload("res://src/battle/runtime/battle_runtime_state.gd")
const BattleSessionScript = preload("res://src/battle/runtime/battle_session.gd")
const BattleSetupPayloadScript = preload("res://src/battle/runtime/battle_setup_payload.gd")
const CombatantBattleStateScript = preload("res://src/battle/runtime/combatant_battle_state.gd")
const MoveDefinitionScript = preload("res://src/battle/data/move_definition.gd")
const StatusRuntimeStateScript = preload("res://src/battle/runtime/status_runtime_state.gd")


func test_npc_prefers_super_effective_attack_at_seventy_percent_with_priority_over_status_and_power() -> void:
	var session: BattleSession = _make_session([
		_make_move(&"fire_bite", &"Fire", &"attack", 30),
		_make_move(&"stone_slam", &"Stone", &"attack", 90),
		_make_move(&"poison_cloud", &"Venom", &"status", 0, &"poison"),
	])
	session.enemy = _make_combatant()
	var super_effective_count: int = 0

	for index in range(100):
		var selected: BattleAction = session.select_npc_action(&"Ice", float(index) / 100.0, 0)
		if selected.move_id == &"fire_bite":
			super_effective_count += 1

	assert_eq(super_effective_count, 70)
	assert_eq(session.select_npc_action(&"Ice", 0.69, 0).move_id, &"fire_bite")
	assert_eq(session.select_npc_action(&"Ice", 0.70, 0).move_id, &"stone_slam")


func test_npc_prefers_status_at_forty_percent_only_when_no_super_effective_and_target_is_clean() -> void:
	var session: BattleSession = _make_session([
		_make_move(&"stone_slam", &"Stone", &"attack", 90),
		_make_move(&"poison_cloud", &"Venom", &"status", 0, &"poison"),
	])
	session.enemy = _make_combatant()
	session.player = _make_combatant()

	var status_count: int = 0
	for index in range(100):
		var selected: BattleAction = session.select_npc_action(&"Ice", float(index) / 100.0, 0)
		if selected.move_id == &"poison_cloud":
			status_count += 1

	assert_eq(status_count, 40)
	assert_eq(session.select_npc_action(&"Ice", 0.39, 0).move_id, &"poison_cloud")
	assert_eq(session.select_npc_action(&"Ice", 0.40, 0).move_id, &"stone_slam")

	session.player.active_status = _make_status(session.STATUS_BURN, 2)
	assert_eq(session.select_npc_action(&"Ice", 0.0, 0).move_id, &"stone_slam")


func test_npc_prefers_highest_power_fallback_at_sixty_percent_then_random_themed_move() -> void:
	var session: BattleSession = _make_session([
		_make_move(&"ember", &"Fire", &"attack", 20),
		_make_move(&"stone_slam", &"Stone", &"attack", 90),
		_make_move(&"venom_jab", &"Venom", &"attack", 45),
	])
	session.enemy = _make_combatant()

	var high_power_count: int = 0
	for index in range(100):
		var selected: BattleAction = session.select_npc_action(&"Void", float(index) / 100.0, 2)
		if selected.move_id == &"stone_slam":
			high_power_count += 1

	assert_eq(high_power_count, 60)
	assert_eq(session.select_npc_action(&"Void", 0.59, 0).move_id, &"stone_slam")
	assert_eq(session.select_npc_action(&"Void", 0.60, 2).move_id, &"venom_jab")


func test_npc_respects_defend_cooldown_and_defend_returns_after_another_action() -> void:
	var session: BattleSession = _make_session([
		_make_move(&"ember", &"Fire", &"attack", 20),
	])
	session.state = BattleRuntimeState.TELEGRAPH
	session.enemy = _make_combatant()

	var defend: BattleActionResult = session.submit_enemy_action(_make_defend_action())
	assert_true(defend.success, defend.reason)

	_advance_to_next_telegraph(session)

	var selected_on_cooldown: BattleAction = session.select_npc_action(&"Void", 0.99, 1)
	assert_eq(selected_on_cooldown.action_id, &"battle_attack")
	assert_ne(selected_on_cooldown.action_id, session.ACTION_DEFEND)

	var attack: BattleActionResult = session.submit_enemy_action(selected_on_cooldown)
	assert_true(attack.success, attack.reason)

	_advance_to_next_telegraph(session)

	var selected_after_attack: BattleAction = session.select_npc_action(&"Void", 0.99, 1)
	assert_eq(selected_after_attack.action_id, session.ACTION_DEFEND)


func test_npc_cannot_submit_player_consumables_even_when_defrag_is_available() -> void:
	var setup: BattleSetupPayload = BattleSetupPayloadScript.new()
	setup.battle_id = &"npc_selection_consumable_test"
	setup.expedition_defrag_patch = true
	var session: BattleSession = BattleSessionScript.new()
	session.configure(setup)
	session.state = BattleRuntimeState.TELEGRAPH
	session.enemy = _make_combatant()

	var result: BattleActionResult = session.submit_enemy_action(_make_consumable_action(session.DEFRAG_PATCH_FLAG))

	assert_false(result.success)
	assert_false(result.accepted)
	assert_eq(result.reason, &"item_unavailable")
	assert_null(session.pending_enemy_action)


func test_npc_selection_does_not_mutate_authored_move_resources() -> void:
	var root_spark: MoveDefinition = _make_move(&"root_spark", &"Fire", &"attack", 50)
	var original_power: int = root_spark.power
	var original_kind: StringName = root_spark.move_kind
	var session: BattleSession = _make_session([root_spark])
	session.enemy = _make_combatant()

	var selected: BattleAction = session.select_npc_action(&"Ice", 0.0, 0)

	assert_eq(selected.move_id, &"root_spark")
	assert_eq(root_spark.power, original_power)
	assert_eq(root_spark.move_kind, original_kind)


func _make_session(moves: Array[MoveDefinition]) -> BattleSession:
	var setup: BattleSetupPayload = BattleSetupPayloadScript.new()
	setup.battle_id = &"npc_selection_test"
	for move in moves:
		setup.move_definitions[move.move_id] = move
	var session: BattleSession = BattleSessionScript.new()
	session.configure(setup)
	session.player = _make_combatant()
	return session


func _make_move(
		move_id: StringName,
		element: StringName,
		move_kind: StringName,
		power: int,
		status_id: StringName = &""
) -> MoveDefinition:
	var move: MoveDefinition = MoveDefinitionScript.new()
	move.move_id = move_id
	move.element = element
	move.move_kind = move_kind
	move.power = power
	move.status_id = status_id
	return move


func _make_combatant() -> CombatantBattleState:
	var combatant: CombatantBattleState = CombatantBattleStateScript.new()
	combatant.max_hp = 100
	combatant.current_hp = 100
	combatant.base_defense = 40
	return combatant


func _make_status(status_id: StringName, duration_turns: int) -> StatusRuntimeState:
	var status: StatusRuntimeState = StatusRuntimeStateScript.new()
	status.status_id = status_id
	status.duration_turns = duration_turns
	return status


func _make_defend_action() -> BattleAction:
	var action: BattleAction = BattleActionScript.new()
	action.action_id = &"battle_defend"
	action.source = &"test"
	return action


func _make_consumable_action(item_id: StringName) -> BattleAction:
	var action: BattleAction = BattleActionScript.new()
	action.action_id = &"battle_consumable"
	action.item_id = item_id
	action.source = &"test"
	return action


func _advance_to_next_telegraph(session: BattleSession) -> void:
	var impact: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)
	assert_true(impact.success, impact.reason)
	var recoil: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RECOIL)
	assert_true(recoil.success, recoil.reason)
	var resolution: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RESOLUTION)
	assert_true(resolution.success, resolution.reason)
	var telegraph: BattleAdvanceResult = session.transition_to(BattleRuntimeState.TELEGRAPH)
	assert_true(telegraph.success, telegraph.reason)
