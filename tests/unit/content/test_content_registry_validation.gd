extends GutTest

const CONTENT_DEFINITION_PATH: String = "res://src/content/content_definition.gd"
const CONTENT_REGISTRY_PATH: String = "res://src/content/content_registry.gd"


func test_registry_loads_required_definitions_by_stable_string_name_ids() -> void:
	var registry: Node = _make_registry()
	if registry == null:
		return

	var result: RefCounted = registry.register_definitions(
		[
			_make_definition(&"hub", &"screen", true),
			_make_definition(&"battle", &"screen", true),
		],
		[&"hub", &"battle"],
		&"screen"
	)

	assert_true(result.ok)
	assert_true(registry.has_definition(&"hub", &"screen"))
	assert_true(registry.has_definition(&"battle", &"screen"))
	assert_eq(registry.get_definition(&"hub", &"screen").content_id, &"hub")


func test_registry_rejects_duplicate_required_ids() -> void:
	var registry: Node = _make_registry()
	if registry == null:
		return

	var result: RefCounted = registry.register_definitions(
		[
			_make_definition(&"hub", &"screen", true),
			_make_definition(&"hub", &"screen", true),
		],
		[&"hub"],
		&"screen"
	)

	assert_false(result.ok)
	assert_true(result.duplicate_required_ids.has(&"hub"))
	assert_true(result.actionable_errors[0].contains("hub"))
	assert_false(registry.has_definition(&"hub", &"screen"))


func test_registry_reports_missing_required_ids_with_actionable_errors() -> void:
	var registry: Node = _make_registry()
	if registry == null:
		return

	var result: RefCounted = registry.register_definitions(
		[_make_definition(&"shop", &"screen", true)],
		[&"hub", &"shop"],
		&"screen"
	)

	assert_false(result.ok)
	assert_true(result.missing_required_ids.has(&"hub"))
	assert_true(_messages_contain(result.actionable_errors, "Missing required content ID 'hub'"))


func test_optional_duplicate_ids_warn_without_blocking_startup() -> void:
	var registry: Node = _make_registry()
	if registry == null:
		return

	var result: RefCounted = registry.register_definitions(
		[
			_make_definition(&"ambient_glint", &"presentation", false),
			_make_definition(&"ambient_glint", &"presentation", false),
		],
		[],
		&"presentation"
	)

	assert_true(result.ok)
	assert_true(result.duplicate_optional_ids.has(&"ambient_glint"))
	assert_true(_messages_contain(result.warnings, "ambient_glint"))


func test_runtime_definitions_are_safe_copies_not_shared_mutable_resources() -> void:
	var registry: Node = _make_registry()
	if registry == null:
		return

	var result: RefCounted = registry.register_definitions(
		[_make_definition(&"hub", &"screen", true)],
		[&"hub"],
		&"screen"
	)
	assert_true(result.ok)

	var runtime_copy: Resource = registry.get_definition(&"hub", &"screen")
	runtime_copy.content_id = &"mutated_hub"

	var second_copy: Resource = registry.get_definition(&"hub", &"screen")
	assert_eq(second_copy.content_id, &"hub")
	assert_ne(runtime_copy, second_copy)


func test_registry_loads_real_battle_fixture_resources_by_stable_ids() -> void:
	var registry: Node = _make_registry()
	if registry == null:
		return

	var result: RefCounted = registry.load_resource_paths(
		[
			"res://assets/battle/battles/village_edge_admin_protocol.tres",
			"res://assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres",
			"res://assets/battle/moves/root_spark.tres",
			"res://assets/battle/moves/thorn_surge.tres",
			"res://assets/battle/moves/guarded_spark.tres",
			"res://assets/battle/moves/data_leak.tres",
		],
		[
			&"village_edge_admin_protocol",
			&"root_wyrmling_vs_admin_protocol",
			&"root_spark",
			&"thorn_surge",
			&"guarded_spark",
			&"data_leak",
		],
		&"battle_fixture"
	)

	assert_true(result.ok)
	assert_true(registry.has_definition(&"village_edge_admin_protocol", &"battle_fixture"))
	assert_true(registry.has_definition(&"root_wyrmling_vs_admin_protocol", &"battle_fixture"))
	assert_eq(registry.get_definition(&"root_spark", &"battle_fixture").move_id, &"root_spark")


func _make_registry() -> Node:
	assert_true(ResourceLoader.exists(CONTENT_REGISTRY_PATH), "ContentRegistry script should exist.")
	if not ResourceLoader.exists(CONTENT_REGISTRY_PATH):
		return null
	var script: GDScript = load(CONTENT_REGISTRY_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return add_child_autofree(script.new())


func _make_definition(content_id: StringName, content_type: StringName, required: bool) -> Resource:
	assert_true(ResourceLoader.exists(CONTENT_DEFINITION_PATH), "ContentDefinition script should exist.")
	var script: GDScript = load(CONTENT_DEFINITION_PATH)
	assert_not_null(script)
	var definition: Resource = script.new()
	definition.content_id = content_id
	definition.content_type = content_type
	definition.required = required
	return definition


func _messages_contain(messages: PackedStringArray, expected: String) -> bool:
	for message in messages:
		if message.contains(expected):
			return true
	return false
