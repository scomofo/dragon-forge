extends SceneTree
## Motion evidence from actual controller replay; timestamps are saved, not inferred FPS.
const Arena = preload("res://validation/gameplay_arena.tscn")
var arena
var captures: Array = []
var failures = 0
func _initialize() -> void:
	_run.call_deferred()
func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/foot-motion")
	arena = Arena.instantiate()
	root.add_child(arena)
	arena.stage_index = 0
	arena.reset_stage()
	await frames(16)
	arena.scenario = 1
	arena.start_replay()
	for i in range(36):
		await frames(2)
		await RenderingServer.frame_post_draw
		var file = "step-%02d.png" % i
		var image = root.get_texture().get_image()
		if image.save_png("res://artifacts/foot-motion/"+file) != OK:
			failures += 1
		captures.append({"file":file,"simulation_time":arena.review_clock,"clip":arena.dragon.rig.sampled_clip,"phase":arena.dragon.rig.feet.phase})
	var out = FileAccess.open("res://artifacts/foot-motion/frames.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"source":"actual gameplay validation scene, unchanged camera and 1x simulation", "frames":captures},"  "))
	out.close()
	arena.stop_replay()
	arena.queue_free()
	await process_frame
	print("NEXTGEN_POLISH_MOTION: %d frames, %d failures" % [captures.size(),failures])
	quit(1 if failures else 0)
