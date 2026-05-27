extends GutTest

const DragonProgressionServiceScript = preload("res://src/dragon/dragon_progression_service.gd")
const DragonRecordScript = preload("res://src/dragon/dragon_record.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const TEST_SAVE_PATH: String = "user://gut_dragon_progression_events_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_dragon_progression_events_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_dragon_progression_events_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_successful_commit_publishes_ordered_stage_events_with_dragon_payloads() -> void:
	var services: Dictionary = _make_initialized_services(_make_dragon(9, 0, 0))
	var dragon_service: DragonProgressionService = services.dragon
	var save_service: SaveService = services.save
	dragon_service.bind_save_service(save_service)
	var observed: Array[DragonProgressionEvent] = _capture_all_progression_events(dragon_service)

	var tx: SaveTransaction = save_service.begin_transaction(&"stage_order")
	var xp_result: XPApplyResult = dragon_service.apply_xp(tx, &"fire_test", 1250, &"unit_test")
	var commit_result: SaveCommitResult = save_service.commit_transaction(tx)

	assert_true(xp_result.success, xp_result.error_message)
	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(observed.size(), 3)
	assert_eq(_event_ids(observed), [&"stage_advanced", &"stage_advanced", &"stats_updated"])
	assert_eq(observed[0].dragon_id, &"fire_test")
	assert_eq(observed[0].element, &"Fire")
	assert_eq(observed[0].from_stage, 1)
	assert_eq(observed[0].to_stage, 2)
	assert_eq(observed[1].from_stage, 2)
	assert_eq(observed[1].to_stage, 3)


func test_stage_iv_crossing_publishes_after_commit_and_failed_commit_publishes_none() -> void:
	var success_services: Dictionary = _make_initialized_services(_make_dragon(49, 119, 0))
	var success_dragon_service: DragonProgressionService = success_services.dragon
	var success_save_service: SaveService = success_services.save
	success_dragon_service.bind_save_service(success_save_service)
	var success_events: Array[DragonProgressionEvent] = _capture_all_progression_events(success_dragon_service)

	var success_tx: SaveTransaction = success_save_service.begin_transaction(&"stage_iv_success")
	var success_xp_result: XPApplyResult = success_dragon_service.apply_xp(success_tx, &"fire_test", 240, &"unit_test")
	var success_commit: SaveCommitResult = success_save_service.commit_transaction(success_tx)

	assert_true(success_xp_result.success, success_xp_result.error_message)
	assert_true(success_commit.success, success_commit.error_message)
	assert_eq(_event_ids(success_events), [&"stage_advanced", &"stage_iv_reached", &"stats_updated"])
	assert_eq(success_events[1].event_id, &"stage_iv_reached")
	assert_eq(success_events[1].old_level, 49)
	assert_eq(success_events[1].new_level, 50)
	assert_eq(success_events[1].element, &"Fire")

	var failed_services: Dictionary = _make_initialized_services(_make_dragon(49, 119, 0))
	var failed_dragon_service: DragonProgressionService = failed_services.dragon
	var failed_save_service: SaveService = failed_services.save
	failed_dragon_service.bind_save_service(failed_save_service)
	failed_save_service.set_failure_injection(SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP, true)
	var failed_events: Array[DragonProgressionEvent] = _capture_all_progression_events(failed_dragon_service)

	var failed_tx: SaveTransaction = failed_save_service.begin_transaction(&"stage_iv_failure")
	var failed_xp_result: XPApplyResult = failed_dragon_service.apply_xp(failed_tx, &"fire_test", 240, &"unit_test")
	var failed_commit: SaveCommitResult = failed_save_service.commit_transaction(failed_tx)

	assert_true(failed_xp_result.success, failed_xp_result.error_message)
	assert_false(failed_commit.success)
	assert_eq(failed_events.size(), 0)


func test_stage_iv_reached_emits_once_when_award_continues_to_max_level() -> void:
	var services: Dictionary = _make_initialized_services(_make_dragon(49, 119, 0))
	var dragon_service: DragonProgressionService = services.dragon
	var save_service: SaveService = services.save
	dragon_service.bind_save_service(save_service)
	var observed: Array[DragonProgressionEvent] = _capture_all_progression_events(dragon_service)

	var tx: SaveTransaction = save_service.begin_transaction(&"stage_iv_to_max")
	var xp_result: XPApplyResult = dragon_service.apply_xp(tx, &"fire_test", 10000, &"unit_test")
	var commit_result: SaveCommitResult = save_service.commit_transaction(tx)

	assert_true(xp_result.success, xp_result.error_message)
	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(_count_events(observed, &"stage_iv_reached"), 1)
	assert_eq(_count_events(observed, &"stage_advanced"), 1)
	assert_eq(observed[0].event_id, &"stage_advanced")
	assert_eq(observed[1].event_id, &"stage_iv_reached")


func test_missing_progression_event_listeners_do_not_block_commit() -> void:
	var services: Dictionary = _make_initialized_services(_make_dragon(49, 119, 0))
	var dragon_service: DragonProgressionService = services.dragon
	var save_service: SaveService = services.save
	dragon_service.bind_save_service(save_service)

	var tx: SaveTransaction = save_service.begin_transaction(&"no_progression_listeners")
	var xp_result: XPApplyResult = dragon_service.apply_xp(tx, &"fire_test", 120, &"unit_test")
	var commit_result: SaveCommitResult = save_service.commit_transaction(tx)

	assert_true(xp_result.success, xp_result.error_message)
	assert_true(commit_result.success, commit_result.error_message)
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)
	assert_not_null(committed_save)
	assert_eq(committed_save.dragons[0].level, 50)
	assert_eq(committed_save.dragons[0].xp, 119)


func _make_initialized_services(dragon: DragonRecord) -> Dictionary:
	var save_service: SaveService = SaveServiceScript.new()
	var save_data: SaveData = SaveDataScript.new()
	save_data.dragons.append(dragon)
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(save_data)
	assert_true(initialize_result.success, initialize_result.error_message)
	return {
		"save": save_service,
		"dragon": DragonProgressionServiceScript.new(),
	}


func _make_dragon(level: int, xp: int, battle_charges: int) -> DragonRecord:
	var dragon: DragonRecord = DragonRecordScript.new()
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


func _capture_all_progression_events(dragon_service: DragonProgressionService) -> Array[DragonProgressionEvent]:
	var observed: Array[DragonProgressionEvent] = []
	dragon_service.stage_advanced.connect(func(event: DragonProgressionEvent) -> void:
		observed.append(event)
	)
	dragon_service.stage_iv_reached.connect(func(event: DragonProgressionEvent) -> void:
		observed.append(event)
	)
	dragon_service.stats_updated.connect(func(event: DragonProgressionEvent) -> void:
		observed.append(event)
	)
	return observed


func _event_ids(events: Array[DragonProgressionEvent]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for event: DragonProgressionEvent in events:
		ids.append(event.event_id)
	return ids


func _count_events(events: Array[DragonProgressionEvent], event_id: StringName) -> int:
	var count: int = 0
	for event: DragonProgressionEvent in events:
		if event.event_id == event_id:
			count += 1
	return count


func _load_save(path: String) -> SaveData:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is SaveData:
		return loaded
	return null


func _remove_save_files() -> void:
	for path in [TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
