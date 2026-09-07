extends Node3D
## Cairn is a distinct imported block-golem guardian. Animation sampling is presentation-only.
const Scene = preload("res://campaign/stone/stone_guardian.glb")
const Art = preload("res://presentation/art_library.gd")
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var clock=0.0
var hurt_time=0.0
var death_time=0.0
var sampled_clip="idle"
var sampled_time=0.0
func _ready()->void:
	model=Scene.instantiate();add_child(model)
	skeleton=model.find_child("Skeleton3D",true,false);player=model.find_child("AnimationPlayer",true,false)
	player.process_mode=Node.PROCESS_MODE_DISABLED;reset_pose()
func reset_pose()->void:
	clock=0.0;hurt_time=0.0;death_time=0.0
	if is_instance_valid(player):Art.sample(player,"idle",0.0)
func hurt(guarded:bool)->void:hurt_time=.06 if guarded else .24
func animate(delta:float,speed:float,reduced:bool,state:Dictionary)->void:
	var dt=maxf(0.0,delta) if is_finite(delta) else 0.0
	clock+=dt;hurt_time=maxf(0.0,hurt_time-dt);sampled_clip="idle";sampled_time=0.0 if reduced else fposmod(clock,1.8)
	if state.hp<=0.0:death_time=minf(.8,death_time+dt);sampled_clip="defeat";sampled_time=death_time
	elif state.action!="":sampled_clip=state.action;sampled_time=state.action_time
	elif state.guard:sampled_clip="guard";sampled_time=.5
	elif hurt_time>0.0:sampled_clip="hurt";sampled_time=.24-hurt_time
	elif speed>.15:sampled_clip="walk";sampled_time=0.0 if reduced else fposmod(clock,.9)
	Art.sample(player,sampled_clip,sampled_time)
func muzzle_position()->Vector3:
	return skeleton.global_transform*(skeleton.get_bone_global_pose(skeleton.find_bone("Head"))*Vector3(0,-.08,-.62))
