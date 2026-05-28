extends GutTest

const SaveData = preload("res://src/save/save_data.gd")

const SAVE_DATA_PATH: String = "res://src/save/save_data.gd"
const SAVE_SERVICE_PATH: String = "res://src/save/save_service.gd"
const SEMANTIC_EVENT_CONTRACT_PATH: String = "res://src/events/semantic_event_contract.gd"

var _save_path: String = ""


func before_each() -> void:
	_save_path = "user://semantic-event-contract-%s.tres" % Time.get_ticks_usec()


func after_each() -> void:
	for path in [_save_path, _path_with_marker(_save_path, "tmp"), _path_with_marker(_save_path, "bak")]:
		if path != "" and FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_contract_defines_named_semantic_event_examples_and_payload_conventions() -> void:
	var contract: Node = _make_contract()
	if contract == null:
		return

	var required_event_ids: Array[StringName] = [
		&"save_committed",
		&"screen_changed",
		&"battle_ended",
		&"journal_entry_available",
		&"corruption_class_changed",
		&"ending_resolved",
	]

	for event_id in required_event_ids:
		assert_true(contract.has_event_definition(event_id), "Missing semantic event definition: %s" % event_id)
		var definition: Dictionary = contract.get_event_definition(event_id)
		assert_eq(definition.event_id, event_id)
		assert_true(definition.channel == &"committed_state" or definition.channel == &"presentation")
		assert_false(String(definition.event_id).contains("Button"))
		assert_false(String(definition.event_id).contains("mouse"))
		assert_false(String(definition.event_id).contains("key"))


func test_missing_listeners_do_not_block_gameplay_progress() -> void:
	var contract: Node = _make_contract()
	if contract == null:
		return

	var result: RefCounted = contract.emit_presentation_event(
		&"screen_changed",
		&"hub",
		{"source": &"test_missing_listener"}
	)

	assert_true(result.success)
	assert_eq(result.event_id, &"screen_changed")
	assert_eq(result.listener_count, 0)


func test_presentation_only_events_emit_without_mutating_durable_state() -> void:
	var contract: Node = _make_contract()
	if contract == null:
		return
	var save_service: RefCounted = _make_initialized_save_service(7)
	var observed: Array[RefCounted] = []
	var on_event: Callable = func(payload: RefCounted) -> void:
		observed.append(payload)
	contract.presentation_event.connect(on_event)

	var result: RefCounted = contract.emit_presentation_event(
		&"battle_ended",
		&"village_edge_admin_protocol",
		{"raw_xp_awarded": 12, "scraps_earned": 20}
	)

	contract.presentation_event.disconnect(on_event)
	assert_true(result.success)
	assert_eq(observed.size(), 1)
	assert_eq(observed[0].event_id, &"battle_ended")
	assert_true(observed[0].presentation_only)
	assert_false(observed[0].durable_state)
	assert_eq(_load_save(_save_path).player_scraps, 7)


func test_durable_events_emit_only_after_save_commit_success() -> void:
	var contract: Node = _make_contract()
	if contract == null:
		return
	var save_service: RefCounted = _make_initialized_save_service(0)
	var durable_events: Array[RefCounted] = []
	var on_durable_event: Callable = func(payload: RefCounted) -> void:
		durable_events.append(payload)
	contract.committed_state_event.connect(on_durable_event)

	var tx = save_service.begin_transaction(&"ending_test")
	tx.staged_save.ending_id = &"restored_mainframe"
	var commit_result: RefCounted = save_service.commit_transaction(tx)
	var event_result: RefCounted = contract.emit_committed_state_event_after_commit(
		&"ending_resolved",
		&"restored_mainframe",
		{"ending_id": &"restored_mainframe"},
		commit_result
	)

	contract.committed_state_event.disconnect(on_durable_event)
	assert_true(commit_result.success)
	assert_true(event_result.success)
	assert_eq(durable_events.size(), 1)
	assert_eq(durable_events[0].event_id, &"ending_resolved")
	assert_true(durable_events[0].durable_state)
	assert_false(durable_events[0].presentation_only)
	assert_eq(_load_save(_save_path).ending_id, &"restored_mainframe")


func test_failed_save_commit_suppresses_durable_event_but_allows_presentation_event() -> void:
	var contract: Node = _make_contract()
	if contract == null:
		return
	var save_service: RefCounted = _make_initialized_save_service(0)
	var durable_events: Array[RefCounted] = []
	var presentation_events: Array[RefCounted] = []
	var on_durable_event: Callable = func(payload: RefCounted) -> void:
		durable_events.append(payload)
	var on_presentation_event: Callable = func(payload: RefCounted) -> void:
		presentation_events.append(payload)
	contract.committed_state_event.connect(on_durable_event)
	contract.presentation_event.connect(on_presentation_event)

	save_service.set_failure_injection(&"after_temp_write_before_swap", true)
	var tx = save_service.begin_transaction(&"corruption_test")
	tx.staged_save.corruption_class = &"breach"
	var commit_result: RefCounted = save_service.commit_transaction(tx)
	var durable_result: RefCounted = contract.emit_committed_state_event_after_commit(
		&"corruption_class_changed",
		&"breach",
		{"corruption_class": &"breach"},
		commit_result
	)
	var presentation_result: RefCounted = contract.emit_presentation_event(
		&"screen_changed",
		&"battle",
		{"transition_failed": true}
	)

	contract.committed_state_event.disconnect(on_durable_event)
	contract.presentation_event.disconnect(on_presentation_event)
	assert_false(commit_result.success)
	assert_false(durable_result.success)
	assert_eq(durable_result.reason, &"commit_failed")
	assert_eq(durable_events.size(), 0)
	assert_true(presentation_result.success)
	assert_eq(presentation_events.size(), 1)
	assert_eq(_load_save(_save_path).corruption_class, &"")


func _make_contract() -> Node:
	assert_true(ResourceLoader.exists(SEMANTIC_EVENT_CONTRACT_PATH), "SemanticEventContract script should exist.")
	if not ResourceLoader.exists(SEMANTIC_EVENT_CONTRACT_PATH):
		return null
	var script: GDScript = load(SEMANTIC_EVENT_CONTRACT_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return add_child_autofree(script.new())


func _make_initialized_save_service(scraps: int) -> RefCounted:
	var save_script: GDScript = load(SAVE_SERVICE_PATH)
	var save_data_script: GDScript = load(SAVE_DATA_PATH)
	var save_service: RefCounted = save_script.new()
	var save_data: Resource = save_data_script.new()
	save_data.player_scraps = scraps
	save_service.configure(_save_path, 0)
	var result: RefCounted = save_service.initialize_slot(save_data)
	assert_true(result.success)
	return save_service


func _load_save(path: String) -> SaveData:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is SaveData:
		return loaded
	return null


func _path_with_marker(path: String, marker: String) -> String:
	if path == "":
		return ""
	var extension: String = path.get_extension()
	if extension == "":
		return "%s.%s" % [path, marker]
	return "%s.%s.%s" % [path.get_basename(), marker, extension]
