extends SceneTree
## Real renderer asset review. Studio cameras are labelled; gameplay captures are separate.
const Art = preload("res://presentation/art_library.gd")
const Rig = preload("res://presentation/dragon_rig.gd")
const Combat = preload("res://sim/combat.gd")
const Main = preload("res://world/main.tscn")
var scene: Node3D
var camera: Camera3D
var caption: Label
var failures = 0
func _initialize() -> void:
	_run.call_deferred()
func _capture(id: String, title: String) -> void:
	caption.text = title
	await process_frame
	await RenderingServer.frame_post_draw
	var image = root.get_texture().get_image()
	var err = image.save_png("res://artifacts/" + id + ".png")
	if err != OK:
		failures += 1
	print("ART_SCREENSHOT %s result=%d" % [id, err])
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	scene = Node3D.new()
	root.add_child(scene)
	var env = WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("10171b")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bac5c9")
	env.environment.ambient_light_energy = 0.50
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	scene.add_child(env)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -25, 0)
	sun.light_energy = 1.4
	sun.light_color = Color("ffe2c0")
	sun.shadow_enabled = true
	scene.add_child(sun)
	var rim = OmniLight3D.new()
	rim.position = Vector3(-3, 3, 2)
	rim.light_color = Color("71bbd1")
	rim.light_energy = 2.0
	rim.omni_range = 9
	scene.add_child(rim)
	var platform = MeshInstance3D.new()
	platform.mesh = CylinderMesh.new()
	platform.mesh.top_radius = 3.3
	platform.mesh.bottom_radius = 3.3
	platform.mesh.height = 0.08
	platform.position.y = -0.06
	platform.material_override = StandardMaterial3D.new()
	platform.material_override.albedo_color = Color("283338")
	platform.material_override.roughness = 0.9
	scene.add_child(platform)
	camera = Camera3D.new()
	camera.position = Vector3(4.0, 3.0, -6)
	camera.fov = 38
	scene.add_child(camera)
	camera.look_at(Vector3(0, 1.35, 0.1))
	camera.current = true
	var ui = CanvasLayer.new()
	root.add_child(ui)
	caption = Label.new()
	caption.position = Vector2(32, 28)
	caption.add_theme_font_size_override("font_size", 23)
	caption.modulate = Color("e3d7bc")
	ui.add_child(caption)
	var actor = Rig.new()
	scene.add_child(actor)
	actor.animate(0, 0, false, Combat.fresh())
	await create_timer(0.2).timeout
	await _capture("magma-material", "MAGMA GUARDIAN  /  Imported mesh + shared PBR atlas\nStudio inspection camera")
	camera.position = Vector3(-3.8, 3.0, 6.1)
	camera.look_at(Vector3(0, 1.25, 0.2))
	await _capture("magma-back", "MAGMA GUARDIAN  /  Layered dorsal scales + skinned tail\nStudio inspection camera")
	camera.position = Vector3(4.0, 3.0, -6)
	camera.look_at(Vector3(0, 1.35, 0.1))
	var state = Combat.fresh()
	Combat.cast(state, "breath")
	Combat.tick(state, 0.24)
	actor.animate(0, 0, false, state)
	await _capture("magma-breath-pose", "MAGMA GUARDIAN  /  Authored breath contact pose\nStudio inspection camera - simulation sampled")
	if OS.get_cmdline_user_args().has("--motion-frames"):
		for i in range(32):
			var pose = Combat.fresh()
			if i < 16:
				actor.gait = i * 0.8 / 16.0
				actor.animate(0, 6.2, false, pose)
			else:
				Combat.cast(pose, "breath")
				Combat.tick(pose, (i - 16) * 0.5 / 16.0)
				actor.animate(0, 0, false, pose)
			await _capture("motion-%02d" % i, "MAGMA GUARDIAN  /  Skinned locomotion + breath\nStudio inspection - actual engine frames")
	actor.queue_free()
	await process_frame
	for id in ["firewall_sentinel", "packet_warden"]:
		var model = Art.place(scene, id)
		await _capture(id + "-material", id.to_upper().replace("_", " ") + "  /  Plated mesh + imported skeleton\nStudio inspection camera")
		model.queue_free()
		await process_frame
	scene.queue_free()
	await process_frame
	var world = Main.instantiate()
	world.test_mode = true
	root.add_child(world)
	world.interact()
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	world.dragon.rig.visible = true
	world.dragon.rig.animate(0, 0, false, world.dragon.state)
	world.camera_rig.set_process(false)
	world.hud.visible = false
	world.camera_rig.camera.current = false
	var view = Camera3D.new()
	world.add_child(view)
	view.position = Vector3(10.0, 9.2, 19.3)
	view.look_at(Vector3(0, 1.0, 8.0))
	view.fov = 51
	view.current = true
	await _capture("forge-environment", "THE FORGE  /  Shipped stations, hearths and breach architecture\nEnvironment inspection camera - gameplay layout")
	view.position = Vector3(12.5, 11.4, -1.0)
	view.look_at(Vector3(0, 0.9, -13.5))
	await _capture("outer-grid-environment", "OUTER GRID  /  Modular deck, bulkheads and relay crown\nEnvironment inspection camera - gameplay layout")
	world.queue_free()
	ui.queue_free()
	await process_frame
	print("NEXTGEN_ART_REVIEW: failures=%d" % failures)
	quit(1 if failures else 0)
