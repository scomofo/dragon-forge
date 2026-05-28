extends GutTest

const INPUT_ROUTER_PATH: String = "res://src/input/input_router.gd"


func test_mouse_hover_tracking_does_not_steal_keyboard_gamepad_focus() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var primary_button: Button = Button.new()
	var hovered_button: Button = Button.new()
	var root: Control = _make_focus_root([primary_button, hovered_button])
	add_child_autofree(root)

	assert_true(router.request_focus(primary_button))
	await get_tree().process_frame
	assert_eq(root.get_viewport().gui_get_focus_owner(), primary_button)

	router.record_hovered_control(hovered_button)
	await get_tree().process_frame

	assert_eq(router.get_hovered_control(), hovered_button)
	assert_eq(router.get_input_mode(), &"mouse_touch")
	assert_eq(root.get_viewport().gui_get_focus_owner(), primary_button)


func test_disabled_actions_reject_confirm_without_gameplay_action() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var gameplay_actions: Array[RefCounted] = []
	var rejected_actions: Array[RefCounted] = []
	var on_gameplay_action: Callable = func(payload: RefCounted) -> void:
		gameplay_actions.append(payload)
	var on_rejected_action: Callable = func(payload: RefCounted) -> void:
		rejected_actions.append(payload)
	router.semantic_action.connect(on_gameplay_action)
	router.semantic_action_rejected.connect(on_rejected_action)

	router.set_context(&"battle_telegraph")
	router.set_action_disabled(&"battle_attack", true)
	assert_false(router.route_input_event(_make_action_event(&"battle_attack")))

	router.semantic_action.disconnect(on_gameplay_action)
	router.semantic_action_rejected.disconnect(on_rejected_action)
	assert_eq(gameplay_actions.size(), 0)
	assert_eq(rejected_actions.size(), 1)
	assert_eq(rejected_actions[0].action_id, &"battle_attack")
	assert_eq(rejected_actions[0].context_id, &"battle_telegraph")


func test_focus_can_restore_to_requested_control_after_transition() -> void:
	var router: Node = _make_router()
	if router == null:
		return
	var old_focus: Button = Button.new()
	var next_focus: Button = Button.new()
	var disabled_focus: Button = Button.new()
	disabled_focus.disabled = true
	var root: Control = _make_focus_root([old_focus, next_focus, disabled_focus])
	add_child_autofree(root)
	var restored_controls: Array[Control] = []
	var failed_reasons: Array[StringName] = []
	var on_restored: Callable = func(control: Control) -> void:
		restored_controls.append(control)
	var on_failed: Callable = func(reason: StringName) -> void:
		failed_reasons.append(reason)
	router.focus_restored.connect(on_restored)
	router.focus_restore_failed.connect(on_failed)

	assert_true(router.request_focus(old_focus))
	await get_tree().process_frame
	assert_eq(root.get_viewport().gui_get_focus_owner(), old_focus)
	assert_true(router.restore_focus_after_transition(next_focus))
	await get_tree().process_frame
	assert_eq(root.get_viewport().gui_get_focus_owner(), next_focus)
	assert_false(router.restore_focus_after_transition(disabled_focus))
	await get_tree().process_frame

	router.focus_restored.disconnect(on_restored)
	router.focus_restore_failed.disconnect(on_failed)
	assert_eq(root.get_viewport().gui_get_focus_owner(), next_focus)
	assert_eq(restored_controls.size(), 2)
	assert_eq(restored_controls[1], next_focus)
	assert_eq(failed_reasons, [&"control_disabled"])


func _make_router() -> Node:
	assert_true(ResourceLoader.exists(INPUT_ROUTER_PATH), "InputRouter script should exist.")
	if not ResourceLoader.exists(INPUT_ROUTER_PATH):
		return null
	var script: GDScript = load(INPUT_ROUTER_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return add_child_autofree(script.new())


func _make_focus_root(children: Array) -> Control:
	var root: Control = Control.new()
	root.name = "DualFocusRoot"
	for index in children.size():
		var control: Control = children[index]
		control.name = "FocusTarget%s" % index
		control.focus_mode = Control.FOCUS_ALL
		control.visible = true
		root.add_child(control)
	return root


func _make_action_event(action_id: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action_id
	event.pressed = true
	return event
