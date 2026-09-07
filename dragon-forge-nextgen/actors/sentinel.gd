extends CharacterBody3D
const Brain = preload("res://sim/enemy_brain.gd")
const Geo = preload("res://presentation/geometry.gd")
signal slam(at: Vector3, radius: float, amount: float)
signal defeated(encounter: int)
signal hit_feedback(at: Vector3, text: String, blocked: bool)
var brain = Brain.new()
var target
var encounter = 0
var boss = false
var hp = 100.0
var max_hp = 100.0
var radius = 2.4
var reduced_motion = false
var visual: Node3D
var shield: MeshInstance3D
var tell: Node3D
var tell_ring: MeshInstance3D
var title: Label3D
var hp_label: Label3D
var clock = 0.0

func _ready() -> void:
	max_hp = 260.0 if boss else 100.0
	hp = max_hp
	radius = 3.1 if boss else 2.4
	brain.boss = boss
	collision_layer = 4
	collision_mask = 1 | 2
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.75 if boss else 0.60
	capsule.height = 2.4
	collision.shape = capsule
	collision.position.y = 1.2
	add_child(collision)
	visual = Node3D.new()
	add_child(visual)
	var armor = Geo.material(Color("49435c") if boss else Color("354e59"))
	var trim = Geo.material(Geo.AMBER if boss else Geo.CYAN, 1.6)
	Geo.box(visual, Vector3(0, 1.2, 0), Vector3(1.15, 1.25, 0.75), armor)
	Geo.orb(visual, Vector3(0, 1.4, -0.46), 0.29, trim)
	Geo.box(visual, Vector3(0, 2.1, 0), Vector3(0.64, 0.45, 0.59), armor)
	Geo.box(visual, Vector3(0, 2.12, -0.32), Vector3(0.45, 0.09, 0.08), trim)
	for side in [-1.0, 1.0]:
		Geo.box(visual, Vector3(side * 0.78, 1.37, 0), Vector3(0.39, 1.15, 0.50), armor)
		Geo.box(visual, Vector3(side * 0.36, 0.41, 0), Vector3(0.40, 0.80, 0.50), armor)
		Geo.box(visual, Vector3(side * 0.36, 0.16, -0.18), Vector3(0.49, 0.29, 0.80), armor)
	shield = Geo.box(visual, Vector3(0, 1.25, -0.73), Vector3(1.58, 1.63, 0.08), Geo.material(Color(0.35, 0.8, 0.96, 0.40), 0.6, true))
	if boss:
		visual.scale = Vector3.ONE * 1.2
	title = Geo.label(self, Vector3(0, 3.6 if boss else 3.15, 0), "")
	hp_label = Geo.label(self, Vector3(0, 2.85 if boss else 2.4, 0), "", Geo.CYAN)
	title.font_size = 40
	hp_label.font_size = 36
	# Telegraph is a sibling: it does NOT follow the enemy or player after lock.
	tell = Node3D.new()
	get_parent().call_deferred("add_child", tell)
	tell_ring = Geo.ring(tell, Vector3(0, 0.09, 0), radius, Geo.material(Color("ffcf68"), 1.0, true), 0.09)
	Geo.cylinder(tell, Vector3(0, 0.045, 0), radius, radius, 0.025, Geo.material(Color(1.0, 0.25, 0.16, 0.2), 0.0, true), 40)
	Geo.label(tell, Vector3(0, 0.2, 0), "IMPACT", Color("ffdf9b"))
	tell.visible = false

func _exit_tree() -> void:
	if is_instance_valid(tell):
		tell.queue_free()

func _physics_process(delta: float) -> void:
	# The fixed world-space tell is attached by a deferred call.
	# Wait until it has entered the tree before assigning global transforms.
	if not is_instance_valid(tell) or not tell.is_inside_tree():
		return
	if not is_instance_valid(target) or target.state.hp <= 0.0 or brain.mode == "dead":
		if is_instance_valid(tell):
			tell.visible = false
		return
	if target.global_position.z > 1.5:
		brain.mode = "seek"
		velocity = Vector3.ZERO
		tell.visible = false
		return
	clock += delta
	brain.enraged = boss and hp <= max_hp * 0.5
	var offset: Vector3 = target.global_position - global_position
	offset.y = 0.0
	var event = brain.tick(delta, offset.length(), target.global_position)
	if event == "tell":
		tell.global_position = Vector3(brain.locked_target.x, 0, brain.locked_target.z)
	elif event == "slam":
		slam.emit(brain.locked_target, radius, 32.0 if boss else 22.0)
	var direction = offset.normalized()
	velocity.x = direction.x * (2.7 if brain.enraged else 2.1) if brain.mode == "seek" else 0.0
	velocity.z = direction.z * (2.7 if brain.enraged else 2.1) if brain.mode == "seek" else 0.0
	velocity.y = -1.0 if is_on_floor() else velocity.y - delta * 25.0
	move_and_slide()
	if direction.length() > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), minf(delta * 6.0, 1.0))
	visual.position.y = 0.0 if reduced_motion else sin(clock * 3.0) * 0.045
	tell.visible = brain.mode == "tell"
	# A shrinking ring indicates time, without flashing or shaking the screen.
	var fraction = clampf(brain.timer / brain.tell_duration(), 0.0, 1.0)
	tell_ring.scale = Vector3.ONE * (1.0 if reduced_motion else maxf(0.1, fraction))
	shield.visible = not brain.vulnerable()
	var name_text = "PACKET WARDEN" if boss else "FIREWALL SENTINEL"
	var status = "OPEN - COUNTER!" if brain.vulnerable() else ("DODGE / GUARD" if brain.mode == "tell" else "SHIELD CLOSED")
	title.text = name_text + (" // OVERCLOCK" if brain.enraged else "") + "\n" + status
	hp_label.text = "%d / %d" % [int(hp), int(max_hp)]

func take_hit(amount: float, bypass_shield: bool = false) -> float:
	if hp <= 0.0 or amount <= 0.0:
		return 0.0
	if not bypass_shield and not brain.vulnerable():
		hit_feedback.emit(global_position, "SHIELDED", true)
		return 0.0
	var applied = minf(hp, amount)
	hp -= applied
	hit_feedback.emit(global_position, str(int(applied)), false)
	if hp <= 0.0:
		brain.kill()
		defeated.emit(encounter)
		queue_free()
	return applied

func overload() -> void:
	brain.open_window(2.4)
	take_hit(55.0, true)
