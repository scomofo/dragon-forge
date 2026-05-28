extends GutTest

const SaveData = preload("res://src/save/save_data.gd")
const DragonRecord = preload("res://src/dragon/dragon_record.gd")

const SAVE_SERVICE_PATH: String = "res://src/save/save_service.gd"
const TEST_SAVE_PATH: String = "user://gut_save_transaction_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_save_transaction_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_save_transaction_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_begin_transaction_returns_staged_copy_isolated_from_canonical_state() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return
	var initial_save: SaveData = _make_save_data(0)
	var dragon: DragonRecord = DragonRecord.new()
	dragon.dragon_id = &"root_wyrmling"
	dragon.element = &"Root"
	dragon.level = 1
	initial_save.dragons.append(dragon)
	var initialize_result: RefCounted = service.initialize_slot(initial_save)
	assert_true(initialize_result.success, initialize_result.error_message)

	var tx: RefCounted = service.begin_transaction(&"test_stage_isolation")

	assert_not_null(tx)
	if tx == null:
		return
	assert_eq(tx.reason, &"test_stage_isolation")
	assert_not_same(tx.staged_save, initial_save)
	tx.staged_save.player_scraps = 10
	tx.staged_save.visited_nodes.append(&"village_edge")
	tx.staged_save.dragons[0].level = 7

	var canonical_after_stage: SaveData = _load_save(TEST_SAVE_PATH)

	assert_eq(canonical_after_stage.player_scraps, 0)
	assert_eq(canonical_after_stage.visited_nodes.size(), 0)
	assert_eq(canonical_after_stage.dragons[0].level, 1)


func test_commit_transaction_writes_backup_swaps_and_reload_validates() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return
	var initialize_result: RefCounted = service.initialize_slot(_make_save_data(0))
	assert_true(initialize_result.success, initialize_result.error_message)
	assert_false(FileAccess.file_exists(TEST_BACKUP_PATH), "First slot initialization should not create a backup file.")

	var first_tx: RefCounted = service.begin_transaction(&"first_commit")
	first_tx.staged_save.player_scraps = 10
	var first_result: RefCounted = service.commit_transaction(first_tx)
	var first_loaded: SaveData = _load_save(TEST_SAVE_PATH)
	var first_backup: SaveData = _load_save(TEST_BACKUP_PATH)

	assert_true(first_result.success, first_result.error_message)
	assert_eq(first_result.reason, &"first_commit")
	assert_eq(first_result.slot_id, 0)
	assert_eq(first_loaded.player_scraps, 10)
	assert_false(FileAccess.file_exists(TEST_TEMP_PATH), "Successful commit should remove or consume the temp save.")
	assert_not_null(first_backup, "Successful commit should back up the previous canonical save.")
	if first_backup != null:
		assert_eq(first_backup.player_scraps, 0)

	var second_tx: RefCounted = service.begin_transaction(&"existing_backup_commit")
	second_tx.staged_save.player_scraps = 25
	var second_result: RefCounted = service.commit_transaction(second_tx)
	var second_loaded: SaveData = _load_save(TEST_SAVE_PATH)
	var replaced_backup: SaveData = _load_save(TEST_BACKUP_PATH)

	assert_true(second_result.success, second_result.error_message)
	assert_eq(second_loaded.player_scraps, 25)
	assert_not_null(replaced_backup, "Existing backup should be replaced by the pre-commit canonical save.")
	if replaced_backup != null:
		assert_eq(replaced_backup.player_scraps, 10)


func test_injected_failure_after_temp_write_preserves_canonical_save_after_reload() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return
	var initialize_result: RefCounted = service.initialize_slot(_make_save_data(0))
	assert_true(initialize_result.success, initialize_result.error_message)
	var backup_seed_tx: RefCounted = service.begin_transaction(&"seed_backup")
	backup_seed_tx.staged_save.player_scraps = 5
	var backup_seed_result: RefCounted = service.commit_transaction(backup_seed_tx)
	assert_true(backup_seed_result.success, backup_seed_result.error_message)
	var backup_before_failure: SaveData = _load_save(TEST_BACKUP_PATH)
	assert_not_null(backup_before_failure)
	if backup_before_failure != null:
		assert_eq(backup_before_failure.player_scraps, 0)

	service.set_failure_injection(&"after_temp_write_before_swap", true)
	var tx: RefCounted = service.begin_transaction(&"injected_rollback")
	tx.staged_save.player_scraps = 10
	var failed_result: RefCounted = service.commit_transaction(tx)
	var canonical_after_failure: SaveData = _load_save(TEST_SAVE_PATH)
	var backup_after_failure: SaveData = _load_save(TEST_BACKUP_PATH)

	assert_false(failed_result.success, "Injected failure should return a failed commit result.")
	assert_eq(failed_result.reason, &"injected_rollback")
	assert_eq(failed_result.failure_point, &"after_temp_write_before_swap")
	assert_eq(canonical_after_failure.player_scraps, 5)
	assert_true(FileAccess.file_exists(TEST_TEMP_PATH), "Injected failure should leave the temp save for recovery tests.")
	assert_not_null(backup_after_failure, "Backup should remain untouched when failure happens before swap.")
	if backup_after_failure != null:
		assert_eq(backup_after_failure.player_scraps, 0)

	service.clear_failure_injection()
	var recovery_tx: RefCounted = service.begin_transaction(&"recovery_commit")
	recovery_tx.staged_save.player_scraps = 12
	var recovery_result: RefCounted = service.commit_transaction(recovery_tx)

	assert_true(recovery_result.success, recovery_result.error_message)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 12)
	assert_false(FileAccess.file_exists(TEST_TEMP_PATH), "A later successful commit should clean stale temp save state.")


func test_commit_transaction_rejects_invalid_transactions_without_file_io() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var wrong_type_result: RefCounted = service.commit_transaction(RefCounted.new())

	assert_false(wrong_type_result.success)
	assert_eq(wrong_type_result.reason, &"commit_transaction")
	assert_eq(wrong_type_result.error_code, ERR_INVALID_PARAMETER)
	assert_false(FileAccess.file_exists(TEST_TEMP_PATH), "Invalid transactions should not create temp save files.")

	var initialize_result: RefCounted = service.initialize_slot(_make_save_data(0))
	assert_true(initialize_result.success, initialize_result.error_message)
	var inactive_tx: RefCounted = service.begin_transaction(&"inactive_commit")
	inactive_tx.active = false
	var inactive_result: RefCounted = service.commit_transaction(inactive_tx)

	assert_false(inactive_result.success)
	assert_eq(inactive_result.reason, &"commit_transaction")
	assert_eq(inactive_result.error_code, ERR_INVALID_PARAMETER)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 0)


func _make_service() -> RefCounted:
	assert_true(ResourceLoader.exists(SAVE_SERVICE_PATH), "SaveService script should exist for transaction tests.")
	if not ResourceLoader.exists(SAVE_SERVICE_PATH):
		return null

	var script: GDScript = load(SAVE_SERVICE_PATH)
	assert_not_null(script)
	if script == null:
		return null
	var service: RefCounted = script.new()
	service.configure(TEST_SAVE_PATH, 0)
	return service


func _make_save_data(scraps: int) -> SaveData:
	var save_data: SaveData = SaveData.new()
	save_data.player_scraps = scraps
	return save_data


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
