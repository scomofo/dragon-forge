class_name BootstrapRoot
extends Node

## Explicit startup orchestrator for foundation services.
## Autoload construction stays light; this root owns deterministic initialization order.

const BootstrapResultResource = preload("res://src/scene_flow/bootstrap_result.gd")
const ContentDefinitionResource = preload("res://src/content/content_definition.gd")
const ContentRegistryResource = preload("res://src/content/content_registry.gd")
const InputRouterResource = preload("res://src/input/input_router.gd")
const SaveDataResource = preload("res://src/save/save_data.gd")
const SaveServiceResource = preload("res://src/save/save_service.gd")
const SceneFlowServiceResource = preload("res://src/scene_flow/scene_flow_service.gd")

const STEP_CONTENT: StringName = &"content"
const STEP_SAVE: StringName = &"save"
const STEP_INPUT: StringName = &"input"
const STEP_SCENE_FLOW: StringName = &"scene_flow"
const STEP_PRESENTATION_SUBSCRIBERS: StringName = &"presentation_subscribers"
const STEP_HUB: StringName = &"hub"
const STEP_FOCUS: StringName = &"focus"
const HUB_SCREEN_ID: StringName = &"hub"

@export var auto_boot: bool = false
@export var production_save_path: String = "user://dragon-forge-slot-0.tres"
@export var production_slot_id: int = 0
@export var production_hub_scene: PackedScene = null

var _content_registry: Object = null
var _save_service: Object = null
var _input_router: Object = null
var _scene_flow_service: Object = null
var _presentation_subscribers: Array = []
var _screen_definitions: Array = []
var _required_screen_ids: Array = []
var _screen_registrations: Dictionary = {}
var _save_path: String = ""
var _slot_id: int = 0
var _initial_save_data: Resource = null
var _initial_input_context: StringName = &"ui"
var _initial_screen_id: StringName = &"hub"
var _boot_log: Array[StringName] = []
var _last_boot_result: RefCounted = null
var _configured: bool = false


func _ready() -> void:
	if not auto_boot:
		return
	if not _configured:
		configure_production_defaults()
	_last_boot_result = boot()


func configure(config: Dictionary) -> void:
	_configured = true
	_content_registry = config.get("content_registry")
	_save_service = config.get("save_service")
	_input_router = config.get("input_router")
	_scene_flow_service = config.get("scene_flow_service")
	_presentation_subscribers = config.get("presentation_subscribers", [])
	_screen_definitions = config.get("screen_definitions", [])
	_required_screen_ids = config.get("required_screen_ids", [])
	_screen_registrations = config.get("screen_registrations", {})
	_save_path = config.get("save_path", "")
	_slot_id = config.get("slot_id", 0)
	_initial_save_data = config.get("initial_save_data", null)
	_initial_input_context = config.get("initial_input_context", &"ui")
	_initial_screen_id = config.get("initial_screen_id", &"hub")


func configure_production_defaults() -> void:
	var content_registry: Node = ContentRegistryResource.new()
	content_registry.name = "ContentRegistry"
	add_child(content_registry)

	var input_router: Node = InputRouterResource.new()
	input_router.name = "InputRouter"
	add_child(input_router)

	var scene_flow_service: Node = SceneFlowServiceResource.new()
	scene_flow_service.name = "SceneFlowService"
	add_child(scene_flow_service)

	configure({
		"content_registry": content_registry,
		"save_service": SaveServiceResource.new(),
		"input_router": input_router,
		"scene_flow_service": scene_flow_service,
		"save_path": production_save_path,
		"slot_id": production_slot_id,
		"initial_save_data": SaveDataResource.new(),
		"screen_definitions": [_make_screen_definition(HUB_SCREEN_ID, "res://scenes/hub/HubShell.tscn")],
		"required_screen_ids": [HUB_SCREEN_ID],
		"screen_registrations": {HUB_SCREEN_ID: production_hub_scene},
		"initial_screen_id": HUB_SCREEN_ID,
		"initial_input_context": &"ui",
	})


func boot() -> RefCounted:
	_boot_log = []

	var content_result: RefCounted = _boot_content()
	if content_result != null and not content_result.get("ok"):
		return _complete_boot(_failure(&"content_validation_failed", "Content validation failed.", content_result))

	var save_result: RefCounted = _boot_save()
	if save_result != null and not save_result.get("success"):
		return _complete_boot(_failure(&"save_initialization_failed", "Save initialization failed.", save_result))

	_boot_input()

	var scene_result: RefCounted = _boot_scene_flow()
	if scene_result != null and not scene_result.get("success"):
		return _complete_boot(_failure(&"scene_registration_failed", "Scene registration failed.", scene_result))

	_boot_presentation_subscribers()

	var hub_result: RefCounted = _open_initial_screen()
	if hub_result != null and not hub_result.get("success"):
		return _complete_boot(_failure(&"initial_screen_failed", "Initial screen failed to open.", hub_result))

	_boot_log.append(STEP_FOCUS)
	return _complete_boot(_success())


func get_last_boot_result() -> RefCounted:
	return _last_boot_result


func get_boot_log() -> Array[StringName]:
	return _boot_log.duplicate()


func get_content_registry() -> Object:
	return _content_registry


func get_input_router() -> Object:
	return _input_router


func get_scene_flow_service() -> Object:
	return _scene_flow_service


func _boot_content() -> RefCounted:
	_boot_log.append(STEP_CONTENT)
	if _content_registry == null or not _content_registry.has_method("register_definitions"):
		return _simple_failure(&"content_registry_missing", "ContentRegistry is missing.")
	return _content_registry.call(
		"register_definitions",
		_screen_definitions,
		_required_screen_ids,
		&"screen"
	)


func _boot_save() -> RefCounted:
	_boot_log.append(STEP_SAVE)
	if _save_service == null or not _save_service.has_method("configure"):
		return _simple_failure(&"save_service_missing", "SaveService is missing.")
	_save_service.call("configure", _save_path, _slot_id)
	if _save_service.has_method("has_current_save") and _save_service.call("has_current_save"):
		return _simple_success(&"save_loaded")
	var initial_save_data: Resource = _initial_save_data
	if initial_save_data == null:
		initial_save_data = SaveDataResource.new()
	return _save_service.call("initialize_slot", initial_save_data)


func _boot_input() -> void:
	_boot_log.append(STEP_INPUT)
	if _input_router == null:
		return
	if _input_router.has_method("ensure_input_map_actions"):
		_input_router.call("ensure_input_map_actions")
	if _input_router.has_method("set_context"):
		_input_router.call("set_context", _initial_input_context)


func _boot_scene_flow() -> RefCounted:
	_boot_log.append(STEP_SCENE_FLOW)
	if _scene_flow_service == null or not _scene_flow_service.has_method("register_screen"):
		return _simple_failure(&"scene_flow_service_missing", "SceneFlowService is missing.")
	if _scene_flow_service.has_method("set_input_router"):
		_scene_flow_service.call("set_input_router", _input_router)
	for screen_id in _screen_registrations.keys():
		var raw_scene: Variant = _screen_registrations[screen_id]
		if not raw_scene is PackedScene:
			return _scene_flow_service.call("register_screen", StringName(screen_id), null, true)
		var scene: PackedScene = raw_scene
		var result: RefCounted = _scene_flow_service.call("register_screen", StringName(screen_id), scene, true)
		if not result.get("success"):
			return result
	return _simple_success(&"screens_registered")


func _boot_presentation_subscribers() -> void:
	_boot_log.append(STEP_PRESENTATION_SUBSCRIBERS)
	var services := {
		"content_registry": _content_registry,
		"save_service": _save_service,
		"input_router": _input_router,
		"scene_flow_service": _scene_flow_service,
	}
	for subscriber in _presentation_subscribers:
		if subscriber != null and subscriber.has_method("bootstrap_subscribe"):
			subscriber.call("bootstrap_subscribe", services)


func _open_initial_screen() -> RefCounted:
	if _scene_flow_service == null or not _scene_flow_service.has_method("change_screen"):
		return _simple_failure(&"scene_flow_service_missing", "SceneFlowService is missing.")
	var result: RefCounted = _scene_flow_service.call("change_screen", _initial_screen_id, {"source": &"bootstrap"})
	if result.get("success"):
		_boot_log.append(STEP_HUB)
	return result


func _make_screen_definition(screen_id: StringName, source_path: String) -> Resource:
	var definition: ContentDefinition = ContentDefinitionResource.new()
	definition.content_id = screen_id
	definition.content_type = &"screen"
	definition.source_path = source_path
	definition.required = true
	return definition


func _success() -> RefCounted:
	return BootstrapResultResource.new().configure(true, &"success", "Bootstrap complete.", _boot_log)


func _failure(reason: StringName, message: String, source_result: RefCounted = null) -> RefCounted:
	return BootstrapResultResource.new().configure(false, reason, message, _boot_log, source_result)


func _simple_success(reason: StringName) -> RefCounted:
	return BootstrapResultResource.new().configure(true, reason, "", _boot_log)


func _simple_failure(reason: StringName, message: String) -> RefCounted:
	return BootstrapResultResource.new().configure(false, reason, message, _boot_log)


func _complete_boot(result: RefCounted) -> RefCounted:
	_last_boot_result = result
	return result
