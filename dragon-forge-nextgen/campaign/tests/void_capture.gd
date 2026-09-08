extends SceneTree
## Seeded prepared-state capture of real campaign and imported inspection clips.
## Files are review evidence, not a claim that human visual/balance review occurred.
const Inspection = preload("res://validation/character_inspection.gd")
const World = preload("res://campaign/world.gd")
const Fixture = preload("res://campaign/tests/void_tests.gd")
const Contract = preload("res://release/void_contract.gd")
const Patterns = preload("res://campaign/patterns.gd")
var failures = 0
var captured = 0
const OUT = "res://artifacts/void/captures"
func _initialize():
	root.size = Vector2i(1280,720)
	call_deferred("run")
func frames(n: int = 4):
	for i in range(n):await process_frame
func shot(label: String):
	await frames(3)
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT + "/" + label + ".png") != OK:
		failures += 1
	else:
		captured += 1
	print("VOID_CAPTURE " + label)

func focus_control(w, scroll_name: String, control_name: String):
	await frames(3)
	var scroll = w.hud.overlay_column.find_child(scroll_name, true, false)
	var control = w.hud.overlay_column.find_child(control_name, true, false)
	if scroll == null or control == null:
		failures += 1
		return
	scroll.ensure_control_visible(control)
	await frames(3)

func run():
	seed(4107)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames(5)
	w.title_open = false
	w.hud.close_overlay()
	w.campaign = Fixture.completed(true)
	w._enter_room("singularity", true)
	await frames(5)
	w.dragon.position = Vector3(-3.0,.1,-1.0)
	await shot("01-singularity-void-imprint")
	w.campaign.void_imprint_recovered = true
	w.campaign.room = "forge"
	w._enter_room("forge", true)
	await frames(5)
	w.dragon.position = Vector3(-7.0,.1,8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_fusion()
	await focus_control(w, "ResonanceScroll", "StabilizeVoid")
	await shot("02-void-imprint-forging")
	w.forge_void()
	await focus_control(w, "ResonanceScroll", "AwakenNull")
	await shot("02b-null-awakening")
	w.hatch_void()
	w.hud.close_overlay()
	w.dragon.position = Vector3(6.0,.1,8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_party()
	await shot("03-seven-guardian-roster")
	var roster = w.hud.overlay_column.find_child("GuardianScroll", true, false)
	var null_card = w.hud.overlay_column.find_child("Guardian_void", true, false)
	if roster != null and null_card != null:
		roster.ensure_control_visible(null_card.find_children("*", "Label", true, false)[0])
		await frames(3)
		roster.scroll_vertical += roundi(null_card.get_global_rect().position.y - roster.get_global_rect().position.y)
		await frames(3)
		await shot("03b-null-roster-identity")
	else:failures += 1
	await focus_control(w, "GuardianScroll", "EquipReserve_void")
	await shot("03c-null-roster-control")
	w.equip_reserve("void")
	w.hud.close_overlay()
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	w.swap_guardian("void")
	w.dragon.position = Vector3(0.0,.1,2.0)
	w.dragon.aim = Vector3.FORWARD
	await shot("04-null-hollow-frame")
	w.set_physics_process(false)
	w.dragon.set_physics_process(false)
	var foe = Contract.target(w, "void-capture", false)
	Contract.prepare(w)
	w.dragon.try_ability("wall")
	w.dragon.advance_combat(.181)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	paused = true
	await shot("05-null-reflect-contact")
	paused = false
	var shape = Patterns.lock("slam", foe.global_position, w.dragon.global_position)
	w._on_pattern(shape, 20.0, foe)
	paused = true
	await shot("06-reflect-counter")
	paused = false
	Contract.prepare(w)
	w.dragon.try_ability("breath")
	w.dragon.advance_combat(.261)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	paused = true
	await shot("07-void-rift-push")
	paused = false
	Contract.prepare(w)
	w.dragon.state.hp = w.dragon.state.max_hp - 30.0
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.301)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	paused = true
	await shot("08-siphon-rift-pull")
	paused = false
	w.queue_free()
	await frames(4)
	await inspect_clips()
	print("VOID_VISUAL: %d failures; %d captures; prepared-state evidence awaits human visual review" % [failures, captured])
	quit(1 if failures else 0)

func inspect_clips():
	var scene = Inspection.new()
	root.add_child(scene)
	var actor_index = Inspection.ACTORS.find("void_guardian")
	if actor_index < 0:
		failures += 1
		scene.queue_free()
		return
	scene.load_actor(actor_index)
	scene.find_children("*", "OptionButton", true, false)[0].select(actor_index)
	scene.playing = false
	scene.cycle_all = false
	# The hollow diamond's aperture faces -Z; a slight front angle shows the gap
	# and the frame's thickness together instead of hiding it in a side profile.
	scene.orbit = .30
	scene.focus = Vector3(0.0, 1.3, 0.0)
	scene.elevation = .12
	scene.distance = 5.0
	scene._update_camera()
	for lighting in ["neutral", "rim"]:
		scene.key.light_energy = 1.6 if lighting == "neutral" else .35
		scene.rim.light_energy = 0.0 if lighting == "neutral" else 6.0
		for toggle in scene.find_children("*", "CheckButton", true, false):
			if toggle.text == "Strong rim light":toggle.set_pressed_no_signal(lighting == "rim")
		for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
			if not scene.player.has_animation(clip):
				failures += 1
				continue
			scene.select_clip(scene.clips.find(clip))
			scene.scrub(scene.player.get_animation(clip).length * .5)
			await shot("inspection-" + lighting + "-" + clip)
	scene.queue_free()
	await frames(4)
