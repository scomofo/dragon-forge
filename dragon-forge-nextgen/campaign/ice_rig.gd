extends Node3D
## Distinct imported quadruped; sampled animation cannot deal damage.
const Scene = preload("res://campaign/guardians/ice_guardian.glb")
const Art = preload("res://presentation/art_library.gd")
const Geo = preload("res://presentation/geometry.gd")
const Feet = preload("res://campaign/ice_feet.gd")
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var planting = Feet.new()
var ward_shell: MeshInstance3D
var sampled_clip = "idle"
var sampled_time = 0.0
var clock = 0.0
var hurt_time = 0.0
var death_time = 0.0

func _ready() -> void:
	model = _make_model()
	skeleton = model.find_child("Skeleton3D",true,false)
	player = model.find_child("AnimationPlayer",true,false)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Art.sample(player,"idle",0.0)
	planting.configure(self)
	ward_shell=Geo.cylinder(self,Vector3(0,.85,-.15),1.02,1.02,1.45,Geo.material(Color(.45,.85,1.0,.12),.3,true),6)
	ward_shell.scale.z=1.75
	ward_shell.visible=false

func reset_pose() -> void:
	clock=0.0
	hurt_time=0.0
	death_time=0.0
	if is_instance_valid(player):
		Art.sample(player,"idle",0.0)
	planting.reset()

func hurt(guarded: bool) -> void:
	hurt_time=0.06 if guarded else 0.24

func animate(delta: float, speed: float, reduced: bool, state: Dictionary) -> void:
	clock+=maxf(delta,0.0)
	hurt_time=maxf(0,hurt_time-delta)
	sampled_clip="idle"
	sampled_time=0.0 if reduced else fposmod(clock,1.8)
	if state.hp<=0:
		death_time=minf(.8,death_time+delta)
		sampled_clip="defeat";sampled_time=death_time
	elif state.action!="":
		sampled_clip=state.action;sampled_time=state.action_time
	elif state.guard:
		sampled_clip="guard";sampled_time=.5
	elif hurt_time>0:
		sampled_clip="hurt";sampled_time=.24-hurt_time
	elif speed>.15:
		sampled_clip="walk";sampled_time=planting.phase*.8
	Art.sample(player,sampled_clip,sampled_time)
	planting.apply(delta,state)
	ward_shell.visible=state.get("ward",0.0)>0.0 and state.hp>0.0

func muzzle_position() -> Vector3:
	return skeleton.global_transform*(skeleton.get_bone_global_pose(skeleton.find_bone("Head"))*Vector3(0,-.12,-.63))

func _make_model() -> Node3D:
	var imported = Scene.instantiate()
	add_child(imported)
	return imported
