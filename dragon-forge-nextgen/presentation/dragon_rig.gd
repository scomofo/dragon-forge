extends Node3D
## Animated geometric Magma blockout: broad hex body, horn nubs, heavy biped.
## Not a production model, skeleton, or imported animation asset.
const Geo = preload("res://presentation/geometry.gd")
var torso: Node3D
var left_leg: Node3D
var right_leg: Node3D
var tail: Node3D
var clock = 0.0
var attack_time = 0.0

func _ready() -> void:
	var armor = Geo.material(Color("3f3032"))
	var plates = Geo.material(Color("5b4542"))
	var lava = Geo.material(Geo.AMBER, 2.2)
	var bone = Geo.material(Color("ead9b7"))
	torso = Node3D.new()
	add_child(torso)
	Geo.cylinder(torso, Vector3(0, 1.25, 0), 0.82, 0.61, 1.25, armor, 6)
	Geo.box(torso, Vector3(0, 1.38, -0.65), Vector3(0.43, 0.72, 0.10), lava)
	for side in [-1.0, 1.0]:
		Geo.box(torso, Vector3(side * 0.49, 1.37, -0.47), Vector3(0.32, 0.62, 0.28), plates).rotation.z = side * 0.25
		Geo.cylinder(torso, Vector3(side * 0.87, 1.22, -0.08), 0.23, 0.31, 0.88, armor, 6).rotation.z = side * 0.28
		Geo.box(torso, Vector3(side * 0.93, 0.84, -0.25), Vector3(0.37, 0.27, 0.47), plates)
		for claw in [-0.12, 0.12]:
			Geo.box(torso, Vector3(side * 0.93 + claw, 0.79, -0.50), Vector3(0.08, 0.09, 0.24), bone)
	Geo.box(torso, Vector3(0, 2.00, -0.32), Vector3(0.85, 0.66, 0.86), plates)
	Geo.box(torso, Vector3(0, 1.88, -0.89), Vector3(0.72, 0.31, 0.52), armor)
	Geo.box(torso, Vector3(0, 1.74, -0.92), Vector3(0.65, 0.045, 0.48), lava)
	for side in [-1.0, 1.0]:
		Geo.box(torso, Vector3(side * 0.405, 2.06, -0.61), Vector3(0.07, 0.12, 0.25), lava)
		Geo.cylinder(torso, Vector3(side * 0.37, 2.49, -0.17), 0.17, 0.025, 0.54, bone, 5).rotation.z = side * -0.3
	left_leg = _leg(-0.55, armor, plates, bone)
	right_leg = _leg(0.55, armor, plates, bone)
	tail = Node3D.new()
	tail.position = Vector3(0, 0.95, 0.62)
	torso.add_child(tail)
	for i in range(5):
		var part = Geo.box(tail, Vector3(0, -i * 0.10, i * 0.40), Vector3(0.52 - i * 0.075, 0.47 - i * 0.055, 0.55), armor)
		part.rotation.x = -0.18
		Geo.cylinder(tail, Vector3(0, 0.28 - i * 0.10, i * 0.40), 0.13, 0.0, 0.25, lava, 4)

func _leg(x: float, armor: Material, plates: Material, bone: Material) -> Node3D:
	var pivot = Node3D.new()
	pivot.position = Vector3(x, 0.77, 0.10)
	add_child(pivot)
	Geo.box(pivot, Vector3(0, -0.16, 0), Vector3(0.45, 0.68, 0.46), armor)
	Geo.box(pivot, Vector3(0, -0.58, -0.21), Vector3(0.56, 0.28, 0.83), plates)
	for i in [-0.17, 0.0, 0.17]:
		Geo.box(pivot, Vector3(i, -0.60, -0.66), Vector3(0.10, 0.10, 0.23), bone)
	return pivot

func act() -> void:
	attack_time = 0.28

func animate(delta: float, speed: float, reduced: bool, dead: bool) -> void:
	clock += delta
	attack_time = maxf(0.0, attack_time - delta)
	var stride = minf(speed / 6.0, 1.0)
	left_leg.rotation.x = sin(clock * 10.0) * 0.48 * stride
	right_leg.rotation.x = -left_leg.rotation.x
	tail.rotation.y = sin(clock * 2.6) * (0.06 if reduced else 0.24)
	torso.position.y = sin(clock * 3.0) * (0.01 if reduced else 0.035)
	torso.rotation.x = -sin(attack_time / 0.28 * PI) * (0.07 if reduced else 0.28)
	rotation.z = lerpf(rotation.z, 1.25 if dead else 0.0, minf(delta * 8.0, 1.0))
