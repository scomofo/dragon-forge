extends Node3D
var target
var opponent
var reduced_motion = false
var camera: Camera3D
var trauma = 0.0
var clock = 0.0
# Defaults preserve the prototype; campaign bosses opt into a wider shared focus.
var opponent_weight = 0.22
var opponent_limit = 4.0
var focus_height = 0.7
var view_distance = 14.0
var settled_distance = 14.0

func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 14, 14)
	camera.fov = 49.0
	camera.far = 160.0
	camera.current = true
	add_child(camera)
	if is_instance_valid(target):
		global_position = target.global_position
	camera.look_at(global_position + Vector3.UP * focus_height)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	clock += delta
	trauma = maxf(0.0, trauma - delta * 2.0)
	var focus: Vector3 = target.global_position
	if is_instance_valid(opponent):
		focus += (opponent.global_position - focus).limit_length(opponent_limit) * opponent_weight
	global_position = global_position.lerp(focus, 1.0 - exp(-delta * 6.0))
	var shake = Vector3.ZERO if reduced_motion else Vector3(sin(clock * 48.0), cos(clock * 43.0), 0) * trauma * 0.12
	settled_distance = lerpf(settled_distance,view_distance,1.0-exp(-delta*6.0))
	camera.position = Vector3(0, settled_distance, settled_distance) + shake
	camera.look_at(global_position + Vector3.UP * focus_height)

func impact() -> void:
	if not reduced_motion:
		trauma = 0.45
