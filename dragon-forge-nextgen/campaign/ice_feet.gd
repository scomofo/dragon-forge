extends RefCounted
## Presentation-only, analytic two-bone solver. Never moves the collider or combat clock.
## Contacts are authored in normalized travel phase, not inferred from surface proximity.
const SURFACE_LAYER = 64
const STRIDE = 1.20 # metres per complete diagonal-pair travel cycle
const DUTY = 0.58
const LIFT = 0.12
const SETTLE_TIME = 0.12
var skeleton: Skeleton3D
var rig: Node3D
var legs: Dictionary = {}
var phase = 0.0
var last_origin = Vector3.ZERO
var initialized = false
var sequence = 0
var moving = false
var samples: Dictionary = {}
var enabled = true

func configure(owner_rig: Node3D) -> void:
	rig = owner_rig
	skeleton = rig.skeleton
	var mesh: MeshInstance3D = rig.model.find_children("*", "MeshInstance3D", true, false)[0]
	var arrays = mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride = weights.size() / vertices.size()
	for side in ["FL", "FR", "RL", "RR"]:
		var foot = skeleton.find_bone("Foot." + side)
		var bind = -1
		for i in range(mesh.skin.get_bind_count()):
			if mesh.skin.get_bind_name(i) == StringName("Foot." + side):
				bind = i
		var candidates: Array = []
		var low = INF
		for v in range(vertices.size()):
			var influence = 0.0
			for k in range(int(stride)):
				if joints[v * int(stride) + k] == bind:
					influence += weights[v * int(stride) + k]
			if influence >= 0.8:
				candidates.append(vertices[v])
				low = minf(low, vertices[v].y)
		var center = Vector3.ZERO
		var count = 0
		for p in candidates:
			if p.y <= low + 0.025:
				center += p
				count += 1
		assert(count > 0, "Rime foot contact requires weighted sole geometry")
		center /= count
		var rest = skeleton.get_bone_global_rest(foot)
		legs[side] = {"hip": skeleton.find_bone("Thigh." + side), "knee": skeleton.find_bone("Hock." + side), "foot": foot,
			"rest_center": center, "sole": rest.affine_inverse() * center, "height": center.y-low+0.004,
			"planted": false, "anchor": Vector3.ZERO, "basis": Basis.IDENTITY, "from": Vector3.ZERO,
			"last": Vector3.ZERO, "settle": 0.0, "id": 0, "blocked": false}
	reset()

func reset() -> void:
	initialized = false
	phase = 0.0
	moving = false
	samples.clear()
	for leg in legs.values():
		leg.planted = false
		leg.blocked = false
		leg.settle = 0.0

func _ground(at: Vector3, height: float) -> Dictionary:
	var query = PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.25, at - Vector3.UP * 1.5, SURFACE_LAYER)
	var hit = rig.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty() or hit.normal.dot(Vector3.UP) < 0.85:
		return {}
	return {"position": Vector3(at.x, hit.position.y + height, at.z), "normal": hit.normal}

func apply(delta: float, state: Dictionary) -> void:
	if not enabled or not rig.is_inside_tree():
		reset()
		return
	var origin = rig.global_position
	var displacement = origin - last_origin if initialized else Vector3.ZERO
	displacement.y = 0.0
	var teleported = initialized and origin.distance_to(last_origin) > 1.0
	if teleported:
		reset()
		displacement = Vector3.ZERO
	var parent = rig.get_parent()
	var grounded = parent.is_on_floor() if parent is CharacterBody3D else true
	if state.hp <= 0.0 or state.dash > 0.0 or not grounded:
		reset()
		last_origin = origin
		return
	var was_moving = moving
	moving = delta > 0.0 and displacement.length() > 0.0001
	if moving:
		phase = fposmod(phase + displacement.length() / STRIDE, 1.0)
	var direction = displacement.normalized() if moving else Vector3.ZERO
	var yaw_basis = Basis(Vector3.UP, rig.global_rotation.y)
	samples.clear()
	for side in ["FL", "FR", "RL", "RR"]:
		var leg: Dictionary = legs[side]
		var nominal: Vector3 = rig.global_transform * leg.rest_center
		var ground = _ground(nominal + direction * (STRIDE * DUTY * 0.5), leg.height)
		if ground.is_empty():
			leg.planted = false
			continue
		var p = fposmod(phase + (0.5 if side in ["FR", "RL"] else 0.0), 1.0)
		var want_plant = not moving or p < DUTY
		# Release rather than dragging or overstretching a planted leg after sharp turns.
		if leg.planted and Vector2(nominal.x-leg.anchor.x, nominal.z-leg.anchor.z).length() > 0.48:
			leg.planted = false
			leg.blocked = true
			leg.from = leg.last
			leg.settle = 0.0
		if not want_plant:
			leg.blocked = false
		var target: Vector3
		if not initialized:
			leg.last = _ground(nominal, leg.height).get("position", ground.position)
			leg.from = leg.last
			leg.basis = yaw_basis
			leg.planted = true
			leg.anchor = leg.last
			sequence += 1
			leg.id = sequence
		if leg.planted and not want_plant:
			leg.planted = false
			leg.from = leg.anchor
			leg.settle = 0.0
		if not leg.planted and want_plant:
			if moving and not leg.blocked:
				# Touch down where the swing actually ended; no horizontal target snap.
				var landing = _ground(leg.last, leg.height)
				if not landing.is_empty():
					leg.anchor = landing.position
					leg.planted = true
				else:
					# The previous sole may be over a gap; never solve to Vector3.ZERO.
					leg.blocked = true
					leg.from = leg.last
					target = ground.position
			else:
				# Stop/reversal/reach recovery: explicit small landing, not an endless lock.
				if was_moving and not moving:
					leg.from = leg.last
					leg.settle = 0.0
				leg.settle = minf(1.0, leg.settle + maxf(0, delta) / SETTLE_TIME)
				target = leg.from.lerp(ground.position, smoothstep(0, 1, leg.settle))
				if leg.settle >= 1.0:
					leg.anchor = ground.position
					leg.planted = true
					leg.blocked = false
			if leg.planted:
				sequence += 1
				leg.id = sequence
				leg.basis = yaw_basis
		if leg.planted:
			target = leg.anchor
		elif not want_plant:
			var swing = clampf((p - DUTY) / (1.0 - DUTY), 0.0, 1.0)
			target = leg.from.lerp(ground.position, smoothstep(0, 1, swing))
			target.y += sin(swing * PI) * LIFT
			leg.basis = leg.basis.slerp(yaw_basis, minf(maxf(delta,0) * 18, 1))
		# A lock is released BEFORE an unreachable target can drag the support foot.
		var hip_pose = skeleton.get_bone_global_pose(leg.hip)
		var knee_pose = skeleton.get_bone_global_pose(leg.knee)
		var foot_pose = skeleton.get_bone_global_pose(leg.foot)
		var reach_limit = hip_pose.origin.distance_to(knee_pose.origin) + knee_pose.origin.distance_to(foot_pose.origin) - 0.012
		var required = (skeleton.global_transform.affine_inverse() * (target - leg.basis * leg.sole)).distance_to(hip_pose.origin)
		if leg.planted and required > reach_limit:
			leg.planted = false
			leg.blocked = true
			leg.from = leg.last
			leg.settle = 0.0
			target = leg.from
		if not leg.planted:
			leg.basis = leg.basis.slerp(yaw_basis, minf(maxf(delta,0) * 18, 1))
		if not leg.planted:
			var swing_surface = _ground(target, leg.height)
			if not swing_surface.is_empty():
				target.y = maxf(target.y, swing_surface.position.y)
		var error = _solve(leg, target, leg.basis, -1 if side in ["FL", "RL"] else 1)
		leg.last = skeleton.global_transform * (skeleton.get_bone_global_pose(leg.foot) * leg.sole)
		samples[side] = {"planted": leg.planted, "plant_id": leg.id, "target": target, "reach_error": error, "phase": p}
	last_origin = origin
	initialized = true

func _solve(leg: Dictionary, support: Vector3, world_basis: Basis, sign_value: int) -> float:
	var transform = skeleton.global_transform
	var desired_basis = transform.basis.inverse() * world_basis
	var goal = transform.affine_inverse() * (support - world_basis * leg.sole)
	var hip: Transform3D = skeleton.get_bone_global_pose(leg.hip)
	var knee: Transform3D = skeleton.get_bone_global_pose(leg.knee)
	var foot: Transform3D = skeleton.get_bone_global_pose(leg.foot)
	var upper = knee.origin.distance_to(hip.origin)
	var lower = foot.origin.distance_to(knee.origin)
	var offset: Vector3 = goal - hip.origin
	var actual = offset.length()
	var length = clampf(actual, absf(upper-lower)+0.001, upper+lower-0.001)
	var axis = offset.normalized()
	var pole = Vector3(sign_value * 0.28, 0.0, -1.0)
	pole = (pole - axis * pole.dot(axis)).normalized()
	if pole.length() < 0.1:
		pole = Vector3.RIGHT
	var along = (upper*upper - lower*lower + length*length) / (2.0*length)
	var bend = sqrt(maxf(0,upper*upper-along*along))
	var elbow = hip.origin + axis*along + pole*bend
	_set_global_rotation(leg.hip, Basis(Quaternion((knee.origin-hip.origin).normalized(), (elbow-hip.origin).normalized())) * hip.basis)
	knee = skeleton.get_bone_global_pose(leg.knee)
	foot = skeleton.get_bone_global_pose(leg.foot)
	var end = hip.origin + axis*length
	_set_global_rotation(leg.knee, Basis(Quaternion((foot.origin-knee.origin).normalized(),(end-knee.origin).normalized())) * knee.basis)
	_set_global_rotation(leg.foot, desired_basis)
	return absf(actual-length)

func _set_global_rotation(bone: int, basis: Basis) -> void:
	var parent = skeleton.get_bone_parent(bone)
	var parent_basis = skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	skeleton.set_bone_pose_rotation(bone, (parent_basis.inverse()*basis).orthonormalized().get_rotation_quaternion())
