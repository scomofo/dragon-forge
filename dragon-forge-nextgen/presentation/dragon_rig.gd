extends Node3D
## Articulated procedural Magma. Replaceable joint rig; not a skinned production asset.
## Poses sample the authoritative attack clock. They never apply gameplay damage.
const Geo = preload("res://presentation/geometry.gd")
const Combat = preload("res://sim/combat.gd")
var body: Node3D
var torso: Node3D
var head: Node3D
var jaw: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var tail: Node3D
var tail_joints: Array = []
var core: MeshInstance3D
var lava: StandardMaterial3D
var clock = 0.0
var gait = 0.0
var hurt_time = 0.0

func _pivot(parent: Node3D, title: String, at: Vector3) -> Node3D:
	var node = Node3D.new()
	node.name = title
	node.position = at
	parent.add_child(node)
	return node

func _ready() -> void:
	var armor = Geo.material(Color("41393e"))
	var plates = Geo.material(Color("855342"))
	var edge = Geo.material(Color("bd8260"))
	var bone = Geo.material(Color("e4bd83"))
	lava = Geo.material(Color("ff712e"), 1.5)
	body = _pivot(self, "Body", Vector3.ZERO)
	torso = _pivot(body, "Chest", Vector3(0, 1.30, 0))
	Geo.cylinder(torso, Vector3.ZERO, 0.64, 0.92, 1.13, armor, 6).scale.z = 0.82
	Geo.cylinder(torso, Vector3(0, 0.0, -0.12), 0.57, 0.82, 0.96, plates, 6).scale.z = 0.88
	core = Geo.cylinder(torso, Vector3(0, 0.08, -0.69), 0.27, 0.21, 0.12, lava, 6)
	core.rotation.x = PI / 2.0
	for row in range(3):
		Geo.box(torso, Vector3(0, -0.13 - row * 0.15, -0.59), Vector3(0.48 - row * 0.08, 0.065, 0.13), edge)
	for side in [-1.0, 1.0]:
		Geo.cylinder(torso, Vector3(side * 0.65, 0.48, 0), 0.40, 0.25, 0.31, plates, 5).rotation.z = side * -0.45
		Geo.cylinder(torso, Vector3(side * 0.84, 0.69, 0.04), 0.16, 0.025, 0.46, bone, 5).rotation.z = side * -0.65
		for row in range(3):
			Geo.box(torso, Vector3(side * 0.54, 0.25 - row * 0.19, -0.49), Vector3(0.26, 0.07, 0.11), lava).rotation.z = side * 0.35
	head = _pivot(torso, "Head", Vector3(0, 0.64, -0.23))
	Geo.orb(head, Vector3(0, 0.10, -0.06), 0.49, plates).scale = Vector3(1.1, 0.84, 1.1)
	Geo.cylinder(head, Vector3(0, -0.07, -0.50), 0.28, 0.38, 0.72, armor, 6).rotation.x = PI / 2.0
	Geo.box(head, Vector3(0, 0.01, -0.78), Vector3(0.46, 0.20, 0.24), plates)
	jaw = _pivot(head, "Jaw", Vector3(0, -0.20, -0.19))
	Geo.box(jaw, Vector3(0, -0.055, -0.37), Vector3(0.47, 0.12, 0.69), armor)
	Geo.box(jaw, Vector3(0, 0.017, -0.36), Vector3(0.34, 0.035, 0.52), lava)
	for side in [-1.0, 1.0]:
		Geo.box(head, Vector3(side * 0.43, 0.10, -0.32), Vector3(0.055, 0.11, 0.24), lava).rotation.z = side * -0.28
		Geo.box(head, Vector3(side * 0.43, 0.23, -0.30), Vector3(0.17, 0.10, 0.34), armor).rotation.z = side * -0.25
		Geo.cylinder(head, Vector3(side * 0.37, 0.52, 0.15), 0.18, 0.015, 0.59, bone, 5).rotation = Vector3(0.35, 0, side * -0.35)
		Geo.cylinder(head, Vector3(side * 0.25, -0.22, -0.58), 0.0, 0.06, 0.16, bone, 4)
	left_arm = _arm(-1.0, armor, plates, bone)
	right_arm = _arm(1.0, armor, plates, bone)
	left_leg = _leg(-0.49, armor, plates, bone)
	right_leg = _leg(0.49, armor, plates, bone)
	tail = _pivot(torso, "Tail", Vector3(0, -0.35, 0.52))
	var parent = tail
	for i in range(6):
		var joint = _pivot(parent, "Segment%d" % i, Vector3(0, -0.04, 0.0 if i == 0 else 0.34))
		var size = 0.46 - i * 0.057
		Geo.cylinder(joint, Vector3(0, 0, 0.16), size * 0.50, size * 0.60, 0.43, armor, 6).rotation.x = PI / 2.0
		Geo.cylinder(joint, Vector3(0, size * 0.48 + 0.09, 0.14), 0.12 - i * 0.011, 0.0, 0.28 - i * 0.025, plates if i % 2 == 0 else lava, 4)
		tail_joints.append(joint)
		parent = joint
	for i in range(3):
		Geo.cylinder(torso, Vector3(0, 0.30 - i * 0.27, 0.55), 0.17, 0.0, 0.38, plates, 4).rotation.x = 0.9

func _arm(side: float, armor: Material, plates: Material, bone: Material) -> Node3D:
	var pivot = _pivot(torso, "LeftArm" if side < 0 else "RightArm", Vector3(side * 0.79, 0.30, -0.04))
	Geo.cylinder(pivot, Vector3(side * 0.05, -0.26, 0), 0.24, 0.28, 0.57, armor, 6)
	Geo.orb(pivot, Vector3(side * 0.06, -0.49, -0.07), 0.25, plates)
	Geo.box(pivot, Vector3(side * 0.07, -0.59, -0.24), Vector3(0.40, 0.29, 0.50), plates)
	for claw in [-0.13, 0.0, 0.13]:
		Geo.cylinder(pivot, Vector3(side * 0.07 + claw, -0.63, -0.57), 0.065, 0.0, 0.28, bone, 4).rotation.x = -PI / 2.0
	return pivot

func _leg(x: float, armor: Material, plates: Material, bone: Material) -> Node3D:
	var pivot = _pivot(body, "LeftHip" if x < 0 else "RightHip", Vector3(x, 0.77, 0.13))
	Geo.orb(pivot, Vector3(0, -0.07, 0), 0.32, plates).scale.y = 1.2
	Geo.cylinder(pivot, Vector3(0, -0.28, 0.10), 0.18, 0.24, 0.40, armor, 6).rotation.x = -0.35
	Geo.box(pivot, Vector3(0, -0.55, -0.23), Vector3(0.53, 0.26, 0.77), plates)
	for i in [-0.17, 0.0, 0.17]:
		Geo.cylinder(pivot, Vector3(i, -0.56, -0.68), 0.075, 0.0, 0.26, bone, 4).rotation.x = -PI / 2.0
	return pivot

func hurt(guarded: bool) -> void:
	hurt_time = 0.07 if guarded else 0.20

func reset_pose() -> void:
	hurt_time = 0.0
	gait = 0.0
	if is_instance_valid(body):
		body.rotation = Vector3.ZERO

func animate(delta: float, speed: float, reduced: bool, state: Dictionary) -> void:
	clock += maxf(delta, 0.0)
	hurt_time = maxf(0.0, hurt_time - delta)
	var stride = clampf(speed / 6.2, 0.0, 1.0)
	gait += delta * speed * 1.65
	var walk = sin(gait) * 0.42 * stride
	left_leg.rotation.x = walk
	right_leg.rotation.x = -walk
	left_leg.position.y = 0.77 + maxf(0.0, sin(gait)) * 0.07 * stride
	right_leg.position.y = 0.77 + maxf(0.0, -sin(gait)) * 0.07 * stride
	torso.position.y = 1.3 + (0.0 if reduced else sin(clock * 2.8) * 0.025 + absf(sin(gait)) * 0.035 * stride)
	torso.rotation = Vector3(-stride * 0.10, 0, 0)
	head.rotation = Vector3.ZERO
	jaw.rotation.x = 0.0
	left_arm.rotation = Vector3(-walk * 0.4, 0, 0.12)
	right_arm.rotation = Vector3(walk * 0.4, 0, -0.12)
	if state.guard:
		left_arm.rotation.x = -0.90
		right_arm.rotation.x = -0.90
		head.rotation.x = -0.12
	if state.action != "":
		var rule: Dictionary = Combat.ABILITIES[state.action]
		var winding: bool = state.action_time < rule.windup
		var strength = smoothstep(0.0, rule.windup, state.action_time) if winding else 1.0 - smoothstep(rule.windup, rule.windup + rule.recovery, state.action_time)
		var calm = 0.60 if reduced else 1.0
		match state.action:
			"claw":
				torso.rotation.y = (-0.38 if winding else 0.52) * strength * calm
				right_arm.rotation.x = (-1.35 if winding else 0.40) * strength * calm
				right_arm.rotation.z = (-0.45 if winding else 0.28) * strength * calm
			"breath":
				torso.rotation.x = (0.14 if winding else -0.24) * strength * calm
				head.rotation.x = (0.14 if winding else -0.16) * strength * calm
				jaw.rotation.x = -0.60 * strength
			"wall":
				left_arm.rotation.x = (-1.25 if winding else 0.35) * strength * calm
				right_arm.rotation.x = left_arm.rotation.x
				torso.position.y -= (0.03 if winding else 0.18) * strength * calm
			"burst":
				torso.rotation.x = (0.18 if winding else -0.15) * strength * calm
				left_arm.rotation.z = (0.3 if winding else 1.0) * strength * calm
				right_arm.rotation.z = -left_arm.rotation.z
				jaw.rotation.x = -0.35 * strength
	for i in range(tail_joints.size()):
		tail_joints[i].rotation.y = sin(clock * 2.3 - i * 0.55) * (0.015 if reduced else 0.075)
		tail_joints[i].rotation.x = -0.02 + stride * 0.04
	lava.emission_energy_multiplier = 1.3 + state.heat / 100.0 * 1.4
	body.rotation.z = lerpf(body.rotation.z, 1.10 if state.hp <= 0.0 else 0.0, minf(delta * 8.0, 1.0))
	body.rotation.x = hurt_time * (0.15 if reduced else 0.7)
