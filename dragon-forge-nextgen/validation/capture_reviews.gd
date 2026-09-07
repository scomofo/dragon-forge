extends SceneTree
## Captures the interactive scenes, not a substitute beauty-render setup.
const Studio = preload("res://validation/character_inspection.tscn")
const Arena = preload("res://validation/gameplay_arena.tscn")
var failures = 0
var folder = "res://artifacts/review-scenes"
func _initialize() -> void:
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func capture(id: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	if image.save_png(folder + "/" + id + ".png") != OK:
		failures += 1
	print("REVIEW_CAPTURE " + id)
func report(id: String, data: Dictionary) -> void:
	var file = FileAccess.open(folder + "/" + id + ".json", FileAccess.WRITE)
	if file == null:
		failures += 1
	else:
		file.store_string(JSON.stringify(data, "  "))
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	var studio = Studio.instantiate()
	root.add_child(studio)
	await frames(10)
	studio.playing = false
	studio.select_clip(studio.clips.find("idle"))
	studio.scrub(0.0)
	await capture("inspection-full")
	studio.select_clip(studio.clips.find("breath"))
	studio.scrub(0.22)
	studio.set_view(3)
	await capture("inspection-jaw")
	studio.set_view(1)
	studio.select_clip(studio.clips.find("claw"))
	studio.scrub(0.1)
	studio.set_material(2)
	await capture("inspection-shoulder-clay")
	studio.set_view(2)
	studio.set_material(0)
	studio.select_clip(studio.clips.find("wall"))
	studio.scrub(0.2)
	await capture("inspection-hips")
	studio.set_view(0)
	studio.select_clip(studio.clips.find("walk"))
	studio.playing = true
	await frames(34)
	studio.playing = false
	report("studio-walk", studio.feet.report({"scene": "character_inspection", "in_place": true}))
	await capture("inspection-walk-probes")
	studio.queue_free()
	await frames(2)
	var arena = Arena.instantiate()
	root.add_child(arena)
	await frames(28)
	paused = true
	await capture("arena-real-camera")
	paused = false
	arena.stage_index = 0
	arena.scenario = 7
	arena.start_replay()
	arena.freeze_next_contact = true
	var deadline = Time.get_ticks_msec() + 30000
	while not paused and Time.get_ticks_msec() < deadline:
		await process_frame
	if not paused:
		failures += 1
		print("FAIL contact capture did not pause")
		paused = true
	arena.stop_replay()
	await capture("arena-moving-breath")
	report("arena-moving-breath", arena.review_report())
	paused = false
	arena.scenario = 1
	arena.start_replay()
	await frames(70)
	arena.stop_replay()
	paused = true
	await capture("arena-walk-stop")
	report("arena-walk-stop", arena.review_report())
	paused = false
	arena.set_quality(0)
	arena.set_reduced_motion(true)
	arena.stage_index = 2
	arena.reset_stage()
	await frames(24)
	paused = true
	await capture("arena-low-calm")
	arena.review_box.visible = false
	arena.feet.display_enabled = false
	arena.feet._draw()
	await capture("arena-clean-gameplay")
	paused = false
	arena.queue_free()
	await frames(2)
	print("NEXTGEN_REVIEW_CAPTURES: failures=%d" % failures)
	quit(1 if failures else 0)
