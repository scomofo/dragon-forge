extends SceneTree
const Main = preload("res://world/main.tscn")
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func _capture(name_text: String) -> void:
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	var result = image.save_png("res://artifacts/" + name_text + ".png")
	if result != OK:
		failures += 1
	print("SCREENSHOT %s result=%d size=%s" % [name_text, result, image.get_size()])

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts"))
	var world = Main.instantiate()
	world.test_mode = true
	root.add_child(world)
	await create_timer(0.6).timeout
	await _capture("forge")
	world.interact()
	world.progress.gate_open = true
	world.progress.clears = 2
	world._apply_progress()
	world.dragon.global_position = Vector3(0, 0.1, -15)
	world.start_encounter()
	await create_timer(0.8).timeout
	world.dragon.try_ability("burst")
	await create_timer(0.15).timeout
	await _capture("arena")
	world.set_reduced_motion(true)
	await create_timer(0.2).timeout
	await _capture("reduced-motion")
	world.hud.set_pause(true)
	await create_timer(0.15).timeout
	await _capture("settings")
	world.hud.set_pause(false)
	print("NEXTGEN_VISUAL_SMOKE: failures=%d" % failures)
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
