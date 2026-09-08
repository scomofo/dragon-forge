extends SceneTree
## Seeded real campaign UI/contact and imported animation samples. Prepared
## states are review evidence, not an unassisted playthrough or human sign-off.
const Inspection = preload("res://validation/character_inspection.gd")
const World = preload("res://campaign/world.gd")
const Fixture = preload("res://campaign/tests/light_tests.gd")
const Contract = preload("res://release/light_contract.gd")
const Fusion = preload("res://campaign/fusion.gd")
var failures = 0
var captured = 0
const OUT = "res://artifacts/light/captures"
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
	else:captured += 1
	print("LIGHT_CAPTURE " + label)
func require(ok: bool, label: String):
	if not ok:
		failures += 1
		print("FAIL LIGHT_CAPTURE " + label)

func run():
	seed(4308)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames(5)
	w.title_open = false
	w.hud.close_overlay()
	w.campaign = Fixture.before_completion(["fire","ice","storm","stone","venom","shadow"])
	w._enter_room("singularity", true)
	await frames(5)
	w.dragon.position = w.level.core_node.position + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	await shot("01-stabilize-singularity")
	w.interact()
	require(w.campaign.guardians.has("light"), "real ending grants Light")
	await shot("02-lumen-completion-reward")
	w.hud.close_overlay()
	w.dragon.position = Fusion.VOID_IMPRINT + Vector3.UP * .1
	w.interact()
	w.hud.close_overlay()
	require(w.travel("forge"), "return to Forge")
	await frames(5)
	w.dragon.position = Fusion.STATION + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	require(w.forge_void() and w.hatch_void(), "existing Void recipe retains Light")
	w.hud.close_overlay()
	w.dragon.position = Vector3(6.0, .1, 8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_party()
	await shot("03-eight-guardian-roster")
	var scroll = w.hud.overlay_column.find_child("GuardianScroll", true, false)
	var card = w.hud.overlay_column.find_child("Guardian_light", true, false)
	var button = w.hud.overlay_column.find_child("EquipReserve_light", true, false)
	require(scroll != null and card != null and button != null, "eighth guardian has accessible scroll control")
	if scroll != null and card != null and button != null:
		scroll.ensure_control_visible(card.find_children("*", "Label", true, false)[0])
		await frames(3)
		scroll.scroll_vertical += roundi(card.get_global_rect().position.y - scroll.get_global_rect().position.y)
		await shot("04-lumen-nursery-identity")
		scroll.ensure_control_visible(button)
		await shot("05-lumen-nursery-control")
		button.pressed.emit()
	w.hud.close_overlay()
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	require(w.swap_guardian("light"), "real party selects Light")
	w.dragon.position = Vector3(0.0, .1, 2.0)
	w.dragon.aim = Vector3.FORWARD
	w.hud.toast_remaining = 0.0
	await shot("06-lumen-gameplay-silhouette")
	w.dragon.set_physics_process(false)
	var foe = Contract.target(w, "light-capture")
	await frames(3)
	w.set_physics_process(false)
	foe.brain.open_window(2.0)
	Contract.prepare(w)
	require(w.dragon.try_ability("breath"), "Radiant Beam cast")
	w.dragon.advance_combat(.261)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	paused = true
	await shot("07-radiant-beam-contact")
	paused = false
	Contract.prepare(w)
	foe.brain.mode = "seek"
	var hp: float = foe.hp
	require(w.dragon.try_ability("wall"), "shielded Solar Flare cast")
	w.dragon.advance_combat(.321)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(foe.hp == hp and foe.spec.shield, "Solar Flare preserves closed shield")
	paused = true
	await shot("08-solar-flare-shielded")
	paused = false
	Contract.prepare(w)
	foe.brain.open_window(2.0)
	require(w.dragon.try_ability("wall"), "recovery Solar Flare cast")
	w.dragon.advance_combat(.321)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(foe.hp < hp and foe.spec.shield, "Solar Flare lands through real recovery")
	paused = true
	await shot("09-solar-flare-recovery-counter")
	paused = false
	Contract.prepare(w)
	w.dragon.state.hp = w.dragon.state.max_hp * .4
	var before: float = w.dragon.state.hp
	require(w.dragon.try_ability("burst"), "Restoration cast")
	w.dragon.advance_combat(.399)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(w.dragon.state.hp == before, "Restoration waits for contact")
	paused = true
	await shot("10-restoration-windup")
	paused = false
	w.dragon.advance_combat(.002)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(is_equal_approx(w.dragon.state.hp - before, w.dragon.state.max_hp * .25), "Restoration contact heals living owner")
	paused = true
	await shot("11-restoration-heal-contact")
	paused = false
	w.queue_free()
	await frames(4)
	await inspect_clips()
	print("LIGHT_VISUAL: %d failures; %d captures; prepared-state evidence awaits human visual review" % [failures, captured])
	quit(1 if failures else 0)

func inspect_clips():
	var scene = Inspection.new()
	root.add_child(scene)
	var index = Inspection.ACTORS.find("light_guardian")
	if index < 0:
		failures += 1
		scene.queue_free()
		return
	scene.load_actor(index)
	scene.find_children("*", "OptionButton", true, false)[0].select(index)
	scene.playing = false
	scene.cycle_all = false
	scene.orbit = .38
	scene.focus = Vector3(0.0, 1.55, 0.0)
	scene.elevation = .16
	scene.distance = 6.3
	scene._update_camera()
	scene.rim.light_color = Color("fff3d0")
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
