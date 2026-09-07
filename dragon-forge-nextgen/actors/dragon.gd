extends CharacterBody3D
const Combat = preload("res://sim/combat.gd")
const Rig = preload("res://presentation/dragon_rig.gd")
const Geo = preload("res://presentation/geometry.gd")
signal ability_started(id: String)
signal ability_used(id: String, origin: Vector3, direction: Vector3)
signal damaged(amount: float, guarded: bool)
signal died
signal hint(text: String)
var state = Combat.fresh()
var active = false
var reduced_motion = false
var aim = Vector3.FORWARD
var dash_direction = Vector3.FORWARD
var mouse_aim = false
var input_grace = 0.15
var rig: Node3D
var guard_ring: MeshInstance3D
var aim_marker: Node3D
var committed_aim = Vector3.FORWARD
var buffered_id = ""
var buffer_time = 0.0
const BUFFER_WINDOW = 0.16

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1 | 4
	var collider = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.58
	capsule.height = 2.1
	collider.shape = capsule
	collider.position.y = 1.05
	add_child(collider)
	rig = Rig.new()
	add_child(rig)
	guard_ring = Geo.ring(self, Vector3(0, 0.12, 0), 1.05, Geo.material(Geo.CYAN, 1.2, true))
	guard_ring.visible = false
	aim_marker = Node3D.new()
	add_child(aim_marker)
	for side in [-1, 1]:
		var arrow = Geo.box(aim_marker, Vector3(side * 0.15, 0.09, -2.05), Vector3(0.055, 0.04, 0.48), Geo.material(Geo.AMBER, 0.5, true))
		arrow.rotation.y = side * -0.65

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.relative.length() > 1.0:
		mouse_aim = true
	elif event is InputEventKey and event.pressed and event.physical_keycode in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
		mouse_aim = false
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.25:
		mouse_aim = false

func _physics_process(delta: float) -> void:
	rig.visible = active
	aim_marker.visible = active
	if not active:
		return
	input_grace = maxf(0.0, input_grace - delta)
	advance_combat(delta, Input.is_action_pressed("ng_guard") and input_grace <= 0.0)
	var movement = Input.get_vector("ng_left", "ng_right", "ng_up", "ng_down") if input_grace <= 0.0 else Vector2.ZERO
	var direction = Vector3(movement.x, 0, movement.y)
	if direction.length() > 0.1 and not mouse_aim:
		aim = direction.normalized()
	var stick = Input.get_vector("ng_aim_left", "ng_aim_right", "ng_aim_up", "ng_aim_down")
	if stick.length() > 0.2:
		aim = Vector3(stick.x, 0, stick.y).normalized()
	elif mouse_aim:
		_update_mouse_aim()
	if state.hp > 0.0 and input_grace <= 0.0:
		if Input.is_action_just_pressed("ng_dodge") and Combat.dodge(state):
			dash_direction = direction.normalized() if direction.length() > 0.1 else aim
			buffered_id = ""
		for id in Combat.ORDER:
			if Input.is_action_just_pressed("ng_" + id):
				try_ability(id)
	var speed = 2.8 if state.guard else (3.8 if state.action != "" else 6.2)
	var desired = dash_direction * 17.0 if state.dash > 0.0 else direction * speed
	if state.hp <= 0.0:
		desired = Vector3.ZERO
	velocity.x = move_toward(velocity.x, desired.x, delta * 65.0)
	velocity.z = move_toward(velocity.z, desired.z, delta * 65.0)
	velocity.y = -1.0 if is_on_floor() else velocity.y - 25.0 * delta
	move_and_slide()
	var facing: Vector3 = committed_aim if state.action != "" else aim
	rig.rotation.y = lerp_angle(rig.rotation.y, atan2(-facing.x, -facing.z), minf(delta * 18.0, 1.0))
	rig.animate(delta, Vector2(velocity.x, velocity.z).length(), reduced_motion, state)
	aim_marker.rotation.y = atan2(-facing.x, -facing.z)
	aim_marker.visible = state.hp > 0.0
	guard_ring.visible = state.guard and state.hp > 0.0

func _update_mouse_aim() -> void:
	var camera = get_viewport().get_camera_3d()
	if camera == null:
		return
	var pointer = get_viewport().get_mouse_position()
	var hit = Plane(Vector3.UP, 0.0).intersects_ray(camera.project_ray_origin(pointer), camera.project_ray_normal(pointer))
	if hit != null:
		var offset: Vector3 = hit - global_position
		offset.y = 0.0
		if offset.length() > 0.4:
			aim = offset.normalized()

func try_ability(id: String) -> bool:
	if not active or get_tree().paused or input_grace > 0.0:
		return false
	if not Combat.cast(state, id):
		# A single bounded input buffer, never a queue of delayed attacks.
		if Combat.ABILITIES.has(id) and state.hp > 0.0 and not state.guard and state.dash <= 0.0 and state.heat + Combat.ABILITIES[id].heat <= 100.0:
			var wait = maxf(Combat.action_remaining(state), state.cooldowns.get(id, 0.0))
			if wait > 0.0 and wait <= BUFFER_WINDOW:
				buffered_id = id
				buffer_time = BUFFER_WINDOW
				return false
		hint.emit(Combat.rejection(state, id))
		return false
	committed_aim = aim
	buffered_id = ""
	ability_started.emit(id)
	return true

func receive_damage(amount: float) -> float:
	var guarded: bool = state.guard
	var applied = Combat.damage(state, amount)
	if applied > 0.0:
		rig.hurt(guarded)
		damaged.emit(applied, guarded)
		if state.hp <= 0.0:
			died.emit()
	return applied

func respawn(at: Vector3) -> void:
	state = Combat.fresh()
	global_position = at
	velocity = Vector3.ZERO
	input_grace = 0.2
	buffered_id = ""
	buffer_time = 0.0
	rig.reset_pose()
	aim = Vector3.FORWARD

## The authoritative contact clock is simulation-driven, not a tween callback.
func advance_combat(delta: float, guarding: bool = false) -> void:
	var impact: String = Combat.tick(state, delta, guarding)
	if impact != "" and active and state.hp > 0.0:
		ability_used.emit(impact, global_position, committed_aim)
	if buffered_id != "":
		buffer_time -= maxf(delta, 0.0)
		if buffer_time < 0.0 or state.hp <= 0.0 or guarding or state.dash > 0.0:
			buffered_id = ""
		elif Combat.rejection(state, buffered_id) == "":
			try_ability(buffered_id)
