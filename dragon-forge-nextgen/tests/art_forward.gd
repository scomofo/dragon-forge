extends SceneTree
## Software-Vulkan acceptance smoke, not a GPU benchmark or manual playtest.
const Main = preload("res://world/main.tscn")
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL " + message)

func _capture(id: String) -> void:
	for frame in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	_check(not image.is_empty(), "nonempty Forward+ framebuffer")
	_check(image.save_png("res://artifacts/" + id + ".png") == OK, "Forward+ screenshot saved")
	print("FORWARD_SCREENSHOT " + id)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	_check(RenderingServer.get_current_rendering_method() == "forward_plus", "Forward+ is actually active")
	var world = Main.instantiate()
	world.test_mode = true
	root.add_child(world)
	await create_timer(0.25).timeout
	world.interact()
	world.progress.gate_open = true
	world.progress.clears = 2
	world._apply_progress()
	world.dragon.global_position = Vector3(-1.8, 0.1, -15)
	world.start_encounter()
	await create_timer(0.4).timeout
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	world.enemy.set_physics_process(false)
	world.dragon.rig.animate(0, 0, false, world.dragon.state)
	world.hud.toast_remaining = 0
	var state = world.dragon.state.duplicate(true)
	world.set_quality(0)
	_check(not world.environment.ssao_enabled and not world.environment.volumetric_fog_enabled, "Low disables costly effects")
	await _capture("forward-low-arena")
	world.set_quality(2)
	_check(world.environment.ssao_enabled and world.environment.volumetric_fog_enabled and world.environment.glow_enabled, "High enables AO, atmosphere and glow")
	_check(world.effects.particle_budget == 64, "High enables GPU particle budget")
	await _capture("forward-high-arena")
	world.set_reduced_motion(true)
	_check(not world.environment.volumetric_fog_enabled and not world.environment.glow_enabled, "calm mode removes moving atmosphere and glow")
	_check(world.dragon.state == state, "renderer presets do not mutate combat")
	await _capture("forward-high-reduced")
	world.queue_free()
	await process_frame
	print("NEXTGEN_FORWARD_ART: failures=%d" % failures)
	quit(1 if failures else 0)
