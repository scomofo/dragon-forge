extends "res://campaign/storm_rig.gd"
## Same hover/attack animation and collider; distinct imported crown and wing armor.
const Evolved = preload("res://campaign/tempest/tempest_arc.glb")

func _make_model() -> Node3D:
	var imported = Evolved.instantiate()
	add_child(imported)
	return imported
