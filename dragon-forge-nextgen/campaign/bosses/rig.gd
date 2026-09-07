extends Node3D
## Presentation follows the real enemy clock. No damage, state transitions or save writes.
const Art = preload("res://presentation/art_library.gd")
const Catalog = preload("res://campaign/bosses/catalog.gd")
var boss_id = "outer-boss"
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var pattern = "slam"
var phase_index = 1
var sampled_clip = "idle"
var sampled_time = 0.0
var clock = 0.0
var travel = 0.0
var strike_age = -1.0
var contact_frame = -1
var dying = false
var death_age = 0.0
var death_reduced = false

func _ready() -> void:
	var info = Catalog.entry(boss_id)
	assert(not info.is_empty(), "Unknown campaign boss")
	model = load("res://campaign/bosses/assets/" + info.asset + ".glb").instantiate()
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false)
	player = model.find_child("AnimationPlayer", true, false)
	assert(skeleton != null and player != null, "Missing imported boss rig")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.custom_aabb = AABB(Vector3(-3,-1,-3),Vector3(6,7,6))
	_sample("idle",0.0)
	set_process(false)

func begin_attack(kind: String) -> void:
	pattern = kind
	strike_age = -1.0

func contact_now() -> void:
	# Called before the authoritative impact signal, so contact observers see the strike.
	strike_age = 0.0
	contact_frame = Engine.get_physics_frames()
	_sample("strike_" + pattern,0.0)

func animate(delta: float, brain, speed: float, reduced: bool) -> void:
	if dying: return
	var dt = maxf(0.0, delta) if is_finite(delta) else 0.0
	clock += dt
	travel += maxf(speed,0.0) * dt
	if brain.mode == "tell":
		strike_age = -1.0
		_sample("tell_"+pattern,1.0-clampf(brain.timer/maxf(brain.locked_duration,.001),0.0,1.0))
	elif brain.vulnerable():
		if strike_age >= 0.0 and strike_age < .4:
			if contact_frame != Engine.get_physics_frames(): strike_age += dt
			_sample("strike_"+pattern,minf(strike_age,.4))
		else:
			_sample("open",.5 if reduced else fposmod(clock,1.0))
	elif speed > .15:
		strike_age = -1.0
		# Wheels roll with actual travel, not a clock that keeps spinning while blocked.
		_sample("walk",fposmod(travel/(TAU*.26),1.0)*.9 if boss_id=="outer-boss" else (.0 if reduced else fposmod(clock,.9)))
	else:
		strike_age = -1.0
		_sample("idle",0.0 if reduced else fposmod(clock,1.8))

func _sample(clip: String, time: float) -> void:
	if not is_instance_valid(player): return
	sampled_clip = clip
	sampled_time = time
	skeleton.reset_bone_poses()
	Art.sample(player,clip,time)
	if boss_id == "singularity-final": _phase_shell()
	skeleton.force_update_all_bone_transforms()

func _phase_shell() -> void:
	# Permanent health-phase stance, not a strobe. The same thresholds choose attacks.
	var amount = clampi(phase_index-1,0,2)
	for i in range(4):
		var bone = skeleton.find_bone("Frame"+str(i))
		var offset = skeleton.get_bone_rest(bone).origin.normalized()*.11*amount
		skeleton.set_bone_pose_position(bone,skeleton.get_bone_pose_position(bone)+offset)
	for i in range(3):
		var bone = skeleton.find_bone("Gyro"+str(i))
		var axis = Vector3.RIGHT if i==1 else Vector3.FORWARD
		skeleton.set_bone_pose_rotation(bone,skeleton.get_bone_pose_rotation(bone)*Quaternion(axis,.16*amount*(i+1)))

func emission_origin() -> Vector3:
	var bone = skeleton.find_bone("Core")
	return skeleton.to_global(skeleton.get_bone_global_pose(bone).origin)

func begin_defeat(reduced: bool) -> void:
	dying = true
	death_age = 0.0
	death_reduced = reduced
	set_process(true)
	_sample("defeat",0.0)

func _process(delta: float) -> void:
	if not dying: return
	death_age += maxf(delta,0.0)
	_sample("defeat",minf(death_age,.8))
	if death_age >= .85: queue_free()
