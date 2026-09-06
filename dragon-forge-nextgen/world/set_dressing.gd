extends Node3D
## Bounded, authored decorative geometry. No physics bodies or gameplay triggers.
const Geo = preload("res://presentation/geometry.gd")
var details: Node3D
var forge_circuits: MultiMeshInstance3D
var restored = false

func _ready() -> void:
	var graphite = Geo.material(Color("18202d"))
	var alloy = Geo.material(Color("485463"))
	var copper = Geo.material(Color("a66947"))
	var blue = Geo.material(Color("489aac"), 0.8)
	var amber = Geo.material(Color("ed8549"), 0.9)
	# Broken peripheral pylons turn the box arena into a suspended relay station.
	for side in [-1.0, 1.0]:
		for i in range(5):
			var tower = Node3D.new()
			tower.position = Vector3(side * (12.8 + (i % 2) * 1.7), -1.7, -23.0 + i * 7.8)
			tower.rotation.z = side * (0.10 + (i % 3) * 0.04)
			add_child(tower)
			Geo.cylinder(tower, Vector3(0, 2.8, 0), 1.2, 0.85, 7.0 + i % 3, graphite, 5)
			Geo.box(tower, Vector3(-side * 0.78, 2.5, 0), Vector3(0.09, 5.0, 0.12), blue)
		Geo.cylinder(self, Vector3(side * 10.4, -0.75, -5), 0.31, 0.31, 35.0, copper, 10).rotation.x = PI / 2.0
		for z in [-20.0, -8.0, 4.0, 12.0]:
			Geo.box(self, Vector3(side * 9.95, -0.9, z), Vector3(1.1, 1.4, 0.30), alloy).rotation.z = side * 0.5
	# The north wall is an interrupted crown around the Warden's relay.
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		var height = 5.8 - absf(x) * 0.35
		Geo.box(self, Vector3(x, height * 0.5, -24.4), Vector3(1.0, height, 1.2), graphite)
		Geo.box(self, Vector3(x, height * 0.5, -23.75), Vector3(0.10, height * 0.77, 0.045), blue)
	# A low octagonal relay medallion: no raised collision or invisible obstruction.
	Geo.cylinder(self, Vector3(0, 0.055, -15), 4.4, 4.4, 0.02, Geo.material(Color("213741")), 8)
	Geo.ring(self, Vector3(0, 0.082, -15), 3.95, blue, 0.026)
	Geo.ring(self, Vector3(0, 0.085, -15), 3.62, Geo.material(Color("54727b")), 0.018)
	var ticks: Array = []
	for z in range(-20, 2, 2):
		for side in [-1, 1]:
			ticks.append(Vector3(side * 5.8, 0.071, z))
	Geo.batch_boxes(self, ticks, Vector3(0.34, 0.025, 0.055), blue)
	# Forge machinery, set against the rear wall rather than in the playable lane.
	for side in [-1, 1]:
		Geo.cylinder(self, Vector3(side * 6.5, 1.4, 12.8), 0.75, 0.75, 2.8, graphite, 8)
		for y in [0.4, 1.2, 2.0, 2.7]:
			Geo.ring(self, Vector3(side * 6.5, y, 12.8), 0.76, copper, 0.055)
		Geo.box(self, Vector3(side * 6.5, 1.7, 11.99), Vector3(0.70, 1.3, 0.04), amber)
		Geo.cylinder(self, Vector3(side * 4.7, 0.3, 13.5), 0.17, 0.17, 3.4, copper, 8).rotation.z = PI / 2.0
	var paths: Array = []
	for x in range(-6, 7):
		paths.append(Vector3(x, 0.071, 12.7))
	forge_circuits = Geo.batch_boxes(self, paths, Vector3(0.82, 0.028, 0.065), amber)
	# High-quality-only ornament. It never includes the actual combat tell or conduit.
	details = Node3D.new()
	details.name = "OptionalDetail"
	add_child(details)
	var lamps: Array = []
	for side in [-1, 1]:
		for z in range(-21, 14):
			lamps.append(Vector3(side * 9.70, 1.42, z))
	Geo.batch_boxes(details, lamps, Vector3(0.09, 0.06, 0.20), blue)
	var bolts: Array = []
	for x in range(-8, 9, 2):
		for z in range(-20, 15, 2):
			bolts.append(Vector3(x + 0.72, 0.072, z + 0.74))
	Geo.batch_boxes(details, bolts, Vector3(0.085, 0.025, 0.085), alloy)

func set_restored(value: bool) -> void:
	if value == restored:
		return
	restored = value
	forge_circuits.material_override = Geo.material(Geo.CYAN if value else Color("ed8549"), 0.9)

func set_quality(level: int) -> void:
	details.visible = level >= 2
