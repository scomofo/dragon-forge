extends SceneTree
## Compare independent CPU skin samples with/without the runtime foot correction.
## Baseline uses the SAME revised GLB and exact actor transform/clip sample per frame.
const Arena = preload("res://validation/gameplay_arena.tscn")
const Studio = preload("res://validation/character_inspection.tscn")
const Art = preload("res://presentation/art_library.gd")
const Probe = preload("res://validation/foot_review.gd")
const Combat = preload("res://sim/combat.gd")
var arena
var raw_model: Node3D
var raw_player: AnimationPlayer
var raw_feet
var results: Array = []
var starts: Dictionary = {}
var raw_starts: Dictionary = {}
var max_drift = 0.0
var raw_drift = 0.0
var min_clearance = INF
var min_any_clearance = INF
var locks = 0
var swings = 0
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func frames(count: int, collect: bool = true) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
		if not collect:
			continue
		var rig = arena.dragon.rig
		raw_model.global_transform = rig.model.global_transform
		Art.sample(raw_player, rig.sampled_clip, rig.sampled_time)
		var actual: Dictionary = arena.feet.points()
		var uncorrected: Dictionary = raw_feet.points()
		for side in ["L", "R"]:
			if arena.feet.latest.has(side):
				min_any_clearance = minf(min_any_clearance, arena.feet.latest[side].clearance)
			if not rig.feet.samples.has(side):
				continue
			var plant: Dictionary = rig.feet.samples[side]
			if not plant.planted:
				swings += 1
				continue
			locks += 1
			var center = average(actual[side])
			var raw_center = average(uncorrected[side])
			var key = str(plant.plant_id)
			if not starts.has(key):
				starts[key] = center
				raw_starts[key] = raw_center
			max_drift = maxf(max_drift, horizontal(center-starts[key]))
			raw_drift = maxf(raw_drift, horizontal(raw_center-raw_starts[key]))
			if arena.feet.latest.has(side):
				min_clearance = minf(min_clearance,arena.feet.latest[side].clearance)
func average(points: Array) -> Vector3:
	var center = Vector3.ZERO
	for point in points:
		center += point
	return center / points.size()
func horizontal(point: Vector3) -> float:
	return Vector2(point.x,point.z).length()
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var studio = Studio.instantiate()
	root.add_child(studio)
	await frames(3,false)
	studio.playing = false
	# Frozen extremities are checked in raw imported animation, not hidden behind IK.
	for clip in ["claw","breath","wall","burst","guard","hurt"]:
		studio.select_clip(studio.clips.find(clip))
		studio.scrub(0)
		var start: Dictionary = studio.feet.points()
		var worst = 0.0
		for i in range(41):
			studio.scrub(studio.player.get_animation(clip).length * i / 40.0)
			var points: Dictionary = studio.feet.points()
			for side in ["L","R"]:
				worst = maxf(worst,average(points[side]).distance_to(average(start[side])))
		check(worst < 0.012, clip + " baked stationary sole displacement < 12 mm")
	studio.select_clip(studio.clips.find("breath"))
	studio.scrub(0.22)
	var jaw = studio.skeleton.find_bone("Jaw")
	check(studio.skeleton.get_bone_pose_rotation(jaw).get_angle() <= 0.501, "jaw opening limited to corrected 0.50 rad hinge pose")
	check(studio.actor_mesh.get_active_material(0).albedo_texture.get_width() == 2048, "repainted 2048 atlas is actually imported")
	studio.queue_free()
	await frames(2,false)
	arena = Arena.instantiate()
	root.add_child(arena)
	arena.stage_index = 0
	arena.reset_stage()
	raw_model = Art.place(arena,"magma_guardian")
	raw_model.visible = false
	raw_player = raw_model.find_child("AnimationPlayer",true,false)
	raw_player.process_mode = Node.PROCESS_MODE_DISABLED
	raw_feet = Probe.new()
	arena.add_child(raw_feet)
	check(raw_feet.configure(raw_model,"magma_guardian"), "independent uncorrected skin sampler configured")
	await frames(15,false)
	for scenario in range(1,8):
		starts.clear();raw_starts.clear();max_drift=0;raw_drift=0;min_clearance=INF;min_any_clearance=INF;locks=0;swings=0
		arena.scenario=scenario
		arena.start_replay()
		await frames(220)
		check(locks > 160,"scenario %d has real contact coverage, not all feet released" % scenario)
		check(max_drift < 0.015,"scenario %d actual skinned stance drift < 15 mm" % scenario)
		check(min_any_clearance >= -0.012,"scenario %d lift/turn/settle samples stay above deck" % scenario)
		check(min_clearance >= -0.01,"scenario %d planted soles do not sink through visible deck" % scenario)
		if scenario in [1,2,7]:
			check(swings > 20 and starts.size() >= 4,"scenario %d has alternating lift/replant contacts" % scenario)
			check(max_drift < raw_drift*.2,"scenario %d reduces same-window uncorrected drift by >80%%" % scenario)
		results.append({"scenario":arena.SCENARIOS[scenario],"locked_samples":locks,"swing_samples":swings,"plant_intervals":starts.size(),"corrected_stance_drift_m":max_drift,"uncorrected_same_window_drift_m":raw_drift,"min_planted_clearance_m":min_clearance,"min_all_sample_clearance_m":min_any_clearance})
		print("POLISH_METRIC " + JSON.stringify(results[-1]))
	arena.stop_replay()
	arena.review_key(KEY_F11)
	check(not arena.dragon.rig.foot_lock_enabled,"F11 enables real uncorrected A/B comparison")
	arena.review_key(KEY_F11)
	check(arena.dragon.rig.foot_lock_enabled,"F11 restores the live correction")
	var state: Dictionary = arena.dragon.state.duplicate(true)
	arena.dragon.rig.animate(0,0,false,state)
	check(state == arena.dragon.state,"grounding does not mutate combat state")
	for quality in range(4):
		arena.set_quality(quality)
		check(arena.dragon.collision_mask & 64 == 0,"quality %d support rays excluded from gameplay collision" % quality)
	arena.set_reduced_motion(true)
	arena.scenario=4;arena.start_replay()
	await frames(65,false)
	check(arena.dragon.rig.feet.samples.size() == 2,"reduced motion retains foot solver")
	arena.stop_replay()
	arena.dragon.state.dash = 0.2
	arena.dragon.rig.animate(1.0/60,0,true,arena.dragon.state)
	check(arena.dragon.rig.feet.samples.is_empty(),"dodge explicitly releases locks")
	arena.dragon.respawn(Vector3(0,0.1,-18))
	check(not arena.dragon.rig.feet.initialized,"respawn discards old world anchors")
	await frames(20,false)
	check(arena.dragon.rig.feet.initialized,"solver reacquires actual dais surface after respawn")
	arena.dragon.state.hp=0
	arena.dragon.rig.animate(1.0/60,0,false,arena.dragon.state)
	check(arena.dragon.rig.feet.samples.is_empty(),"defeat does not pin the falling actor")
	var file=FileAccess.open("res://artifacts/magma-polish-metrics.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"engine":Engine.get_version_info().string,"asset_sha256":FileAccess.get_sha256("res://art/generated/magma_guardian.glb"),"method":"Independent CPU skin samples; same revised asset/actor transform/clip/time with IK disabled as paired baseline. Contact intervals come from active travel-phase contract, not proximity.","results":results},"  "))
	file.close()
	arena.queue_free()
	await frames(2,false)
	print("NEXTGEN_POLISH_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
