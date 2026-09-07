extends "res://campaign/ice_rig.gd"
## Same animation and contact solver, distinct committed evolved mesh; no collider scaling.
const Evolved = preload("res://campaign/evolutions/rime_evolved.glb")

func _make_model() -> Node3D:
	var imported = Evolved.instantiate()
	add_child(imported)
	return imported
