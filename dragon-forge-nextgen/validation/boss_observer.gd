extends Node
var review
func _ready() -> void:
	process_physics_priority=100
	process_mode=Node.PROCESS_MODE_ALWAYS
func _physics_process(_delta: float) -> void:
	if is_instance_valid(review) and not get_tree().paused: review.observe_frame()
func _input(event: InputEvent) -> void:
	if not is_instance_valid(review) or not get_tree().paused: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_F10 and review.contact_paused:
			review.contact_paused=false
			get_tree().paused=false
			get_viewport().set_input_as_handled()
		elif event.keycode==KEY_F7:
			review.review_panel.visible=not review.review_panel.visible
			get_viewport().set_input_as_handled()
