extends SceneTree
## Deterministic engine captures, not concept art. No normal user saves are accessed.
const Main = preload("res://world/main.tscn")
const Combat = preload("res://sim/combat.gd")
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func _capture(name_text: String) -> void:
	# Let the always-processing HUD sample the same contact state as the scene.
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
	await _capture("forge")
	world.interact()
	world.progress.gate_open = true
	world.progress.clears = 2
	world._apply_progress()
	world.dragon.global_position = Vector3(-1.8, 0.1, -14.0)
	world.start_encounter()
	await create_timer(0.6).timeout
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	world.enemy.set_physics_process(false)
	world.dragon.input_grace = 0.0
	world.dragon.rig.visible = true
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
	# Inspect the actual articulated mesh from an unobstructed three-quarter camera.
	world.camera_rig.set_process(false)
	world.hud.visible = false
	world.enemy.visible = false
	world.enemy.tell.visible = false
	world.dragon.aim_marker.visible = false
	world.dragon.state = Combat.fresh()
	world.dragon.rig.rotation.y = -0.35
	world.dragon.rig.animate(0.0, 0.0, false, world.dragon.state)
	world.camera_rig.camera.global_position = world.dragon.global_position + Vector3(4.5, 3.8, -5.6)
	world.camera_rig.camera.look_at(world.dragon.global_position + Vector3.UP * 1.25)
	await _capture("guardian-closeup")
	# Restore the playable camera before the return-reward image.
	world.camera_rig.camera.position = Vector3(0, 16, 15)
	world.camera_rig.set_process(true)
	world.hud.visible = true
	world.dragon.global_position = world.SPAWN
	world.progress.clears = 3
	world.progress.core = true
	world.progress.upgraded = true
	world.hud.toast("FORGE RESTORED. The recovered core powers your home.")
	world._apply_progress()
	world.enemy.queue_free()
	world.enemy = null
	world.camera_rig.opponent = null
	await create_timer(0.8).timeout
	await _capture("restored-forge")
	print("NEXTGEN_VISUAL_SMOKE: failures=%d" % failures)
	world.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
