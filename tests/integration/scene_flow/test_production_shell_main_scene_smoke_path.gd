extends GutTest

const EXPECTED_MAIN_SCENE: String = "res://scenes/bootstrap/BootstrapRoot.tscn"
const PRODUCTION_SAVE_PATH: String = "user://dragon-forge-slot-0.tres"
const MISSING_CONTENT_SAVE_PATH: String = "user://scene-003-missing-content.tres"
const INVALID_REGISTRATION_SAVE_PATH: String = "user://scene-003-invalid-registration.tres"
const FOCUS_ROUTING_SAVE_PATH: String = "user://scene-003-focus-routing.tres"


func before_each() -> void:
	_remove_save_artifacts(PRODUCTION_SAVE_PATH)
	_remove_save_artifacts(MISSING_CONTENT_SAVE_PATH)
	_remove_save_artifacts(INVALID_REGISTRATION_SAVE_PATH)
	_remove_save_artifacts(FOCUS_ROUTING_SAVE_PATH)


func after_each() -> void:
	_remove_save_artifacts(PRODUCTION_SAVE_PATH)
	_remove_save_artifacts(MISSING_CONTENT_SAVE_PATH)
	_remove_save_artifacts(INVALID_REGISTRATION_SAVE_PATH)
	_remove_save_artifacts(FOCUS_ROUTING_SAVE_PATH)


func test_project_defines_production_main_scene_that_boots_shell() -> void:
	var main_scene_path: String = str(ProjectSettings.get_setting("application/run/main_scene", ""))

	assert_eq(main_scene_path, EXPECTED_MAIN_SCENE)
	assert_true(ResourceLoader.exists(main_scene_path), "Configured production main scene should exist.")
	if not ResourceLoader.exists(main_scene_path):
		return

	var packed_scene: PackedScene = load(main_scene_path)
	assert_not_null(packed_scene)
	if packed_scene == null:
		return
	assert_true(packed_scene.can_instantiate())

	var bootstrap: Node = packed_scene.instantiate()
	add_child_autofree(bootstrap)
	await get_tree().process_frame

	assert_true(bootstrap.has_method("get_last_boot_result"))
	assert_true(bootstrap.has_method("get_scene_flow_service"))
	assert_true(bootstrap.has_method("get_input_router"))
	if not bootstrap.has_method("get_last_boot_result"):
		return

	var boot_result: RefCounted = bootstrap.call("get_last_boot_result")
	assert_not_null(boot_result)
	if boot_result == null:
		return
	assert_true(boot_result.success)
	assert_eq(boot_result.reason, &"success")

	var scene_flow: Node = bootstrap.call("get_scene_flow_service")
	assert_not_null(scene_flow)
	if scene_flow == null:
		return
	assert_true(scene_flow.has_registered_screen(&"hub"))
	assert_eq(scene_flow.get_active_screen_id(), &"hub")

	var active_screen: Node = scene_flow.get_active_screen()
	assert_not_null(active_screen)
	if active_screen == null:
		return
	assert_true(active_screen.has_method("get_shell_state"))
	assert_true(active_screen.has_method("accepts_input"))
	assert_true(active_screen.has_method("get_initial_focus_control"))
	assert_eq(active_screen.call("get_shell_state"), &"hub_floor")
	assert_true(active_screen.call("accepts_input"))
	var focus_target: Variant = active_screen.call("get_initial_focus_control")
	assert_not_null(focus_target)
	assert_true(focus_target is Control)
	if not focus_target is Control:
		return
	assert_eq(focus_target.name, "HatcheryRingFocus")
	assert_eq(get_viewport().gui_get_focus_owner(), focus_target)


func test_bootstrap_blocks_shell_when_required_hub_content_is_missing() -> void:
	var bootstrap_script: GDScript = load("res://src/scene_flow/bootstrap_root.gd")
	var content_script: GDScript = load("res://src/content/content_registry.gd")
	var input_script: GDScript = load("res://src/input/input_router.gd")
	var save_script: GDScript = load("res://src/save/save_service.gd")
	var scene_flow_script: GDScript = load("res://src/scene_flow/scene_flow_service.gd")

	var bootstrap: Node = bootstrap_script.new()
	add_child_autofree(bootstrap)
	var content: Node = add_child_autofree(content_script.new())
	var input: Node = add_child_autofree(input_script.new())
	var scene_flow: Node = add_child_autofree(scene_flow_script.new())

	bootstrap.configure({
		"content_registry": content,
		"save_service": save_script.new(),
		"input_router": input,
		"scene_flow_service": scene_flow,
		"save_path": MISSING_CONTENT_SAVE_PATH,
		"slot_id": 0,
		"screen_definitions": [],
		"required_screen_ids": [&"hub"],
		"screen_registrations": {},
		"initial_screen_id": &"hub",
	})

	var result: RefCounted = bootstrap.boot()

	assert_false(result.success)
	assert_eq(result.reason, &"content_validation_failed")
	assert_eq(bootstrap.call("get_last_boot_result"), result)
	assert_eq(scene_flow.get_active_screen_id(), &"")


func test_bootstrap_returns_named_failure_for_invalid_screen_registration() -> void:
	var bootstrap_script: GDScript = load("res://src/scene_flow/bootstrap_root.gd")
	var content_script: GDScript = load("res://src/content/content_registry.gd")
	var content_definition_script: GDScript = load("res://src/content/content_definition.gd")
	var input_script: GDScript = load("res://src/input/input_router.gd")
	var save_script: GDScript = load("res://src/save/save_service.gd")
	var scene_flow_script: GDScript = load("res://src/scene_flow/scene_flow_service.gd")

	var bootstrap: Node = bootstrap_script.new()
	add_child_autofree(bootstrap)
	var content: Node = add_child_autofree(content_script.new())
	var input: Node = add_child_autofree(input_script.new())
	var scene_flow: Node = add_child_autofree(scene_flow_script.new())
	var screen_definition: Resource = content_definition_script.new()
	screen_definition.content_id = &"hub"
	screen_definition.content_type = &"screen"
	screen_definition.source_path = "res://scenes/hub/HubShell.tscn"
	screen_definition.required = true

	bootstrap.configure({
		"content_registry": content,
		"save_service": save_script.new(),
		"input_router": input,
		"scene_flow_service": scene_flow,
		"save_path": INVALID_REGISTRATION_SAVE_PATH,
		"slot_id": 0,
		"screen_definitions": [screen_definition],
		"required_screen_ids": [&"hub"],
		"screen_registrations": {&"hub": "res://scenes/hub/HubShell.tscn"},
		"initial_screen_id": &"hub",
	})

	var result: RefCounted = bootstrap.boot()

	assert_false(result.success)
	assert_eq(result.reason, &"scene_registration_failed")
	assert_not_null(result.source_result)
	if result.source_result != null:
		assert_eq(result.source_result.reason, &"invalid_registration")
	assert_eq(bootstrap.call("get_last_boot_result"), result)
	assert_eq(scene_flow.get_active_screen_id(), &"")


func test_initial_shell_focus_restoration_emits_through_input_router() -> void:
	var bootstrap_script: GDScript = load("res://src/scene_flow/bootstrap_root.gd")
	var content_script: GDScript = load("res://src/content/content_registry.gd")
	var content_definition_script: GDScript = load("res://src/content/content_definition.gd")
	var input_script: GDScript = load("res://src/input/input_router.gd")
	var save_script: GDScript = load("res://src/save/save_service.gd")
	var scene_flow_script: GDScript = load("res://src/scene_flow/scene_flow_service.gd")
	var hub_scene: PackedScene = load("res://scenes/hub/HubShell.tscn")

	var bootstrap: Node = bootstrap_script.new()
	add_child_autofree(bootstrap)
	var content: Node = add_child_autofree(content_script.new())
	var input: Node = add_child_autofree(input_script.new())
	var scene_flow: Node = add_child_autofree(scene_flow_script.new())
	var restored_controls: Array[Control] = []
	input.focus_restored.connect(func(control: Control) -> void:
		restored_controls.append(control)
	)
	var screen_definition: Resource = content_definition_script.new()
	screen_definition.content_id = &"hub"
	screen_definition.content_type = &"screen"
	screen_definition.source_path = "res://scenes/hub/HubShell.tscn"
	screen_definition.required = true

	bootstrap.configure({
		"content_registry": content,
		"save_service": save_script.new(),
		"input_router": input,
		"scene_flow_service": scene_flow,
		"save_path": FOCUS_ROUTING_SAVE_PATH,
		"slot_id": 0,
		"screen_definitions": [screen_definition],
		"required_screen_ids": [&"hub"],
		"screen_registrations": {&"hub": hub_scene},
		"initial_screen_id": &"hub",
	})

	var result: RefCounted = bootstrap.boot()

	assert_true(result.success)
	assert_eq(restored_controls.size(), 1)
	if restored_controls.is_empty():
		return
	assert_eq(restored_controls[0].name, "HatcheryRingFocus")
	assert_eq(get_viewport().gui_get_focus_owner(), restored_controls[0])


func _remove_save_artifacts(path: String) -> void:
	_remove_file(path)
	_remove_file(_path_with_marker(path, "tmp"))
	_remove_file(_path_with_marker(path, "bak"))


func _path_with_marker(path: String, marker: String) -> String:
	var extension: String = path.get_extension()
	if extension == "":
		return "%s.%s" % [path, marker]
	return "%s.%s.%s" % [path.get_basename(), marker, extension]


func _remove_file(path: String) -> void:
	if path == "":
		return
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
