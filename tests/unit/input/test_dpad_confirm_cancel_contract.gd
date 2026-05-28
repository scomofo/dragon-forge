extends GutTest

const FOCUS_NAVIGATION_CONTRACT_PATH: String = "res://src/input/focus_navigation_contract.gd"
const INPUT_ROUTER_PATH: String = "res://src/input/input_router.gd"


func test_required_flows_have_dpad_confirm_cancel_navigation_contracts() -> void:
	var contract: RefCounted = _make_contract()
	if contract == null:
		return

	for flow_id in [&"hub", &"shop", &"campaign_map", &"battle_telegraph", &"crown", &"terminals"]:
		assert_true(contract.has_flow_contract(flow_id), "Missing flow contract: %s" % flow_id)
		var flow: Dictionary = contract.get_flow_contract(flow_id)
		assert_true(flow.actions.has(&"ui_up") or flow.actions.has(&"ui_left"))
		assert_true(flow.actions.has(&"ui_down") or flow.actions.has(&"ui_right"))
		assert_true(flow.actions.has(&"ui_confirm"))
		assert_true(flow.actions.has(&"ui_cancel"))
		assert_false(flow.hover_required)


func test_shop_and_crown_row_navigation_stop_at_row_ends() -> void:
	var contract: RefCounted = _make_contract()
	if contract == null:
		return

	assert_eq(contract.move_row_focus(&"shop", 0, 4, &"left"), 0)
	assert_eq(contract.move_row_focus(&"shop", 3, 4, &"right"), 3)
	assert_eq(contract.move_row_focus(&"shop", 1, 4, &"right"), 2)
	assert_eq(contract.move_row_focus(&"crown", 0, 3, &"left"), 0)
	assert_eq(contract.move_row_focus(&"crown", 2, 3, &"right"), 2)
	assert_eq(contract.move_row_focus(&"crown", 2, 3, &"left"), 1)


func test_hub_row_wrap_is_explicitly_configured_by_gdd_exception() -> void:
	var contract: RefCounted = _make_contract()
	if contract == null:
		return

	assert_eq(contract.move_row_focus(&"hub", 0, 7, &"left"), 6)
	assert_eq(contract.move_row_focus(&"hub", 6, 7, &"right"), 0)


func test_keyboard_fallback_bindings_exist_for_required_navigation_actions() -> void:
	var router: Node = _make_router()
	if router == null:
		return

	router.ensure_input_map_actions()

	assert_true(_action_has_key_event(&"ui_up", KEY_UP))
	assert_true(_action_has_key_event(&"ui_down", KEY_DOWN))
	assert_true(_action_has_key_event(&"ui_left", KEY_LEFT))
	assert_true(_action_has_key_event(&"ui_right", KEY_RIGHT))
	assert_true(_action_has_key_event(&"ui_confirm", KEY_ENTER))
	assert_true(_action_has_key_event(&"ui_cancel", KEY_ESCAPE))


func _make_contract() -> RefCounted:
	assert_true(ResourceLoader.exists(FOCUS_NAVIGATION_CONTRACT_PATH), "FocusNavigationContract script should exist.")
	if not ResourceLoader.exists(FOCUS_NAVIGATION_CONTRACT_PATH):
		return null
	var script: GDScript = load(FOCUS_NAVIGATION_CONTRACT_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func _make_router() -> Node:
	assert_true(ResourceLoader.exists(INPUT_ROUTER_PATH), "InputRouter script should exist.")
	if not ResourceLoader.exists(INPUT_ROUTER_PATH):
		return null
	var script: GDScript = load(INPUT_ROUTER_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return add_child_autofree(script.new())


func _action_has_key_event(action_id: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action_id):
		if event is InputEventKey and event.keycode == keycode:
			return true
	return false
