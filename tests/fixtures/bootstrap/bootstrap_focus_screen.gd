extends Control

var focus_button: Button = null


func _init() -> void:
	focus_button = Button.new()
	focus_button.name = "InitialFocus"
	focus_button.focus_mode = Control.FOCUS_ALL
	add_child(focus_button)


func get_initial_focus_control() -> Control:
	return focus_button
