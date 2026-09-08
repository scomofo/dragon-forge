extends SceneTree
## Device-independent controller safety and GUI routing. Synthetic Godot events
## verify the shipped bindings; physical hardware feel and OS mappings remain manual.
const World = preload("res://campaign/world.gd")
const Rules = preload("res://campaign/progress.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	root.size = Vector2i(1280, 720)
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + label)

func frames(count: int = 2) -> void:
	for _i in range(count):
		await process_frame

func joy_button(index: JoyButton, device: int = 0) -> void:
	var event = InputEventJoypadButton.new()
	event.device = device
	event.button_index = index
	event.pressed = true
	event.pressure = 1.0
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	event.pressure = 0.0
	Input.parse_input_event(event)
	await process_frame

func joy_motion(axis: JoyAxis, value: float, device: int = 0) -> void:
	var event = InputEventJoypadMotion.new()
	event.device = device
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.axis_value = 0.0
	Input.parse_input_event(event)
	await process_frame

func action_press(action: String) -> void:
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await process_frame

func _run() -> void:
	var world = World.new()
	world.test_mode = true
	root.add_child(world)
	await frames(4)
	Rules.hatch(world.campaign)
	world._enter_room("forge", true)
	await frames(4)
	world.dragon.input_grace = 0.0
	var actor_before: Dictionary = world.dragon.state.duplicate(true)

	await joy_button(JOY_BUTTON_START)
	check(paused and world.hud.menu.visible, "joypad Start opens the real pause menu")
	check(world.hud.resume_button.has_focus(), "controller pause seeds focus on Resume")
	var resume = world.hud.resume_button
	await joy_button(JOY_BUTTON_DPAD_DOWN)
	var next_focus = root.gui_get_focus_owner()
	check(next_focus != null and next_focus != resume and world.hud.menu.is_ancestor_of(next_focus), "D-pad moves focus through the pause menu")
	await joy_button(JOY_BUTTON_DPAD_UP)
	check(resume.has_focus(), "D-pad can return focus to Resume")
	await joy_button(JOY_BUTTON_A)
	check(not paused and not world.hud.menu.visible, "joypad A activates focused Resume")
	await joy_button(JOY_BUTTON_BACK)
	var utility_routes = world.hud.overlay_column.find_child("UtilityRoutes", true, false)
	check(paused and world.hud.overlay_kind == "utility" and utility_routes != null and utility_routes.has_focus(), "View/Back opens the focused controller utility")
	await joy_button(JOY_BUTTON_A)
	check(paused and world.hud.overlay_kind == "map", "joypad A opens Routes from the utility overlay")
	await joy_button(JOY_BUTTON_START)
	check(not paused and not world.hud.overlay.visible, "Start closes the controller-opened route overlay")
	world.dragon.state.hp -= 60.0
	var repairs_before: int = world.repairs
	await joy_motion(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	check(world.repairs == repairs_before - 1 and world.dragon.state.hp == actor_before.hp, "right trigger invokes the real finite Repair action")

	Input.action_press("ng_up")
	Input.action_press("ng_guard")
	await physics_frame
	await physics_frame
	var stopped_at: Vector3 = world.dragon.position
	var resources_before = {"campaign": world.campaign.duplicate(true), "hp": world.dragon.state.hp, "heat": world.dragon.state.heat, "cooldowns": world.dragon.state.cooldowns.duplicate(true), "repairs": world.repairs}
	world.hud._on_joy_connection_changed(1, false)
	check(not paused, "disconnecting an unrelated controller does not interrupt the active device")
	world.hud._on_joy_connection_changed(0, false)
	await frames()
	check(paused and world.hud.menu.visible and world.hud.controller_disconnected, "controller loss safely pauses live gameplay")
	check(world.hud.controller_notice.visible and "DISCONNECTED" in world.hud.controller_notice.text, "controller loss presents a visible recovery notice")
	check(world.hud.resume_button.has_focus(), "controller loss restores focus to Resume")
	check(not Input.is_action_pressed("ng_up") and not Input.is_action_pressed("ng_guard"), "controller loss releases held gameplay actions")
	check(world.campaign == resources_before.campaign and world.dragon.state.hp == resources_before.hp and world.dragon.state.heat == resources_before.heat and world.dragon.state.cooldowns == resources_before.cooldowns and world.repairs == resources_before.repairs and world.dragon.position == stopped_at, "disconnect pause preserves campaign and combat resources")

	world.hud._on_joy_connection_changed(3, true)
	await frames()
	check(paused and world.hud.menu.visible and not world.hud.controller_disconnected, "replacement controller never resumes gameplay automatically")
	check(world.hud.active_joypad_device == 3 and world.hud.controller_notice.visible and "RECONNECTED" in world.hud.controller_notice.text and world.hud.resume_button.has_focus(), "re-enumerated controller becomes active and focuses explicit Resume")
	# Headless Input rejects raw events for a device ID it has not enumerated;
	# the earlier A assertion covers the joypad mapping and this checks the GUI
	# resume action independently after mocked replacement-device connection.
	await action_press("ui_accept")
	await frames()
	check(not paused and not world.hud.menu.visible, "explicit accept resumes after replacement-controller connection")
	await physics_frame
	check(not Input.is_action_pressed("ng_up") and not Input.is_action_pressed("ng_guard") and not world.dragon.state.guard and world.dragon.position == stopped_at, "released controller state cannot leak movement or guard after resume")
	check(world.campaign == resources_before.campaign and world.dragon.state.hp == resources_before.hp and world.dragon.state.heat == resources_before.heat and world.dragon.state.cooldowns == resources_before.cooldowns and world.repairs == resources_before.repairs, "controller recovery does not mutate progress or combat resources")

	world.queue_free()
	await frames()
	print("CONTROLLER_RUNTIME_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
