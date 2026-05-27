extends GutTest

const BattleRuntimeControllerScript = preload("res://src/battle/runtime/battle_runtime_controller.gd")
const BattleRuntimeStateScript = preload("res://src/battle/runtime/battle_runtime_state.gd")
const BattleActionScript = preload("res://src/battle/runtime/battle_action.gd")
const BattleSessionScript = preload("res://src/battle/runtime/battle_session.gd")
const BattleSetupPayloadScript = preload("res://src/battle/runtime/battle_setup_payload.gd")
const BattlePhaseCheckpointDeltaScript = preload("res://src/battle/runtime/battle_phase_checkpoint_delta.gd")
const PresentationEventPayloadScript = preload("res://src/battle/runtime/presentation_event_payload.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")


func test_controller_owns_one_refcounted_session_and_rejects_overlap() -> void:
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var first_start: BattleStartResult = controller.start_battle(_make_setup(false))
	var second_start: BattleStartResult = controller.start_battle(_make_setup(false))

	assert_true(first_start.success, first_start.reason)
	assert_not_null(first_start.session)
	assert_true(first_start.session is BattleSession)
	assert_true(first_start.session is RefCounted)
	assert_eq(controller.get_session(), first_start.session)
	assert_false(second_start.success)
	assert_eq(second_start.reason, &"session_already_active")


func test_session_advances_legal_phase_graph_and_rejects_illegal_transitions() -> void:
	var session: BattleSession = BattleSessionScript.new()
	session.configure(_make_setup(false))

	var observed_states: Array[StringName] = [session.state]
	for index in 5:
		var advance_result: BattleAdvanceResult = session.advance()
		assert_true(advance_result.success, advance_result.reason)
		observed_states.append(session.state)

	assert_eq(observed_states, [
		BattleRuntimeState.INIT,
		BattleRuntimeState.TELEGRAPH,
		BattleRuntimeState.IMPACT,
		BattleRuntimeState.RECOIL,
		BattleRuntimeState.RESOLUTION,
		BattleRuntimeState.TELEGRAPH,
	])

	var illegal_state_before: StringName = session.state
	var illegal_result: BattleAdvanceResult = session.transition_to(BattleRuntimeState.COMPLETE)

	assert_false(illegal_result.success)
	assert_eq(illegal_result.reason, &"illegal_transition")
	assert_eq(session.state, illegal_state_before)

	session.state = BattleRuntimeState.RESOLUTION
	var illegal_completion: BattleAdvanceResult = session.transition_to(BattleRuntimeState.COMPLETE)

	assert_false(illegal_completion.success)
	assert_eq(illegal_completion.reason, &"illegal_transition")
	assert_eq(session.state, BattleRuntimeState.RESOLUTION)


func test_actions_are_accepted_only_during_telegraph() -> void:
	var session: BattleSession = BattleSessionScript.new()
	session.configure(_make_setup(false))
	var action: BattleAction = _make_action(&"battle_attack")

	for state in [
		BattleRuntimeState.INIT,
		BattleRuntimeState.IMPACT,
		BattleRuntimeState.RECOIL,
		BattleRuntimeState.RESOLUTION,
		BattleRuntimeState.COMPLETE,
	]:
		session.state = state
		var rejected: BattleActionResult = session.submit_action(action)
		assert_false(rejected.success, "State should reject gameplay actions: %s" % state)
		assert_false(rejected.accepted)
		assert_eq(rejected.reason, &"action_not_allowed")

	session.state = BattleRuntimeState.TELEGRAPH
	var accepted: BattleActionResult = session.submit_action(action)

	assert_true(accepted.success, accepted.reason)
	assert_true(accepted.accepted)
	assert_eq(accepted.reason, &"ok")
	assert_eq(session.pending_player_action, action)

	var disabled_result: BattleActionResult = session.submit_action(_make_action(&"battle_disabled"))
	var unknown_result: BattleActionResult = session.submit_action(_make_action(&"unknown_action"))

	assert_false(disabled_result.success)
	assert_eq(disabled_result.reason, &"action_disabled")
	assert_false(unknown_result.success)
	assert_eq(unknown_result.reason, &"unknown_action")


func test_battle_completed_emits_typed_payload_and_delta_once() -> void:
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var observed_payloads: Array[BattleEndedPayload] = []
	var observed_deltas: Array[BattleDurableDelta] = []
	var observed_states: Array[StringName] = []
	controller.battle_completed.connect(func(payload: BattleEndedPayload, delta: BattleDurableDelta) -> void:
		observed_payloads.append(payload)
		observed_deltas.append(delta)
	)

	var start_result: BattleStartResult = controller.start_battle(_make_setup(true))
	assert_true(start_result.success, start_result.reason)

	observed_states.append(controller.get_state())
	while controller.get_state() != BattleRuntimeState.COMPLETE:
		var advance_result: BattleAdvanceResult = controller.advance()
		assert_true(advance_result.success, advance_result.reason)
		observed_states.append(controller.get_state())

	var repeated_advance: BattleAdvanceResult = controller.advance()

	assert_eq(observed_states, [
		BattleRuntimeState.INIT,
		BattleRuntimeState.TELEGRAPH,
		BattleRuntimeState.IMPACT,
		BattleRuntimeState.RECOIL,
		BattleRuntimeState.RESOLUTION,
		BattleRuntimeState.COMPLETE,
	])
	assert_eq(observed_payloads.size(), 1)
	assert_eq(observed_deltas.size(), 1)
	assert_false(repeated_advance.success)
	assert_eq(repeated_advance.reason, &"session_complete")

	var payload: BattleEndedPayload = observed_payloads[0]
	var delta: BattleDurableDelta = observed_deltas[0]
	assert_true(payload is BattleEndedPayload)
	assert_true(delta is BattleDurableDelta)
	assert_true(payload.victory)
	assert_eq(payload.raw_xp_awarded, 12)
	assert_eq(payload.scraps_earned, 7)
	assert_eq(payload.player_hp_remaining, 9)
	assert_eq(payload.player_level_start, 4)
	assert_eq(payload.enemy_level, 5)
	assert_eq(payload.battle_id, &"test_battle")
	assert_true(delta.battle_completed)
	assert_true(delta.victory)
	assert_eq(delta.raw_xp_awarded, payload.raw_xp_awarded)
	assert_eq(delta.scraps_earned, payload.scraps_earned)
	assert_eq(delta.player_hp_remaining, payload.player_hp_remaining)
	assert_null(delta.phase_checkpoint)


func test_session_snapshots_setup_values_on_configure() -> void:
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var observed_payloads: Array[BattleEndedPayload] = []
	var observed_deltas: Array[BattleDurableDelta] = []
	controller.battle_completed.connect(func(payload: BattleEndedPayload, delta: BattleDurableDelta) -> void:
		observed_payloads.append(payload)
		observed_deltas.append(delta)
	)
	var setup: BattleSetupPayload = _make_setup(true)

	var start_result: BattleStartResult = controller.start_battle(setup)
	setup.battle_id = &"mutated_battle"
	setup.victory = false
	setup.raw_xp_awarded = 999
	setup.scraps_earned = 999
	setup.player_hp_remaining = 1
	setup.player_level_start = 99
	setup.enemy_level = 99
	setup.player_dragon_id = &"mutated_dragon"
	setup.boss_id = &"mutated_boss"
	setup.final_phase_id = &"mutated_phase"

	assert_true(start_result.success, start_result.reason)
	while controller.get_state() != BattleRuntimeState.COMPLETE:
		var advance_result: BattleAdvanceResult = controller.advance()
		assert_true(advance_result.success, advance_result.reason)

	var payload: BattleEndedPayload = observed_payloads[0]
	var delta: BattleDurableDelta = observed_deltas[0]
	assert_true(payload.victory)
	assert_eq(payload.raw_xp_awarded, 12)
	assert_eq(payload.scraps_earned, 7)
	assert_eq(payload.player_hp_remaining, 9)
	assert_eq(payload.player_level_start, 4)
	assert_eq(payload.enemy_level, 5)
	assert_eq(payload.battle_id, &"test_battle")
	assert_eq(payload.boss_id, &"")
	assert_eq(payload.final_phase_id, &"")
	assert_eq(delta.player_dragon_id, &"root_dragon")
	assert_eq(delta.defeated_boss_id, &"")


func test_public_payload_shells_reject_loose_dictionary_contracts() -> void:
	var delta: BattleDurableDelta = preload("res://src/battle/runtime/battle_durable_delta.gd").new()
	var checkpoint: BattlePhaseCheckpointDelta = BattlePhaseCheckpointDeltaScript.new()
	var turn_payload: TurnResolvedPayload = preload("res://src/battle/runtime/turn_resolved_payload.gd").new()
	var presentation_event: PresentationEventPayload = PresentationEventPayloadScript.new()

	delta.phase_checkpoint = checkpoint
	turn_payload.presentation_events.append(presentation_event)

	assert_eq(delta.phase_checkpoint, checkpoint)
	assert_eq(turn_payload.presentation_events[0], presentation_event)


func test_runtime_exposes_no_save_facing_api_or_mutation_boundary() -> void:
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var immutable_save: SaveData = SaveDataScript.new()
	immutable_save.player_scraps = 321
	immutable_save.loadout_hp = [44, 33, 22]
	immutable_save.cleared_bosses = [&"already_cleared"]
	immutable_save.expedition_defrag_patch = true

	var start_result: BattleStartResult = controller.start_battle(_make_setup(true))
	assert_true(start_result.success, start_result.reason)

	while controller.get_state() != BattleRuntimeState.COMPLETE:
		var advance_result: BattleAdvanceResult = controller.advance()
		assert_true(advance_result.success, advance_result.reason)

	assert_not_null(controller.last_completed_payload)
	assert_not_null(controller.last_completed_delta)
	assert_eq(immutable_save.player_scraps, 321)
	assert_eq(immutable_save.loadout_hp, [44, 33, 22])
	assert_eq(immutable_save.cleared_bosses, [&"already_cleared"])
	assert_true(immutable_save.expedition_defrag_patch)
	_assert_no_save_facing_api(controller)
	_assert_no_save_facing_api(controller.get_session())
	for path in [
		"res://src/battle/runtime/battle_runtime_controller.gd",
		"res://src/battle/runtime/battle_session.gd",
		"res://src/battle/runtime/battle_setup_payload.gd",
		"res://src/battle/runtime/battle_ended_payload.gd",
		"res://src/battle/runtime/battle_durable_delta.gd",
		"res://src/battle/runtime/battle_phase_checkpoint_delta.gd",
	]:
		var source: String = FileAccess.get_file_as_string(path)
		assert_false(source.contains("SaveService"), "%s must not depend on SaveService." % path)
		assert_false(source.contains("SaveTransaction"), "%s must not depend on SaveTransaction." % path)
		assert_false(source.contains("SaveData"), "%s must not depend on SaveData." % path)


func _make_setup(complete_on_resolution: bool) -> BattleSetupPayload:
	var setup: BattleSetupPayload = BattleSetupPayloadScript.new()
	setup.battle_id = &"test_battle"
	setup.complete_on_resolution = complete_on_resolution
	setup.victory = true
	setup.raw_xp_awarded = 12
	setup.scraps_earned = 7
	setup.player_hp_remaining = 9
	setup.player_level_start = 4
	setup.enemy_level = 5
	setup.player_dragon_id = &"root_dragon"
	return setup


func _make_action(action_id: StringName) -> BattleAction:
	var action: BattleAction = BattleActionScript.new()
	action.action_id = action_id
	action.move_id = &"root_spark"
	action.source = &"test"
	return action


func _assert_no_save_facing_api(instance: Object) -> void:
	for method in instance.get_method_list():
		var method_name: String = str(method.name)
		assert_false(method_name.contains("save"), "%s should not expose save-facing method %s." % [instance.get_class(), method_name])
		assert_false(method_name.contains("transaction"), "%s should not expose transaction-facing method %s." % [instance.get_class(), method_name])
	for property in instance.get_property_list():
		var property_name: String = str(property.name)
		assert_false(property_name.contains("save"), "%s should not expose save-facing property %s." % [instance.get_class(), property_name])
		assert_false(property_name.contains("transaction"), "%s should not expose transaction-facing property %s." % [instance.get_class(), property_name])
