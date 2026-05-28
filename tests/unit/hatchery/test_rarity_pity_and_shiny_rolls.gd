extends GutTest

const PULL_RESOLUTION_RESULT_PATH: String = "res://src/hatchery/hatchery_pull_resolution_result.gd"
const PULL_RESOLVER_PATH: String = "res://src/hatchery/hatchery_pull_resolver.gd"
const PULL_TABLE_PATH: String = "res://src/hatchery/hatchery_pull_table.gd"
const RNG_PROVIDER_PATH: String = "res://src/hatchery/hatchery_rng_provider.gd"

const CANONICAL_SEED: int = 1337
const TRIAL_COUNT: int = 10000


func test_natural_distribution_counts_pre_pity_values_with_canonical_seed() -> void:
	var first_counts: Dictionary = _run_natural_distribution(CANONICAL_SEED)
	var second_counts: Dictionary = _run_natural_distribution(CANONICAL_SEED)
	if first_counts.is_empty() or second_counts.is_empty():
		return

	assert_eq(first_counts, second_counts)
	assert_between(first_counts.get(&"Common", 0), 4800, 5200)
	assert_between(first_counts.get(&"Uncommon", 0), 3800, 4200)
	assert_between(first_counts.get(&"Rare", 0), 800, 1200)
	assert_between(first_counts.get(&"Fire", 0), 2300, 2700)
	assert_between(first_counts.get(&"Ice", 0), 2300, 2700)
	assert_between(first_counts.get(&"Storm", 0), 1133, 1533)
	assert_between(first_counts.get(&"Venom", 0), 1133, 1533)
	assert_between(first_counts.get(&"Stone", 0), 1133, 1533)
	assert_eq(first_counts.get(&"Void", 0), 0)


func test_rare_pity_forces_shadow_after_nine_non_rare_without_element_roll() -> void:
	var result: RefCounted = _resolve_with_scripted_rolls([0.10, 0.001], 9)
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_eq(result.natural_rarity, &"Common")
	assert_eq(result.natural_element, &"")
	assert_eq(result.final_rarity, &"Rare")
	assert_eq(result.final_element, &"Shadow")
	assert_true(result.pity_forced)
	assert_true(result.shiny)
	assert_eq(result.next_pity_counter, 0)
	assert_eq(result.rarity_roll_basis_point, 1000)
	assert_eq(result.element_roll_basis_point, -1)
	assert_eq(result.shiny_roll_basis_point, 10)


func test_pity_counter_eight_does_not_force_and_consumes_element_roll() -> void:
	var result: RefCounted = _resolve_with_scripted_rolls([0.10, 0.75, 0.99], 8)
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_eq(result.natural_rarity, &"Common")
	assert_eq(result.natural_element, &"Ice")
	assert_eq(result.final_rarity, &"Common")
	assert_eq(result.final_element, &"Ice")
	assert_false(result.pity_forced)
	assert_false(result.shiny)
	assert_eq(result.next_pity_counter, 9)
	assert_eq(result.rarity_roll_basis_point, 1000)
	assert_eq(result.element_roll_basis_point, 7500)
	assert_eq(result.shiny_roll_basis_point, 9900)


func test_natural_rare_at_pity_nine_is_not_forced_and_still_rolls_shiny() -> void:
	var result: RefCounted = _resolve_with_scripted_rolls([0.95, 0.001], 9)
	if result == null:
		return

	assert_true(result.success, result.error_message)
	assert_eq(result.natural_rarity, &"Rare")
	assert_eq(result.natural_element, &"Shadow")
	assert_eq(result.final_rarity, &"Rare")
	assert_eq(result.final_element, &"Shadow")
	assert_false(result.pity_forced)
	assert_true(result.shiny)
	assert_eq(result.next_pity_counter, 0)
	assert_eq(result.rarity_roll_basis_point, 9500)
	assert_eq(result.element_roll_basis_point, -1)
	assert_eq(result.shiny_roll_basis_point, 10)


func test_pity_counter_increments_for_common_and_uncommon_and_resets_for_rare() -> void:
	var common_result: RefCounted = _resolve_with_scripted_rolls([0.10, 0.10, 0.99], 0)
	var uncommon_result: RefCounted = _resolve_with_scripted_rolls([0.70, 0.10, 0.99], 0)
	var rare_result: RefCounted = _resolve_with_scripted_rolls([0.95, 0.99], 8)
	var forced_result: RefCounted = _resolve_with_scripted_rolls([0.10, 0.99], 9)
	if common_result == null or uncommon_result == null or rare_result == null or forced_result == null:
		return

	assert_eq(common_result.final_rarity, &"Common")
	assert_eq(common_result.next_pity_counter, 1)
	assert_eq(uncommon_result.final_rarity, &"Uncommon")
	assert_eq(uncommon_result.next_pity_counter, 1)
	assert_eq(rare_result.final_rarity, &"Rare")
	assert_false(rare_result.pity_forced)
	assert_eq(rare_result.next_pity_counter, 0)
	assert_eq(forced_result.final_rarity, &"Rare")
	assert_true(forced_result.pity_forced)
	assert_eq(forced_result.next_pity_counter, 0)


func test_shiny_rate_uses_canonical_seed_and_is_repeatable() -> void:
	var first_count: int = _count_shiny_pulls(CANONICAL_SEED)
	var second_count: int = _count_shiny_pulls(CANONICAL_SEED)

	assert_eq(first_count, second_count)
	assert_between(first_count, 100, 300)


func test_resolver_and_resolution_result_are_named_contracts_without_global_random() -> void:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var result: RefCounted = _new_refcounted(PULL_RESOLUTION_RESULT_PATH)
	if resolver == null or result == null:
		return

	assert_true(resolver is RefCounted)
	assert_true(result is RefCounted)
	assert_true(resolver.get_script().resource_path.ends_with("hatchery_pull_resolver.gd"))
	assert_true(result.get_script().resource_path.ends_with("hatchery_pull_resolution_result.gd"))
	assert_false(_source_uses_global_random(PULL_RESOLVER_PATH))


func _run_natural_distribution(seed_value: int) -> Dictionary:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var rng: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var snapshot: RefCounted = _make_mvp_snapshot()
	if resolver == null or rng == null or snapshot == null:
		return {}

	rng.configure_seed(seed_value)
	var counts: Dictionary = {
		&"Common": 0,
		&"Uncommon": 0,
		&"Rare": 0,
		&"Fire": 0,
		&"Ice": 0,
		&"Storm": 0,
		&"Venom": 0,
		&"Stone": 0,
		&"Shadow": 0,
		&"Void": 0,
	}
	for _trial in TRIAL_COUNT:
		var result: RefCounted = resolver.resolve(snapshot, 0, rng)
		counts[result.natural_rarity] = counts.get(result.natural_rarity, 0) + 1
		counts[result.natural_element] = counts.get(result.natural_element, 0) + 1
	return counts


func _count_shiny_pulls(seed_value: int) -> int:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var rng: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var snapshot: RefCounted = _make_mvp_snapshot()
	if resolver == null or rng == null or snapshot == null:
		return -1

	rng.configure_seed(seed_value)
	var shiny_count: int = 0
	for _trial in TRIAL_COUNT:
		var result: RefCounted = resolver.resolve(snapshot, 0, rng)
		if result.shiny:
			shiny_count += 1
	return shiny_count


func _resolve_with_scripted_rolls(rolls: Array, pity_counter: int) -> RefCounted:
	var resolver: RefCounted = _new_refcounted(PULL_RESOLVER_PATH)
	var rng: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var snapshot: RefCounted = _make_mvp_snapshot()
	if resolver == null or rng == null or snapshot == null:
		return null

	rng.configure_scripted_rolls(rolls)
	return resolver.resolve(snapshot, pity_counter, rng)


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


func _source_uses_global_random(path: String) -> bool:
	var source := FileAccess.get_file_as_string(path)
	for line in source.split("\n"):
		var stripped := line.strip_edges()
		if stripped.begins_with("randf(") or stripped.begins_with("randi("):
			return true
		if stripped.contains(" randf(") or stripped.contains(" randi("):
			return true
	return false
