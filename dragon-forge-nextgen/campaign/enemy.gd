extends CharacterBody3D
## Campaign combat adapters reuse imported rigs but have distinct, readable attack sequences.
const Brain = preload("res://sim/enemy_brain.gd")
const Rig = preload("res://presentation/sentinel_rig.gd")
const Geo = preload("res://presentation/geometry.gd")
const Patterns = preload("res://campaign/patterns.gd")
signal defeated(id: String)
signal impact(payload: Dictionary, amount: float)
signal hit_feedback(at: Vector3, text: String, blocked: bool)
var spec: Dictionary = {}
var brain = Brain.new()
var target
var navigation
var boss = false
var hp = 100.0
var max_hp = 100.0
var reduced_motion = false
var visual: Node3D
var shield: MeshInstance3D
var tell: Node3D
var label: Label3D
var sequence = 0
var shape: Dictionary = {}
var pattern = "slam"
var warmup = 0.8
var hit_time = 0.0
var chilled = 0.0

func _ready() -> void:
	boss = spec.get("boss", false)
	max_hp = float(spec.get("hp", 100.0))
	hp = max_hp
	brain.boss = boss
	collision_layer = 4
	collision_mask = 1 | 2 | 4
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.70 if boss else 0.6
	capsule.height = 2.4
	collision.shape = capsule
	collision.position.y = 1.2
	add_child(collision)
	visual = Rig.new()
	visual.boss = boss
	add_child(visual)
	shield = Geo.cylinder(visual, Vector3(0, 1.4, -0.85), 1.08, 1.08, 0.03, Geo.material(Color(0.35, 0.76, 0.9, 0.20), 0.4, true), 6)
	shield.rotation.x = PI / 2.0
	var crown_color = Color(spec.get("color", "eabe80"))
	Geo.ring(self, Vector3(0, 0.15, 0), 1.2, Geo.material(crown_color, 0.6, true), 0.045)
	label = Geo.label(self, Vector3(0, 3.25, 0), spec.get("name", "Guardian"), crown_color)
	label.font_size = 24
	tell = Node3D.new()
	tell.name = "LockedAttackGeometry"
	get_parent().add_child.call_deferred(tell)

func _exit_tree() -> void:
	if is_instance_valid(tell):
		tell.queue_free()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(tell) or not tell.is_inside_tree() or not is_instance_valid(target) or brain.mode == "dead":
		return
	if target.state.hp <= 0.0:
		tell.visible = false
		return
	chilled=maxf(0.0,chilled-delta)
	label.text=spec.get("name","Guardian")+(" / CHILLED" if chilled>0.0 else "")
	warmup = maxf(0, warmup - delta)
	brain.enraged = boss and hp <= max_hp * 0.5
	var toward: Vector3 = target.global_position - global_position
	toward.y = 0.0
	if brain.mode == "seek" and warmup <= 0.0:
		if toward.length() <= (9.0 if boss else 6.5) and navigation.line_clear(global_position, target.global_position):
			_begin_attack()
	elif brain.mode != "seek":
		brain.timer = maxf(0.0, brain.timer - delta)
		if brain.timer <= 0.0:
			if brain.mode == "tell":
				brain.mode = "recover"
				brain.timer = 2.0 if boss else 2.3
				impact.emit(shape.duplicate(true), float(spec.damage))
			else:
				brain.mode = "seek"
				warmup = 0.3
	var direction = Vector3.ZERO
	if brain.mode == "seek" and warmup <= 0.0:
		direction = navigation.direction_to(global_position, target.global_position)
	velocity.x = direction.x * (2.8 if brain.enraged else 2.3)
	velocity.z = direction.z * (2.8 if brain.enraged else 2.3)
	velocity.x *= (0.6 if chilled>0.0 else 1.0)
	velocity.z *= (0.6 if chilled>0.0 else 1.0)
	velocity.y = -1 if is_on_floor() else velocity.y - 25 * delta
	move_and_slide()
	if brain.mode == "seek" and toward.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-toward.x, -toward.z), minf(delta * 7.0, 1.0))
	tell.visible = brain.mode == "tell"
	shield.visible = spec.get("shield", true) and not brain.vulnerable()
	hit_time = maxf(0.0, hit_time - delta)
	visual.rotation.x = hit_time * (0.10 if reduced_motion else 0.4)
	visual.animate(delta, brain, Vector2(velocity.x, velocity.z).length(), reduced_motion)

func _begin_attack() -> void:
	var list: Array = spec.get("patterns", ["slam"])
	if spec.id == "singularity-final":
		var phase = 1 if hp > max_hp * 0.66 else (2 if hp > max_hp * 0.33 else 3)
		list = list.slice(0, phase)
	pattern = list[sequence % list.size()]
	sequence += 1
	shape = Patterns.lock(pattern, global_position, target.global_position)
	brain.mode = "tell"
	brain.locked_duration = 1.15 if brain.enraged else (1.65 if boss else 1.5)
	brain.timer = brain.locked_duration
	for n in tell.get_children():
		tell.remove_child(n)
		n.queue_free()
	_draw_shape(shape)

func _draw_shape(data: Dictionary) -> void:
	var edge = Geo.material(Color("ffcc7e"), 0.3, true)
	var fill = Geo.material(Color(1.0, 0.28, 0.1, 0.17), 0.0, true)
	match data.kind:
		"beam":
			var center: Vector3 = data.origin + data.direction * (data.length / 2.0 - 0.4)
			center.y = 0.17
			var beam = Geo.box(tell, center, Vector3(data.half_width * 2, 0.015, data.length + 0.8), fill)
			beam.rotation.y = atan2(-data.direction.x, -data.direction.z)
			for side in [-1, 1]:
				var offset = data.direction.cross(Vector3.UP) * side * data.half_width
				var rail = Geo.box(tell, center + offset, Vector3(0.04, 0.02, data.length + 0.8), edge)
				rail.rotation.y = beam.rotation.y
		"ring":
			var at: Vector3 = data.origin
			at.y = 0.17
			Geo.ring(tell, at, data.outer, edge, 0.10)
			Geo.ring(tell, at, data.inner, Geo.material(Color("72dfc1"), 0.3, true), 0.10)
			for j in range(24):
				var a = TAU * j / 24.0
				var marker = Geo.box(tell, at + Vector3(sin(a),0,cos(a)) * 4.9, Vector3(0.06,0.02,3.6), fill)
				marker.rotation.y = a
		_:
			for center in data.circles:
				var at: Vector3 = center
				at.y = 0.17
				Geo.ring(tell, at, data.radius, edge, 0.07)
				Geo.cylinder(tell, at, data.radius, data.radius, 0.012, fill, 40)

func take_hit(amount: float, bypass_shield: bool = false) -> float:
	if hp <= 0.0 or amount <= 0.0 or is_queued_for_deletion():
		return 0.0
	if spec.get("shield", true) and not bypass_shield and not brain.vulnerable():
		hit_feedback.emit(global_position, "SHIELDED", true)
		return 0.0
	var actual = minf(hp, amount)
	hp -= actual
	hit_time = 0.15
	hit_feedback.emit(global_position, str(int(actual)), false)
	if hp <= 0.0:
		brain.kill()
		defeated.emit(spec.id)
		queue_free()
	return actual

func overload() -> void:
	brain.open_window(2.4)
	take_hit(55.0, true)

func element_hit(amount: float,guardian: String,id: String) -> float:
	var shatter = guardian=="fire" and id!="wall" and chilled>0.0
	var actual=take_hit(amount*(1.4 if shatter else 1.0))
	if actual<=0.0:return 0.0
	if shatter:
		chilled=0.0
		hit_feedback.emit(global_position,"SHATTER",false)
	elif guardian=="ice" and id in ["breath","wall"] and hp>0.0:
		chilled=3.0
	return actual
