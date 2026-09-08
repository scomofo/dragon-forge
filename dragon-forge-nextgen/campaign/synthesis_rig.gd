extends Node3D
## Prism combines the imported Void frame and rigid Light panes. Sampling never resolves combat.
const Scene = preload("res://campaign/synthesis/synthesis_guardian.glb")
const Art = preload("res://presentation/art_library.gd")
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var emitter_bone = -1
var clock = 0.0
var hurt_time = 0.0
var death_time = 0.0
var sampled_clip = "idle"
var sampled_time = 0.0

func _ready() -> void:
	model = Scene.instantiate()
	add_child(model)
	skeleton = model.find_child("Skeleton3D", true, false)
	player = model.find_child("AnimationPlayer", true, false)
	emitter_bone = skeleton.find_bone("Emitter")
	assert(emitter_bone >= 0, "Prism requires the authored frame-rim emitter")
	player.process_mode = Node.PROCESS_MODE_DISABLED
	reset_pose()

func reset_pose() -> void:
	clock = 0.0
	hurt_time = 0.0
	death_time = 0.0
	sampled_clip = "idle"
	sampled_time = 0.0
	if is_instance_valid(player):
		Art.sample(player, sampled_clip, sampled_time)

func hurt(guarded: bool) -> void:
	hurt_time = .06 if guarded else .24

func animate(delta: float, speed: float, reduced: bool, state: Dictionary) -> void:
	var dt = maxf(0.0, delta) if is_finite(delta) else 0.0
	clock += dt
	hurt_time = maxf(0.0, hurt_time - dt)
	sampled_clip = "idle"
	sampled_time = 0.0 if reduced else fposmod(clock, 1.8)
	if state.hp <= 0.0:
		death_time = minf(.9, death_time + dt)
		sampled_clip = "defeat"
		sampled_time = death_time
	elif state.action != "":
		sampled_clip = state.action
		sampled_time = state.action_time
	elif state.guard:
		sampled_clip = "guard"
		sampled_time = .6
	elif hurt_time > 0.0:
		sampled_clip = "hurt"
		sampled_time = .24 - hurt_time
	elif speed > .15:
		sampled_clip = "walk"
		sampled_time = 0.0 if reduced else fposmod(clock, .8)
	Art.sample(player, sampled_clip, sampled_time)

func muzzle_position() -> Vector3:
	return skeleton.global_transform * skeleton.get_bone_global_pose(emitter_bone).origin
