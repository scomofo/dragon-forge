extends GutTest

const ELEMENT_WEIGHT_PATH: String = "res://src/hatchery/hatchery_element_weight.gd"
const PITY_RULES_PATH: String = "res://src/hatchery/hatchery_pity_rules.gd"
const PREVIEW_RESULT_PATH: String = "res://src/hatchery/hatchery_preview_result.gd"
const PULL_RESULT_PATH: String = "res://src/hatchery/hatchery_pull_result.gd"
const PULL_TABLE_PATH: String = "res://src/hatchery/hatchery_pull_table.gd"
const RARITY_WEIGHT_PATH: String = "res://src/hatchery/hatchery_rarity_weight.gd"
const RNG_PROVIDER_PATH: String = "res://src/hatchery/hatchery_rng_provider.gd"
const SNAPSHOT_PATH: String = "res://src/hatchery/hatchery_pull_table_snapshot.gd"
const VALIDATION_RESULT_PATH: String = "res://src/hatchery/hatchery_pull_table_validation_result.gd"
const STANDARD_TABLE_ASSET_PATH: String = "res://assets/hatchery/pull_tables/standard_hatchery.tres"


func test_mvp_pull_table_defines_gdd_contract_values() -> void:
	var table: Resource = _make_mvp_table()
	if table == null:
		return

	var result: RefCounted = table.validate()

	assert_true(result.ok, _join_errors(result))
	assert_eq(table.pull_id, &"standard_hatchery")
	assert_eq(table.scrap_cost, 50)
	assert_eq(table.shiny_rate_basis_points, 200)
	assert_eq(table.rarity_weight_for(&"Common"), 5000)
	assert_eq(table.rarity_weight_for(&"Uncommon"), 4000)
	assert_eq(table.rarity_weight_for(&"Rare"), 1000)
	assert_eq(table.element_weight_for(&"Fire"), 2500)
	assert_eq(table.element_weight_for(&"Ice"), 2500)
	assert_between(table.element_weight_for(&"Storm"), 1333, 1334)
	assert_between(table.element_weight_for(&"Venom"), 1333, 1334)
	assert_between(table.element_weight_for(&"Stone"), 1333, 1334)
	assert_eq(table.element_weight_for(&"Shadow"), 1000)
	assert_eq(table.total_rarity_weight(), 10000)
	assert_eq(table.total_element_weight(), 10000)
	assert_eq(table.pity_rules.rare_pity_threshold, 10)
	assert_eq(table.pity_rules.element_soft_pity_onset, 20)
	assert_eq(table.pity_rules.element_soft_pity_guaranteed, 40)


func test_authored_mvp_pull_table_resource_loads_and_validates() -> void:
	assert_true(ResourceLoader.exists(STANDARD_TABLE_ASSET_PATH), "Standard Hatchery pull table asset should exist.")
	if not ResourceLoader.exists(STANDARD_TABLE_ASSET_PATH):
		return

	var table: Resource = ResourceLoader.load(STANDARD_TABLE_ASSET_PATH)
	assert_not_null(table)
	if table == null:
		return

	var result: RefCounted = table.validate()

	assert_true(result.ok, _join_errors(result))
	assert_eq(table.pull_id, &"standard_hatchery")
	assert_eq(table.scrap_cost, 50)
	assert_eq(table.shiny_rate_basis_points, 200)
	assert_eq(table.rarity_weight_for(&"Common"), 5000)
	assert_eq(table.rarity_weight_for(&"Uncommon"), 4000)
	assert_eq(table.rarity_weight_for(&"Rare"), 1000)
	assert_eq(table.element_weight_for(&"Fire"), 2500)
	assert_eq(table.element_weight_for(&"Ice"), 2500)
	assert_between(table.element_weight_for(&"Storm"), 1333, 1334)
	assert_between(table.element_weight_for(&"Venom"), 1333, 1334)
	assert_between(table.element_weight_for(&"Stone"), 1333, 1334)
	assert_eq(table.element_weight_for(&"Shadow"), 1000)
	assert_eq(table.total_rarity_weight(), 10000)
	assert_eq(table.total_element_weight(), 10000)
	assert_eq(table.pity_rules.rare_pity_threshold, 10)
	assert_eq(table.pity_rules.element_soft_pity_onset, 20)
	assert_eq(table.pity_rules.element_soft_pity_guaranteed, 40)
	assert_false(table.has_standard_element(&"Void"))


func test_standard_pool_excludes_void_and_validation_rejects_void_entries() -> void:
	var table: Resource = _make_mvp_table()
	if table == null:
		return

	assert_false(table.has_standard_element(&"Void"))

	var void_weight: Resource = _make_element_weight(&"Void", &"Rare", 1)
	table.element_weights.append(void_weight)
	var result: RefCounted = table.validate()

	assert_false(result.ok)
	assert_true(result.forbidden_element_ids.has(&"Void"))
	assert_true(result.failed_fields.has("element_weights"))


func test_pull_table_validation_reports_invalid_required_fields() -> void:
	var invalid_cost: Resource = _make_mvp_table()
	var missing_shadow: Resource = _make_mvp_table()
	var duplicate_fire: Resource = _make_mvp_table()
	var invalid_probabilities: Resource = _make_mvp_table()
	var invalid_pity: Resource = _make_mvp_table()
	var invalid_shiny: Resource = _make_mvp_table()
	if invalid_cost == null or missing_shadow == null or duplicate_fire == null or invalid_probabilities == null or invalid_pity == null or invalid_shiny == null:
		return

	invalid_cost.scrap_cost = 0
	missing_shadow.element_weights.remove_at(_element_index(missing_shadow, &"Shadow"))
	duplicate_fire.element_weights.append(_make_element_weight(&"Fire", &"Common", 1))
	invalid_probabilities.rarity_weights[0].weight_basis_points = 4999
	invalid_pity.pity_rules.element_soft_pity_guaranteed = invalid_pity.pity_rules.element_soft_pity_onset
	invalid_shiny.shiny_rate_basis_points = 10001

	assert_true(invalid_cost.validate().failed_fields.has("scrap_cost"))
	assert_true(missing_shadow.validate().missing_element_ids.has(&"Shadow"))
	assert_true(duplicate_fire.validate().duplicate_element_ids.has(&"Fire"))
	assert_true(invalid_probabilities.validate().failed_fields.has("rarity_weights"))
	assert_true(invalid_pity.validate().failed_fields.has("pity_rules"))
	assert_true(invalid_shiny.validate().failed_fields.has("shiny_rate_basis_points"))


func test_pull_table_validation_rejects_rarity_and_element_weight_mismatch() -> void:
	var table: Resource = _make_mvp_table()
	if table == null:
		return

	table.element_weights[_element_index(table, &"Fire")].weight_basis_points = 1500
	table.element_weights[_element_index(table, &"Shadow")].weight_basis_points = 2000

	var result: RefCounted = table.validate()

	assert_false(result.ok)
	assert_true(result.failed_fields.has("element_weights"))
	assert_true(_join_errors(result).contains("Common"))
	assert_true(_join_errors(result).contains("Rare"))


func test_result_preview_and_validation_contracts_are_named_typed_classes() -> void:
	var preview: RefCounted = _new_refcounted(PREVIEW_RESULT_PATH)
	var pull_result: RefCounted = _new_refcounted(PULL_RESULT_PATH)
	var validation: RefCounted = _new_refcounted(VALIDATION_RESULT_PATH)
	if preview == null or pull_result == null or validation == null:
		return

	preview.pull_id = &"standard_hatchery"
	preview.cost = 50
	pull_result.pull_id = &"standard_hatchery"
	pull_result.element_id = &"Fire"
	validation.add_field_error("unit_test", "contract failure")

	assert_true(preview is RefCounted)
	assert_true(pull_result is RefCounted)
	assert_true(validation is RefCounted)
	assert_true(preview.get_script().resource_path.ends_with("hatchery_preview_result.gd"))
	assert_true(pull_result.get_script().resource_path.ends_with("hatchery_pull_result.gd"))
	assert_true(validation.get_script().resource_path.ends_with("hatchery_pull_table_validation_result.gd"))
	assert_eq(preview.pull_id, &"standard_hatchery")
	assert_eq(pull_result.element_id, &"Fire")
	assert_false(validation.ok)


func test_runtime_snapshot_is_detached_from_authored_resource_mutation() -> void:
	var table: Resource = _make_mvp_table()
	if table == null:
		return

	var original_first_weight: Resource = table.element_weights[0]
	var snapshot: RefCounted = table.create_runtime_snapshot()
	snapshot.element_weights[&"Fire"] = 1
	snapshot.required_element_ids.append(&"Void")
	snapshot.element_soft_pity_onset = 1

	assert_true(snapshot.get_script().resource_path.ends_with("hatchery_pull_table_snapshot.gd"))
	assert_eq(table.element_weight_for(&"Fire"), 2500)
	assert_false(table.required_element_ids.has(&"Void"))
	assert_eq(table.pity_rules.element_soft_pity_onset, 20)
	assert_eq(table.element_weights[0], original_first_weight)


func test_rng_provider_supports_scripted_and_seeded_deterministic_rolls_without_global_random() -> void:
	var first_seeded: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var second_seeded: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	var scripted: RefCounted = _new_refcounted(RNG_PROVIDER_PATH)
	if first_seeded == null or second_seeded == null or scripted == null:
		return

	first_seeded.configure_seed(1337)
	second_seeded.configure_seed(1337)
	scripted.configure_scripted_rolls([0.125, 0.875])

	assert_eq(scripted.next_float(), 0.125)
	assert_eq(scripted.next_float(), 0.875)
	assert_eq(first_seeded.next_float(), second_seeded.next_float())
	assert_eq(first_seeded.next_basis_point(), second_seeded.next_basis_point())
	assert_false(_source_uses_global_random(RNG_PROVIDER_PATH))
	assert_false(_source_uses_global_random(PULL_TABLE_PATH))


func _make_mvp_table() -> Resource:
	var script: GDScript = _load_required_script(PULL_TABLE_PATH)
	if script == null:
		return null
	var table: Resource = script.new()
	table.configure_mvp_standard_table()
	return table


func _make_element_weight(element_id: StringName, rarity_id: StringName, weight_basis_points: int) -> Resource:
	var script: GDScript = _load_required_script(ELEMENT_WEIGHT_PATH)
	if script == null:
		return null
	var weight: Resource = script.new()
	weight.element_id = element_id
	weight.rarity_id = rarity_id
	weight.weight_basis_points = weight_basis_points
	return weight


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


func _element_index(table: Resource, element_id: StringName) -> int:
	for index in table.element_weights.size():
		if table.element_weights[index].element_id == element_id:
			return index
	return -1


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
