extends GutTest

const DragonProgressionServiceScript = preload("res://src/dragon/dragon_progression_service.gd")
const DragonRecordScript = preload("res://src/dragon/dragon_record.gd")
const FusionChildDataScript = preload("res://src/dragon/fusion_child_data.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const TEST_SAVE_PATH: String = "user://gut_dragon_creation_helpers_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_dragon_creation_helpers_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_dragon_creation_helpers_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_hatchery_creation_stages_canonical_core_dragon_and_rejects_void() -> void:
	var services: Dictionary = _make_initialized_services([])
	var dragon_service: DragonProgressionService = services.dragon
	var save_service: SaveService = services.save
	var tx: SaveTransaction = save_service.begin_transaction(&"hatchery_fire")

	var result: DragonCreationResult = dragon_service.create_from_hatchery(tx, &"Fire", true, &"hatchery_pull")

	assert_true(result.success, result.error_message)
	assert_eq(result.reason, &"ok")
	assert_eq(result.source_id, &"hatchery_pull")
	assert_ne(result.dragon_id, &"")
	assert_eq(result.element, &"Fire")
	assert_eq(tx.staged_save.dragons.size(), 1)
	var fire: DragonRecord = tx.staged_save.dragons[0]
	assert_eq(fire.dragon_id, result.dragon_id)
	assert_eq(fire.element, &"Fire")
	assert_eq([fire.base_hp, fire.base_atk, fire.base_def, fire.base_spd], [110, 28, 16, 22])
	assert_eq(fire.level, 1)
	assert_eq(fire.xp, 0)
	assert_true(fire.shiny)
	assert_eq(fire.battle_charges, 0)
	assert_false(fire.is_elder)
	assert_not_null(result.dragon)
	assert_false(result.dragon == fire)
	result.dragon.shiny = false
	result.dragon.element = &"Void"
	assert_true(fire.shiny, "Creation result snapshots must not mutate staged shiny after hatch.")
	assert_eq(fire.element, &"Fire", "Creation result snapshots must not mutate staged identity.")
	assert_eq(_load_save(TEST_SAVE_PATH).dragons.size(), 0, "Creation must remain staged until commit.")

	var duplicate_result: DragonCreationResult = dragon_service.create_from_hatchery(tx, &"Fire", false, &"hatchery_duplicate")
	assert_false(duplicate_result.success)
	assert_eq(duplicate_result.reason, &"duplicate_element")
	assert_eq(tx.staged_save.dragons.size(), 1)

	var commit_result: SaveCommitResult = save_service.commit_transaction(tx)
	assert_true(commit_result.success, commit_result.error_message)
	assert_eq(_load_save(TEST_SAVE_PATH).dragons.size(), 1)

	var reject_services: Dictionary = _make_initialized_services([])
	var reject_tx: SaveTransaction = reject_services.save.begin_transaction(&"hatchery_void")
	var void_result: DragonCreationResult = reject_services.dragon.create_from_hatchery(reject_tx, &"Void", false, &"hatchery_pull")
	assert_false(void_result.success)
	assert_eq(void_result.reason, &"invalid_element")
	assert_eq(reject_tx.staged_save.dragons.size(), 0)


func test_fusion_creation_uses_inherited_data_and_rejects_void_output() -> void:
	var services: Dictionary = _make_initialized_services([])
	var dragon_service: DragonProgressionService = services.dragon
	var tx: SaveTransaction = services.save.begin_transaction(&"fusion_child")
	var child_data: FusionChildData = _make_child_data(&"fusion_storm_child", &"Storm", [140, 31, 22, 35], true)

	var result: DragonCreationResult = dragon_service.create_from_fusion(tx, &"fire_parent", &"ice_parent", child_data, &"fusion_lab")

	assert_true(result.success, result.error_message)
	assert_eq(result.reason, &"ok")
	assert_eq(result.source_id, &"fusion_lab")
	assert_eq(result.primary_id, &"fire_parent")
	assert_eq(result.secondary_id, &"ice_parent")
	assert_eq(tx.staged_save.dragons.size(), 1)
	var child: DragonRecord = tx.staged_save.dragons[0]
	assert_eq(child.dragon_id, &"fusion_storm_child")
	assert_eq(child.element, &"Storm")
	assert_eq([child.base_hp, child.base_atk, child.base_def, child.base_spd], [140, 31, 22, 35])
	assert_eq(child.level, 1)
	assert_eq(child.xp, 0)
	assert_false(child.shiny)
	assert_eq(child.battle_charges, 0)
	assert_true(child.is_elder)

	var reject_tx: SaveTransaction = services.save.begin_transaction(&"fusion_void")
	var void_data: FusionChildData = _make_child_data(&"void_child", &"Void", [80, 40, 20, 36], false)
	var void_result: DragonCreationResult = dragon_service.create_from_fusion(reject_tx, &"fire_parent", &"ice_parent", void_data, &"fusion_lab")
	assert_false(void_result.success)
	assert_eq(void_result.reason, &"invalid_element")
	assert_eq(reject_tx.staged_save.dragons.size(), 0)


func test_singularity_void_grant_uses_story_roster_capacity_and_forces_non_shiny() -> void:
	var services: Dictionary = _make_initialized_services(_make_full_core_roster())
	var dragon_service: DragonProgressionService = services.dragon
	var tx: SaveTransaction = services.save.begin_transaction(&"singularity_void")

	var result: DragonCreationResult = dragon_service.grant_void_dragon(tx, &"singularity_reward")

	assert_true(result.success, result.error_message)
	assert_eq(result.reason, &"ok")
	assert_eq(result.dragon_id, &"void_dragon")
	assert_eq(result.element, &"Void")
	assert_eq(tx.staged_save.dragons.size(), 7)
	assert_true(tx.staged_save.void_dragon_granted)
	assert_true(tx.staged_save.story_roster.has(&"void_dragon"))
	var void_dragon: DragonRecord = _find_dragon(tx.staged_save, &"void_dragon")
	assert_not_null(void_dragon)
	assert_eq(void_dragon.element, &"Void")
	assert_eq([void_dragon.base_hp, void_dragon.base_atk, void_dragon.base_def, void_dragon.base_spd], [80, 40, 20, 36])
	assert_eq(void_dragon.level, 30)
	assert_eq(void_dragon.xp, 0)
	assert_false(void_dragon.shiny)
	assert_eq(void_dragon.battle_charges, 0)
	assert_false(void_dragon.is_elder)

	var repeated_result: DragonCreationResult = dragon_service.grant_void_dragon(tx, &"singularity_reward")
	assert_true(repeated_result.success, repeated_result.error_message)
	assert_eq(repeated_result.reason, &"already_granted")
	assert_true(repeated_result.already_present)
	assert_false(repeated_result.created)
	assert_not_null(repeated_result.dragon)
	repeated_result.dragon.shiny = true
	assert_eq(_count_dragon_id(tx.staged_save, &"void_dragon"), 1)
	assert_false(void_dragon.shiny)


func test_shiny_immutability_and_missing_duplicate_target_discards_with_log() -> void:
	var services: Dictionary = _make_initialized_services([_make_dragon(&"fire_party", &"Fire", false)])
	var dragon_service: DragonProgressionService = services.dragon
	var tx: SaveTransaction = services.save.begin_transaction(&"missing_duplicate")

	assert_false(dragon_service.has_method("set_shiny"))
	assert_false(dragon_service.has_method("update_shiny"))

	var result: XPApplyResult = dragon_service.apply_hatchery_duplicate_xp(tx, &"Wind", 50, &"dupe_common")

	assert_false(result.success)
	assert_eq(result.reason, &"missing_duplicate_target")
	assert_eq(result.element, &"Wind")
	assert_eq(result.xp_requested, 50)
	assert_eq(result.xp_awarded, 0)
	assert_eq(tx.staged_save.dragons.size(), 1)
	assert_false(tx.staged_save.dragons[0].shiny)
	assert_eq(tx.staged_save.dragons[0].xp, 0)
	assert_push_error("Hatchery XP discarded: element Wind not in party.")


func _make_initialized_services(dragons: Array) -> Dictionary:
	var save_service: SaveService = SaveServiceScript.new()
	var save_data: SaveData = SaveDataScript.new()
	for dragon: DragonRecord in dragons:
		save_data.dragons.append(dragon)
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(save_data)
	assert_true(initialize_result.success, initialize_result.error_message)
	return {
		"save": save_service,
		"dragon": DragonProgressionServiceScript.new(),
	}


func _make_full_core_roster() -> Array:
	var dragons: Array = []
	for element: StringName in [&"Fire", &"Ice", &"Storm", &"Stone", &"Venom", &"Shadow"]:
		dragons.append(_make_dragon(StringName("%s_party" % String(element).to_lower()), element, false))
	return dragons


func _make_dragon(dragon_id: StringName, element: StringName, shiny: bool) -> DragonRecord:
	var dragon: DragonRecord = DragonRecordScript.new()
	dragon.dragon_id = dragon_id
	dragon.element = element
	dragon.base_hp = 110
	dragon.base_atk = 28
	dragon.base_def = 16
	dragon.base_spd = 22
	dragon.level = 1
	dragon.xp = 0
	dragon.shiny = shiny
	return dragon


func _make_child_data(dragon_id: StringName, element: StringName, stats: Array, is_elder: bool) -> FusionChildData:
	var child_data: FusionChildData = FusionChildDataScript.new()
	child_data.dragon_id = dragon_id
	child_data.element = element
	child_data.base_hp = int(stats[0])
	child_data.base_atk = int(stats[1])
	child_data.base_def = int(stats[2])
	child_data.base_spd = int(stats[3])
	child_data.is_elder = is_elder
	return child_data


func _find_dragon(save_data: SaveData, dragon_id: StringName) -> DragonRecord:
	for dragon: DragonRecord in save_data.dragons:
		if dragon.dragon_id == dragon_id:
			return dragon
	return null


func _count_dragon_id(save_data: SaveData, dragon_id: StringName) -> int:
	var count: int = 0
	for dragon: DragonRecord in save_data.dragons:
		if dragon.dragon_id == dragon_id:
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
