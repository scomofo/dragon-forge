extends GutTest

const HatcheryEngine = preload("res://scripts/sim/hatchery_engine.gd")
const GameData       = preload("res://scripts/sim/game_data.gd")

func test_roll_rarity_returns_valid_object() -> void:
	var result := HatcheryEngine.roll_rarity(0)
	assert_true(result.has("name"),       "missing name")
	assert_true(result.has("elements"),   "missing elements")
	assert_true(result.has("multiplier"), "missing multiplier")

func test_roll_rarity_forces_rare_plus_at_pity() -> void:
	var rare_or_exotic_count := 0
	for _i in range(50):
		var result := HatcheryEngine.roll_rarity(9)
		if result["name"] == "Rare" or result["name"] == "Exotic":
			rare_or_exotic_count += 1
	assert_eq(rare_or_exotic_count, 50, "pity=9 must always yield Rare+")

func test_roll_rarity_valid_name_at_normal_pity() -> void:
	var valid_names := ["Common", "Uncommon", "Rare", "Exotic"]
	for _i in range(20):
		assert_true(valid_names.has(HatcheryEngine.roll_rarity(0)["name"]))

func test_roll_element_from_uncommon_tier() -> void:
	var tier := { "name": "Uncommon", "elements": ["storm", "venom", "stone"], "multiplier": 2 }
	for _i in range(20):
		assert_true(["storm", "venom", "stone"].has(HatcheryEngine.roll_element(tier)))

func test_roll_element_single_element_tier() -> void:
	var tier := { "name": "Rare", "elements": ["shadow"], "multiplier": 3 }
	assert_eq(HatcheryEngine.roll_element(tier), "shadow")

func test_roll_shiny_returns_bool() -> void:
	var result := HatcheryEngine.roll_shiny(false)
	assert_true(result == true or result == false)

func test_roll_shiny_guaranteed_always_true() -> void:
	for _i in range(20):
		assert_true(HatcheryEngine.roll_shiny(true))

func test_execute_pull_result_shape() -> void:
	var result := HatcheryEngine.execute_pull(0)
	assert_true(result.has("element"),           "missing element")
	assert_true(result.has("rarity_name"),       "missing rarity_name")
	assert_true(result.has("rarity_multiplier"), "missing rarity_multiplier")
	assert_true(result.has("shiny"),             "missing shiny")
	assert_true(result.has("new_pity_counter"),  "missing new_pity_counter")

func test_execute_pull_resets_pity_on_rare_plus() -> void:
	var result := HatcheryEngine.execute_pull(9)
	assert_eq(result.new_pity_counter, 0)

func test_execute_pull_increments_pity_on_common_or_uncommon() -> void:
	var found_non_rare := false
	for _i in range(100):
		var result := HatcheryEngine.execute_pull(0)
		if result.rarity_name == "Common" or result.rarity_name == "Uncommon":
			assert_eq(result.new_pity_counter, 1)
			found_non_rare = true
			break
	assert_true(found_non_rare, "never got a Common/Uncommon in 100 pulls")

func _base_save_with_fire_unowned() -> Dictionary:
	return {
		"dragons":      { "fire": { "level": 1, "xp": 0, "owned": false, "shiny": false } },
		"data_scraps":  100,
		"pity_counter": 0,
	}

func _base_save_with_fire_owned() -> Dictionary:
	return {
		"dragons":      { "fire": { "level": 1, "xp": 0, "owned": true, "shiny": false } },
		"data_scraps":  100,
		"pity_counter": 0,
	}

func test_apply_pull_unlocks_new_dragon() -> void:
	var save := _base_save_with_fire_unowned()
	var pull := { "element": "fire", "rarity_name": "Common", "rarity_multiplier": 1, "shiny": false, "new_pity_counter": 1 }
	var result := HatcheryEngine.apply_pull_result(save, pull)
	assert_true(result.save.dragons.fire.owned)
	assert_true(result.is_new)
	assert_eq(result.xp_gained, 0)

func test_apply_pull_merges_duplicate_with_xp() -> void:
	var save := _base_save_with_fire_owned()
	var pull := { "element": "fire", "rarity_name": "Uncommon", "rarity_multiplier": 2, "shiny": false, "new_pity_counter": 1 }
	var result := HatcheryEngine.apply_pull_result(save, pull)
	assert_false(result.is_new)
	assert_eq(result.xp_gained, 100)
	assert_eq(result.save.dragons.fire.xp, 0)
	assert_eq(result.save.dragons.fire.level, 2)

func test_apply_pull_upgrades_to_shiny_on_duplicate() -> void:
	var save := {
		"dragons":      { "shadow": { "level": 5, "xp": 20, "owned": true, "shiny": false } },
		"data_scraps":  100,
		"pity_counter": 0,
	}
	var pull := { "element": "shadow", "rarity_name": "Rare", "rarity_multiplier": 3, "shiny": true, "new_pity_counter": 0 }
	var result := HatcheryEngine.apply_pull_result(save, pull)
	assert_true(result.save.dragons.shadow.shiny)

func test_apply_pull_updates_pity_counter() -> void:
	var save := _base_save_with_fire_unowned()
	save.pity_counter = 3
	var pull := { "element": "fire", "rarity_name": "Common", "rarity_multiplier": 1, "shiny": false, "new_pity_counter": 4 }
	var result := HatcheryEngine.apply_pull_result(save, pull)
	assert_eq(result.save.pity_counter, 4)

func test_apply_pull_levels_up_on_excess_xp() -> void:
	var save := {
		"dragons":      { "fire": { "level": 1, "xp": 80, "owned": true, "shiny": false } },
		"data_scraps":  100,
		"pity_counter": 0,
	}
	var pull := { "element": "fire", "rarity_name": "Exotic", "rarity_multiplier": 5, "shiny": false, "new_pity_counter": 0 }
	var result := HatcheryEngine.apply_pull_result(save, pull)
	assert_eq(result.save.dragons.fire.level, 4)
	assert_eq(result.save.dragons.fire.xp, 30)
	assert_eq(result.xp_gained, 250)
