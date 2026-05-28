extends GutTest

const DragonProgressionServiceScript = preload("res://src/dragon/dragon_progression_service.gd")
const DragonRecordScript = preload("res://src/dragon/dragon_record.gd")
const EconomyLedgerScript = preload("res://src/economy/economy_ledger.gd")
const HatcheryServiceScript = preload("res://src/hatchery/hatchery_service.gd")
const HatcheryPullTableScript = preload("res://src/hatchery/hatchery_pull_table.gd")
const HatcheryRngProviderScript = preload("res://src/hatchery/hatchery_rng_provider.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const TEST_SAVE_PATH: String = "user://gut_hatchery_dragon_unlock_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_hatchery_dragon_unlock_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_hatchery_dragon_unlock_slot.bak.tres"
const STANDARD_ELEMENTS: Array[StringName] = [&"Fire", &"Ice", &"Storm", &"Venom", &"Stone", &"Shadow"]


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_unowned_pulls_create_core_dragons_with_shiny_state_from_roll() -> void:
	var non_shiny_services: Dictionary = _make_initialized_services(50, [])
	var non_shiny_hatchery: RefCounted = _make_hatchery_service(non_shiny_services.save, non_shiny_services.ledger, non_shiny_services.dragon)
	var non_shiny_result: HatcheryPullResult = non_shiny_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.99]))
	var non_shiny_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(non_shiny_result.success, non_shiny_result.error_message)
	assert_false(non_shiny_result.duplicate)
	assert_eq(non_shiny_result.xp_awarded, 0)
	assert_eq(non_shiny_save.dragons.size(), 1)
	var fire: DragonRecord = _dragon_by_element(non_shiny_save, &"Fire")
	assert_not_null(fire)
	assert_eq(fire.level, 1)
	assert_eq(fire.xp, 0)
	assert_false(fire.shiny)
	assert_eq(fire.battle_charges, 0)
	assert_false(fire.is_elder)
	assert_gt(fire.base_hp, 0)
	assert_null(_dragon_by_element(non_shiny_save, &"Void"))

	_remove_save_files()
	var shiny_services: Dictionary = _make_initialized_services(50, [])
	var shiny_hatchery: RefCounted = _make_hatchery_service(shiny_services.save, shiny_services.ledger, shiny_services.dragon)
	var shiny_result: HatcheryPullResult = shiny_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.0]))
	var shiny_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(shiny_result.success, shiny_result.error_message)
	assert_false(shiny_result.duplicate)
	var shiny_fire: DragonRecord = _dragon_by_element(shiny_save, &"Fire")
	assert_not_null(shiny_fire)
	assert_true(shiny_fire.shiny)


func test_duplicate_xp_amounts_follow_rarity_multipliers() -> void:
	_assert_duplicate_awards_xp(&"Fire", [0.10, 0.10, 0.99], 50)
	_assert_duplicate_awards_xp(&"Stone", [0.70, 0.85, 0.99], 100)
	_assert_duplicate_awards_xp(&"Shadow", [0.95, 0.99], 150)


func test_duplicate_xp_uses_dragon_progression_loop_and_max_level_cleanup() -> void:
	var level_services: Dictionary = _make_initialized_services(50, [_make_dragon(&"fire_existing", &"Fire", 5, 30, false)])
	var level_hatchery: RefCounted = _make_hatchery_service(level_services.save, level_services.ledger, level_services.dragon)
	var level_result: HatcheryPullResult = level_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.99]))
	var level_save: SaveData = _load_save(TEST_SAVE_PATH)
	var leveled_fire: DragonRecord = _dragon_by_element(level_save, &"Fire")

	assert_true(level_result.success, level_result.error_message)
	assert_true(level_result.duplicate)
	assert_eq(level_result.xp_awarded, 50)
	assert_eq(leveled_fire.level, 6)
	assert_eq(leveled_fire.xp, 30)

	_remove_save_files()
	var max_services: Dictionary = _make_initialized_services(50, [_make_dragon(&"fire_existing", &"Fire", 60, 0, false)])
	var max_hatchery: RefCounted = _make_hatchery_service(max_services.save, max_services.ledger, max_services.dragon)
	var max_result: HatcheryPullResult = max_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.99]))
	var max_save: SaveData = _load_save(TEST_SAVE_PATH)
	var max_fire: DragonRecord = _dragon_by_element(max_save, &"Fire")

	assert_true(max_result.success, max_result.error_message)
	assert_true(max_result.duplicate)
	assert_eq(max_result.xp_awarded, 50)
	assert_eq(max_fire.level, 60)
	assert_eq(max_fire.xp, 0)


func test_duplicate_shiny_upgrade_and_non_shiny_duplicate_no_downgrade() -> void:
	var upgrade_services: Dictionary = _make_initialized_services(50, [_make_dragon(&"fire_existing", &"Fire", 25, 0, false)])
	var upgrade_hatchery: RefCounted = _make_hatchery_service(upgrade_services.save, upgrade_services.ledger, upgrade_services.dragon)
	var upgrade_result: HatcheryPullResult = upgrade_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.0]))
	var upgrade_save: SaveData = _load_save(TEST_SAVE_PATH)
	var upgraded_fire: DragonRecord = _dragon_by_element(upgrade_save, &"Fire")

	assert_true(upgrade_result.success, upgrade_result.error_message)
	assert_true(upgrade_result.duplicate)
	assert_true(upgrade_result.shiny_upgraded)
	assert_eq(upgraded_fire.level, 25)
	assert_eq(upgraded_fire.xp, 50)
	assert_true(upgraded_fire.shiny)

	_remove_save_files()
	var no_downgrade_services: Dictionary = _make_initialized_services(50, [_make_dragon(&"ice_existing", &"Ice", 25, 0, true)])
	var no_downgrade_hatchery: RefCounted = _make_hatchery_service(no_downgrade_services.save, no_downgrade_services.ledger, no_downgrade_services.dragon)
	var no_downgrade_result: HatcheryPullResult = no_downgrade_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.30, 0.99]))
	var no_downgrade_save: SaveData = _load_save(TEST_SAVE_PATH)
	var ice: DragonRecord = _dragon_by_element(no_downgrade_save, &"Ice")

	assert_true(no_downgrade_result.success, no_downgrade_result.error_message)
	assert_true(no_downgrade_result.duplicate)
	assert_false(no_downgrade_result.shiny_upgraded)
	assert_eq(ice.level, 25)
	assert_eq(ice.xp, 50)
	assert_true(ice.shiny)


func test_max_level_shiny_duplicate_upgrades_shiny_without_retaining_xp() -> void:
	var services: Dictionary = _make_initialized_services(50, [_make_dragon(&"fire_existing", &"Fire", 60, 0, false)])
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger, services.dragon)

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.0]))
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)
	var fire: DragonRecord = _dragon_by_element(committed_save, &"Fire")

	assert_true(result.success, result.error_message)
	assert_true(result.duplicate)
	assert_true(result.shiny_upgraded)
	assert_eq(result.xp_awarded, 50)
	assert_eq(fire.level, 60)
	assert_eq(fire.xp, 0)
	assert_true(fire.shiny)


func test_all_owned_standard_dragons_route_every_standard_outcome_to_duplicate_xp() -> void:
	var roll_by_element: Dictionary[StringName, Array] = {
		&"Fire": [0.10, 0.10, 0.99],
		&"Ice": [0.10, 0.30, 0.99],
		&"Storm": [0.70, 0.55, 0.99],
		&"Venom": [0.70, 0.70, 0.99],
		&"Stone": [0.70, 0.85, 0.99],
		&"Shadow": [0.95, 0.99],
	}

	for element_id in STANDARD_ELEMENTS:
		_remove_save_files()
		var services: Dictionary = _make_initialized_services(50, _make_all_standard_dragons())
		var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger, services.dragon)
		var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng(roll_by_element[element_id]))
		var committed_save: SaveData = _load_save(TEST_SAVE_PATH)

		assert_true(result.success, result.error_message)
		assert_eq(result.element_id, element_id)
		assert_true(result.duplicate, "%s should route to duplicate XP." % element_id)
		assert_gt(result.xp_awarded, 0)
		assert_eq(committed_save.dragons.size(), STANDARD_ELEMENTS.size())


func test_save_failure_rolls_back_duplicate_xp_and_shiny_upgrade_together() -> void:
	var services: Dictionary = _make_initialized_services(50, [_make_dragon(&"fire_existing", &"Fire", 25, 0, false)])
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger, services.dragon)
	services.save.set_failure_injection(SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP, true)

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng([0.10, 0.10, 0.0]))
	var canonical_after_failure: SaveData = _load_save(TEST_SAVE_PATH)
	var fire: DragonRecord = _dragon_by_element(canonical_after_failure, &"Fire")

	assert_false(result.success)
	assert_eq(result.reason, &"save_commit_failed")
	assert_eq(canonical_after_failure.player_scraps, 50)
	assert_eq(fire.level, 25)
	assert_eq(fire.xp, 0)
	assert_false(fire.shiny)


func _assert_duplicate_awards_xp(element_id: StringName, rolls: Array, expected_xp: int) -> void:
	_remove_save_files()
	var services: Dictionary = _make_initialized_services(50, [_make_dragon(StringName("%s_existing" % String(element_id).to_lower()), element_id, 50, 0, false)])
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger, services.dragon)

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", _make_rng(rolls))
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)
	var dragon: DragonRecord = _dragon_by_element(committed_save, element_id)

	assert_true(result.success, result.error_message)
	assert_true(result.duplicate)
	assert_eq(result.element_id, element_id)
	assert_eq(result.xp_awarded, expected_xp)
	assert_eq(dragon.xp, expected_xp)


func _make_initialized_services(scraps: int, dragons: Array) -> Dictionary:
	var save_service: SaveService = SaveServiceScript.new()
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(_make_save_data(scraps, dragons))
	assert_true(initialize_result.success, initialize_result.error_message)
	return {
		"save": save_service,
		"ledger": EconomyLedgerScript.new(),
		"dragon": DragonProgressionServiceScript.new(),
	}


func _make_save_data(scraps: int, dragons: Array) -> SaveData:
	var save_data: SaveData = SaveDataScript.new()
	save_data.player_scraps = scraps
	save_data.hatchery_pity_counter = 0
	for element_id in STANDARD_ELEMENTS:
		save_data.element_drought_counters[element_id] = 0
	for dragon: DragonRecord in dragons:
		save_data.dragons.append(dragon)
	return save_data


func _make_hatchery_service(
		save_service: SaveService,
		ledger: EconomyLedger,
		dragon_service: DragonProgressionService
) -> RefCounted:
	var service: RefCounted = HatcheryServiceScript.new()
	var table: HatcheryPullTable = HatcheryPullTableScript.new()
	table.configure_mvp_standard_table()
	service.configure(save_service, ledger, dragon_service, table)
	return service


func _make_rng(rolls: Array) -> HatcheryRngProvider:
	var rng: HatcheryRngProvider = HatcheryRngProviderScript.new()
	rng.configure_scripted_rolls(rolls)
	return rng


func _make_all_standard_dragons() -> Array[DragonRecord]:
	var dragons: Array[DragonRecord] = []
	for element_id in STANDARD_ELEMENTS:
		dragons.append(_make_dragon(StringName("%s_existing" % String(element_id).to_lower()), element_id, 25, 0, false))
	return dragons


func _make_dragon(dragon_id: StringName, element: StringName, level: int, xp: int, shiny: bool) -> DragonRecord:
	var dragon: DragonRecord = DragonRecordScript.new()
	dragon.dragon_id = dragon_id
	dragon.element = element
	dragon.level = level
	dragon.xp = xp
	dragon.shiny = shiny
	dragon.base_hp = 100
	dragon.base_atk = 20
	dragon.base_def = 15
	dragon.base_spd = 10
	return dragon


func _dragon_by_element(save_data: SaveData, element: StringName) -> DragonRecord:
	if save_data == null:
		return null
	for dragon: DragonRecord in save_data.dragons:
		if dragon.element == element:
			return dragon
	return null


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
