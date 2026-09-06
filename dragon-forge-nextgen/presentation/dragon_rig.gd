extends Node3D
## Imported UV-mapped skinned asset. Animation is sampled, never authoritative for damage.
const FootPlant = preload("res://presentation/foot_plant.gd")
var feet = FootPlant.new()
var foot_lock_enabled = true
const Art = preload("res://presentation/art_library.gd")
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var lava: StandardMaterial3D
var clock = 0.0
var gait = 0.0
var hurt_time = 0.0
var death_time = 0.0
var sampled_clip = "idle"
var sampled_time = 0.0

func _ready() -> void:
	model = Art.place(self, "magma_guardian")
	skeleton = model.find_child("Skeleton3D", true, false)
	player = model.find_child("AnimationPlayer", true, false)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	var mesh: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]
	lava = mesh.get_active_material(0).duplicate()
	mesh.material_override = lava
	feet.configure(self)
	reset_pose()

func hurt(guarded: bool) -> void:
	hurt_time = 0.06 if guarded else 0.24

func reset_pose() -> void:
	feet.reset()
	hurt_time = 0.0
	death_time = 0.0
	gait = 0.0
	if is_instance_valid(player):
		Art.sample(player, "idle", 0.0)

func pose_signature() -> Array:
	var result: Array = []
	for bone in ["Chest", "Arm.R", "Jaw"]:
		result.append(skeleton.get_bone_pose_rotation(skeleton.find_bone(bone)))
	return result

func animate(delta: float, speed: float, reduced: bool, state: Dictionary) -> void:
	var dt = maxf(0.0, delta)
	clock += dt
	gait += dt * clampf(speed / 6.2, 0.0, 1.6)
	hurt_time = maxf(0.0, hurt_time - dt)
	sampled_clip = "idle"
	sampled_time = 0.0 if reduced else fposmod(clock, 1.8)
	if state.hp <= 0.0:
		death_time = minf(0.8, death_time + dt)
		sampled_clip = "defeat"
		sampled_time = death_time
	elif state.action != "":
		death_time = 0.0
		sampled_clip = state.action
		sampled_time = state.action_time
	elif state.guard:
		sampled_clip = "guard"
		sampled_time = 0.5
	elif hurt_time > 0.0:
		sampled_clip = "hurt"
		sampled_time = 0.24 - hurt_time
	elif speed > 0.15:
		sampled_clip = "walk"
		sampled_time = fposmod(gait, 0.8)
	skeleton.reset_bone_poses()
	Art.sample(player, sampled_clip, sampled_time)
	if reduced and sampled_clip not in ["walk", "defeat", "guard"]:
		# Keep the jaw and attacking limbs readable; quiet only secondary torso/tail motion.
		for bone in ["Chest", "Neck", "Tail00", "Tail01", "Tail02", "Tail03", "Tail04", "Tail05"]:
			var index = skeleton.find_bone(bone)
			var rest = skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
			skeleton.set_bone_pose_rotation(index, rest.slerp(skeleton.get_bone_pose_rotation(index), 0.65))
	feet.enabled = foot_lock_enabled
	feet.apply(dt, state)
	if feet.initialized and feet.moving:
		gait = feet.phase * 0.8
	lava.emission_energy_multiplier = 1.1 + clampf(state.heat / 100.0, 0.0, 1.0) * 0.8

## The mouth socket follows the actual skinned Head pose, including breath anticipation.
func muzzle_position() -> Vector3:
	var head = skeleton.find_bone("Head")
	return skeleton.global_transform * (skeleton.get_bone_global_pose(head) * Vector3(0, -0.10, -0.74))
