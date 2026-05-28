extends GutTest

const BOOTSTRAP_ROOT_PATH: String = "res://src/scene_flow/bootstrap_root.gd"
const CONTENT_DEFINITION_PATH: String = "res://src/content/content_definition.gd"
const CONTENT_REGISTRY_PATH: String = "res://src/content/content_registry.gd"
const INPUT_ROUTER_PATH: String = "res://src/input/input_router.gd"
const SAVE_DATA_PATH: String = "res://src/save/save_data.gd"
const SAVE_SERVICE_PATH: String = "res://src/save/save_service.gd"
const SCENE_FLOW_SERVICE_PATH: String = "res://src/scene_flow/scene_flow_service.gd"
const FOCUS_SCREEN_PATH: String = "res://tests/fixtures/bootstrap/bootstrap_focus_screen.gd"

var _save_path: String = ""


func before_each() -> void:
	_save_path = "user://bootstrap-order-test-%s.tres" % Time.get_ticks_usec()


func after_each() -> void:
	if _save_path != "" and FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path))
	var temp_path: String = _path_with_marker(_save_path, "tmp")
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
	var backup_path: String = _path_with_marker(_save_path, "bak")
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))


func test_bootstrap_starts_services_in_deterministic_order_and_restores_focus() -> void:
	var bootstrap: Node = _make_bootstrap()
	if bootstrap == null:
		return
	add_child_autofree(bootstrap)
	var services: Dictionary = _make_services()
	var hub_scene: PackedScene = _make_packed_screen(load(FOCUS_SCREEN_PATH))
	bootstrap.configure({
		"content_registry": services.content,
		"save_service": services.save,
		"input_router": services.input,
		"scene_flow_service": services.scene_flow,
		"save_path": _save_path,
		"slot_id": 0,
		"initial_save_data": _make_save_data(42),
		"screen_definitions": [_make_content_definition(&"hub", &"screen", true)],
		"required_screen_ids": [&"hub"],
		"screen_registrations": {&"hub": hub_scene},
		"initial_screen_id": &"hub",
		"initial_input_context": &"ui",
		"presentation_subscribers": [_make_presentation_subscriber()],
	})

	var result: RefCounted = bootstrap.boot()

	assert_true(result.success)
	assert_eq(bootstrap.get_boot_log(), [
		&"content",
		&"save",
		&"input",
		&"scene_flow",
		&"presentation_subscribers",
		&"hub",
		&"focus",
	])
	var loaded_save: Resource = _load_save(_save_path)
	assert_not_null(loaded_save)
	if loaded_save != null:
		assert_eq(loaded_save.get("player_scraps"), 42)
	assert_eq(services.input.get_context(), &"ui")
	assert_true(services.scene_flow.has_registered_screen(&"hub"))
	assert_eq(services.scene_flow.get_active_screen_id(), &"hub")
	assert_eq(get_viewport().gui_get_focus_owner().name, "InitialFocus")


func test_bootstrap_blocks_before_save_when_required_content_validation_fails() -> void:
	var bootstrap: Node = _make_bootstrap()
	if bootstrap == null:
		return
	add_child_autofree(bootstrap)
	var services: Dictionary = _make_services()
	bootstrap.configure({
		"content_registry": services.content,
		"save_service": services.save,
		"input_router": services.input,
		"scene_flow_service": services.scene_flow,
		"save_path": _save_path,
		"slot_id": 0,
		"initial_save_data": _make_save_data(0),
		"screen_definitions": [],
		"required_screen_ids": [&"hub"],
		"screen_registrations": {},
		"initial_screen_id": &"hub",
	})

	var result: RefCounted = bootstrap.boot()

	assert_false(result.success)
	assert_eq(result.reason, &"content_validation_failed")
	assert_eq(bootstrap.get_boot_log(), [&"content"])
	assert_null(_load_save(_save_path))
	assert_eq(services.scene_flow.get_active_screen_id(), &"")


func test_bootstrap_blocks_before_input_when_save_initialization_fails() -> void:
	var bootstrap: Node = _make_bootstrap()
	if bootstrap == null:
		return
	add_child_autofree(bootstrap)
	var services: Dictionary = _make_services()
	bootstrap.configure({
		"content_registry": services.content,
		"save_service": services.save,
		"input_router": services.input,
		"scene_flow_service": services.scene_flow,
		"save_path": "",
		"slot_id": 0,
		"initial_save_data": _make_save_data(0),
		"screen_definitions": [_make_content_definition(&"hub", &"screen", true)],
		"required_screen_ids": [&"hub"],
		"screen_registrations": {&"hub": _make_packed_screen(load(FOCUS_SCREEN_PATH))},
		"initial_screen_id": &"hub",
	})

	var result: RefCounted = bootstrap.boot()

	assert_false(result.success)
	assert_eq(result.reason, &"save_initialization_failed")
	assert_eq(bootstrap.get_boot_log(), [&"content", &"save"])
	assert_eq(services.input.get_context(), &"ui")
	assert_eq(services.scene_flow.get_active_screen_id(), &"")


func _make_bootstrap() -> Node:
	assert_true(ResourceLoader.exists(BOOTSTRAP_ROOT_PATH), "BootstrapRoot script should exist.")
	if not ResourceLoader.exists(BOOTSTRAP_ROOT_PATH):
		return null
	var script: GDScript = load(BOOTSTRAP_ROOT_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func _make_services() -> Dictionary:
	var content_script: GDScript = load(CONTENT_REGISTRY_PATH)
	var save_script: GDScript = load(SAVE_SERVICE_PATH)
	var input_script: GDScript = load(INPUT_ROUTER_PATH)
	var scene_flow_script: GDScript = load(SCENE_FLOW_SERVICE_PATH)
	return {
		"content": add_child_autofree(content_script.new()),
		"save": save_script.new(),
		"input": add_child_autofree(input_script.new()),
		"scene_flow": add_child_autofree(scene_flow_script.new()),
	}


func _make_save_data(scraps: int) -> Resource:
	var script: GDScript = load(SAVE_DATA_PATH)
	var save_data: Resource = script.new()
	save_data.player_scraps = scraps
	return save_data


func _make_content_definition(content_id: StringName, content_type: StringName, required: bool) -> Resource:
	var script: GDScript = load(CONTENT_DEFINITION_PATH)
	var definition: Resource = script.new()
	definition.content_id = content_id
	definition.content_type = content_type
	definition.required = required
	return definition


func _make_packed_screen(script: Script) -> PackedScene:
	var root: Control = Control.new()
	root.name = "BootstrapFocusScreen"
	root.set_script(script)
	var packed_scene := PackedScene.new()
	var pack_result: Error = packed_scene.pack(root)
	root.free()
	assert_eq(pack_result, OK)
	return packed_scene


func _make_presentation_subscriber() -> Object:
	var subscriber := RefCounted.new()
	subscriber.set_meta("subscribed", false)
	subscriber.set_script(_PresentationSubscriberScript)
	return subscriber


func _load_save(path: String) -> Resource:
	if path == "" or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)


func _path_with_marker(path: String, marker: String) -> String:
	if path == "":
		return ""
	var extension: String = path.get_extension()
	if extension == "":
		return "%s.%s" % [path, marker]
	return "%s.%s.%s" % [path.get_basename(), marker, extension]


class _PresentationSubscriber:
	extends RefCounted

	func bootstrap_subscribe(_services: Dictionary) -> void:
		set_meta("subscribed", true)


const _PresentationSubscriberScript = _PresentationSubscriber
