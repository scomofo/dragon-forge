extends GutTest

const SaveData = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const TEST_SAVE_PATH: String = "user://gut_save_commit_signal_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_save_commit_signal_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_save_commit_signal_slot.bak.tres"
const SAVE_SERVICE_PATH: String = "res://src/save/save_service.gd"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_save_committed_emits_once_after_successful_reload_validation() -> void:
	var service: SaveService = _make_service()
	var initialize_result: SaveCommitResult = service.initialize_slot(_make_save_data(0))
	assert_true(initialize_result.success, initialize_result.error_message)
	var emitted_results: Array[SaveCommitResult] = []
	var loaded_scraps_during_signal: Array[int] = []
	var on_committed: Callable = func(result: SaveCommitResult) -> void:
		emitted_results.append(result)
		loaded_scraps_during_signal.append(_load_save(TEST_SAVE_PATH).player_scraps)
	service.save_committed.connect(on_committed)

	var tx: SaveTransaction = service.begin_transaction(&"commit_signal_success")
	tx.staged_save.player_scraps = 10
	var commit_result: SaveCommitResult = service.commit_transaction(tx)
	service.save_committed.disconnect(on_committed)

	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(emitted_results.size(), 1)
	assert_same(emitted_results[0], commit_result)
	assert_eq(loaded_scraps_during_signal, [10])


func test_commit_failure_emits_no_committed_state_signal() -> void:
	var service: SaveService = _make_service()
	var initialize_result: SaveCommitResult = service.initialize_slot(_make_save_data(0))
	assert_true(initialize_result.success, initialize_result.error_message)
	service.set_failure_injection(SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP, true)
	var committed_results: Array[SaveCommitResult] = []
	var failed_results: Array[SaveCommitResult] = []
	var on_committed: Callable = func(result: SaveCommitResult) -> void:
		committed_results.append(result)
	var on_failed: Callable = func(result: SaveCommitResult) -> void:
		failed_results.append(result)
	service.save_committed.connect(on_committed)
	service.save_failed.connect(on_failed)

	var tx: SaveTransaction = service.begin_transaction(&"commit_signal_failure")
	tx.staged_save.player_scraps = 10
	var failed_result: SaveCommitResult = service.commit_transaction(tx)
	service.save_committed.disconnect(on_committed)
	service.save_failed.disconnect(on_failed)

	assert_false(failed_result.success)
	assert_eq(committed_results.size(), 0)
	assert_eq(failed_results.size(), 1)
	assert_same(failed_results[0], failed_result)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 0)


func test_successful_commit_does_not_require_signal_listeners() -> void:
	var service: SaveService = _make_service()
	var initialize_result: SaveCommitResult = service.initialize_slot(_make_save_data(0))
	assert_true(initialize_result.success, initialize_result.error_message)
	var tx: SaveTransaction = service.begin_transaction(&"commit_without_listeners")
	tx.staged_save.player_scraps = 7

	var commit_result: SaveCommitResult = service.commit_transaction(tx)

	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 7)


func test_failure_injection_api_is_guarded_by_debug_build() -> void:
	var service: SaveService = _make_service()
	assert_eq(service.is_failure_injection_available(), OS.is_debug_build())

	var source: String = _read_text(SAVE_SERVICE_PATH)
	assert_string_contains(source, "OS.is_debug_build()")
	assert_string_contains(source, "if not is_failure_injection_available():")


func _make_service() -> SaveService:
	var service: SaveService = SaveServiceScript.new()
	service.configure(TEST_SAVE_PATH, 0)
	return service


func _make_save_data(scraps: int) -> SaveData:
	var save_data: SaveData = SaveData.new()
	save_data.player_scraps = scraps
	return save_data


func _read_text(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "Expected readable file at %s" % path)
	if file == null:
		return ""
	return file.get_as_text()


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
