extends GutTest

const BattleActionScript = preload("res://src/battle/runtime/battle_action.gd")
const BattleRuntimeStateScript = preload("res://src/battle/runtime/battle_runtime_state.gd")
const BattleSessionScript = preload("res://src/battle/runtime/battle_session.gd")
const BattleSetupPayloadScript = preload("res://src/battle/runtime/battle_setup_payload.gd")
const CombatantBattleStateScript = preload("res://src/battle/runtime/combatant_battle_state.gd")
const StatusRuntimeStateScript = preload("res://src/battle/runtime/status_runtime_state.gd")


func test_defend_cooldown_blocks_player_next_turn_until_another_action() -> void:
	var session: BattleSession = _make_session(false)
	session.player = _make_combatant()

	var first_defend: BattleActionResult = session.submit_action(_make_action(session.ACTION_DEFEND))
	assert_true(first_defend.success, first_defend.reason)
	assert_eq(session.player.defend_cooldown_turns, 1)

	_advance_to_next_telegraph(session)

	var repeated_defend: BattleActionResult = session.submit_action(_make_action(session.ACTION_DEFEND))
	assert_false(repeated_defend.success)
	assert_eq(repeated_defend.reason, &"defend_on_cooldown")

	var attack: BattleActionResult = session.submit_action(_make_action(&"battle_attack"))
	assert_true(attack.success, attack.reason)
	assert_eq(session.player.defend_cooldown_turns, 0)

	_advance_to_next_telegraph(session)

	var second_defend: BattleActionResult = session.submit_action(_make_action(session.ACTION_DEFEND))
	assert_true(second_defend.success, second_defend.reason)


func test_npc_submitted_defend_uses_same_runtime_cooldown_legality() -> void:
	var session: BattleSession = _make_session(false)
	session.enemy = _make_combatant()

	var first_defend: BattleActionResult = session.submit_enemy_action(_make_action(session.ACTION_DEFEND))
	assert_true(first_defend.success, first_defend.reason)

	_advance_to_next_telegraph(session)

	var repeated_defend: BattleActionResult = session.submit_enemy_action(_make_action(session.ACTION_DEFEND))
	assert_false(repeated_defend.success)
	assert_eq(repeated_defend.reason, &"defend_on_cooldown")

	var status_action: BattleActionResult = session.submit_enemy_action(_make_action(&"battle_status"))
	assert_true(status_action.success, status_action.reason)
	assert_eq(session.enemy.defend_cooldown_turns, 0)

	_advance_to_next_telegraph(session)

	var second_defend: BattleActionResult = session.submit_enemy_action(_make_action(session.ACTION_DEFEND))
	assert_true(second_defend.success, second_defend.reason)


func test_defend_cooldown_survives_status_skip_until_another_action_is_accepted() -> void:
	var session: BattleSession = _make_session(false)
	session.player = _make_combatant()

	var first_defend: BattleActionResult = session.submit_action(_make_action(session.ACTION_DEFEND))
	assert_true(first_defend.success, first_defend.reason)

	_advance_to_next_telegraph(session)
	session.player.active_status = _make_status(session.STATUS_FREEZE, 1)
	session.player.pending_skip = session.STATUS_FREEZE

	assert_true(session.should_skip_telegraph_action(session.player, 1.0))
	assert_false(session.can_select_defend(session.player))
	assert_eq(session.player.defend_cooldown_turns, 1)

	_advance_to_next_telegraph(session)

	var repeated_defend: BattleActionResult = session.submit_action(_make_action(session.ACTION_DEFEND))
	assert_false(repeated_defend.success)
	assert_eq(repeated_defend.reason, &"defend_on_cooldown")

	var attack: BattleActionResult = session.submit_action(_make_action(&"battle_attack"))
	assert_true(attack.success, attack.reason)
	assert_eq(session.player.defend_cooldown_turns, 0)


func test_telegraph_accepts_only_one_valid_action_per_combatant() -> void:
	var session: BattleSession = _make_session(true)
	session.player = _make_combatant()
	session.enemy = _make_combatant()

	var player_defrag: BattleActionResult = session.submit_action(_make_consumable_action(session.DEFRAG_PATCH_FLAG))
	var player_attack: BattleActionResult = session.submit_action(_make_action(&"battle_attack"))
	var enemy_defend: BattleActionResult = session.submit_enemy_action(_make_action(session.ACTION_DEFEND))
	var enemy_attack: BattleActionResult = session.submit_enemy_action(_make_action(&"battle_attack"))

	assert_true(player_defrag.success, player_defrag.reason)
	assert_false(player_attack.success)
	assert_eq(player_attack.reason, &"action_already_submitted")
	assert_true(enemy_defend.success, enemy_defend.reason)
	assert_false(enemy_attack.success)
	assert_eq(enemy_attack.reason, &"action_already_submitted")


func test_defrag_patch_clears_active_player_status_before_impact_and_reports_delta() -> void:
	var session: BattleSession = _make_session(true)
	session.player = _make_combatant()
	session.player.active_status = _make_status(session.STATUS_BURN, 2)
	session.player.pending_skip = session.STATUS_BURN

	var submit_result: BattleActionResult = session.submit_action(_make_consumable_action(session.DEFRAG_PATCH_FLAG))
	var impact_result: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)

	assert_true(submit_result.success, submit_result.reason)
	assert_true(impact_result.success, impact_result.reason)
	assert_null(session.player.active_status)
	assert_eq(session.player.pending_skip, &"")
	assert_eq(session.get_consumed_item_flags(), [session.DEFRAG_PATCH_FLAG])
	assert_eq(session.available_telegraph_item_flags(), [])

	_complete_session(session)

	assert_not_null(session.last_completed_delta)
	assert_eq(session.last_completed_delta.consumed_item_flags, [session.DEFRAG_PATCH_FLAG])


func test_defrag_patch_with_no_status_still_consumes_without_status_mutation() -> void:
	var session: BattleSession = _make_session(true)
	session.player = _make_combatant()

	var submit_result: BattleActionResult = session.submit_action(_make_consumable_action(session.DEFRAG_PATCH_FLAG))
	var impact_result: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)

	assert_true(submit_result.success, submit_result.reason)
	assert_true(impact_result.success, impact_result.reason)
	assert_null(session.player.active_status)
	assert_eq(session.player.pending_skip, &"")
	assert_eq(session.get_consumed_item_flags(), [session.DEFRAG_PATCH_FLAG])
	assert_eq(session.available_telegraph_item_flags(), [])

	_complete_session(session)

	assert_not_null(session.last_completed_delta)
	assert_eq(session.last_completed_delta.consumed_item_flags, [session.DEFRAG_PATCH_FLAG])


func test_only_defrag_patch_is_available_as_in_battle_consumable() -> void:
	var session: BattleSession = _make_session(true)
	session.player = _make_combatant()

	assert_eq(session.available_telegraph_item_flags(), [session.DEFRAG_PATCH_FLAG])
	assert_false(session.available_telegraph_item_flags().has(&"expedition_emergency_patch"))

	var emergency_patch: BattleActionResult = session.submit_action(_make_consumable_action(&"expedition_emergency_patch"))
	assert_false(emergency_patch.success)
	assert_eq(emergency_patch.reason, &"item_unavailable")

	for map_item_id in [&"expedition_field_kit", &"expedition_cache_shard"]:
		assert_false(session.available_telegraph_item_flags().has(map_item_id))
		var map_item: BattleActionResult = session.submit_action(_make_consumable_action(map_item_id))
		assert_false(map_item.success)
		assert_eq(map_item.reason, &"item_unavailable")

	var absent_session: BattleSession = _make_session(false)
	absent_session.player = _make_combatant()
	assert_eq(absent_session.available_telegraph_item_flags(), [])

	var absent_defrag: BattleActionResult = absent_session.submit_action(_make_consumable_action(absent_session.DEFRAG_PATCH_FLAG))
	assert_false(absent_defrag.success)
	assert_eq(absent_defrag.reason, &"item_unavailable")


func _make_session(defrag_available: bool) -> BattleSession:
	var session: BattleSession = BattleSessionScript.new()
	session.configure(_make_setup(defrag_available))
	session.state = BattleRuntimeState.TELEGRAPH
	return session


func _make_setup(defrag_available: bool) -> BattleSetupPayload:
	var setup: BattleSetupPayload = BattleSetupPayloadScript.new()
	setup.battle_id = &"telegraph_defend_defrag_test"
	setup.complete_on_resolution = true
	setup.victory = true
	setup.raw_xp_awarded = 1
	setup.scraps_earned = 0
	setup.player_hp_remaining = 42
	setup.player_level_start = 4
	setup.enemy_level = 4
	setup.player_dragon_id = &"root_dragon"
	setup.expedition_defrag_patch = defrag_available
	return setup


func _make_combatant() -> RefCounted:
	var combatant: RefCounted = CombatantBattleStateScript.new()
	combatant.combatant_id = &"combatant"
	combatant.dragon_id = &"dragon"
	combatant.max_hp = 100
	combatant.current_hp = 100
	combatant.base_defense = 40
	return combatant


func _make_status(status_id: StringName, duration_turns: int) -> RefCounted:
	var status: RefCounted = StatusRuntimeStateScript.new()
	status.status_id = status_id
	status.duration_turns = duration_turns
	return status


func _make_action(action_id: StringName) -> BattleAction:
	var action: BattleAction = BattleActionScript.new()
	action.action_id = action_id
	action.source = &"test"
	return action


func _make_consumable_action(item_id: StringName) -> BattleAction:
	var action: BattleAction = _make_action(&"battle_consumable")
	action.item_id = item_id
	return action


func _complete_session(session: BattleSession) -> void:
	while session.state != BattleRuntimeState.COMPLETE:
		var result: BattleAdvanceResult = session.advance()
		assert_true(result.success, result.reason)


func _advance_to_next_telegraph(session: BattleSession) -> void:
	var impact: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)
	assert_true(impact.success, impact.reason)
	var recoil: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RECOIL)
	assert_true(recoil.success, recoil.reason)
	var resolution: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RESOLUTION)
	assert_true(resolution.success, resolution.reason)
	var telegraph: BattleAdvanceResult = session.transition_to(BattleRuntimeState.TELEGRAPH)
	assert_true(telegraph.success, telegraph.reason)
