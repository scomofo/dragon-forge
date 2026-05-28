extends GutTest

const PULL_RESOLVER_PATH: String = "res://src/hatchery/hatchery_pull_resolver.gd"
const PULL_TABLE_PATH: String = "res://src/hatchery/hatchery_pull_table.gd"
const RNG_PROVIDER_PATH: String = "res://src/hatchery/hatchery_rng_provider.gd"

const CANONICAL_SEED: int = 1337
const TRIAL_COUNT: int = 10000
const STANDARD_ELEMENTS: Array[StringName] = [&"Fire", &"Ice", &"Storm", &"Venom", &"Stone", &"Shadow"]


func test_below_guarantee_stone_uses_ramp_draw_without_forcing() -> void:
	var result: RefCounted = _resolve_with_droughts([0.10, 0.0, 0.99], 0, _make_droughts({&"Stone": 39}))
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_false(result.element_soft_pity_forced)
	assert_true(result.element_soft_pity_ramped)
	assert_eq(result.final_element, &"Fire")
	assert_eq(result.final_rarity, &"Common")
	assert_eq(result.rarity_roll_basis_point, 1000)
	assert_eq(result.element_roll_basis_point, 0)
	assert_eq(result.shiny_roll_basis_point, 9900)


func test_guarantee_threshold_forces_stone_before_natural_shadow_or_rare_pity() -> void:
	var result: RefCounted = _resolve_with_droughts([0.99], 9, _make_droughts({&"Stone": 40}))
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_true(result.element_soft_pity_forced)
	assert_false(result.pity_forced)
	assert_eq(result.final_element, &"Stone")
	assert_eq(result.final_rarity, &"Uncommon")
	assert_eq(result.next_pity_counter, 10)
	assert_eq(result.element_roll_basis_point, -1)
	assert_eq(result.shiny_roll_basis_point, 9900)


func test_drought_counters_update_for_natural_ramp_and_guaranteed_stone() -> void:
	var natural_stone: RefCounted = _resolve_with_droughts([0.10, 0.88, 0.99], 0, _make_droughts({&"Stone": 30}))
	var ramp_stone: RefCounted = _resolve_with_droughts([0.10, 0.55, 0.99], 0, _make_droughts({&"Stone": 30}))
	var guaranteed_stone: RefCounted = _resolve_with_droughts([0.99], 0, _make_droughts({&"Stone": 40}))
	if natural_stone == null or ramp_stone == null or guaranteed_stone == null:
		return

	for result in [natural_stone, ramp_stone, guaranteed_stone]:
		assert_true(result.success, result.error_message)
		assert_eq(result.final_element, &"Stone")
		assert_eq(result.next_drought_counters.get(&"Stone", -1), 0)
		assert_eq(result.next_drought_counters.get(&"Fire", -1), 1)
		assert_eq(result.next_drought_counters.get(&"Ice", -1), 1)
		assert_eq(result.next_drought_counters.get(&"Storm", -1), 1)
		assert_eq(result.next_drought_counters.get(&"Venom", -1), 1)
		assert_eq(result.next_drought_counters.get(&"Shadow", -1), 1)


func test_highest_guaranteed_counter_wins_and_other_guarantees_remain_eligible() -> void:
	var result: RefCounted = _resolve_with_droughts([0.99], 0, _make_droughts({&"Storm": 42, &"Venom": 40}))
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_true(result.element_soft_pity_forced)
	assert_eq(result.final_element, &"Storm")
	assert_eq(result.next_drought_counters.get(&"Storm", -1), 0)
	assert_eq(result.next_drought_counters.get(&"Venom", -1), 41)

	var follow_up: RefCounted = _resolve_with_droughts([0.99], result.next_pity_counter, result.next_drought_counters)
	assert_true(follow_up.success, follow_up.error_message)
	assert_true(follow_up.element_soft_pity_forced)
	assert_eq(follow_up.final_element, &"Venom")

	var tie_result: RefCounted = _resolve_with_droughts([0.99], 0, _make_droughts({&"Stone": 40, &"Storm": 40}))
	assert_true(tie_result.success, tie_result.error_message)
	assert_eq(tie_result.final_element, &"Stone")


func test_soft_pity_forced_shadow_resets_rare_pity_and_stone_increments_it() -> void:
	var forced_shadow: RefCounted = _resolve_with_droughts([0.99], 5, _make_droughts({&"Shadow": 40}))
	var forced_stone: RefCounted = _resolve_with_droughts([0.99], 5, _make_droughts({&"Stone": 40}))
	if forced_shadow == null or forced_stone == null:
		return

	assert_true(forced_shadow.success, forced_shadow.error_message)
	assert_eq(forced_shadow.final_element, &"Shadow")
	assert_eq(forced_shadow.next_pity_counter, 0)
	assert_true(forced_shadow.element_soft_pity_forced)

	assert_true(forced_stone.success, forced_stone.error_message)
	assert_eq(forced_stone.final_element, &"Stone")
	assert_eq(forced_stone.next_pity_counter, 6)
	assert_true(forced_stone.element_soft_pity_forced)


func test_element_guarantee_preempts_rare_pity_then_next_pull_can_force_shadow() -> void:
	var first_result: RefCounted = _resolve_with_droughts([0.99], 9, _make_droughts({&"Stone": 40}))
	if first_result == null:
		return

	assert_true(first_result.success, first_result.error_message)
	assert_eq(first_result.final_element, &"Stone")
	assert_eq(first_result.next_pity_counter, 10)

	var next_result: RefCounted = _resolve_with_droughts([0.10, 0.99], first_result.next_pity_counter, first_result.next_drought_counters)
	assert_true(next_result.success, next_result.error_message)
	assert_true(next_result.pity_forced)
	assert_false(next_result.element_soft_pity_forced)
	assert_eq(next_result.final_element, &"Shadow")
	assert_eq(next_result.next_pity_counter, 0)
	assert_eq(next_result.rarity_roll_basis_point, 1000)
	assert_eq(next_result.element_roll_basis_point, -1)
	assert_eq(next_result.shiny_roll_basis_point, 9900)


func test_natural_shadow_at_pity_nine_is_not_forced_in_drought_resolver() -> void:
	var result: RefCounted = _resolve_with_droughts([0.95, 0.001], 9, _make_droughts())
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_eq(result.natural_rarity, &"Rare")
	assert_eq(result.natural_element, &"Shadow")
	assert_eq(result.final_element, &"Shadow")
	assert_false(result.pity_forced)
	assert_eq(result.next_pity_counter, 0)
	assert_eq(result.rarity_roll_basis_point, 9500)
	assert_eq(result.element_roll_basis_point, -1)
	assert_eq(result.shiny_roll_basis_point, 10)
	assert_eq(result.next_drought_counters.get(&"Shadow", -1), 0)


func test_next_pull_element_guarantee_can_preempt_rare_pity_after_stone_force() -> void:
	var first_result: RefCounted = _resolve_with_droughts([0.99], 9, _make_droughts({&"Stone": 40, &"Venom": 39}))
	if first_result == null:
		return

	assert_true(first_result.success, first_result.error_message)
	assert_eq(first_result.final_element, &"Stone")
	assert_eq(first_result.next_pity_counter, 10)
	assert_eq(first_result.next_drought_counters.get(&"Venom", -1), 40)

	var next_result: RefCounted = _resolve_with_droughts([0.99], first_result.next_pity_counter, first_result.next_drought_counters)
	assert_true(next_result.success, next_result.error_message)
	assert_true(next_result.element_soft_pity_forced)
	assert_false(next_result.pity_forced)
	assert_eq(next_result.final_element, &"Venom")
	assert_eq(next_result.next_pity_counter, 11)
	assert_eq(next_result.rarity_roll_basis_point, -1)
	assert_eq(next_result.element_roll_basis_point, -1)
	assert_eq(next_result.shiny_roll_basis_point, 9900)


func test_stone_ramp_expected_value_uses_independent_held_drought_trials() -> void:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var rng: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var snapshot: RefCounted = _make_mvp_snapshot()
	if resolver == null or rng == null or snapshot == null:
		return

	rng.configure_seed(CANONICAL_SEED)
	var stone_count: int = 0
	var trial_droughts: Dictionary = _make_droughts({&"Stone": 30})
	for _trial in TRIAL_COUNT:
		var result: RefCounted = resolver.resolve_with_droughts(snapshot, 0, trial_droughts, rng)
		if result.final_element == &"Stone":
			stone_count += 1

	assert_between(stone_count, 3500, 4500)


func test_success_returns_all_counters_and_missing_counter_fails() -> void:
	var result: RefCounted = _resolve_with_droughts([0.10, 0.0, 0.99], 0, _make_droughts())
	var missing_counter: Dictionary = _make_droughts()
	missing_counter.erase(&"Venom")
	var failed: RefCounted = _resolve_with_droughts([0.10, 0.0, 0.99], 0, missing_counter)
	if result == null or failed == null:
		return

	assert_true(result.success, result.error_message)
	for element_id in STANDARD_ELEMENTS:
		assert_true(result.next_drought_counters.has(element_id), "%s should be returned." % element_id)
	assert_eq(result.next_drought_counters.size(), STANDARD_ELEMENTS.size())

	assert_false(failed.success)
	assert_eq(failed.reason, &"missing_drought_counter")


func test_shadow_drought_never_reaches_soft_pity_onset_with_rare_pity_active() -> void:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var rng: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var snapshot: RefCounted = _make_mvp_snapshot()
	if resolver == null or rng == null or snapshot == null:
		return

	rng.configure_seed(CANONICAL_SEED)
	var pity_counter: int = 0
	var droughts: Dictionary = _make_droughts()
	var max_shadow_drought: int = 0
	for _trial in TRIAL_COUNT:
		var result: RefCounted = resolver.resolve_with_droughts(snapshot, pity_counter, droughts, rng)
		assert_true(result.success, result.error_message)
		pity_counter = result.next_pity_counter
		droughts = result.next_drought_counters
		max_shadow_drought = max(max_shadow_drought, int(droughts.get(&"Shadow", 0)))

	assert_lte(max_shadow_drought, 9)


func _resolve_with_droughts(rolls: Array, pity_counter: int, drought_counters: Dictionary) -> RefCounted:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var rng: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var snapshot: RefCounted = _make_mvp_snapshot()
	if resolver == null or rng == null or snapshot == null:
		return null

	rng.configure_scripted_rolls(rolls)
	return resolver.resolve_with_droughts(snapshot, pity_counter, drought_counters, rng)


func _make_mvp_snapshot() -> RefCounted:
	var script: GDScript = _load_required_script(PULL_TABLE_PATH)
	if script == null:
		return null
	var table: Resource = script.new()
	table.configure_mvp_standard_table()
	var validation: RefCounted = table.validate()
	assert_true(validation.ok, _join_errors(validation))
	if not validation.ok:
		return null
	return table.create_runtime_snapshot()


func _make_droughts(overrides: Dictionary = {}) -> Dictionary:
	var droughts: Dictionary = {}
	for element_id in STANDARD_ELEMENTS:
		droughts[element_id] = int(overrides.get(element_id, 0))
	return droughts


func _new_refcounted(path: String) -> RefCounted:
	var script: GDScript = _load_required_script(path)
	if script == null:
		return null
	return script.new()


func _load_required_script(path: String) -> GDScript:
	assert_true(ResourceLoader.exists(path), "%s should exist." % path)
	if not ResourceLoader.exists(path):
		return null
	var script: GDScript = load(path)
	assert_not_null(script)
	return script


func _join_errors(result: RefCounted) -> String:
	if result == null:
		return "validation result was null"
	return "\n".join(result.actionable_errors)
