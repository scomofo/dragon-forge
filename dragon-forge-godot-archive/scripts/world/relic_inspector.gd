extends Node3D
class_name RelicInspector

var relic_resource: Relic
var relic_instance: Node3D
var is_dragging := false

func inspect_relic(relic: Relic) -> void:
	relic_resource = relic
	if relic_instance != null and is_instance_valid(relic_instance):
		relic_instance.queue_free()
		relic_instance = null
	if relic.physical_model != null:
		var instance := relic.physical_model.instantiate()
		if instance is Node3D:
			relic_instance = instance
			add_child(relic_instance)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		is_dragging = event.pressed
	elif event is InputEventMouseMotion and is_dragging and relic_instance != null:
		rotate_relic(event.relative)

func rotate_relic(relative: Vector2) -> void:
	if relic_instance == null:
		return
	relic_instance.rotate_y(relative.x * 0.01)
	relic_instance.rotate_x(relative.y * 0.01)

func current_bypass_code() -> String:
	if relic_resource == null:
		return ""
	return relic_resource.bypass_code
