extends Node3D
## Read-only measurements of actual skinned sole vertices, not ankle-bone motion.
## CONTACT means near the review surface, NOT an authored contact event or IK lock.
const Geo = preload("res://presentation/geometry.gd")
const SURFACE_LAYER = 128
const MAX_SAMPLES = 7200
const PROXIMITY = 0.06
const DRIFT_LIMIT = 0.03
const SINK_LIMIT = -0.02
var skeleton: Skeleton3D
var mesh: MeshInstance3D
var probes: Dictionary = {}
var binds: Array = []
var frames: Array = []
var latest: Dictionary = {}
var anchors: Dictionary = {}
var elapsed = 0.0
var dropped = 0
var max_drift = 0.0
var min_clearance = INF
var display_enabled = true
var lines: MeshInstance3D
var geometry: ImmediateMesh
var markers: Dictionary = {}
var valid = false
var error = ""
var asset_id = ""
var stance_anchors: Dictionary = {}
var max_stance_drift = 0.0
var stance_samples = 0
var plant_states: Dictionary = {}

func _ready() -> void:
	geometry = ImmediateMesh.new()
	lines = MeshInstance3D.new()
	lines.mesh = geometry
	lines.material_override = Geo.material(Color.WHITE, 0, true)
	lines.material_override.vertex_color_use_as_albedo = true
	lines.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lines)
	for foot in ["L", "R"]:
		markers[foot] = Geo.ring(self, Vector3.ZERO, 0.16, Geo.material(Color("75ddca"), 0, true), 0.015)
		markers[foot].visible = false

func configure(model: Node3D, id: String) -> bool:
	asset_id = id
	valid = false
	probes.clear()
	binds.clear()
	reset()
	skeleton = model.find_child("Skeleton3D", true, false)
	var meshes = model.find_children("*", "MeshInstance3D", true, false)
	if skeleton == null or meshes.is_empty():
		error = "No skeleton or skinned mesh"
		return false
	mesh = meshes[0]
	if mesh.skin == null:
		error = "No skin bindings"
		return false
	for i in range(mesh.skin.get_bind_count()):
		var bone_name = mesh.skin.get_bind_name(i)
		var bone = skeleton.find_bone(bone_name) if bone_name != &"" else mesh.skin.get_bind_bone(i)
		if bone < 0 or bone >= skeleton.get_bone_count():
			error = "Unresolved skin joint"
			return false
		binds.append({"bone": bone, "inverse": mesh.skin.get_bind_pose(i)})
	var arrays = mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var joints: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride = int(weights.size() / vertices.size())
	if stride not in [4, 8]:
		error = "Unsupported skin influence count"
		return false
	for side in ["L", "R"]:
		var bone = skeleton.find_bone("Foot." + side)
		if bone < 0:
			error = "Foot." + side + " not present\nSole diagnostics unavailable for this rig"
			return false
		var candidates: Array = []
		var low = INF
		for v in range(vertices.size()):
			var influence = 0.0
			for k in range(stride):
				var j = joints[v * stride + k]
				if weights[v * stride + k] > 0.0 and binds[j].bone == bone:
					influence += weights[v * stride + k]
			if influence >= 0.8:
				candidates.append(v)
				low = minf(low, vertices[v].y)
		var sole: Array = []
		for v in candidates:
			if vertices[v].y <= low + 0.025:
				sole.append(v)
		if sole.is_empty():
			error = "No weighted sole vertices"
			return false
		probes[side] = []
		for k in range(mini(8, sole.size())):
			var v: int = sole[int(k * sole.size() / mini(8, sole.size()))]
			var influences: Array = []
			for j in range(stride):
				if weights[v * stride + j] > 0.0:
					influences.append([joints[v * stride + j], weights[v * stride + j]])
			probes[side].append({"vertex": vertices[v], "influences": influences})
	valid = true
	error = ""
	return true

func reset() -> void:
	frames.clear()
	latest.clear()
	anchors.clear()
	stance_anchors.clear()
	max_stance_drift = 0.0
	stance_samples = 0
	plant_states.clear()
	elapsed = 0.0
	dropped = 0
	max_drift = 0.0
	min_clearance = INF
	if geometry != null:
		geometry.clear_surfaces()
	for marker in markers.values():
		marker.visible = false

func points() -> Dictionary:
	var result: Dictionary = {}
	if not valid:
		return result
	var palette: Array = []
	for bind in binds:
		palette.append(skeleton.get_bone_global_pose(bind.bone) * bind.inverse)
	for foot in probes:
		result[foot] = []
		for probe in probes[foot]:
			var point = Vector3.ZERO
			for influence in probe.influences:
				point += (palette[influence[0]] * probe.vertex) * influence[1]
			result[foot].append(skeleton.global_transform * point)
	return result

func sample(delta: float, clip: String, clip_time: float, label: String = "", authored_plants: Dictionary = {}) -> void:
	if not valid or not is_inside_tree():
		return
	elapsed += maxf(0.0, delta)
	plant_states = authored_plants.duplicate(true)
	var world_points = points()
	for foot in world_points:
		var center = Vector3.ZERO
		var low = INF
		for p in world_points[foot]:
			center += p
			low = minf(low, p.y)
		center /= world_points[foot].size()
		var ray = PhysicsRayQueryParameters3D.create(center + Vector3.UP * 1.5, center - Vector3.UP * 3.0, SURFACE_LAYER)
		var hit = get_world_3d().direct_space_state.intersect_ray(ray)
		var distance = low - hit.position.y if not hit.is_empty() else INF
		var contact = is_finite(distance) and distance <= PROXIMITY and distance >= -0.25
		if contact and not anchors.has(foot):
			anchors[foot] = center
		elif not contact:
			anchors.erase(foot)
		var drift = Vector2(center.x - anchors[foot].x, center.z - anchors[foot].z).length() if anchors.has(foot) else 0.0
		max_drift = maxf(max_drift, drift)
		if is_finite(distance):
			min_clearance = minf(min_clearance, distance)
		var plant: Dictionary = authored_plants.get(foot, {})
		var stance_drift = 0.0
		if plant.get("planted", false):
			var key = str(plant.plant_id)
			if not stance_anchors.has(key):
				stance_anchors[key] = center
				if stance_anchors.size() > 256:
					stance_anchors.erase(stance_anchors.keys()[0])
			stance_drift = Vector2(center.x-stance_anchors[key].x,center.z-stance_anchors[key].z).length()
			max_stance_drift = maxf(max_stance_drift, stance_drift)
			stance_samples += 1
		latest[foot] = {"position": center, "surface_y": hit.position.y if not hit.is_empty() else INF, "clearance": distance, "contact": contact, "drift": drift, "authored": not plant.is_empty(), "planted": plant.get("planted", false), "stance_drift": stance_drift}
		if frames.size() < MAX_SAMPLES:
			frames.append({"t": elapsed, "foot": foot, "clip": clip, "clip_time": clip_time, "context": label, "world": [center.x, low, center.z], "surface_y": hit.position.y if not hit.is_empty() else null, "clearance_m": distance if is_finite(distance) else null, "near_surface": contact, "drift_m": drift, "authored_plant": plant.get("planted", false), "plant_id": plant.get("plant_id", -1), "stance_drift_m": stance_drift})
		else:
			dropped += 1
	_draw()

func _draw() -> void:
	geometry.clear_surfaces()
	for foot in markers:
		markers[foot].visible = display_enabled and latest.has(foot)
	if not display_enabled or latest.is_empty():
		return
	geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	for foot in latest:
		var reading = latest[foot]
		var p: Vector3 = reading.position
		var displayed_drift = reading.stance_drift if reading.get("authored", false) else reading.drift
		var tint = Color("ffa46a") if displayed_drift > DRIFT_LIMIT or reading.clearance < SINK_LIMIT else Color("75ddca")
		if reading.get("authored", false) and not reading.planted and reading.clearance >= SINK_LIMIT:
			tint = Color("88abda")
		var marker_y = maxf(p.y, reading.surface_y) if is_finite(reading.surface_y) else p.y
		markers[foot].global_position = Vector3(p.x, marker_y + 0.025, p.z)
		markers[foot].material_override.albedo_color = tint
		geometry.surface_set_color(tint)
		geometry.surface_add_vertex(to_local(p))
		geometry.surface_add_vertex(to_local(p + Vector3.UP * 0.5))
		if anchors.has(foot):
			geometry.surface_add_vertex(to_local(p + Vector3.UP * 0.03))
			geometry.surface_add_vertex(to_local(anchors[foot] + Vector3.UP * 0.03))
	geometry.surface_end()

func readout() -> String:
	if not valid:
		return error
	var words = "Sole probes / visible surface"
	for foot in ["L", "R"]:
		if latest.has(foot):
			var r = latest[foot]
			var height = "%+.1f cm" % (r.clearance * 100) if is_finite(r.clearance) else "no surface"
			var d = r.stance_drift if r.get("authored", false) else r.drift
			words += "\n%s: %s | drift %.1f cm" % [foot, height, d * 100]
	if not plant_states.is_empty():
		var left = "LOCK" if plant_states.get("L", {}).get("planted", false) else "SWING"
		var right = "LOCK" if plant_states.get("R", {}).get("planted", false) else "SWING"
		return words + "\nAuthored: L %s / R %s\nStance drift max %.2f cm" % [left, right, max_stance_drift*100]
	return words + "\nNear-surface drift, NOT an IK lock"

func report(context: Dictionary) -> Dictionary:
	return {"schema": 1, "context": context, "engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "asset": asset_id, "asset_sha256": FileAccess.get_sha256("res://art/generated/" + asset_id + ".glb"), "method": "CPU skin of up to eight lowest-rest sole vertices per foot; vertical ray at centroid against review-only surface mesh. Proximity is not an authored plant window. In-place studio walk cannot certify locomotion planting.", "thresholds_m": {"proximity": PROXIMITY, "max_penetration_for_drift": 0.25, "review_drift": DRIFT_LIMIT, "review_penetration": SINK_LIMIT}, "max_drift_m": max_drift, "max_authored_stance_drift_m": max_stance_drift, "authored_stance_samples": stance_samples, "min_clearance_m": min_clearance if is_finite(min_clearance) else null, "samples_dropped": dropped, "samples": frames}

static func surface(parent: Node3D, source: Mesh, transform: Transform3D) -> StaticBody3D:
	var body = StaticBody3D.new()
	body.collision_layer = SURFACE_LAYER
	body.collision_mask = 0
	body.transform = transform
	var collider = CollisionShape3D.new()
	collider.shape = source.create_trimesh_shape()
	body.add_child(collider)
	parent.add_child(body)
	return body

static func save_report(data: Dictionary) -> String:
	var folder = "user://validation_reviews"
	if DirAccess.make_dir_recursive_absolute(folder) != OK:
		return "ERROR: could not create report folder"
	var path = folder + "/review-%d-%d.json" % [Time.get_unix_time_from_system(), Time.get_ticks_msec()]
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return "ERROR: could not write review report"
	file.store_string(JSON.stringify(data, "  "))
	file.flush()
	if file.get_error() != OK:
		return "ERROR: incomplete review report"
	return path
