extends GutTest

const DRAGON_RECORD_PATH: String = "res://src/dragon/dragon_record.gd"
const DRAGON_STATS_PATH: String = "res://src/dragon/dragon_stats.gd"
const DRAGON_PROGRESSION_SERVICE_PATH: String = "res://src/dragon/dragon_progression_service.gd"


func test_canonical_level_one_stats_for_core_elements_and_void() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var expected_by_element: Dictionary[StringName, Array] = {
		&"Fire": [110, 28, 16, 22],
		&"Ice": [100, 24, 17, 14],
		&"Storm": [90, 30, 13, 32],
		&"Stone": [120, 22, 24, 8],
		&"Venom": [95, 26, 19, 12],
		&"Shadow": [85, 32, 11, 28],
		&"Void": [80, 40, 20, 36],
	}

	for element in expected_by_element:
		var stats: RefCounted = service.calculate_stats(_make_dragon(element, 1, false))
		_assert_stats_equal(stats, expected_by_element[element], "%s level 1" % element)


func test_representative_level_and_shiny_formula_outputs_match_gdd() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	assert_eq(service.calculate_stats(_make_dragon(&"Shadow", 30, false)).atk, 119)
	assert_eq(service.calculate_stats(_make_dragon(&"Fire", 30, false)).hp, 197)
	assert_eq(service.calculate_stats(_make_dragon(&"Stone", 60, false)).atk, 199)
	var shadow_max: RefCounted = service.calculate_stats(_make_dragon(&"Shadow", 60, false))
	assert_eq(shadow_max.atk, 209)
	assert_eq(shadow_max.hp, 262)
	assert_eq(shadow_max.def, 188)
	assert_eq(service.calculate_stats(_make_dragon(&"Stone", 60, false)).hp, 297)
	assert_eq(service.calculate_stats(_make_dragon(&"Shadow", 1, true)).atk, 38)
	assert_eq(service.calculate_stats(_make_dragon(&"Stone", 1, true)).atk, 26)
	assert_eq(service.calculate_stats(_make_dragon(&"Shadow", 60, true)).atk, 250)
	assert_eq(service.calculate_stats(_make_dragon(&"Stone", 60, true)).hp, 356)
	assert_eq(service.calculate_stats(_make_dragon(&"Shadow", 60, true)).def, 225)


func test_shiny_stats_are_greater_floor_once_and_stats_are_monotonic() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var core_elements: Array[StringName] = [&"Fire", &"Ice", &"Storm", &"Stone", &"Venom", &"Shadow"]
	for element in core_elements:
		for level in [1, 30, 60]:
			var standard: RefCounted = service.calculate_stats(_make_dragon(element, level, false))
			var shiny: RefCounted = service.calculate_stats(_make_dragon(element, level, true))
			assert_gt(shiny.hp, standard.hp, "%s level %d shiny HP should be higher." % [element, level])
			assert_gt(shiny.atk, standard.atk, "%s level %d shiny ATK should be higher." % [element, level])
			assert_gt(shiny.def, standard.def, "%s level %d shiny DEF should be higher." % [element, level])
			assert_gt(shiny.spd, standard.spd, "%s level %d shiny SPD should be higher." % [element, level])
		for shiny_state in [false, true]:
			var previous: RefCounted = service.calculate_stats(_make_dragon(element, 1, shiny_state))
			for level in range(2, 61):
				var current: RefCounted = service.calculate_stats(_make_dragon(element, level, shiny_state))
				assert_gte(current.hp, previous.hp)
				assert_gte(current.atk, previous.atk)
				assert_gte(current.def, previous.def)
				assert_gte(current.spd, previous.spd)
				previous = current

	assert_eq(service.calculate_stats(_make_dragon(&"Stone", 1, true)).atk, 26, "Shiny Stone ATK level 1 verifies floor after the full expression.")


func test_stage_boundaries_and_standard_stage_multipliers_are_derived_from_level() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	assert_eq(service.stage_for_level(1), 1)
	assert_eq(service.stage_for_level(9), 1)
	assert_eq(service.stage_for_level(10), 2)
	assert_eq(service.stage_for_level(24), 2)
	assert_eq(service.stage_for_level(25), 3)
	assert_eq(service.stage_for_level(49), 3)
	assert_eq(service.stage_for_level(50), 4)
	assert_eq(service.stage_for_level(60), 4)
	assert_almost_eq(service.stage_multiplier_for_level(1), 0.5, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(10), 0.75, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(25), 1.0, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(50), 1.4, 0.001)


func test_spd_is_computed_internally_for_core_elements() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	for element in [&"Fire", &"Ice", &"Storm", &"Stone", &"Venom", &"Shadow"]:
		for level in [1, 30, 60]:
			var stats: RefCounted = service.calculate_stats(_make_dragon(element, level, false))
			assert_gt(stats.spd, 0, "%s level %d SPD should be positive." % [element, level])


func test_defensive_formula_calls_return_safe_stats_without_crashing() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	_assert_stats_equal(service.calculate_stats(_make_dragon(&"Fire", 0, false)), [110, 28, 16, 22], "level 0 clamps down to level 1 base stats")
	_assert_stats_equal(service.calculate_stats(_make_dragon(&"Fire", -5, false)), [110, 28, 16, 22], "negative level clamps down to level 1 base stats")
	assert_eq(service.calculate_stats(_make_dragon(&"Fire", 61, false)).hp, 287)
	_assert_stats_equal(service.calculate_stats(_make_dragon(&"Wind", 1, false)), [0, 0, 0, 0], "unknown element returns zero stats")
	_assert_stats_equal(service.calculate_stats(_make_dragon(&"Void", 1, true)), [80, 40, 20, 36], "Void shiny input is corrected to standard Void stats")
	assert_false(service.calculate_stats(_make_dragon(&"Void", 1, true)).shiny, "Void stats snapshot should report non-shiny.")
	assert_eq(service.calculate_stats_for_values(&"Fire", 1, 1.5).hp, 110)
	assert_push_error("level 0 below 1")
	assert_push_error("level -5 below 1")
	assert_push_error("level 61 above 60")
	assert_push_error("unknown element 'Wind'")
	assert_push_error("invalid shiny multiplier 1.5")


func test_dragon_record_does_not_persist_derived_stage() -> void:
	var dragon: Resource = _make_dragon(&"Fire", 10, false)
	assert_false(_property_names(dragon).has("stage"), "DragonRecord must not persist derived stage.")


func _make_service() -> RefCounted:
	assert_true(ResourceLoader.exists(DRAGON_PROGRESSION_SERVICE_PATH), "DragonProgressionService script should exist.")
	assert_true(ResourceLoader.exists(DRAGON_STATS_PATH), "DragonStats snapshot script should exist.")
	if not ResourceLoader.exists(DRAGON_PROGRESSION_SERVICE_PATH) or not ResourceLoader.exists(DRAGON_STATS_PATH):
		return null
	var script: GDScript = load(DRAGON_PROGRESSION_SERVICE_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func _make_dragon(element: StringName, level: int, shiny: bool) -> Resource:
	assert_true(ResourceLoader.exists(DRAGON_RECORD_PATH), "DragonRecord script should exist.")
	var script: GDScript = load(DRAGON_RECORD_PATH)
	assert_not_null(script)
	var dragon: Resource = script.new()
	dragon.dragon_id = StringName("%s_test" % String(element).to_lower())
	dragon.element = element
	dragon.level = level
	dragon.shiny = shiny
	return dragon


func _assert_stats_equal(stats: RefCounted, expected: Array, context: String) -> void:
	assert_not_null(stats, "%s should return a DragonStats snapshot." % context)
	if stats == null:
		return
	assert_eq(stats.hp, expected[0], "%s HP" % context)
	assert_eq(stats.atk, expected[1], "%s ATK" % context)
	assert_eq(stats.def, expected[2], "%s DEF" % context)
	assert_eq(stats.spd, expected[3], "%s SPD" % context)


func _property_names(object: Object) -> Array[String]:
	var names: Array[String] = []
	for property in object.get_property_list():
		names.append(str(property.name))
	return names
