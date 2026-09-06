extends Node3D
## Quiet, always-visible destination marker; never a collision object.
const Geo = preload("res://presentation/geometry.gd")
var ring: MeshInstance3D
var pin: MeshInstance3D

func _ready() -> void:
	var mat = Geo.material(Color("f4c47c"), 0.5, true)
	ring = Geo.ring(self, Vector3(0, 0.08, 0), 1.05, mat, 0.045)
	pin = Geo.cylinder(self, Vector3(0, 2.65, 0), 0.0, 0.22, 0.42, mat, 4)

func show_target(info: Dictionary, fighting: bool, dead: bool) -> void:
	visible = not fighting and not dead and info.marker != ""
	position = info.target
