class_name SemanticActionPayload
extends RefCounted

## Typed semantic input payload consumed by feature systems.
## Hardware details stay inside InputRouter and are not exposed here.

var action_id: StringName = &""
var context_id: StringName = &""
var input_mode: StringName = &""
var is_pressed: bool = false
var is_echo: bool = false


func configure(
		action: StringName,
		context: StringName,
		mode: StringName,
		pressed: bool,
		echo: bool
) -> SemanticActionPayload:
	action_id = action
	context_id = context
	input_mode = mode
	is_pressed = pressed
	is_echo = echo
	return self
