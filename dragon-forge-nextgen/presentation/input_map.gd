extends RefCounted
## Namespaced actions: keyboard, mouse buttons and standard mapped gamepads.
static func setup() -> void:
	var keys = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "claw": [KEY_1, KEY_J], "breath": [KEY_2, KEY_K], "wall": [KEY_3, KEY_L], "burst": [KEY_4, KEY_I], "dodge": [KEY_SPACE], "guard": [KEY_SHIFT], "interact": [KEY_E], "menu": [KEY_ESCAPE, KEY_F1], "retry": [KEY_R], "aim_left": [], "aim_right": [], "aim_up": [], "aim_down": []}
	for id in keys:
		var action = "ng_" + id
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.22)
		for code in keys[id]:
			var key = InputEventKey.new()
			key.physical_keycode = code
			InputMap.action_add_event(action, key)
	var buttons = {"claw": JOY_BUTTON_X, "breath": JOY_BUTTON_Y, "wall": JOY_BUTTON_LEFT_SHOULDER, "burst": JOY_BUTTON_RIGHT_SHOULDER, "dodge": JOY_BUTTON_A, "interact": JOY_BUTTON_B, "menu": JOY_BUTTON_START, "left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT, "up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN}
	for id in buttons:
		var button = InputEventJoypadButton.new()
		button.button_index = buttons[id]
		InputMap.action_add_event("ng_" + id, button)
	for mapping in [["left", JOY_AXIS_LEFT_X, -1.0], ["right", JOY_AXIS_LEFT_X, 1.0], ["up", JOY_AXIS_LEFT_Y, -1.0], ["down", JOY_AXIS_LEFT_Y, 1.0], ["aim_left", JOY_AXIS_RIGHT_X, -1.0], ["aim_right", JOY_AXIS_RIGHT_X, 1.0], ["aim_up", JOY_AXIS_RIGHT_Y, -1.0], ["aim_down", JOY_AXIS_RIGHT_Y, 1.0], ["guard", JOY_AXIS_TRIGGER_LEFT, 1.0]]:
		var motion = InputEventJoypadMotion.new()
		motion.axis = mapping[1]
		motion.axis_value = mapping[2]
		InputMap.action_add_event("ng_" + mapping[0], motion)
