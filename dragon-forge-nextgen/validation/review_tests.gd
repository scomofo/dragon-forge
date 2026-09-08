extends SceneTree
## Harness tests; asset-quality findings are reported, never disguised as test passes.
const Studio = preload("res://validation/character_inspection.tscn")
const Arena = preload("res://validation/gameplay_arena.tscn")
const Probe = preload("res://validation/foot_review.gd")
var checks = 0
var failures = 0
var paths = ["user://nextgen-progress.json", "user://nextgen-preferences.json", "user://nextgen-progress.json.bak"]
var original: Dictionary = {}
func _initialize() -> void:
	_run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + message)
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func digest(path: String) -> String:
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "MISSING"
func _run() -> void:
	for path in paths:
		original[path] = digest(path)
	var studio = Studio.instantiate()
	root.add_child(studio)
	await frames(3)
	studio.playing = false
	check(studio.clips.size() == 9, "all nine shipped Magma clips are discoverable")
	check(studio.key.light_color == Color.WHITE and studio.rim.visible, "neutral key and strong rim available")
	check(studio.feet.valid, "sole probes resolve the shipped skin bindings")
	for i in range(studio.clips.size()):
		studio.select_clip(i)
		for fraction in [0.0, 0.5, 1.0]:
			studio.scrub(studio.player.get_animation(studio.clip).length * fraction)
			check(is_equal_approx(studio.player.current_animation_position, studio.clip_time), studio.clip + " exact sampled timeline at " + str(fraction))
			for points in studio.feet.points().values():
				check(points[0].is_finite(), studio.clip + " finite skinned support point")
	studio.select_clip(studio.clips.find("idle"))
	studio.scrub(0.0)
	var p: Vector3 = studio.feet.points().L[0]
	var rest: Vector3 = studio.feet.probes.L[0].vertex
	check(p.distance_to(studio.model.global_transform * rest) < 0.001, "CPU skin uses actual bind matrices at rest")
	studio.model.position = Vector3(2, 0, -3)
	studio.model.rotation.y = PI / 2
	check(studio.feet.points().L[0].distance_to(studio.model.global_transform * rest) < 0.001, "support points follow world translation and rotation")
	studio.model.transform = Transform3D.IDENTITY
	studio.feet.reset()
	studio.feet.sample(0.0, "idle", 0.0)
	studio.model.position.x = 0.1
	studio.feet.sample(1.0 / 60, "idle", 0.0)
	check(absf(studio.feet.max_drift - 0.1) < 0.001, "diagnostic detects a known 10 cm displacement")
	studio.model.transform = Transform3D.IDENTITY
	studio.scrub(0.1)
	studio.step_frame(1)
	check(is_equal_approx(studio.clip_time, 0.1 + 1.0 / 60), "single step advances one sixtieth of a second")
	check(not studio.playing and studio.feet.max_drift == 0.0, "scrubbing pauses and resets discontinuous drift")
	for view in range(5):
		studio.set_view(view)
		check(studio.camera.position.is_finite() and studio.camera.current, "inspection camera preset " + str(view))
	for mode in range(3):
		studio.set_material(mode)
		check(studio.actor_mesh.material_override != studio.source_material, "material review uses a private duplicate " + str(mode))
	studio.cycle_all = true
	studio.playing = true
	var old_clip: String = studio.clip
	studio.clip_time = studio.player.get_animation(studio.clip).length + 0.36
	await frames(2)
	check(studio.clip != old_clip, "automatic all-clip cycle advances")
	studio.load_actor(1)
	check(studio.player.has_animation("tell"), "Sentinel clips can be reviewed")
	check(not studio.feet.valid and studio.feet.error != "", "unsupported foot rig is explicit, not a false zero")
	studio.load_actor(2)
	check(studio.player.has_animation("open"), "Warden clips can be reviewed")
	studio.queue_free()
	await frames(2)
	var arena = Arena.instantiate()
	root.add_child(arena)
	await frames(3)
	check(arena.test_mode and arena.store.message == "", "arena skips normal save and preference loading")
	check(arena.camera_rig.get_script().resource_path == "res://presentation/camera_rig.gd", "exact gameplay camera is reused")
	check(arena.dragon.get_script().resource_path == "res://actors/dragon.gd", "exact player controller is reused")
	check(is_instance_valid(arena.enemy) and arena.enemy.boss, "real Warden actor active")
	check(arena.dragon.collision_mask & Probe.SURFACE_LAYER == 0, "review surfaces do not enter actor collision mask")
	arena.stage_index = 0
	arena.reset_stage()
	await frames(3)
	check(not is_instance_valid(arena.enemy), "no-enemy movement lane stays empty")
	check(arena.feet.latest.size() == 2 and is_finite(arena.feet.latest.L.clearance), "probes raycast the real imported deck")
	var baseline: Dictionary = arena.dragon.state.duplicate(true)
	arena.observe_frame(0.0)
	check(arena.dragon.state == baseline, "read-only diagnostics preserve combat")
	for scenario in [3, 4, 5, 6]:
		arena.scenario = scenario
		arena.start_replay()
		await frames(82)
		arena.stop_replay()
		check(arena.start_events.size() == 1 and arena.contact_events.size() == 1, "replay " + str(scenario) + " triggers one actual start and contact")
		if not arena.contact_events.is_empty():
			var hit: Dictionary = arena.contact_events[0]
			check(absf(hit.action_time - hit.authored_windup) <= 1.0 / 60 + 0.00001, hit.id + " contact matches live simulation within one physics tick")
	arena.scenario = 1
	arena.start_replay()
	var start: Vector3 = arena.dragon.position
	await frames(52)
	check(arena.dragon.position.distance_to(start) > 1.0 and arena.dragon.rig.sampled_clip == "walk", "walk replay uses actual collision movement and rig")
	paused = true
	await frames(2)
	check(not arena.replaying and not Input.is_action_pressed("ng_up"), "pause releases injected inputs")
	var frozen: Dictionary = arena.dragon.state.duplicate(true)
	var t: float = arena.review_clock
	await frames(3)
	check(arena.dragon.state == frozen and arena.review_clock == t, "pause freezes combat and measurements together")
	paused = false
	arena.reset_stage()
	arena.scenario = 7
	arena.start_replay()
	await frames(65)
	arena.stop_replay()
	check(not arena.contact_events.is_empty(), "moving breath uses authoritative contact")
	print("BASELINE_FOOT_REVIEW: max near-surface drift %.4f m; min clearance %.4f m (informational, not an art-quality pass)" % [arena.feet.max_drift, arena.feet.min_clearance])
	var report: Dictionary = arena.review_report()
	check(report.context.time_scale == 1.0 and report.context.save_writes == false, "report records 1x playback and save isolation")
	check(report.asset_sha256.length() == 64 and report.samples.size() > 0, "report contains shipped-asset hash and actual samples")
	check(JSON.parse_string(JSON.stringify(report)) is Dictionary, "report serializes without non-finite JSON values")
	arena.scenario = 4
	arena.start_replay()
	arena.freeze_next_contact = true
	await frames(55)
	check(paused and arena.contact_events.size() == 1, "contact freeze occurs after one real hit")
	check(arena.dragon.rig.sampled_clip == "breath", "contact freeze retains the real sampled attack pose")
	var resume_key = InputEventKey.new()
	resume_key.physical_keycode = KEY_F10
	resume_key.pressed = true
	Input.parse_input_event(resume_key)
	await frames(2)
	resume_key.pressed = false
	Input.parse_input_event(resume_key)
	check(not paused, "review resume works while simulation is paused")
	arena.set_reduced_motion(true)
	arena.set_quality(0)
	await frames(2)
	check(arena.test_mode and arena.feet.valid, "calm and low quality retain instrumentation")
	arena.reset_stage()
	check(arena.contact_events.is_empty() and arena.feet.frames.is_empty(), "reset clears old measurements")
	arena.queue_free()
	await frames(2)
	for action in ["ng_up", "ng_down", "ng_guard", "ng_breath"]:
		check(not Input.is_action_pressed(action), "scene exit releases " + action)
	for path in paths:
		check(digest(path) == original[path], "normal user file untouched: " + path)
	print("NEXTGEN_REVIEW_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
