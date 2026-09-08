extends Node
## Runs after the original actor has moved, resolved combat and sampled its rig.
var review
func _ready() -> void:
	process_physics_priority = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
func _physics_process(delta: float) -> void:
	if is_instance_valid(review):
		if get_tree().paused:
			review.stop_replay()
			return
		review.observe_frame(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11]:
		review.review_key(event.physical_keycode)
		get_viewport().set_input_as_handled()
