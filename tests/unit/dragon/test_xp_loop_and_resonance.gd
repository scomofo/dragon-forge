extends GutTest

const DRAGON_RECORD_PATH: String = "res://src/dragon/dragon_record.gd"
const DRAGON_PROGRESSION_SERVICE_PATH: String = "res://src/dragon/dragon_progression_service.gd"
const SAVE_DATA_PATH: String = "res://src/save/save_data.gd"
const SAVE_TRANSACTION_PATH: String = "res://src/save/save_transaction.gd"
const XP_APPLY_RESULT_PATH: String = "res://src/dragon/xp_apply_result.gd"
const DRAGON_PROGRESSION_EVENT_PATH: String = "res://src/dragon/dragon_progression_event.gd"


func test_xp_threshold_boundaries_and_max_level_sentinel() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	assert_eq(service.xp_threshold_for(1), 50)
	assert_eq(service.xp_threshold_for(9), 50)
	assert_eq(service.xp_threshold_for(10), 80)
	assert_eq(service.xp_threshold_for(24), 80)
	assert_eq(service.xp_threshold_for(25), 120)
	assert_eq(service.xp_threshold_for(49), 120)
	assert_eq(service.xp_threshold_for(50), 200)
	assert_eq(service.xp_threshold_for(59), 200)
	assert_eq(service.xp_threshold_for(60), service.MAX_LEVEL_XP_SENTINEL)


func test_xp_awards_advance_levels_preserve_remainders_and_stop_at_max_level() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	_assert_xp_case(service, 1, 0, 50, 2, 0, 1)
	_assert_xp_case(service, 1, 0, 49, 1, 49, 0)
	_assert_xp_case(service, 1, 30, 25, 2, 5, 1)
	_assert_xp_case(service, 1, 0, 100, 3, 0, 2)
	_assert_xp_case(service, 1, 0, 130, 3, 30, 2)
	_assert_xp_case(service, 10, 0, 80, 11, 0, 1)
	_assert_xp_case(service, 9, 40, 50, 10, 40, 1)
	_assert_xp_case(service, 59, 199, 1, 60, 0, 1)
	_assert_xp_case(service, 60, 0, 500, 60, 0, 0)
	_assert_xp_case(service, 59, 0, 10000, 60, 0, 1)


func test_level_up_result_updates_stats_and_records_stats_updated_once() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var tx: RefCounted = _make_transaction(_make_dragon(1, 0, 0))
	var result: RefCounted = service.apply_xp(tx, &"fire_test", 100, &"unit_test")

	assert_true(result.success, result.error_message)
	assert_eq(result.levels_gained, 2)
	assert_eq(result.stats.hp, 116)
	assert_eq(result.stats.atk, 34)
	assert_eq(result.stats.def, 22)
	assert_eq(result.stats.spd, 28)
	assert_eq(_event_count(result.pending_events, &"stats_updated"), 1)


func test_stable_xp_invariants_hold_after_application() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	for case_data in [
		[1, 49, 0],
		[10, 79, 0],
		[25, 119, 0],
		[50, 199, 0],
		[59, 199, 1],
		[60, 77, 0],
	]:
		var tx: RefCounted = _make_transaction(_make_dragon(case_data[0], case_data[1], 0))
		var result: RefCounted = service.apply_xp(tx, &"fire_test", case_data[2], &"unit_test")
		var dragon: Resource = tx.staged_save.dragons[0]
		assert_true(result.success, result.error_message)
		if dragon.level == service.MAX_LEVEL:
			assert_eq(dragon.xp, 0)
		else:
			assert_lt(dragon.xp, service.xp_threshold_for(dragon.level))


func test_negative_float_zero_and_clamped_xp_inputs_follow_gdd_rules() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var negative_tx: RefCounted = _make_transaction(_make_dragon(1, 10, 0))
	var negative_result: RefCounted = service.apply_xp(negative_tx, &"fire_test", -10, &"unit_test")
	assert_false(negative_result.success)
	assert_eq(negative_result.reason, &"invalid_xp")
	assert_eq(negative_tx.staged_save.dragons[0].level, 1)
	assert_eq(negative_tx.staged_save.dragons[0].xp, 10)
	assert_push_error("XP award rejected: xpGained must be >= 0, got -10")

	var inactive_tx: RefCounted = _make_transaction(_make_dragon(1, 10, 0))
	inactive_tx.active = false
	var inactive_result: RefCounted = service.apply_xp(inactive_tx, &"fire_test", 40, &"unit_test")
	assert_false(inactive_result.success)
	assert_eq(inactive_result.reason, &"invalid_transaction")
	assert_eq(inactive_tx.staged_save.dragons[0].level, 1)
	assert_eq(inactive_tx.staged_save.dragons[0].xp, 10)

	var float_tx: RefCounted = _make_transaction(_make_dragon(1, 0, 0))
	var float_result: RefCounted = service.apply_xp(float_tx, &"fire_test", 75.9, &"unit_test")
	assert_true(float_result.success, float_result.error_message)
	assert_eq(float_result.xp_awarded, 75)
	assert_eq(float_tx.staged_save.dragons[0].level, 2)
	assert_eq(float_tx.staged_save.dragons[0].xp, 25)

	var zero_tx: RefCounted = _make_transaction(_make_dragon(5, 10, 0))
	var zero_result: RefCounted = service.apply_xp(zero_tx, &"fire_test", 0, &"unit_test")
	assert_true(zero_result.success, zero_result.error_message)
	assert_eq(zero_tx.staged_save.dragons[0].level, 5)
	assert_eq(zero_tx.staged_save.dragons[0].xp, 10)
	assert_eq(zero_result.levels_gained, 0)
	assert_eq(zero_result.pending_events.size(), 0)

	var clamped_tx: RefCounted = _make_transaction(_make_dragon(1, 0, 0))
	var clamped_result: RefCounted = service.apply_xp(clamped_tx, &"fire_test", 999999, &"unit_test")
	var max_award_tx: RefCounted = _make_transaction(_make_dragon(1, 0, 0))
	var max_award_result: RefCounted = service.apply_xp(max_award_tx, &"fire_test", service.XP_MAX_AWARD, &"unit_test")
	assert_true(clamped_result.success, clamped_result.error_message)
	assert_eq(clamped_result.xp_awarded, service.XP_MAX_AWARD)
	assert_eq(clamped_tx.staged_save.dragons[0].level, max_award_tx.staged_save.dragons[0].level)
	assert_eq(clamped_tx.staged_save.dragons[0].xp, max_award_tx.staged_save.dragons[0].xp)
	assert_eq(clamped_result.levels_gained, max_award_result.levels_gained)


func test_resonance_reduces_effective_threshold_and_consumes_one_charge_per_level() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var one_level_tx: RefCounted = _make_transaction(_make_dragon(5, 0, 3))
	var one_level_result: RefCounted = service.apply_xp(one_level_tx, &"fire_test", 40, &"unit_test")
	assert_true(one_level_result.success, one_level_result.error_message)
	assert_eq(one_level_tx.staged_save.dragons[0].level, 6)
	assert_eq(one_level_tx.staged_save.dragons[0].xp, 7)
	assert_eq(one_level_tx.staged_save.dragons[0].battle_charges, 2)
	assert_eq(one_level_result.charges_consumed, 1)

	var no_level_tx: RefCounted = _make_transaction(_make_dragon(5, 0, 3))
	var no_level_result: RefCounted = service.apply_xp(no_level_tx, &"fire_test", 20, &"unit_test")
	assert_true(no_level_result.success, no_level_result.error_message)
	assert_eq(no_level_tx.staged_save.dragons[0].level, 5)
	assert_eq(no_level_tx.staged_save.dragons[0].xp, 20)
	assert_eq(no_level_tx.staged_save.dragons[0].battle_charges, 3)
	assert_eq(no_level_result.charges_consumed, 0)

	var no_charge_tx: RefCounted = _make_transaction(_make_dragon(5, 0, 0))
	var no_charge_result: RefCounted = service.apply_xp(no_charge_tx, &"fire_test", 40, &"unit_test")
	assert_true(no_charge_result.success, no_charge_result.error_message)
	assert_eq(no_charge_tx.staged_save.dragons[0].level, 5)
	assert_eq(no_charge_tx.staged_save.dragons[0].xp, 40)
	assert_eq(no_charge_result.charges_consumed, 0)


func test_stage_events_are_recorded_as_pending_events_without_signal_emission() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var tx: RefCounted = _make_transaction(_make_dragon(49, 119, 0))
	var result: RefCounted = service.apply_xp(tx, &"fire_test", 200, &"unit_test")

	assert_true(result.success, result.error_message)
	assert_eq(tx.staged_save.dragons[0].level, 50)
	assert_eq(_event_count(result.pending_events, &"stage_advanced"), 1)
	assert_eq(_event_count(result.pending_events, &"stage_iv_reached"), 1)
	assert_eq(_event_count(result.pending_events, &"stats_updated"), 1)
	assert_eq(result.pending_events[0].event_id, &"stage_advanced")
	assert_eq(result.pending_events[0].from_stage, 3)
	assert_eq(result.pending_events[0].to_stage, 4)
	assert_eq(result.pending_events[1].event_id, &"stage_iv_reached")
	assert_eq(result.pending_events[2].event_id, &"stats_updated")


func _assert_xp_case(service: RefCounted, start_level: int, start_xp: int, award, expected_level: int, expected_xp: int, expected_levels_gained: int) -> void:
	var tx: RefCounted = _make_transaction(_make_dragon(start_level, start_xp, 0))
	var result: RefCounted = service.apply_xp(tx, &"fire_test", award, &"unit_test")
	assert_true(result.success, result.error_message)
	assert_eq(tx.staged_save.dragons[0].level, expected_level, "level for start level %d award %s" % [start_level, str(award)])
	assert_eq(tx.staged_save.dragons[0].xp, expected_xp, "xp for start level %d award %s" % [start_level, str(award)])
	assert_eq(result.levels_gained, expected_levels_gained)


func _make_service() -> RefCounted:
	assert_true(ResourceLoader.exists(DRAGON_PROGRESSION_SERVICE_PATH), "DragonProgressionService script should exist.")
	assert_true(ResourceLoader.exists(XP_APPLY_RESULT_PATH), "XPApplyResult script should exist.")
	assert_true(ResourceLoader.exists(DRAGON_PROGRESSION_EVENT_PATH), "DragonProgressionEvent script should exist.")
	if not ResourceLoader.exists(DRAGON_PROGRESSION_SERVICE_PATH) or not ResourceLoader.exists(XP_APPLY_RESULT_PATH) or not ResourceLoader.exists(DRAGON_PROGRESSION_EVENT_PATH):
		return null
	var script: GDScript = load(DRAGON_PROGRESSION_SERVICE_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func _make_transaction(dragon: Resource) -> RefCounted:
	assert_true(ResourceLoader.exists(SAVE_TRANSACTION_PATH), "SaveTransaction script should exist.")
	assert_true(ResourceLoader.exists(SAVE_DATA_PATH), "SaveData script should exist.")
	var tx_script: GDScript = load(SAVE_TRANSACTION_PATH)
	var save_data_script: GDScript = load(SAVE_DATA_PATH)
	assert_not_null(tx_script)
	assert_not_null(save_data_script)
	var tx: RefCounted = tx_script.new()
	tx.active = true
	tx.reason = &"unit_test"
	tx.staged_save = save_data_script.new()
	tx.staged_save.dragons.append(dragon)
	return tx


func _make_dragon(level: int, xp: int, battle_charges: int) -> Resource:
	assert_true(ResourceLoader.exists(DRAGON_RECORD_PATH), "DragonRecord script should exist.")
	var script: GDScript = load(DRAGON_RECORD_PATH)
	assert_not_null(script)
	var dragon: Resource = script.new()
	dragon.dragon_id = &"fire_test"
	dragon.element = &"Fire"
	dragon.base_hp = 110
	dragon.base_atk = 28
	dragon.base_def = 16
	dragon.base_spd = 22
	dragon.level = level
	dragon.xp = xp
	dragon.battle_charges = battle_charges
	return dragon


func _event_count(events: Array, event_id: StringName) -> int:
	var count: int = 0
	for event in events:
		if event.event_id == event_id:
			count += 1
	return count
