extends GutTest

const EconomyLedgerScript = preload("res://src/economy/economy_ledger.gd")
const DragonProgressionServiceScript = preload("res://src/dragon/dragon_progression_service.gd")
const HatcheryServiceScript = preload("res://src/hatchery/hatchery_service.gd")
const HatcheryPullTableScript = preload("res://src/hatchery/hatchery_pull_table.gd")
const HatcheryRngProviderScript = preload("res://src/hatchery/hatchery_rng_provider.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const HATCHERY_SERVICE_PATH: String = "res://src/hatchery/hatchery_service.gd"
const TEST_SAVE_PATH: String = "user://gut_hatchery_pull_transaction_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_hatchery_pull_transaction_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_hatchery_pull_transaction_slot.bak.tres"
const STANDARD_ELEMENTS: Array[StringName] = [&"Fire", &"Ice", &"Storm", &"Venom", &"Stone", &"Shadow"]


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_successful_pull_spends_exact_cost_returns_resolution_and_persists_counters_and_outcome() -> void:
	var services: Dictionary = _make_initialized_services(50, 6, _make_droughts({&"Fire": 7, &"Stone": 19}))
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger)
	var rng: HatcheryRngProvider = _make_rng([0.10, 0.10, 0.99])
	if hatchery == null or rng == null:
		return

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", rng)
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(result.success, result.error_message)
	assert_eq(result.reason, &"ok")
	assert_eq(result.pull_id, &"standard_hatchery")
	assert_eq(result.source_id, &"hatchery_pull")
	assert_eq(result.cost, 50)
	assert_eq(result.balance_before, 50)
	assert_eq(result.balance_after, 0)
	assert_not_null(result.resolution_result)
	assert_eq(result.element_id, &"Fire")
	assert_eq(result.rarity_id, &"Common")
	assert_false(result.shiny)
	assert_eq(result.next_pity_counter, 7)
	assert_eq(result.next_drought_counters.get(&"Fire", -1), 0)
	assert_eq(result.next_drought_counters.get(&"Stone", -1), 20)
	assert_not_null(committed_save)
	assert_eq(committed_save.player_scraps, 0)
	assert_eq(committed_save.hatchery_pity_counter, 7)
	_assert_all_droughts_match(committed_save.element_drought_counters, result.next_drought_counters)
	assert_eq(committed_save.dragons.size(), 1)
	assert_eq(committed_save.dragons[0].element, &"Fire")
	assert_eq(result.save_commit_result.post_commit_events.size(), 0)


func test_successful_pull_preserves_exact_remainder_for_low_and_high_balances() -> void:
	var low_services: Dictionary = _make_initialized_services(51, 0, _make_droughts())
	var low_hatchery: RefCounted = _make_hatchery_service(low_services.save, low_services.ledger)
	var low_rng: HatcheryRngProvider = _make_rng([0.70, 0.10, 0.99])
	if low_hatchery == null or low_rng == null:
		return

	var low_result: HatcheryPullResult = low_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", low_rng)
	var low_committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(low_result.success, low_result.error_message)
	assert_eq(low_result.balance_before, 51)
	assert_eq(low_result.balance_after, 1)
	assert_eq(low_committed_save.player_scraps, 1)

	var high_services: Dictionary = _make_initialized_services(999, 0, _make_droughts())
	var high_hatchery: RefCounted = _make_hatchery_service(high_services.save, high_services.ledger)
	var high_rng: HatcheryRngProvider = _make_rng([0.70, 0.10, 0.99])
	if high_hatchery == null or high_rng == null:
		return

	var high_result: HatcheryPullResult = high_hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", high_rng)
	var high_committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(high_result.success, high_result.error_message)
	assert_eq(high_result.balance_before, 999)
	assert_eq(high_result.balance_after, 949)
	assert_eq(high_committed_save.player_scraps, 949)


func test_rare_pull_resets_and_persists_pity_counter_to_zero() -> void:
	var services: Dictionary = _make_initialized_services(50, 8, _make_droughts())
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger)
	var rng: HatcheryRngProvider = _make_rng([0.95, 0.99])
	if hatchery == null or rng == null:
		return

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", rng)
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(result.success, result.error_message)
	assert_eq(result.rarity_id, &"Rare")
	assert_eq(result.element_id, &"Shadow")
	assert_false(result.pity_forced)
	assert_eq(result.next_pity_counter, 0)
	assert_eq(committed_save.hatchery_pity_counter, 0)


func test_insufficient_scraps_returns_named_failure_without_mutation_or_rng_consumption() -> void:
	var starting_droughts: Dictionary[StringName, int] = _make_droughts({&"Ice": 5})
	var services: Dictionary = _make_initialized_services(49, 4, starting_droughts)
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger)
	var rng: HatcheryRngProvider = _make_rng([0.10, 0.10, 0.99])
	if hatchery == null or rng == null:
		return

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", rng)
	var unchanged_save: SaveData = _load_save(TEST_SAVE_PATH)
	var next_roll_after_failure: int = rng.next_basis_point()

	assert_false(result.success)
	assert_eq(result.reason, &"insufficient_scraps")
	assert_eq(result.balance_before, 49)
	assert_eq(result.balance_after, 49)
	assert_null(result.resolution_result)
	assert_eq(result.element_id, &"")
	assert_eq(result.rarity_id, &"")
	assert_eq(next_roll_after_failure, 1000, "Insufficient pulls must not consume the first scripted RNG roll.")
	assert_eq(unchanged_save.player_scraps, 49)
	assert_eq(unchanged_save.hatchery_pity_counter, 4)
	_assert_all_droughts_match(unchanged_save.element_drought_counters, starting_droughts)


func test_zero_scraps_returns_named_failure_without_mutation_or_rng_consumption() -> void:
	var starting_droughts: Dictionary[StringName, int] = _make_droughts({&"Shadow": 3})
	var services: Dictionary = _make_initialized_services(0, 2, starting_droughts)
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger)
	var rng: HatcheryRngProvider = _make_rng([0.10, 0.10, 0.99])
	if hatchery == null or rng == null:
		return

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", rng)
	var unchanged_save: SaveData = _load_save(TEST_SAVE_PATH)
	var next_roll_after_failure: int = rng.next_basis_point()

	assert_false(result.success)
	assert_eq(result.reason, &"insufficient_scraps")
	assert_eq(result.balance_before, 0)
	assert_eq(result.balance_after, 0)
	assert_null(result.resolution_result)
	assert_eq(next_roll_after_failure, 1000, "Zero-Scrap pulls must not consume the first scripted RNG roll.")
	assert_eq(unchanged_save.player_scraps, 0)
	assert_eq(unchanged_save.hatchery_pity_counter, 2)
	_assert_all_droughts_match(unchanged_save.element_drought_counters, starting_droughts)


func test_save_failure_rolls_back_spend_pity_and_drought_counters_without_committed_outcome() -> void:
	var starting_droughts: Dictionary[StringName, int] = _make_droughts({&"Fire": 7, &"Stone": 19})
	var services: Dictionary = _make_initialized_services(50, 6, starting_droughts)
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger)
	var rng: HatcheryRngProvider = _make_rng([0.10, 0.10, 0.99])
	if hatchery == null or rng == null:
		return
	services.save.set_failure_injection(SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP, true)

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", rng)
	var canonical_after_failure: SaveData = _load_save(TEST_SAVE_PATH)

	assert_false(result.success)
	assert_eq(result.reason, &"save_commit_failed")
	assert_eq(result.balance_before, 50)
	assert_eq(result.balance_after, 50)
	assert_null(result.economy_result)
	assert_null(result.resolution_result)
	assert_eq(result.element_id, &"")
	assert_eq(result.rarity_id, &"")
	assert_not_null(result.save_commit_result)
	assert_eq(result.save_commit_result.failure_point, SaveService.FAILURE_AFTER_TEMP_WRITE_BEFORE_SWAP)
	assert_eq(canonical_after_failure.player_scraps, 50)
	assert_eq(canonical_after_failure.hatchery_pity_counter, 6)
	_assert_all_droughts_match(canonical_after_failure.element_drought_counters, starting_droughts)
	assert_true(FileAccess.file_exists(TEST_TEMP_PATH), "Injected save failure should leave temp artifact for rollback evidence.")


func test_missing_drought_counters_are_repaired_to_complete_atomic_counter_set() -> void:
	var partial_droughts: Dictionary[StringName, int] = {
		&"Fire": 7,
		&"Stone": 19,
	}
	var services: Dictionary = _make_initialized_services(50, 0, partial_droughts)
	var hatchery: RefCounted = _make_hatchery_service(services.save, services.ledger)
	var rng: HatcheryRngProvider = _make_rng([0.10, 0.10, 0.99])
	if hatchery == null or rng == null:
		return

	var result: HatcheryPullResult = hatchery.execute_pull(&"standard_hatchery", &"hatchery_pull", rng)
	var committed_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(result.success, result.error_message)
	assert_eq(committed_save.element_drought_counters.size(), STANDARD_ELEMENTS.size())
	_assert_all_droughts_match(committed_save.element_drought_counters, result.next_drought_counters)


func test_hatchery_service_source_does_not_bypass_economy_ledger_or_use_global_random() -> void:
	assert_true(ResourceLoader.exists(HATCHERY_SERVICE_PATH), "HatcheryService should exist.")
	if not ResourceLoader.exists(HATCHERY_SERVICE_PATH):
		return

	var source: String = FileAccess.get_file_as_string(HATCHERY_SERVICE_PATH)

	assert_true(source.contains("spend_scraps("), "HatcheryService should spend through EconomyLedger.")
	assert_false(source.contains("player_scraps ="), "HatcheryService must not mutate player_scraps directly.")
	assert_false(_source_uses_global_random(HATCHERY_SERVICE_PATH))


func _make_initialized_services(scraps: int, pity_counter: int, drought_counters: Dictionary[StringName, int]) -> Dictionary:
	var save_service: SaveService = SaveServiceScript.new()
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(_make_save_data(scraps, pity_counter, drought_counters))
	assert_true(initialize_result.success, initialize_result.error_message)
	return {
		"save": save_service,
		"ledger": EconomyLedgerScript.new(),
		"dragon": DragonProgressionServiceScript.new(),
	}


func _make_save_data(scraps: int, pity_counter: int, drought_counters: Dictionary[StringName, int]) -> SaveData:
	var save_data: SaveData = SaveDataScript.new()
	save_data.player_scraps = scraps
	save_data.hatchery_pity_counter = pity_counter
	for key in drought_counters.keys():
		save_data.element_drought_counters[StringName(key)] = int(drought_counters[key])
	return save_data


func _make_hatchery_service(save_service: SaveService, ledger: EconomyLedger) -> RefCounted:
	assert_true(ResourceLoader.exists(HATCHERY_SERVICE_PATH), "HatcheryService should exist.")
	if not ResourceLoader.exists(HATCHERY_SERVICE_PATH):
		return null
	var service: RefCounted = HatcheryServiceScript.new()
	assert_eq(service.get_script().resource_path, HATCHERY_SERVICE_PATH)
	var table: HatcheryPullTable = HatcheryPullTableScript.new()
	table.configure_mvp_standard_table()
	service.configure(save_service, ledger, DragonProgressionServiceScript.new(), table)
	return service


func _make_rng(rolls: Array[float]) -> HatcheryRngProvider:
	var rng: HatcheryRngProvider = HatcheryRngProviderScript.new()
	rng.configure_scripted_rolls(rolls)
	return rng


func _make_droughts(overrides: Dictionary = {}) -> Dictionary[StringName, int]:
	var droughts: Dictionary[StringName, int] = {}
	for element_id in STANDARD_ELEMENTS:
		droughts[element_id] = int(overrides.get(element_id, 0))
	return droughts


func _load_save(path: String) -> SaveData:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is SaveData:
		return loaded
	return null


func _assert_all_droughts_match(actual: Dictionary, expected: Dictionary) -> void:
	for element_id in STANDARD_ELEMENTS:
		assert_true(actual.has(element_id), "%s counter should exist." % element_id)
		assert_eq(actual.get(element_id, -1), expected.get(element_id, -1), "%s counter should match." % element_id)


func _source_uses_global_random(path: String) -> bool:
	var source: String = FileAccess.get_file_as_string(path)
	for line in source.split("\n"):
		var stripped: String = line.strip_edges()
		if stripped.begins_with("randf(") or stripped.begins_with("randi("):
			return true
		if stripped.contains(" randf(") or stripped.contains(" randi("):
			return true
	return false


func _remove_save_files() -> void:
	for path in [TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
