extends GutTest

const SaveData = preload("res://src/save/save_data.gd")

const SAVE_SERVICE_PATH: String = "res://src/save/save_service.gd"
const SAVE_STATE_PROJECTION_PATH: String = "res://src/save/save_state_projection.gd"
const TEST_SAVE_PATH: String = "user://gut_ending_id_projection_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_ending_id_projection_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_ending_id_projection_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_projection_script_exists_for_campaign_map_reads() -> void:
	assert_true(ResourceLoader.exists(SAVE_STATE_PROJECTION_PATH), "SaveStateProjection should exist for Campaign Map load reads.")


func test_ending_commit_writes_ending_id_only_without_game_state() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return
	var initial_save: SaveData = _make_save_data()
	initial_save.current_node_id = &"village_edge"
	initial_save.player_scraps = 32
	var initialize_result: RefCounted = service.initialize_slot(initial_save)
	assert_true(initialize_result.success, initialize_result.error_message)

	var tx: RefCounted = service.begin_transaction(&"singularity_ending_commit")
	tx.staged_save.ending_id = &"garden"
	var commit_result: RefCounted = service.commit_transaction(tx)
	var loaded: SaveData = _load_save(TEST_SAVE_PATH)
	var serialized_text: String = FileAccess.get_file_as_string(TEST_SAVE_PATH)

	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(loaded.ending_id, &"garden")
	assert_eq(loaded.current_node_id, &"village_edge", "Ending commit should preserve unrelated Campaign Map state.")
	assert_eq(loaded.player_scraps, 32, "Ending commit should preserve unrelated economy state.")
	assert_ne(serialized_text.find("ending_id"), -1, "Ending commit should serialize ending_id.")
	assert_eq(serialized_text.find("game_state"), -1, "Ending commit must not serialize game_state.")


func test_non_empty_ending_loads_read_projection_for_map_free_roam() -> void:
	var service: RefCounted = _make_service_with_save(&"garden")
	if service == null:
		return
	assert_true(service.has_method("load_state_projection"), "SaveService should expose a load_state_projection API.")
	assert_false(service.has_method("load_current_save"), "SaveService should not expose mutable SaveData reads to runtime systems.")
	if not service.has_method("load_state_projection"):
		return

	var projection: RefCounted = service.load_state_projection()

	assert_not_null(projection)
	if projection == null:
		return
	assert_true(projection.has_method("get_ending_id"), "Projection should expose ending_id through a getter.")
	assert_true(projection.has_method("get_map_state"), "Projection should expose the derived Campaign Map state.")
	assert_true(projection.has_method("is_post_game"), "Projection should expose a post-game predicate.")
	assert_eq(projection.get_ending_id(), &"garden")
	assert_eq(projection.get_map_state(), &"MAP_FREE_ROAM")
	assert_true(projection.is_post_game())
	assert_eq(_load_save(TEST_SAVE_PATH).ending_id, &"garden", "Projection reads must not mutate canonical SaveData.")


func test_empty_ending_loads_explore_projection_without_warnings() -> void:
	var service: RefCounted = _make_service_with_save(&"")
	if service == null:
		return
	assert_true(service.has_method("load_state_projection"), "SaveService should expose a load_state_projection API.")
	if not service.has_method("load_state_projection"):
		return

	var projection: RefCounted = service.load_state_projection()

	assert_not_null(projection)
	if projection == null:
		return
	assert_eq(projection.get_ending_id(), &"")
	assert_eq(projection.get_map_state(), &"MAP_EXPLORE")
	assert_false(projection.is_post_game())
	assert_eq(projection.get_warnings().size(), 0)


func test_unknown_non_empty_ending_warns_but_still_projects_free_roam() -> void:
	var service: RefCounted = _make_service_with_save(&"garden")
	if service == null:
		return
	assert_true(service.has_method("load_state_projection"), "SaveService should expose a load_state_projection API.")
	if not service.has_method("load_state_projection"):
		return

	var known_ending_ids: Array[StringName] = [&"total_restore", &"the_patch", &"hardware_override"]
	var projection: RefCounted = service.load_state_projection(known_ending_ids)

	assert_not_null(projection)
	if projection == null:
		return
	assert_eq(projection.get_ending_id(), &"garden")
	assert_eq(projection.get_map_state(), &"MAP_FREE_ROAM")
	assert_true(projection.is_post_game())
	assert_eq(projection.get_warnings().size(), 1)
	assert_ne(String(projection.get_warnings()[0]).find("garden"), -1)


func _make_service_with_save(ending_id: StringName) -> RefCounted:
	var service: RefCounted = _make_service()
	if service == null:
		return null
	var save_data: SaveData = _make_save_data()
	save_data.ending_id = ending_id
	var initialize_result: RefCounted = service.initialize_slot(save_data)
	assert_true(initialize_result.success, initialize_result.error_message)
	if not initialize_result.success:
		return null
	return service


func _make_service() -> RefCounted:
	assert_true(ResourceLoader.exists(SAVE_SERVICE_PATH), "SaveService script should exist for projection tests.")
	if not ResourceLoader.exists(SAVE_SERVICE_PATH):
		return null

	var script: GDScript = load(SAVE_SERVICE_PATH)
	assert_not_null(script)
	if script == null:
		return null
	var service: RefCounted = script.new()
	service.configure(TEST_SAVE_PATH, 0)
	return service


func _make_save_data() -> SaveData:
	var save_data: SaveData = SaveData.new()
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
