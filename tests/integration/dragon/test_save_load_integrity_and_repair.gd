extends GutTest

const DragonProgressionServiceScript = preload("res://src/dragon/dragon_progression_service.gd")
const DragonRecordScript = preload("res://src/dragon/dragon_record.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const TEST_SAVE_PATH: String = "user://gut_dragon_save_load_repair_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_dragon_save_load_repair_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_dragon_save_load_repair_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_invalid_loaded_records_are_discarded_without_clamping_valid_roster() -> void:
	var service = DragonProgressionServiceScript.new()
	var loaded: SaveData = _round_trip_save([
		_make_dragon(&"fire_valid", &"Fire", 12, 20, 0),
		_make_dragon(&"ice_zero", &"Ice", 0, 0, 0),
		_make_dragon(&"stone_too_high", &"Stone", 61, 0, 0),
		_make_dragon(&"storm_negative_xp", &"Storm", 5, -1, 0),
		_make_dragon(&"wind_unknown", &"Wind", 5, 0, 0),
		_make_dragon(&"fake_void", &"Void", 30, 0, 0),
		_make_dragon(&"fire_valid", &"Fire", 10, 0, 0),
	])

	var result: RefCounted = service.validate_and_repair_save_data(loaded)

	assert_true(result.success, result.error_message)
	assert_eq(loaded.dragons.size(), 1)
	assert_eq(loaded.dragons[0].dragon_id, &"fire_valid")
	assert_eq(loaded.dragons[0].level, 12)
	assert_true(result.discarded_dragon_ids.has(&"ice_zero"))
	assert_true(result.discarded_dragon_ids.has(&"stone_too_high"))
	assert_true(result.discarded_dragon_ids.has(&"storm_negative_xp"))
	assert_true(result.discarded_dragon_ids.has(&"wind_unknown"))
	assert_true(result.discarded_dragon_ids.has(&"fake_void"))
	assert_true(result.discarded_dragon_ids.has(&"fire_valid"))
	assert_push_error("Save integrity violation: dragon.level out of range 0 for element Ice. Dragon record discarded.")
	assert_push_error("Save integrity violation: dragon.level out of range 61 for element Stone. Dragon record discarded.")
	assert_push_error("Save integrity violation: dragon.xp negative -1 for element Storm. Dragon record discarded.")
	assert_push_error("Save integrity violation: unknown element 'Wind'. Dragon record discarded.")
	assert_push_error("Save integrity violation: Void dragon must use reserved dragon_id 'void_dragon'. Dragon record discarded.")
	assert_push_error("Save integrity violation: duplicate dragon_id 'fire_valid'. Dragon record discarded.")


func test_xp_repair_clears_max_level_xp_and_resets_charges_before_repair_loop() -> void:
	var service = DragonProgressionServiceScript.new()
	var loaded: SaveData = _round_trip_save([
		_make_dragon(&"fire_max", &"Fire", 60, 45, 4),
		_make_dragon(&"stone_max_charged", &"Stone", 60, 0, 5),
		_make_dragon(&"ice_overflow_no_charges", &"Ice", 5, 150, 0),
		_make_dragon(&"storm_overflow_charged", &"Storm", 5, 150, 5),
	])

	var result: RefCounted = service.validate_and_repair_save_data(loaded)

	assert_true(result.success, result.error_message)
	var max_dragon: DragonRecord = _find_dragon(loaded, &"fire_max")
	var max_charged: DragonRecord = _find_dragon(loaded, &"stone_max_charged")
	var no_charge: DragonRecord = _find_dragon(loaded, &"ice_overflow_no_charges")
	var charged: DragonRecord = _find_dragon(loaded, &"storm_overflow_charged")
	assert_eq(max_dragon.level, 60)
	assert_eq(max_dragon.xp, 0)
	assert_eq(max_dragon.battle_charges, 0)
	assert_eq(max_charged.level, 60)
	assert_eq(max_charged.xp, 0)
	assert_eq(max_charged.battle_charges, 0)
	assert_eq(no_charge.level, 8)
	assert_eq(no_charge.xp, 0)
	assert_eq(no_charge.battle_charges, 0)
	assert_eq(charged.level, 8)
	assert_eq(charged.xp, 0)
	assert_eq(charged.battle_charges, 0)
	assert_true(result.repaired_dragon_ids.has(&"fire_max"))
	assert_true(result.repaired_dragon_ids.has(&"stone_max_charged"))
	assert_true(result.repaired_dragon_ids.has(&"ice_overflow_no_charges"))
	assert_true(result.repaired_dragon_ids.has(&"storm_overflow_charged"))
	assert_push_warning("Save correction: dragon.xp 45 cleared for MAX_LEVEL dragon Fire.")
	assert_push_warning("Save correction: battle_charges 4 cleared for MAX_LEVEL dragon Fire.")
	assert_push_warning("Save correction: battle_charges 5 cleared for MAX_LEVEL dragon Stone.")
	assert_push_warning("Save correction: dragon.xp 150 at level 5 — running XP loop to resolve.")


func test_conflict_projection_selects_higher_level_then_higher_xp_and_preserves_void() -> void:
	var service = DragonProgressionServiceScript.new()

	var higher_level: RefCounted = service.select_conflict_winner(
		_make_dragon(&"fire_conflict", &"Fire", 12, 20, 0),
		_make_dragon(&"fire_conflict", &"Fire", 10, 40, 0)
	)
	var higher_xp: RefCounted = service.select_conflict_winner(
		_make_dragon(&"ice_conflict", &"Ice", 10, 30, 0),
		_make_dragon(&"ice_conflict", &"Ice", 10, 80, 0)
	)
	var loaded: SaveData = _round_trip_save(_make_full_core_roster() + [
		_make_dragon(&"void_dragon", &"Fire", 30, 0, 0),
		_make_dragon(&"void_dragon", &"Void", 30, 0, 0, true),
	])
	var repair_result: RefCounted = service.validate_and_repair_save_data(loaded)
	var void_dragon: DragonRecord = _find_dragon(loaded, &"void_dragon")

	assert_eq(higher_level.selected_source, &"local")
	assert_eq(higher_level.dragon.level, 12)
	assert_eq(higher_level.dragon.xp, 20)
	assert_eq(higher_xp.selected_source, &"cloud")
	assert_eq(higher_xp.dragon.level, 10)
	assert_eq(higher_xp.dragon.xp, 80)
	assert_true(repair_result.success, repair_result.error_message)
	assert_not_null(void_dragon)
	assert_eq(void_dragon.element, &"Void")
	assert_false(void_dragon.shiny)
	assert_true(loaded.story_roster.has(&"void_dragon"))
	assert_true(loaded.void_dragon_granted)
	assert_eq(loaded.dragons.size(), 7)
	assert_true(repair_result.discarded_dragon_ids.has(&"void_dragon"))
	assert_push_error("Save integrity violation: reserved dragon_id 'void_dragon' requires element Void. Dragon record discarded.")


func test_post_load_snapshots_derive_stage_and_stage_multiplier_without_persisted_stage() -> void:
	var service = DragonProgressionServiceScript.new()
	var loaded: SaveData = _round_trip_save([
		_make_dragon(&"fire_stage_two", &"Fire", 12, 0, 0),
		_make_dragon(&"shadow_stage_four", &"Shadow", 55, 0, 0),
	])

	var result: RefCounted = service.validate_and_repair_save_data(loaded)
	var stage_two_stats: DragonStats = service.calculate_stats(_find_dragon(loaded, &"fire_stage_two"))
	var stage_four_stats: DragonStats = service.calculate_stats(_find_dragon(loaded, &"shadow_stage_four"))

	assert_true(result.success, result.error_message)
	assert_eq(stage_two_stats.stage, service.STAGE_II)
	assert_almost_eq(stage_two_stats.stage_multiplier, 0.75, 0.001)
	assert_eq(stage_four_stats.stage, service.STAGE_IV)
	assert_almost_eq(stage_four_stats.stage_multiplier, 1.4, 0.001)
	assert_false(_record_has_property(_find_dragon(loaded, &"fire_stage_two"), "stage"))


func _round_trip_save(dragons: Array) -> SaveData:
	var save_service: SaveService = SaveServiceScript.new()
	var save_data: SaveData = SaveDataScript.new()
	for dragon: DragonRecord in dragons:
		save_data.dragons.append(dragon)
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(save_data)
	assert_true(initialize_result.success, initialize_result.error_message)
	return _load_save(TEST_SAVE_PATH)


func _make_full_core_roster() -> Array:
	return [
		_make_dragon(&"fire_party", &"Fire", 12, 0, 0),
		_make_dragon(&"ice_party", &"Ice", 12, 0, 0),
		_make_dragon(&"storm_party", &"Storm", 12, 0, 0),
		_make_dragon(&"stone_party", &"Stone", 12, 0, 0),
		_make_dragon(&"venom_party", &"Venom", 12, 0, 0),
		_make_dragon(&"shadow_party", &"Shadow", 12, 0, 0),
	]


func _make_dragon(dragon_id: StringName, element: StringName, level: int, xp: int, battle_charges: int, shiny: bool = false) -> DragonRecord:
	var dragon: DragonRecord = DragonRecordScript.new()
	dragon.dragon_id = dragon_id
	dragon.element = element
	dragon.base_hp = 110
	dragon.base_atk = 28
	dragon.base_def = 16
	dragon.base_spd = 22
	dragon.level = level
	dragon.xp = xp
	dragon.battle_charges = battle_charges
	dragon.shiny = shiny
	return dragon


func _find_dragon(save_data: SaveData, dragon_id: StringName) -> DragonRecord:
	for dragon: DragonRecord in save_data.dragons:
		if dragon.dragon_id == dragon_id:
			return dragon
	return null


func _record_has_property(record: DragonRecord, property_name: String) -> bool:
	for property: Dictionary in record.get_property_list():
		if String(property.get("name", "")) == property_name:
			return true
	return false


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
