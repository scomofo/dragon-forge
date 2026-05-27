extends GutTest

const BATTLE_FORMULA_SERVICE_PATH: String = "res://src/battle/formulas/battle_formula_service.gd"


func test_damage_formula_order_base_damage_and_negative_floor() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var base_result: RefCounted = service.calculate_damage(70, 44, 1.0, 2.0, false, 0.90, 1.0)
	var floor_result: RefCounted = service.calculate_damage(10, 100, 0.5, 0.5, false, 1.0, 1.0)

	assert_true(base_result.hit)
	assert_false(base_result.crit)
	assert_eq(base_result.damage, 149)
	assert_eq(floor_result.damage, 1)


func test_crit_defend_order_rate_and_constants() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var defended_crit: RefCounted = service.calculate_damage(70, 44, 1.0, 2.0, true, 0.90, 0.0)
	assert_true(defended_crit.crit)
	assert_eq(defended_crit.damage, 111)
	assert_almost_eq(service.CRIT_CHANCE, 0.10, 0.001)
	assert_almost_eq(service.CRIT_MULTIPLIER, 1.5, 0.001)
	assert_almost_eq(service.DEFEND_MULTIPLIER, 0.5, 0.001)

	var crits: int = 0
	for index in range(10000):
		if service.is_crit(float(index) / 10000.0):
			crits += 1
	assert_between(crits, 800, 1200, "Deterministic crit harness should land at 10% +/- 2%.")


func test_full_type_matrix_including_void_and_shadow_mirror() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var expected: Dictionary[StringName, Dictionary] = {
		&"Fire": {&"Fire": 0.5, &"Ice": 2.0, &"Storm": 1.0, &"Stone": 0.5, &"Venom": 2.0, &"Shadow": 1.0, &"Void": 1.0},
		&"Ice": {&"Fire": 0.5, &"Ice": 0.5, &"Storm": 2.0, &"Stone": 1.0, &"Venom": 1.0, &"Shadow": 2.0, &"Void": 1.0},
		&"Storm": {&"Fire": 1.0, &"Ice": 0.5, &"Storm": 0.5, &"Stone": 2.0, &"Venom": 1.0, &"Shadow": 2.0, &"Void": 1.0},
		&"Stone": {&"Fire": 2.0, &"Ice": 1.0, &"Storm": 0.5, &"Stone": 0.5, &"Venom": 2.0, &"Shadow": 1.0, &"Void": 1.0},
		&"Venom": {&"Fire": 0.5, &"Ice": 1.0, &"Storm": 1.0, &"Stone": 0.5, &"Venom": 0.5, &"Shadow": 2.0, &"Void": 1.0},
		&"Shadow": {&"Fire": 1.0, &"Ice": 0.5, &"Storm": 0.5, &"Stone": 1.0, &"Venom": 0.5, &"Shadow": 2.0, &"Void": 1.0},
		&"Void": {&"Fire": 1.0, &"Ice": 1.0, &"Storm": 1.0, &"Stone": 1.0, &"Venom": 1.0, &"Shadow": 1.0, &"Void": 1.0},
	}

	for attacker in expected:
		for defender in expected[attacker]:
			assert_almost_eq(service.type_effectiveness(attacker, defender), expected[attacker][defender], 0.001, "%s -> %s" % [attacker, defender])


func test_stage_thresholds_and_elder_stage_multiplier() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	assert_almost_eq(service.stage_multiplier_for_level(9, false), 0.5, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(10, false), 0.75, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(24, false), 0.75, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(25, false), 1.0, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(49, true), 1.0, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(50, false), 1.4, 0.001)
	assert_almost_eq(service.stage_multiplier_for_level(50, true), 1.75, 0.001)


func test_accuracy_blind_stat_scaling_and_raw_xp_are_pure_formula_helpers() -> void:
	var service: RefCounted = _make_service()
	if service == null:
		return

	var miss_result: RefCounted = service.calculate_damage(70, 44, 1.0, 2.0, false, 0.90, 1.0, 85, 86, false)
	var blind_miss: RefCounted = service.calculate_damage(70, 44, 1.0, 2.0, false, 0.90, 1.0, 100, 71, true)
	var blind_hit: RefCounted = service.calculate_damage(70, 44, 1.0, 2.0, false, 0.90, 1.0, 100, 70, true)

	assert_eq(service.effective_accuracy(100, true), 70)
	assert_eq(miss_result.damage, 0)
	assert_false(miss_result.hit)
	assert_eq(blind_miss.damage, 0)
	assert_false(blind_miss.hit)
	assert_true(blind_hit.hit)
	assert_eq(service.stat_at_level(28, 20, false), 85)
	assert_eq(service.stat_at_level(28, 1, true), 33)
	assert_eq(service.raw_xp_awarded(25, 5, 10), 12)
	assert_eq(service.raw_xp_awarded(25, 1, 60), 1)
	assert_false(service.has_method("apply_xp"), "Battle formula helpers must not apply durable progression.")

	var source: String = FileAccess.get_file_as_string(BATTLE_FORMULA_SERVICE_PATH)
	assert_false(source.contains("SaveTransaction"), "Battle formula helpers must not depend on SaveTransaction.")
	assert_false(source.contains("DragonProgressionService.apply_xp"), "Battle formula helpers must not apply XP.")
	assert_false(source.contains("battle_charges"), "Battle formula helpers must not mutate Resonance charges.")


func _make_service() -> RefCounted:
	assert_true(ResourceLoader.exists(BATTLE_FORMULA_SERVICE_PATH), "BattleFormulaService script should exist.")
	if not ResourceLoader.exists(BATTLE_FORMULA_SERVICE_PATH):
		return null
	var script: GDScript = load(BATTLE_FORMULA_SERVICE_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()
