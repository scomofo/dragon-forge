extends GutTest

const INPUT_ROUTER_PATH: String = "res://src/input/input_router.gd"
const ACTION_IDS: Array[StringName] = [
	&"ui_up",
	&"ui_down",
	&"ui_left",
	&"ui_right",
	&"ui_confirm",
	&"ui_cancel",
	&"battle_attack",
	&"battle_defend",
	&"battle_status",
	&"battle_consumable",
	&"map_pan",
]

var _had_actions: Dictionary[StringName, bool] = {}
var _original_action_events: Dictionary[StringName, Array] = {}


func before_each() -> void:
	_had_actions = {}
	_original_action_events = {}
	for action_id in ACTION_IDS:
		_had_actions[action_id] = InputMap.has_action(action_id)
		_original_action_events[action_id] = []
		if _had_actions[action_id]:
			for event in InputMap.action_get_events(action_id):
				_original_action_events[action_id].append(event)


func after_each() -> void:
	for action_id in ACTION_IDS:
		if _had_actions.get(action_id, false):
			if not InputMap.has_action(action_id):
				InputMap.add_action(action_id)
			InputMap.action_erase_events(action_id)
			for event in _original_action_events[action_id]:
				InputMap.action_add_event(action_id, event)
		elif InputMap.has_action(action_id):
			InputMap.erase_action(action_id)


func test_mvp_input_map_actions_are_distinct_string_name_ids() -> void:
	var router: Node = _make_router()
	if router == null:
		return

	router.ensure_input_map_actions()

	assert_eq(ACTION_IDS.size(), 11)
	var seen: Dictionary[StringName, bool] = {}
	for action_id in ACTION_IDS:
		assert_false(seen.has(action_id), "Duplicate action ID found: %s" % action_id)
		seen[action_id] = true
		assert_true(InputMap.has_action(action_id), "InputMap missing action: %s" % action_id)


func test_ui_input_map_actions_define_default_keyboard_and_gamepad_bindings() -> void:
	var router: Node = _make_router()
	if router == null:
		return

	router.ensure_input_map_actions()

	assert_true(_action_has_key_event(&"ui_up", KEY_UP))
	assert_true(_action_has_key_event(&"ui_down", KEY_DOWN))
	assert_true(_action_has_key_event(&"ui_left", KEY_LEFT))
	assert_true(_action_has_key_event(&"ui_right", KEY_RIGHT))
	assert_true(_action_has_key_event(&"ui_confirm", KEY_ENTER))
	assert_true(_action_has_key_event(&"ui_confirm", KEY_SPACE))
	assert_true(_action_has_key_event(&"ui_cancel", KEY_ESCAPE))
	assert_true(_action_has_joy_button_event(&"ui_up", JOY_BUTTON_DPAD_UP))
	assert_true(_action_has_joy_button_event(&"ui_down", JOY_BUTTON_DPAD_DOWN))
	assert_true(_action_has_joy_button_event(&"ui_left", JOY_BUTTON_DPAD_LEFT))
	assert_true(_action_has_joy_button_event(&"ui_right", JOY_BUTTON_DPAD_RIGHT))
	assert_true(_action_has_joy_button_event(&"ui_confirm", JOY_BUTTON_A))
	assert_true(_action_has_joy_button_event(&"ui_cancel", JOY_BUTTON_B))


func test_router_dispatches_enabled_semantic_actions_by_context() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var received: Array[RefCounted] = []
	var on_action: Callable = func(payload: RefCounted) -> void:
		received.append(payload)
	router.semantic_action.connect(on_action)

	router.set_context(&"ui")
	assert_true(router.route_input_event(_make_action_event(&"ui_confirm")))
	router.set_context(&"battle_telegraph")
	assert_true(router.route_input_event(_make_action_event(&"battle_attack")))
	router.set_context(&"campaign_map")
	assert_true(router.route_input_event(_make_action_event(&"map_pan")))
	router.semantic_action.disconnect(on_action)

	assert_eq(received.size(), 3)
	assert_eq(received[0].action_id, &"ui_confirm")
	assert_eq(received[0].context_id, &"ui")
	assert_eq(received[1].action_id, &"battle_attack")
	assert_eq(received[1].context_id, &"battle_telegraph")
	assert_eq(received[2].action_id, &"map_pan")
	assert_eq(received[2].context_id, &"campaign_map")


func test_router_ignores_unmapped_and_inactive_context_actions() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var received: Array[RefCounted] = []
	var on_action: Callable = func(payload: RefCounted) -> void:
		received.append(payload)
	router.semantic_action.connect(on_action)

	router.set_context(&"ui")
	assert_false(router.route_input_event(_make_action_event(&"battle_attack")))
	assert_false(router.route_input_event(_make_action_event(&"debug_unknown")))
	router.semantic_action.disconnect(on_action)

	assert_eq(received.size(), 0)


func test_feature_consumers_receive_semantic_payload_without_raw_hardware_details() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var received: Array[RefCounted] = []
	var on_action: Callable = func(payload: RefCounted) -> void:
		received.append(payload)
	router.semantic_action.connect(on_action)

	router.set_context(&"ui")
	router.route_input_event(_make_action_event(&"ui_cancel"))
	router.semantic_action.disconnect(on_action)

	assert_eq(received.size(), 1)
	assert_eq(received[0].action_id, &"ui_cancel")
	var property_names: Array[StringName] = _property_names(received[0])
	assert_false(property_names.has(&"raw_event"))
	assert_false(property_names.has(&"button_index"))
	assert_false(property_names.has(&"keycode"))
	assert_false(property_names.has(&"device"))


func test_keyboard_and_controller_events_map_to_same_semantic_action() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var received: Array[RefCounted] = []
	var on_action: Callable = func(payload: RefCounted) -> void:
		received.append(payload)
	router.semantic_action.connect(on_action)
	router.set_context(&"ui")

	assert_true(router.route_input_event(_make_key_event(KEY_ENTER)))
	assert_true(router.route_input_event(_make_joy_button_event(JOY_BUTTON_A)))
	router.semantic_action.disconnect(on_action)

	assert_eq(received.size(), 2)
	assert_eq(received[0].action_id, &"ui_confirm")
	assert_eq(received[1].action_id, &"ui_confirm")


func _make_router() -> Node:
	assert_true(ResourceLoader.exists(INPUT_ROUTER_PATH), "InputRouter script should exist.")
	if not ResourceLoader.exists(INPUT_ROUTER_PATH):
		return null
	var script: GDScript = load(INPUT_ROUTER_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return add_child_autofree(script.new())


func _make_action_event(action_id: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action_id
	event.pressed = true
	return event


func _make_key_event(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = true
	return event


func _make_joy_button_event(button_index: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = true
	return event


func _property_names(payload: RefCounted) -> Array[StringName]:
	var names: Array[StringName] = []
	for property in payload.get_property_list():
		names.append(property.name)
	return names


func _action_has_key_event(action_id: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action_id):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false


func _action_has_joy_button_event(action_id: StringName, button_index: JoyButton) -> bool:
	for event in InputMap.action_get_events(action_id):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false
