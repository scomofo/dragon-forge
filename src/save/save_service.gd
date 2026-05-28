class_name SaveService
extends RefCounted

## Save / Persistence service responsible for slot file I/O and atomic commits.
## Runtime systems stage changes through SaveTransaction instead of writing files directly.

signal save_committed(result: SaveCommitResult)
signal save_failed(result: SaveCommitResult)

const SaveDataResource = preload("res://src/save/save_data.gd")
const SaveTransactionResource = preload("res://src/save/save_transaction.gd")
const SaveCommitResultResource = preload("res://src/save/save_commit_result.gd")
const SaveStateProjectionResource = preload("res://src/save/save_state_projection.gd")

const FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP: StringName = &"after_temp_write_before_swap"

var _canonical_path: String = ""
var _slot_id: int = -1
var _failure_injections: Dictionary[StringName, bool] = {}


func configure(canonical_path: String, slot_id: int = 0) -> void:
	_canonical_path = canonical_path
	_slot_id = slot_id


func initialize_slot(save_data: Resource) -> SaveCommitResult:
	if not _is_configured():
		return _failure(&"initialize_slot", "SaveService is not configured.", ERR_UNCONFIGURED)
	if not save_data is SaveDataResource:
		return _failure(&"initialize_slot", "initialize_slot requires SaveData.", ERR_INVALID_PARAMETER)

	_remove_file(_temp_path())
	var save_error: int = ResourceSaver.save(_duplicate_save(save_data), _canonical_path)
	if save_error != OK:
		return _failure(&"initialize_slot", "Failed to write canonical save.", save_error)

	var loaded: SaveData = _load_save(_canonical_path)
	if loaded == null:
		return _failure(&"initialize_slot", "Canonical save failed reload validation.", ERR_FILE_CORRUPT)

	return _success(&"initialize_slot")


func load_state_projection(known_ending_ids: Array[StringName] = []) -> RefCounted:
	var projection: RefCounted = SaveStateProjectionResource.new()
	var save_data: SaveData = _load_current_save()
	if save_data == null:
		projection.configure_from_save_data(null, known_ending_ids)
		return projection
	projection.configure_from_save_data(_duplicate_save(save_data), known_ending_ids)
	return projection


func has_current_save() -> bool:
	return _load_current_save() != null


func _load_current_save() -> SaveData:
	if not _is_configured():
		return null
	return _load_save(_canonical_path)


func begin_transaction(reason: StringName) -> SaveTransaction:
	var canonical_save: SaveData = _load_current_save()
	if canonical_save == null:
		return null

	var tx: SaveTransaction = SaveTransactionResource.new()
	tx.reason = reason
	tx.slot_id = _slot_id
	tx.canonical_path = _canonical_path
	tx.staged_save = _duplicate_save(canonical_save)
	tx.active = true
	return tx


func commit_transaction(tx: RefCounted) -> SaveCommitResult:
	var validation_failure: SaveCommitResult = _validate_transaction(tx)
	if validation_failure != null:
		return _finish_commit(validation_failure)

	var save_tx: SaveTransaction = tx as SaveTransaction
	var temp_failure: SaveCommitResult = _write_verified_temp(save_tx)
	if temp_failure != null:
		return _finish_commit(temp_failure)

	return _finish_commit(_promote_temp_to_canonical(save_tx))


func _validate_transaction(tx: RefCounted) -> SaveCommitResult:
	if not _is_configured():
		return _failure(&"commit_transaction", "SaveService is not configured.", ERR_UNCONFIGURED)
	if tx == null or not tx is SaveTransactionResource:
		return _failure(&"commit_transaction", "SaveTransaction is missing or invalid.", ERR_INVALID_PARAMETER)

	var save_tx: SaveTransaction = tx as SaveTransaction
	if not save_tx.active:
		return _failure(&"commit_transaction", "SaveTransaction is missing or inactive.", ERR_INVALID_PARAMETER)
	if save_tx.slot_id != _slot_id or save_tx.canonical_path != _canonical_path:
		return _failure(save_tx.reason, "SaveTransaction belongs to another slot.", ERR_INVALID_PARAMETER)
	if not save_tx.staged_save is SaveDataResource:
		return _failure(save_tx.reason, "SaveTransaction staged_save must be SaveData.", ERR_INVALID_PARAMETER)

	return null


func _write_verified_temp(tx: SaveTransaction) -> SaveCommitResult:
	_remove_file(_temp_path())
	var temp_write_error: int = ResourceSaver.save(tx.staged_save, _temp_path())
	if temp_write_error != OK:
		tx.active = false
		return _failure(tx.reason, "Failed to write temp save.", temp_write_error)

	var temp_loaded: SaveData = _load_save(_temp_path())
	if temp_loaded == null:
		tx.active = false
		_remove_file(_temp_path())
		return _failure(tx.reason, "Temp save failed reload validation.", ERR_FILE_CORRUPT)

	return null


func _promote_temp_to_canonical(tx: SaveTransaction) -> SaveCommitResult:
	if is_failure_injection_available() and _failure_injections.get(FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP, false):
		tx.active = false
		return _failure(tx.reason, "Injected failure after temp write before swap.", ERR_SKIP, FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP)

	var backup_error: int = _move_canonical_to_backup()
	if backup_error != OK:
		tx.active = false
		_remove_file(_temp_path())
		return _failure(tx.reason, "Failed to move canonical save to backup.", backup_error)

	var swap_error: int = _rename_file(_temp_path(), _canonical_path)
	if swap_error != OK:
		tx.active = false
		_restore_backup()
		_remove_file(_temp_path())
		return _failure(tx.reason, "Failed to promote temp save to canonical.", swap_error)

	var canonical_loaded: SaveData = _load_save(_canonical_path)
	if canonical_loaded == null:
		tx.active = false
		_restore_backup()
		return _failure(tx.reason, "Canonical save failed reload validation after swap.", ERR_FILE_CORRUPT)

	var post_commit_events: Array[RefCounted] = tx.post_commit_events.duplicate()
	tx.active = false
	return _success(tx.reason, post_commit_events)


func is_failure_injection_available() -> bool:
	return OS.is_debug_build()


func set_failure_injection(point: StringName, enabled: bool) -> void:
	if not is_failure_injection_available():
		return
	if enabled:
		_failure_injections[point] = true
	else:
		_failure_injections.erase(point)


func clear_failure_injection() -> void:
	_failure_injections.clear()


func _finish_commit(result: SaveCommitResult) -> SaveCommitResult:
	if result.success:
		save_committed.emit(result)
	else:
		save_failed.emit(result)
	return result


func _is_configured() -> bool:
	return _canonical_path != "" and _slot_id >= 0


func _temp_path() -> String:
	return _path_with_marker(&"tmp")


func _backup_path() -> String:
	return _path_with_marker(&"bak")


func _path_with_marker(marker: StringName) -> String:
	var extension: String = _canonical_path.get_extension()
	if extension == "":
		return "%s.%s" % [_canonical_path, marker]
	return "%s.%s.%s" % [_canonical_path.get_basename(), marker, extension]


func _load_save(path: String) -> SaveData:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is SaveDataResource:
		return loaded as SaveData
	return null


func _duplicate_save(save_data: SaveData) -> SaveData:
	return save_data.duplicate_deep() as SaveData


func _move_canonical_to_backup() -> int:
	_remove_file(_backup_path())
	if not FileAccess.file_exists(_canonical_path):
		return OK
	return _rename_file(_canonical_path, _backup_path())


func _restore_backup() -> void:
	if not FileAccess.file_exists(_backup_path()):
		return
	_remove_file(_canonical_path)
	_rename_file(_backup_path(), _canonical_path)


func _rename_file(from_path: String, to_path: String) -> int:
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(from_path), ProjectSettings.globalize_path(to_path))


func _remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _success(reason: StringName, post_commit_events: Array[RefCounted] = []) -> SaveCommitResult:
	var result: SaveCommitResult = SaveCommitResultResource.new()
	result.success = true
	result.reason = reason
	result.slot_id = _slot_id
	result.post_commit_events = post_commit_events.duplicate()
	return result


func _failure(reason: StringName, message: String, error_code: int, failure_point: StringName = &"") -> SaveCommitResult:
	var result: SaveCommitResult = SaveCommitResultResource.new()
	result.success = false
	result.reason = reason
	result.slot_id = _slot_id
	result.error_message = message
	result.error_code = error_code
	result.failure_point = failure_point
	return result
