extends "res://actors/dragon.gd"
const GuardianCombat = preload("res://campaign/guardian_combat.gd")
const IceRig = preload("res://campaign/ice_rig.gd")
var cooling_level = 0
var guardian = "fire"
var rigs: Dictionary = {}

func _ready() -> void:
	combat_rules = GuardianCombat
	super._ready()
	rigs["fire"] = rig

func use_guardian(id: String, saved_state: Dictionary) -> void:
	if not id in ["fire","ice"]:
		return
	var facing = rig.rotation.y
	rig.visible = false
	if not rigs.has(id):
		var next = IceRig.new() if id == "ice" else Rig.new()
		add_child(next)
		rigs[id] = next
	guardian = id
	rig = rigs[id]
	rig.reset_pose()
	rig.rotation.y = facing
	rig.visible = active
	state = saved_state
	state.guardian = id
	state.ward = state.get("ward",0.0)
	buffered_id = ""
	buffer_time = 0.0
	input_grace = 0.15
	guard_ring.visible = false

func advance_combat(delta: float, guarding: bool = false) -> void:
	super.advance_combat(delta, guarding)
	if state.hp > 0.0:
		var dt = clampf(delta,0.0,0.25) if is_finite(delta) else 0.0
		state.heat = maxf(0.0,state.heat - dt*cooling_level*4.0*(0.5 if state.guard else 1.0))
