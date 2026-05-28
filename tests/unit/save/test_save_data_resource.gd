extends GutTest

const SAVE_DATA_PATH: String = "res://src/save/save_data.gd"
const DRAGON_RECORD_PATH: String = "res://src/dragon/dragon_record.gd"
const TEST_SAVE_PATH: String = "user://gut_save_data_resource_round_trip.tres"

const REQUIRED_FIELDS: Array[String] = [
	"schema_version",
	"created_at_unix",
	"updated_at_unix",
	"last_committed_transaction_id",
	"current_node_id",
	"acts_unlocked",
	"unlocked_gates",
	"matrix_stabilized",
	"visited_nodes",
	"cleared_bosses",
	"cleared_combat_nodes",
	"loadout_hp",
	"previous_node_id",
	"expedition_xp_earned",
	"gate_denial_count",
	"expedition_field_kit",
	"corruption_class",
	"scar_nodes",
	"gatekeeper_fire_defeated",
	"gatekeeper_ice_defeated",
	"gatekeeper_shadow_defeated",
	"mirror_admin_defeated",
	"void_dragon_granted",
	"ending_id",
	"player_scraps",
	"relic_wrench_owned",
	"relic_lens_owned",
	"relic_blade_owned",
	"expedition_defrag_patch",
	"expedition_cache_shard",
	"expedition_emergency_patch",
	"dragons",
	"story_roster",
	"hatchery_pity_counter",
	"element_drought_counters",
	"journal_unlocked_ids",
	"journal_read_ids",
	"terminal_read_ids",
]


func after_each() -> void:
	var absolute_path: String = ProjectSettings.globalize_path(TEST_SAVE_PATH)
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(absolute_path)


func test_save_data_script_exists_and_is_resource() -> void:
	assert_true(ResourceLoader.exists(SAVE_DATA_PATH), "SaveData script should exist at the story evidence path.")
	if not ResourceLoader.exists(SAVE_DATA_PATH):
		return

	var script: GDScript = load(SAVE_DATA_PATH)

	assert_not_null(script, "SaveData script should load at the story evidence path.")
	if script == null:
		return

	var save_data: Resource = script.new()

	assert_true(save_data is Resource, "SaveData must be a typed Godot Resource.")
	assert_eq(save_data.schema_version, 1)


func test_save_data_is_data_only_without_feature_logic_or_signals() -> void:
	var save_data: Resource = _make_save_data()
	if save_data == null:
		return

	assert_eq(save_data.get_script().get_script_signal_list().size(), 0, "SaveData should not introduce committed-state signals.")
	assert_eq(_script_method_names(save_data), [], "SaveData should remain a data Resource without feature logic methods.")


func test_default_slot_contains_mvp_durable_fields() -> void:
	var save_data: Resource = _make_save_data()
	if save_data == null:
		return

	var property_names: Array[String] = _property_names(save_data)

	for field_name in REQUIRED_FIELDS:
		assert_true(property_names.has(field_name), "SaveData should expose required field: %s" % field_name)
	assert_false(property_names.has("game_state"), "SaveData must not expose serialized game_state.")
	assert_eq(save_data.player_scraps, 0)
	assert_eq(save_data.ending_id, &"")
	assert_eq(save_data.dragons.size(), 0)
	assert_eq(save_data.journal_unlocked_ids.size(), 0)


func test_exported_field_types_match_architecture_contracts() -> void:
	var save_data: Resource = _make_save_data()
	if save_data == null:
		return

	assert_eq(typeof(save_data.schema_version), TYPE_INT)
	assert_eq(typeof(save_data.current_node_id), TYPE_STRING_NAME)
	assert_eq(typeof(save_data.previous_node_id), TYPE_STRING_NAME)
	assert_eq(typeof(save_data.corruption_class), TYPE_STRING_NAME)
	assert_eq(typeof(save_data.ending_id), TYPE_STRING_NAME)
	assert_eq(typeof(save_data.player_scraps), TYPE_INT)
	assert_eq(typeof(save_data.matrix_stabilized), TYPE_BOOL)
	assert_eq(typeof(save_data.gatekeeper_fire_defeated), TYPE_BOOL)
	assert_eq(typeof(save_data.void_dragon_granted), TYPE_BOOL)
	assert_eq(typeof(save_data.gate_denial_count), TYPE_DICTIONARY)
	assert_eq(typeof(save_data.element_drought_counters), TYPE_DICTIONARY)
	assert_true(save_data.gate_denial_count.is_typed(), "gate_denial_count should be a typed Dictionary.")
	assert_eq(save_data.gate_denial_count.get_typed_key_builtin(), TYPE_STRING_NAME)
	assert_eq(save_data.gate_denial_count.get_typed_value_builtin(), TYPE_INT)
	assert_true(save_data.element_drought_counters.is_typed(), "element_drought_counters should be a typed Dictionary.")
	assert_eq(save_data.element_drought_counters.get_typed_key_builtin(), TYPE_STRING_NAME)
	assert_eq(save_data.element_drought_counters.get_typed_value_builtin(), TYPE_INT)
	_assert_typed_array(save_data.acts_unlocked, TYPE_STRING_NAME, &"acts_unlocked")
	_assert_typed_array(save_data.visited_nodes, TYPE_STRING_NAME, &"visited_nodes")
	_assert_typed_array(save_data.scar_nodes, TYPE_STRING_NAME, &"scar_nodes")
	_assert_typed_array(save_data.loadout_hp, TYPE_INT, &"loadout_hp")
	_assert_typed_array(save_data.story_roster, TYPE_STRING_NAME, &"story_roster")
	_assert_typed_array(save_data.journal_read_ids, TYPE_STRING_NAME, &"journal_read_ids")
	assert_true(save_data.dragons.is_typed(), "dragons should be a typed Array.")
	assert_eq(save_data.dragons.get_typed_builtin(), TYPE_OBJECT)
	assert_true([&"DragonRecord", &"Resource"].has(save_data.dragons.get_typed_class_name()), "Godot should expose dragon roster as an object/resource typed Array.")


func test_default_slot_round_trips_with_pristine_defaults() -> void:
	var save_data: Resource = _make_save_data()
	if save_data == null:
		return

	var save_error: int = ResourceSaver.save(save_data, TEST_SAVE_PATH)
	var loaded: Resource = ResourceLoader.load(TEST_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

	assert_eq(save_error, OK)
	assert_not_null(loaded, "Completely default SaveData should load through ResourceLoader.")
	if loaded == null:
		return
	assert_eq(loaded.player_scraps, 0)
	assert_eq(loaded.ending_id, &"")
	_assert_default_values(loaded)
	_assert_save_data_collection_fields_empty(loaded)
	_assert_typed_save_data_collections(loaded)


func test_default_slot_round_trips_through_godot_resource_api() -> void:
	var save_data: Resource = _make_save_data()
	if save_data == null:
		return
	save_data.player_scraps = 65
	save_data.current_node_id = &"village_edge"
	save_data.visited_nodes.append(&"village_edge")
	save_data.journal_unlocked_ids.append(&"captains_log_01")

	var save_error: int = ResourceSaver.save(save_data, TEST_SAVE_PATH)
	var loaded: Resource = ResourceLoader.load(TEST_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

	assert_eq(save_error, OK)
	assert_not_null(loaded, "Saved SaveData should load through ResourceLoader.")
	if loaded == null:
		return
	assert_true(loaded is Resource)
	assert_eq(loaded.player_scraps, 65)
	assert_eq(loaded.current_node_id, &"village_edge")
	assert_eq(loaded.visited_nodes, [&"village_edge"])
	assert_eq(loaded.journal_unlocked_ids, [&"captains_log_01"])


func test_dragon_roster_uses_typed_dragon_records() -> void:
	var save_data: Resource = _make_save_data()
	var dragon_record: Resource = _make_dragon_record()
	if save_data == null or dragon_record == null:
		return
	dragon_record.dragon_id = &"root_wyrmling"
	dragon_record.element = &"Root"
	dragon_record.level = 7
	save_data.dragons.append(dragon_record)

	var save_error: int = ResourceSaver.save(save_data, TEST_SAVE_PATH)
	var loaded: Resource = ResourceLoader.load(TEST_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

	assert_eq(save_error, OK)
	assert_not_null(loaded, "SaveData with nested DragonRecord should round-trip.")
	if loaded == null:
		return
	assert_eq(loaded.dragons.size(), 1)
	assert_true(loaded.dragons[0] is Resource, "Dragon roster entries should be typed Resources, not dictionaries.")
	assert_eq(loaded.dragons[0].get_script(), load(DRAGON_RECORD_PATH), "Dragon roster entries should use the DragonRecord Resource script.")
	assert_eq(loaded.dragons[0].dragon_id, &"root_wyrmling")
	assert_eq(loaded.dragons[0].element, &"Root")
	assert_eq(loaded.dragons[0].level, 7)
	assert_false(_property_names(loaded.dragons[0]).has("stage"), "DragonRecord must not persist derived stage.")


func test_nested_arrays_dictionaries_and_loaded_resources_do_not_share_mutations() -> void:
	var first: Resource = _make_save_data()
	var second: Resource = _make_save_data()
	var dragon_record: Resource = _make_dragon_record()
	if first == null or second == null or dragon_record == null:
		return
	dragon_record.dragon_id = &"root_wyrmling"
	first.visited_nodes.append(&"village_edge")
	first.gate_denial_count[&"gate_a"] = 1
	first.dragons.append(dragon_record)

	assert_eq(second.visited_nodes.size(), 0, "Fresh SaveData instances should not share array defaults.")
	assert_eq(second.gate_denial_count.size(), 0, "Fresh SaveData instances should not share dictionary defaults.")
	assert_eq(second.dragons.size(), 0, "Fresh SaveData instances should not share dragon roster defaults.")

	var save_error: int = ResourceSaver.save(first, TEST_SAVE_PATH)
	var loaded: Resource = ResourceLoader.load(TEST_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	assert_eq(save_error, OK)
	assert_not_null(loaded)
	if loaded == null:
		return

	loaded.visited_nodes.append(&"loaded_only")
	loaded.gate_denial_count[&"loaded_gate"] = 2
	loaded.dragons[0].level = 9

	assert_eq(first.visited_nodes, [&"village_edge"], "Loaded SaveData array mutation should not leak back to original object.")
	assert_false(first.gate_denial_count.has(&"loaded_gate"), "Loaded SaveData dictionary mutation should not leak back to original object.")
	assert_eq(first.dragons[0].level, 1, "Loaded nested DragonRecord mutation should not leak back to original object.")


func test_serialized_save_data_uses_ending_id_not_game_state() -> void:
	var save_data: Resource = _make_save_data()
	if save_data == null:
		return
	save_data.ending_id = &"restoration"

	var save_error: int = ResourceSaver.save(save_data, TEST_SAVE_PATH)
	var serialized_text: String = FileAccess.get_file_as_string(TEST_SAVE_PATH)
	var loaded: Resource = ResourceLoader.load(TEST_SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

	assert_eq(save_error, OK)
	assert_ne(serialized_text.find("ending_id"), -1, "Serialized SaveData should include ending_id.")
	assert_eq(serialized_text.find("game_state"), -1, "Serialized SaveData must not include game_state.")
	assert_not_null(loaded)
	if loaded == null:
		return
	assert_eq(loaded.ending_id, &"restoration")
	assert_false(_property_names(loaded).has("game_state"))


func _assert_default_values(save_data: Resource) -> void:
	assert_eq(save_data.schema_version, 1)
	assert_eq(save_data.created_at_unix, 0)
	assert_eq(save_data.updated_at_unix, 0)
	assert_eq(save_data.last_committed_transaction_id, &"")
	assert_eq(save_data.current_node_id, &"")
	assert_eq(save_data.matrix_stabilized, false)
	assert_eq(save_data.previous_node_id, &"")
	assert_eq(save_data.expedition_xp_earned, 0)
	assert_eq(save_data.expedition_field_kit, false)
	assert_eq(save_data.corruption_class, &"")
	assert_eq(save_data.gatekeeper_fire_defeated, false)
	assert_eq(save_data.gatekeeper_ice_defeated, false)
	assert_eq(save_data.gatekeeper_shadow_defeated, false)
	assert_eq(save_data.mirror_admin_defeated, false)
	assert_eq(save_data.void_dragon_granted, false)
	assert_eq(save_data.ending_id, &"")
	assert_eq(save_data.player_scraps, 0)
	assert_eq(save_data.relic_wrench_owned, false)
	assert_eq(save_data.relic_lens_owned, false)
	assert_eq(save_data.relic_blade_owned, false)
	assert_eq(save_data.expedition_defrag_patch, false)
	assert_eq(save_data.expedition_cache_shard, false)
	assert_eq(save_data.expedition_emergency_patch, false)
	assert_eq(save_data.hatchery_pity_counter, 0)


func _assert_save_data_collection_fields_empty(save_data: Resource) -> void:
	assert_eq(save_data.acts_unlocked.size(), 0)
	assert_eq(save_data.unlocked_gates.size(), 0)
	assert_eq(save_data.visited_nodes.size(), 0)
	assert_eq(save_data.cleared_bosses.size(), 0)
	assert_eq(save_data.cleared_combat_nodes.size(), 0)
	assert_eq(save_data.loadout_hp.size(), 0)
	assert_eq(save_data.scar_nodes.size(), 0)
	assert_eq(save_data.gate_denial_count.size(), 0)
	assert_eq(save_data.element_drought_counters.size(), 0)
	assert_eq(save_data.dragons.size(), 0)
	assert_eq(save_data.story_roster.size(), 0)
	assert_eq(save_data.journal_unlocked_ids.size(), 0)
	assert_eq(save_data.journal_read_ids.size(), 0)
	assert_eq(save_data.terminal_read_ids.size(), 0)


func _assert_typed_save_data_collections(save_data: Resource) -> void:
	_assert_typed_array(save_data.acts_unlocked, TYPE_STRING_NAME, &"acts_unlocked")
	_assert_typed_array(save_data.unlocked_gates, TYPE_STRING_NAME, &"unlocked_gates")
	_assert_typed_array(save_data.visited_nodes, TYPE_STRING_NAME, &"visited_nodes")
	_assert_typed_array(save_data.cleared_bosses, TYPE_STRING_NAME, &"cleared_bosses")
	_assert_typed_array(save_data.cleared_combat_nodes, TYPE_STRING_NAME, &"cleared_combat_nodes")
	_assert_typed_array(save_data.loadout_hp, TYPE_INT, &"loadout_hp")
	_assert_typed_array(save_data.scar_nodes, TYPE_STRING_NAME, &"scar_nodes")
	_assert_typed_array(save_data.story_roster, TYPE_STRING_NAME, &"story_roster")
	_assert_typed_array(save_data.journal_unlocked_ids, TYPE_STRING_NAME, &"journal_unlocked_ids")
	_assert_typed_array(save_data.journal_read_ids, TYPE_STRING_NAME, &"journal_read_ids")
	_assert_typed_array(save_data.terminal_read_ids, TYPE_STRING_NAME, &"terminal_read_ids")
	_assert_typed_dictionary(save_data.gate_denial_count, TYPE_STRING_NAME, TYPE_INT, &"gate_denial_count")
	_assert_typed_dictionary(save_data.element_drought_counters, TYPE_STRING_NAME, TYPE_INT, &"element_drought_counters")


func _make_save_data() -> Resource:
	assert_true(ResourceLoader.exists(SAVE_DATA_PATH), "SaveData script should exist before constructing defaults.")
	if not ResourceLoader.exists(SAVE_DATA_PATH):
		return null

	var script: GDScript = load(SAVE_DATA_PATH)
	assert_not_null(script, "SaveData script should load before constructing defaults.")
	if script == null:
		return null
	return script.new()


func _make_dragon_record() -> Resource:
	assert_true(ResourceLoader.exists(DRAGON_RECORD_PATH), "DragonRecord script should exist for typed dragon roster entries.")
	if not ResourceLoader.exists(DRAGON_RECORD_PATH):
		return null

	var script: GDScript = load(DRAGON_RECORD_PATH)
	assert_not_null(script, "DragonRecord script should load before constructing roster entries.")
	if script == null:
		return null
	return script.new()


func _property_names(object: Object) -> Array[String]:
	var names: Array[String] = []
	for property in object.get_property_list():
		names.append(property["name"])
	return names


func _script_method_names(object: Object) -> Array[String]:
	var names: Array[String] = []
	for method in object.get_script().get_script_method_list():
		names.append(method["name"])
	return names


func _assert_typed_array(array: Array, typed_builtin: int, field_name: StringName) -> void:
	assert_true(array.is_typed(), "%s should be a typed Array." % field_name)
	assert_eq(array.get_typed_builtin(), typed_builtin, "%s should use the expected typed Array element type." % field_name)


func _assert_typed_dictionary(dictionary: Dictionary, key_builtin: int, value_builtin: int, field_name: StringName) -> void:
	assert_true(dictionary.is_typed(), "%s should be a typed Dictionary." % field_name)
	assert_eq(dictionary.get_typed_key_builtin(), key_builtin, "%s should use the expected key type." % field_name)
	assert_eq(dictionary.get_typed_value_builtin(), value_builtin, "%s should use the expected value type." % field_name)
