# InputRouter — autoload stub for Plan 2.
# Full gamepad / keyboard remapping in Plan 3.
extends Node

signal action_pressed(action: String)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("confirm"):
		action_pressed.emit("confirm")
	elif event.is_action_pressed("cancel"):
		action_pressed.emit("cancel")
