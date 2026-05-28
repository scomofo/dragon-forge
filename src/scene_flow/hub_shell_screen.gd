class_name HubShellScreen
extends Control

## Minimal production-owned Hub shell used to make the root project launch smokeable.

const STATE_HUB_FLOOR: StringName = &"hub_floor"
const FOCUS_TARGET_NAME: String = "HatcheryRingFocus"

var _shell_state: StringName = STATE_HUB_FLOOR
var _focus_target: Button = null


func _init() -> void:
	name = "HubShell"
	focus_mode = Control.FOCUS_NONE
	_focus_target = Button.new()
	_focus_target.name = FOCUS_TARGET_NAME
	_focus_target.focus_mode = Control.FOCUS_ALL
	_focus_target.text = "Hatchery Ring"
	add_child(_focus_target)


func setup_screen(payload: Variant) -> bool:
	_shell_state = STATE_HUB_FLOOR
	set_meta("setup_source", _payload_source(payload))
	return true


func get_initial_focus_control() -> Control:
	return _focus_target


func get_shell_state() -> StringName:
	return _shell_state


func accepts_input() -> bool:
	return _shell_state == STATE_HUB_FLOOR


func _payload_source(payload: Variant) -> StringName:
	if payload is Dictionary:
		return payload.get("source", &"")
	return &""
