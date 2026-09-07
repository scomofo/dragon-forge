extends Node3D
## Imported modular art only. Simulation/collision never depends on decoration or quality.
const Art = preload("res://presentation/art_library.gd")
const Geo = preload("res://presentation/geometry.gd")
var details: Node3D
var forge_circuits: MultiMeshInstance3D
var restored = false
var art_batches: Array = []

func _ready() -> void:
	var floors: Array = []
	for x in range(-8, 9, 4):
		for z in range(-21, 12, 4):
			floors.append(Transform3D(Basis.IDENTITY, Vector3(x, 0, z)))
		floors.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1, 1, 0.5)), Vector3(x, 0, 14)))
	art_batches.append(Art.batch(self, "deck_panel", floors))
	var bulkheads: Array = []
	var rails: Array = []
	var pipes: Array = []
	for side in [-1.0, 1.0]:
		for z in [-19, -11, -3, 8]:
			bulkheads.append(Transform3D(Basis.IDENTITY, Vector3(side * 8.8, 0, z)))
		for x in [4.2, 5.8, 7.4, 9.0]:
			bulkheads.append(Transform3D(Basis.IDENTITY.scaled(Vector3(1.08, 0.84, 0.32)), Vector3(side * x, 0, 2)))
		for z in range(-21, 15, 4):
			rails.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.22, 0.55, 2.32)), Vector3(side * 10.1, 0, z)))
		for z in range(-21, 15, 4):
			pipes.append(Transform3D(Basis.IDENTITY, Vector3(side * 9.15, -0.005, z)))
		for i in range(5):
			var tower = Art.place(self, "relay_pylon", Vector3(side * (12.9 + (i % 2) * 1.7), -1.7, -23.0 + i * 7.8))
			tower.rotation.z = side * (0.10 + (i % 3) * 0.04)
		Art.place(self, "furnace", Vector3(side * 6.5, 0, 12.8))
	for z in [-23.1, 15.1]:
		for x in range(-8, 9, 4):
			rails.append(Transform3D(Basis(Vector3.UP, PI / 2.0).scaled(Vector3(2.62, 0.55, 0.24)), Vector3(x, 0, z)))
	art_batches.append(Art.batch(self, "bulkhead", bulkheads))
	art_batches.append(Art.batch(self, "bulkhead", rails))
	art_batches.append(Art.batch(self, "cable_tray", pipes))
	Art.place(self, "breach_arch", Vector3(0, 0, 2))
	Art.place(self, "warden_dais", Vector3(0, 0, -15))
	Art.place(self, "anvil", Vector3(-6.0, 0, 11.1))
	# Large architectural silhouettes sit beyond the playable wall.
	for x in [-6.0, -3.0, 0.0, 3.0, 6.0]:
		var tower = Art.place(self, "relay_pylon", Vector3(x, -0.5, -25.4))
		tower.scale = Vector3(0.7, 1.05 - absf(x) * 0.038, 0.8)
	var paths: Array = []
	for x in range(-6, 7):
		paths.append(Vector3(x, 0.075, 12.0))
	forge_circuits = Geo.batch_boxes(self, paths, Vector3(0.80, 0.028, 0.04), Geo.material(Color("d99452"), 0.8))
	details = Node3D.new()
	details.name = "OptionalDetail"
	add_child(details)
	# Small architectural service runs are optional. Core stations and authored meshes are not.
	var service: Array = []
	for side in [-1, 1]:
		for z in range(-20, 13, 4):
			service.append(Transform3D(Basis.IDENTITY.scaled(Vector3(0.7, 0.7, 1)), Vector3(side * 10.7, -0.7, z)))
	Art.batch(details, "cable_tray", service)

func set_restored(value: bool) -> void:
	if value == restored:
		return
	restored = value
	forge_circuits.material_override = Geo.material(Geo.CYAN if value else Color("d99452"), 0.8)

func set_quality(level: int) -> void:
	details.visible = level >= 2
