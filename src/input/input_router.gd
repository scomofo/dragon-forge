class_name InputRouter
extends Node

## Foundation input service that converts Godot input events into semantic action IDs.
## Feature systems subscribe to semantic_action and never receive raw hardware events.

signal semantic_action(payload: SemanticActionPayload)
signal semantic_action_rejected(payload: SemanticActionPayload)
signal input_mode_changed(mode: StringName)
signal hovered_control_changed(control: Control)
signal focus_restored(control: Control)
signal focus_restore_failed(reason: StringName)

const SemanticActionPayloadResource = preload("res://src/input/semantic_action_payload.gd")

const CONTEXT_UI: StringName = &"ui"
const CONTEXT_BATTLE_TELEGRAPH: StringName = &"battle_telegraph"
const CONTEXT_CAMPAIGN_MAP: StringName = &"campaign_map"

const INPUT_MODE_GAMEPAD: StringName = &"gamepad"
const INPUT_MODE_KEYBOARD: StringName = &"keyboard"
const INPUT_MODE_MOUSE_TOUCH: StringName = &"mouse_touch"

const MVP_ACTION_IDS: Array[StringName] = [
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

const DEFAULT_KEY_BINDINGS: Dictionary[StringName, Array] = {
	&"ui_up": [KEY_UP, KEY_W],
	&"ui_down": [KEY_DOWN, KEY_S],
	&"ui_left": [KEY_LEFT, KEY_A],
	&"ui_right": [KEY_RIGHT, KEY_D],
	&"ui_confirm": [KEY_ENTER, KEY_SPACE],
	&"ui_cancel": [KEY_ESCAPE, KEY_BACKSPACE],
}

const DEFAULT_JOYPAD_BUTTON_BINDINGS: Dictionary[StringName, Array] = {
	&"ui_up": [JOY_BUTTON_DPAD_UP],
	&"ui_down": [JOY_BUTTON_DPAD_DOWN],
	&"ui_left": [JOY_BUTTON_DPAD_LEFT],
	&"ui_right": [JOY_BUTTON_DPAD_RIGHT],
	&"ui_confirm": [JOY_BUTTON_A],
	&"ui_cancel": [JOY_BUTTON_B],
}

const CONTEXT_ACTIONS: Dictionary[StringName, Array] = {
	CONTEXT_UI: [
		&"ui_up",
		&"ui_down",
		&"ui_left",
		&"ui_right",
		&"ui_confirm",
		&"ui_cancel",
	],
	CONTEXT_BATTLE_TELEGRAPH: [
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
	],
	CONTEXT_CAMPAIGN_MAP: [
		&"ui_up",
		&"ui_down",
		&"ui_left",
		&"ui_right",
		&"ui_confirm",
		&"ui_cancel",
		&"map_pan",
	],
}

var _context_id: StringName = CONTEXT_UI
var _input_mode: StringName = INPUT_MODE_KEYBOARD
var _input_map_actions_ready: bool = false
var _hovered_control: Control = null
var _disabled_actions: Dictionary[StringName, bool] = {}
var _focused_semantic_actions: Dictionary[StringName, StringName] = {}


func ensure_input_map_actions() -> void:
	if _input_map_actions_ready:
		return
	for action_id in MVP_ACTION_IDS:
		if not InputMap.has_action(action_id):
			InputMap.add_action(action_id)
		_ensure_default_bindings(action_id)
	_input_map_actions_ready = true


func set_context(context_id: StringName) -> void:
	_context_id = context_id


func get_context() -> StringName:
	return _context_id


func get_input_mode() -> StringName:
	return _input_mode


func get_mvp_action_ids() -> Array[StringName]:
	return MVP_ACTION_IDS.duplicate()


func is_action_enabled(action_id: StringName) -> bool:
	var allowed_actions: Array = CONTEXT_ACTIONS.get(_context_id, [])
	return allowed_actions.has(action_id)


func set_action_disabled(action_id: StringName, disabled: bool = true) -> void:
	if disabled:
		_disabled_actions[action_id] = true
	else:
		_disabled_actions.erase(action_id)


func clear_disabled_actions() -> void:
	_disabled_actions.clear()


func is_action_disabled(action_id: StringName) -> bool:
	return _disabled_actions.get(action_id, false)


func set_focused_semantic_action(action_id: StringName) -> bool:
	if action_id == &"" or not is_action_enabled(action_id):
		return false
	_focused_semantic_actions[_context_id] = action_id
	return true


func clear_focused_semantic_action(context_id: StringName = &"") -> void:
	var target_context: StringName = _context_id if context_id == &"" else context_id
	_focused_semantic_actions.erase(target_context)


func get_focused_semantic_action() -> StringName:
	return _focused_semantic_actions.get(_context_id, &"")


func route_input_event(event: InputEvent) -> bool:
	if event == null:
		return false
	ensure_input_map_actions()

	var action_id: StringName = _semantic_action_from_event(event)
	if action_id == &"ui_confirm":
		action_id = _action_for_focused_confirm(action_id)
	if action_id == &"" or not is_action_enabled(action_id):
		return false

	_update_input_mode(event)
	var payload: SemanticActionPayload = _make_payload(action_id, event)
	if is_action_disabled(action_id):
		semantic_action_rejected.emit(payload)
		return false
	semantic_action.emit(payload)
	return true


func record_hovered_control(control: Control) -> void:
	if _hovered_control == control:
		return
	_hovered_control = control
	_set_input_mode(INPUT_MODE_MOUSE_TOUCH)
	hovered_control_changed.emit(control)


func get_hovered_control() -> Control:
	return _hovered_control


func request_focus(control: Control) -> bool:
	var failure_reason: StringName = _focus_failure_reason(control)
	if failure_reason != &"":
		focus_restore_failed.emit(failure_reason)
		return false
	control.grab_focus()
	focus_restored.emit(control)
	return true


func restore_focus_after_transition(control: Control) -> bool:
	return request_focus(control)


func _semantic_action_from_event(event: InputEvent) -> StringName:
	for action_id in MVP_ACTION_IDS:
		if event.is_action_pressed(action_id) or event.is_action_released(action_id):
			return action_id
	return &""


func _action_for_focused_confirm(confirm_action_id: StringName) -> StringName:
	if _context_id != CONTEXT_BATTLE_TELEGRAPH:
		return confirm_action_id
	var focused_action_id: StringName = get_focused_semantic_action()
	if focused_action_id == &"":
		return confirm_action_id
	return focused_action_id


func _make_payload(action_id: StringName, event: InputEvent) -> SemanticActionPayload:
	return SemanticActionPayloadResource.new().configure(
		action_id,
		_context_id,
		_input_mode,
		_is_event_pressed(event),
		_is_event_echo(event)
	)


func _ensure_default_bindings(action_id: StringName) -> void:
	for keycode in DEFAULT_KEY_BINDINGS.get(action_id, []):
		_add_event_if_missing(action_id, _make_key_event(keycode))
	for button_index in DEFAULT_JOYPAD_BUTTON_BINDINGS.get(action_id, []):
		_add_event_if_missing(action_id, _make_joypad_button_event(button_index))


func _add_event_if_missing(action_id: StringName, event: InputEvent) -> void:
	for existing_event in InputMap.action_get_events(action_id):
		if _events_match(existing_event, event):
			return
	InputMap.action_add_event(action_id, event)


func _events_match(left: InputEvent, right: InputEvent) -> bool:
	if left is InputEventKey and right is InputEventKey:
		return left.keycode == right.keycode
	if left is InputEventJoypadButton and right is InputEventJoypadButton:
		return left.button_index == right.button_index
	return false


func _make_key_event(keycode: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	return event


func _make_joypad_button_event(button_index: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.button_index = button_index
	return event


func _update_input_mode(event: InputEvent) -> void:
	_set_input_mode(_mode_from_event(event))


func _set_input_mode(next_mode: StringName) -> void:
	if next_mode == _input_mode:
		return
	_input_mode = next_mode
	input_mode_changed.emit(_input_mode)


func _focus_failure_reason(control: Control) -> StringName:
	if control == null:
		return &"missing_control"
	if not control.is_inside_tree():
		return &"control_not_in_tree"
	if control.disabled:
		return &"control_disabled"
	if control.focus_mode == Control.FOCUS_NONE:
		return &"control_not_focusable"
	return &""


func _mode_from_event(event: InputEvent) -> StringName:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return INPUT_MODE_GAMEPAD
	if event is InputEventMouseButton or event is InputEventMouseMotion or event is InputEventScreenTouch:
		return INPUT_MODE_MOUSE_TOUCH
	return INPUT_MODE_KEYBOARD


func _is_event_pressed(event: InputEvent) -> bool:
	if event is InputEventAction:
		return event.pressed
	if event is InputEventKey:
		return event.pressed
	if event is InputEventJoypadButton:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventScreenTouch:
		return event.pressed
	return true


func _is_event_echo(event: InputEvent) -> bool:
	if event is InputEventKey:
		return event.echo
	return false
