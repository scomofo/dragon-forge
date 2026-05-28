extends GutTest

const InputRouterScript = preload("res://src/input/input_router.gd")
const SemanticActionPayload = preload("res://src/input/semantic_action_payload.gd")

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
	&"battle_counter",
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


func test_tritone_window_counter_confirm_emits_canonical_battle_defend() -> void:
	var router: InputRouter = _make_router()
	if router == null:
		return
	assert_true(router.has_method("set_focused_semantic_action"), "InputRouter should track the focused battle action.")
	assert_false(router.has_method("set_tritone_window_open"), "InputRouter should not own Singularity tritone_window state.")
	if not router.has_method("set_focused_semantic_action"):
		return
	var received: Array[SemanticActionPayload] = []
	var rejected: Array[SemanticActionPayload] = []
	var on_action: Callable = func(payload: SemanticActionPayload) -> void:
		received.append(payload)
	var on_rejected: Callable = func(payload: SemanticActionPayload) -> void:
		rejected.append(payload)
	router.semantic_action.connect(on_action)
	router.semantic_action_rejected.connect(on_rejected)

	router.set_context(&"battle_telegraph")
	assert_true(_focus_counter_presentation(router, true))
	assert_true(router.route_input_event(_make_action_event(&"ui_confirm")))
	router.semantic_action.disconnect(on_action)
	router.semantic_action_rejected.disconnect(on_rejected)

	assert_eq(received.size(), 1)
	assert_eq(rejected.size(), 0)
	assert_eq(received[0].action_id, &"battle_defend")
	assert_eq(received[0].context_id, &"battle_telegraph")


func test_tritone_window_closed_confirm_routes_normal_defend_when_legal() -> void:
	var router: InputRouter = _make_router()
	if router == null:
		return
	if not router.has_method("set_focused_semantic_action"):
		assert_true(false, "InputRouter should expose focused action routing.")
		return
	var received: Array[SemanticActionPayload] = []
	var on_action: Callable = func(payload: SemanticActionPayload) -> void:
		received.append(payload)
	router.semantic_action.connect(on_action)

	router.set_context(&"battle_telegraph")
	assert_true(_focus_counter_presentation(router, false))
	assert_true(router.route_input_event(_make_action_event(&"ui_confirm")))
	router.semantic_action.disconnect(on_action)

	assert_eq(received.size(), 1)
	assert_eq(received[0].action_id, &"battle_defend")


func test_disabled_defend_confirm_rejects_without_gameplay_action() -> void:
	var router: InputRouter = _make_router()
	if router == null:
		return
	if not router.has_method("set_focused_semantic_action"):
		assert_true(false, "InputRouter should expose focused action routing.")
		return
	var received: Array[SemanticActionPayload] = []
	var rejected: Array[SemanticActionPayload] = []
	var on_action: Callable = func(payload: SemanticActionPayload) -> void:
		received.append(payload)
	var on_rejected: Callable = func(payload: SemanticActionPayload) -> void:
		rejected.append(payload)
	router.semantic_action.connect(on_action)
	router.semantic_action_rejected.connect(on_rejected)

	router.set_context(&"battle_telegraph")
	assert_true(_focus_counter_presentation(router, true))
	router.set_action_disabled(&"battle_defend", true)
	assert_false(router.route_input_event(_make_action_event(&"ui_confirm")))
	router.semantic_action.disconnect(on_action)
	router.semantic_action_rejected.disconnect(on_rejected)

	assert_eq(received.size(), 0)
	assert_eq(rejected.size(), 1)
	assert_eq(rejected[0].action_id, &"battle_defend")
	assert_eq(rejected[0].context_id, &"battle_telegraph")


func test_no_mvp_battle_counter_action_or_raw_payload_fields_exist() -> void:
	var router: InputRouter = _make_router()
	if router == null:
		return
	router.ensure_input_map_actions()
	if not router.has_method("get_mvp_action_ids"):
		assert_true(false, "InputRouter should expose MVP action IDs for routing-contract tests.")
		return

	assert_false(router.get_mvp_action_ids().has(&"battle_counter"))
	assert_false(InputMap.has_action(&"battle_counter"))

	var received: Array[SemanticActionPayload] = []
	var on_action: Callable = func(payload: SemanticActionPayload) -> void:
		received.append(payload)
	router.semantic_action.connect(on_action)
	router.set_context(&"battle_telegraph")
	_focus_counter_presentation(router, true)
	router.route_input_event(_make_action_event(&"ui_confirm"))
	router.semantic_action.disconnect(on_action)

	assert_eq(received.size(), 1)
	var property_names: Array[StringName] = _property_names(received[0])
	assert_false(property_names.has(&"raw_event"))
	assert_false(property_names.has(&"button_index"))
	assert_false(property_names.has(&"keycode"))
	assert_false(property_names.has(&"device"))


func _focus_counter_presentation(router: InputRouter, tritone_window_open: bool) -> bool:
	var presentation_context: StringName = &"counter_ready" if tritone_window_open else &"defend"
	assert_true([&"counter_ready", &"defend"].has(presentation_context))
	return router.set_focused_semantic_action(&"battle_defend")


func _make_router() -> InputRouter:
	assert_true(ResourceLoader.exists(INPUT_ROUTER_PATH), "InputRouter script should exist.")
	if not ResourceLoader.exists(INPUT_ROUTER_PATH):
		return null
	var router: InputRouter = InputRouterScript.new()
	return add_child_autofree(router)


func _make_action_event(action_id: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action_id
	event.pressed = true
	return event


func _property_names(payload: SemanticActionPayload) -> Array[StringName]:
	var names: Array[StringName] = []
	for property in payload.get_property_list():
		names.append(property.name)
	return names
