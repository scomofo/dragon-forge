extends SceneTree
## Real engine captures. Scripted setup is not a manual playtest or a benchmark.
const Main = preload("res://world/main.tscn")
const Combat = preload("res://sim/combat.gd")
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func _capture(name_text: String) -> void:
	await process_frame
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
	await create_timer(0.5).timeout
	if world.hud.abilities[0].status.text != "AWAITING HATCH":
		failures += 1
	await _capture("forge")
	world.interact()
	world.dragon.global_position = Vector3(0, 0.1, 5.5)
	world.dragon.input_grace = 0.0
	world.dragon.aim = (world.conduits[0].node.position - world.dragon.position).normalized()
	world.dragon.try_ability("breath")
	await create_timer(0.5).timeout
	await _capture("relay-charged")
	world.progress.gate_open = true
	world.progress.clears = 2
	world._apply_progress()
	world.dragon.global_position = Vector3(-1.8, 0.1, -15.0)
	world.start_encounter()
	await create_timer(0.6).timeout
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	world.enemy.set_physics_process(false)
	world.dragon.input_grace = 0.0
	world.dragon.rig.visible = true
	world.enemy.brain.mode = "seek"
	world.enemy.brain.tick(0.0, 3.0, world.dragon.global_position)
	world.enemy.tell.global_position = Vector3(world.dragon.position.x, 0, world.dragon.position.z)
	world.enemy._physics_process(0.0)
	world.hud.toast_remaining = 0.0
	paused = true
	await _capture("enemy-tell")
	paused = false
	world.enemy.brain.open_window(1.8)
	world.dragon.aim = (world.enemy.global_position - world.dragon.global_position).normalized()
	world.dragon.rig.rotation.y = atan2(-world.dragon.aim.x, -world.dragon.aim.z)
	world.dragon.state = Combat.fresh()
	world.dragon.try_ability("burst")
	world.dragon.advance_combat(0.34)
	world.dragon.rig.animate(0.0, 0.0, false, world.dragon.state)
	world.enemy._physics_process(0.0)
	paused = true
	await _capture("arena")
	paused = false
	world.effects.set_calm(true)
	world.effects.set_calm(false)
	await process_frame
	world.dragon.state = Combat.fresh()
	world.dragon.try_ability("breath")
	world.dragon.advance_combat(0.24)
	world.dragon.rig.animate(0.0, 0.0, false, world.dragon.state)
	world.enemy._physics_process(0.0)
	paused = true
	await _capture("magma-breath")
	paused = false
	world.set_reduced_motion(true)
	world.dragon.rig.animate(0.0, 0.0, true, world.dragon.state)
	await _capture("reduced-motion")
	world.hud.set_pause(true)
	await _capture("settings")
	world.hud.set_pause(false)
	world.set_reduced_motion(false)
	world.dragon.receive_damage(999)
	await process_frame
	await _capture("defeat")
	world.return_to_forge()
	await process_frame
	world.progress.clears = 3
	world.progress.core = true
	world._apply_progress()
	world.dragon.global_position = world.SOCKET
	await create_timer(0.6).timeout
	world.hud.show_modules()
	await _capture("core-choice")
	world.choose_module("coolant")
	await create_timer(0.6).timeout
	await _capture("restored-forge")
	world.hud.show_modules()
	world.start_trial()
	world.interwave_delay = 0.0
	world.start_encounter()
	await process_frame
	world.enemy.set_physics_process(false)
	world.enemy.take_hit(999, true)
	await process_frame
	await _capture("field-test-complete")
	world.return_to_forge()
	world.dragon.global_position = world.SOCKET
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	await process_frame
	world.hud.show_modules()
	await _capture("core-choice-1080p")
	world.hud.close_overlay()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	print("NEXTGEN_VISUAL_SMOKE: failures=%d" % failures)
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
