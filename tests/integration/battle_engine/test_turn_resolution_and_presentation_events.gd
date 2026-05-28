extends GutTest

const BattleActionScript = preload("res://src/battle/runtime/battle_action.gd")
const BattleRuntimeStateScript = preload("res://src/battle/runtime/battle_runtime_state.gd")
const BattleSessionScript = preload("res://src/battle/runtime/battle_session.gd")
const BattleSetupPayloadScript = preload("res://src/battle/runtime/battle_setup_payload.gd")
const CombatantBattleStateScript = preload("res://src/battle/runtime/combatant_battle_state.gd")
const StatusRuntimeStateScript = preload("res://src/battle/runtime/status_runtime_state.gd")


func test_simultaneous_impact_ko_player_wins_but_recoil_ko_uses_declaration_order() -> void:
	var impact_session: BattleSession = _make_session()
	impact_session.state = BattleRuntimeState.IMPACT
	impact_session.player = _make_combatant(10, 10)
	impact_session.enemy = _make_combatant(10, 10)

	impact_session.resolve_impact_effects(10, 10)
	assert_eq(impact_session.player.current_hp, 0)
	assert_eq(impact_session.enemy.current_hp, 0)

	var impact_recoil: BattleAdvanceResult = impact_session.transition_to(BattleRuntimeState.RECOIL)
	var impact_resolution: BattleAdvanceResult = impact_session.transition_to(BattleRuntimeState.RESOLUTION)

	assert_true(impact_recoil.success, impact_recoil.reason)
	assert_true(impact_resolution.success, impact_resolution.reason)
	assert_true(impact_resolution.completed)
	assert_eq(impact_session.state, BattleRuntimeState.COMPLETE)
	assert_true(impact_session.last_completed_payload.victory)

	var recoil_session: BattleSession = _make_session()
	recoil_session.state = BattleRuntimeState.RECOIL
	recoil_session.player = _make_combatant(100, 1)
	recoil_session.enemy = _make_combatant(100, 1)
	recoil_session.player.active_status = _make_status(recoil_session.STATUS_BURN, 1)
	recoil_session.enemy.active_status = _make_status(recoil_session.STATUS_POISON, 1)

	var recoil: BattleRecoilResult = recoil_session.resolve_recoil(recoil_session.player, recoil_session.enemy)
	var recoil_resolution: BattleAdvanceResult = recoil_session.transition_to(BattleRuntimeState.RESOLUTION)

	assert_eq(recoil.tick_order, [&"player", &"enemy"])
	assert_eq(recoil.first_ko_actor, &"player")
	assert_true(recoil_resolution.completed)
	assert_false(recoil_session.last_completed_payload.victory)


func test_defrag_patch_consumable_applies_before_impact_damage_and_reports_delta() -> void:
	var session: BattleSession = _make_session(true)
	session.state = BattleRuntimeState.TELEGRAPH
	session.player = _make_combatant(100, 100)
	session.enemy = _make_combatant(100, 100)
	session.player.active_status = _make_status(session.STATUS_BURN, 2)
	session.player.pending_skip = session.STATUS_BURN

	var submitted: BattleActionResult = session.submit_action(_make_consumable_action(session.DEFRAG_PATCH_FLAG))
	var impact: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)

	assert_true(submitted.success, submitted.reason)
	assert_true(impact.success, impact.reason)
	assert_null(session.player.active_status)
	assert_eq(session.player.pending_skip, &"")

	session.resolve_impact_effects(0, 30)

	assert_eq(session.player.current_hp, 70)
	assert_eq(session.enemy.current_hp, 100)
	assert_eq(session.get_consumed_item_flags(), [session.DEFRAG_PATCH_FLAG])

	session.enemy.current_hp = 0
	var recoil: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RECOIL)
	var resolution: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RESOLUTION)

	assert_true(recoil.success, recoil.reason)
	assert_true(resolution.completed)
	assert_eq(resolution.delta.consumed_item_flags, [session.DEFRAG_PATCH_FLAG])


func test_fifty_turn_loop_with_freeze_and_paralysis_skip_has_no_illegal_transitions() -> void:
	var session: BattleSession = _make_session()
	session.state = BattleRuntimeState.TELEGRAPH
	session.player = _make_combatant(100, 100)
	session.enemy = _make_combatant(100, 100)
	var freeze_skip_seen: bool = false
	var paralysis_skip_seen: bool = false

	for turn in range(50):
		if turn == 7:
			session.player.active_status = _make_status(session.STATUS_FREEZE, 1)
			session.player.pending_skip = session.STATUS_FREEZE
		if turn == 23:
			session.enemy.active_status = _make_status(session.STATUS_PARALYSIS, 2)

		if session.should_skip_telegraph_action(session.player, 1.0):
			freeze_skip_seen = true
		else:
			assert_true(session.submit_action(_make_action(&"battle_attack")).success)

		if session.should_skip_telegraph_action(session.enemy, 0.0):
			paralysis_skip_seen = true
		else:
			assert_true(session.submit_enemy_action(_make_action(&"battle_attack")).success)

		_advance_to_next_telegraph(session)

	assert_true(freeze_skip_seen)
	assert_true(paralysis_skip_seen)
	assert_eq(session.turn_count, 50)
	assert_eq(session.state, BattleRuntimeState.TELEGRAPH)


func test_presentation_profile_signals_emit_exactly_once_when_triggered() -> void:
	var session: BattleSession = _make_session()
	session.state = BattleRuntimeState.RECOIL
	session.player = _make_combatant(100, 100)
	session.enemy = _make_combatant(100, 100)
	var observed_events: Array[StringName] = []
	session.presentation_event.connect(func(payload: PresentationEventPayload) -> void:
		observed_events.append(payload.event_id)
	)

	for event_id in [
		&"miss",
		&"resisted_hit",
		&"normal_hit",
		&"effective_hit",
		&"critical_hit",
		&"status_apply",
		&"ko",
	]:
		var payload: PresentationEventPayload = session.emit_presentation_event_id(event_id, &"enemy")
		assert_eq(payload.event_id, event_id)
		assert_eq(payload.subject_id, &"enemy")

	assert_eq(observed_events, [
		&"miss",
		&"resisted_hit",
		&"normal_hit",
		&"effective_hit",
		&"critical_hit",
		&"status_apply",
		&"ko",
	])

	var resolution: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RESOLUTION)
	assert_true(resolution.success, resolution.reason)
	assert_not_null(resolution.turn_payload)
	assert_eq(resolution.turn_payload.presentation_events.size(), 7)
	for index in range(observed_events.size()):
		assert_eq(resolution.turn_payload.presentation_events[index].event_id, observed_events[index])

	var next_telegraph: BattleAdvanceResult = session.transition_to(BattleRuntimeState.TELEGRAPH)
	assert_true(next_telegraph.success, next_telegraph.reason)
	var next_impact: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)
	assert_true(next_impact.success, next_impact.reason)
	var next_recoil: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RECOIL)
	assert_true(next_recoil.success, next_recoil.reason)
	var next_resolution: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RESOLUTION)
	assert_true(next_resolution.success, next_resolution.reason)
	assert_eq(next_resolution.turn_payload.presentation_events.size(), 0)


func test_turn_resolved_and_battle_completed_emit_once_and_complete_rejects_further_advance() -> void:
	var loop_session: BattleSession = _make_session()
	loop_session.state = BattleRuntimeState.RECOIL
	loop_session.player = _make_combatant(100, 80)
	loop_session.enemy = _make_combatant(100, 70)
	loop_session.pending_player_action = _make_action(&"battle_attack")
	loop_session.pending_enemy_action = _make_action(&"battle_defend")
	var turns: Array[TurnResolvedPayload] = []
	loop_session.turn_resolved.connect(func(payload: TurnResolvedPayload) -> void:
		turns.append(payload)
	)

	var loop_resolution: BattleAdvanceResult = loop_session.transition_to(BattleRuntimeState.RESOLUTION)

	assert_true(loop_resolution.success, loop_resolution.reason)
	assert_false(loop_resolution.completed)
	assert_eq(turns.size(), 1)
	assert_eq(turns[0].player_hp, 80)
	assert_eq(turns[0].enemy_hp, 70)
	assert_eq(turns[0].player_action_id, &"battle_attack")
	assert_eq(turns[0].enemy_action_id, &"battle_defend")

	var ko_session: BattleSession = _make_session()
	ko_session.state = BattleRuntimeState.IMPACT
	ko_session.player = _make_combatant(100, 50)
	ko_session.enemy = _make_combatant(100, 10)
	var completed_payloads: Array[BattleEndedPayload] = []
	var completed_deltas: Array[BattleDurableDelta] = []
	ko_session.battle_completed.connect(func(payload: BattleEndedPayload, delta: BattleDurableDelta) -> void:
		completed_payloads.append(payload)
		completed_deltas.append(delta)
	)

	ko_session.resolve_impact_effects(10, 0)
	var ko_recoil: BattleAdvanceResult = ko_session.transition_to(BattleRuntimeState.RECOIL)
	var ko_resolution: BattleAdvanceResult = ko_session.transition_to(BattleRuntimeState.RESOLUTION)
	var repeated_advance: BattleAdvanceResult = ko_session.advance()

	assert_true(ko_recoil.success, ko_recoil.reason)
	assert_true(ko_resolution.completed)
	assert_eq(completed_payloads.size(), 1)
	assert_eq(completed_deltas.size(), 1)
	assert_true(completed_payloads[0].victory)
	assert_eq(completed_payloads[0].raw_xp_awarded, 10)
	assert_eq(completed_payloads[0].scraps_earned, 2)
	assert_eq(completed_payloads[0].player_hp_remaining, 50)
	assert_eq(completed_payloads[0].player_level_start, 6)
	assert_eq(completed_payloads[0].enemy_level, 7)
	assert_true(completed_deltas[0].battle_completed)
	assert_eq(completed_deltas[0].raw_xp_awarded, completed_payloads[0].raw_xp_awarded)
	assert_eq(ko_session.state, BattleRuntimeState.COMPLETE)
	assert_false(repeated_advance.success)
	assert_eq(repeated_advance.reason, &"session_complete")

	var defeat_session: BattleSession = _make_session()
	defeat_session.state = BattleRuntimeState.IMPACT
	defeat_session.player = _make_combatant(100, 10)
	defeat_session.enemy = _make_combatant(100, 50)

	defeat_session.resolve_impact_effects(0, 10)
	assert_true(defeat_session.transition_to(BattleRuntimeState.RECOIL).success)
	var defeat_resolution: BattleAdvanceResult = defeat_session.transition_to(BattleRuntimeState.RESOLUTION)

	assert_true(defeat_resolution.completed)
	assert_false(defeat_resolution.payload.victory)
	assert_eq(defeat_resolution.payload.raw_xp_awarded, 10)
	assert_eq(defeat_resolution.payload.scraps_earned, 2)
	assert_eq(defeat_resolution.payload.player_hp_remaining, 0)
	assert_eq(defeat_resolution.payload.player_level_start, 6)
	assert_eq(defeat_resolution.payload.enemy_level, 7)


func _make_session(defrag_available: bool = false) -> BattleSession:
	var session: BattleSession = BattleSessionScript.new()
	session.configure(_make_setup(defrag_available))
	return session


func _make_setup(defrag_available: bool) -> BattleSetupPayload:
	var setup: BattleSetupPayload = BattleSetupPayloadScript.new()
	setup.battle_id = &"turn_resolution_test"
	setup.raw_xp_awarded = 10
	setup.scraps_earned = 2
	setup.player_level_start = 6
	setup.enemy_level = 7
	setup.player_dragon_id = &"root_dragon"
	setup.expedition_defrag_patch = defrag_available
	return setup


func _make_combatant(max_hp: int, current_hp: int) -> CombatantBattleState:
	var combatant: CombatantBattleState = CombatantBattleStateScript.new()
	combatant.combatant_id = &"combatant"
	combatant.max_hp = max_hp
	combatant.current_hp = current_hp
	combatant.base_defense = 40
	return combatant


func _make_status(status_id: StringName, duration_turns: int) -> StatusRuntimeState:
	var status: StatusRuntimeState = StatusRuntimeStateScript.new()
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


func _advance_to_next_telegraph(session: BattleSession) -> void:
	var impact: BattleAdvanceResult = session.transition_to(BattleRuntimeState.IMPACT)
	assert_true(impact.success, impact.reason)
	var recoil: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RECOIL)
	assert_true(recoil.success, recoil.reason)
	var resolution: BattleAdvanceResult = session.transition_to(BattleRuntimeState.RESOLUTION)
	assert_true(resolution.success, resolution.reason)
	var telegraph: BattleAdvanceResult = session.transition_to(BattleRuntimeState.TELEGRAPH)
	assert_true(telegraph.success, telegraph.reason)
