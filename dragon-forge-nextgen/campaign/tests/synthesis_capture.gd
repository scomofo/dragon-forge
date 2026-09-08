extends SceneTree
## Prepared real campaign interactions, combat contacts and imported clips.
## These deterministic images support review, not an unassisted playthrough.
const Inspection = preload("res://validation/character_inspection.gd")
const World = preload("res://campaign/world.gd")
const Fixture = preload("res://campaign/tests/synthesis_tests.gd")
const Contract = preload("res://release/synthesis_contract.gd")
const Fusion = preload("res://campaign/fusion.gd")
var failures = 0
var captured = 0
const OUT = "res://artifacts/synthesis/captures"
func _initialize():
	root.size = Vector2i(1280,720)
	call_deferred("run")
func frames(n: int = 4):
	for i in range(n):await process_frame
func shot(label: String):
	await frames(3)
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT + "/" + label + ".png") != OK:failures += 1
	else:captured += 1
	print("SYNTHESIS_CAPTURE " + label)
func require(ok: bool, label: String):
	if not ok:
		failures += 1
		print("FAIL SYNTHESIS_CAPTURE " + label)
func prepare_capture(w):
	Contract.prepare(w)
	# Allow the previous decorative contact to retire before documenting the
	# next ability, so a lingering Recompile pulse cannot resemble a beam field.
	w.effects.set_calm(true)
	w.effects.set_calm(w.reduced_motion)
	w.hud.feedback_remaining = 0.0
	w.feedback_cooldown = 0.0
	await frames(3)
func action(w, scroll_name: String, button_name: String, label: String):
	await frames(3)
	var scroll = w.hud.overlay_column.find_child(scroll_name, true, false)
	var button = w.hud.overlay_column.find_child(button_name, true, false)
	require(scroll != null and button != null, "real control exists " + button_name)
	if scroll == null or button == null:return null
	scroll.ensure_control_visible(button)
	await frames(3)
	require(w.hud.root.get_global_rect().encloses(scroll.get_global_rect()) and scroll.get_global_rect().encloses(button.get_global_rect()) and not button.disabled, "control is fully visible and usable " + button_name)
	await shot(label)
	return button

func run():
	seed(4411)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames(5)
	w.title_open = false
	w.hud.close_overlay()
	w.campaign = Fixture.ready(["fire","ice","storm","stone","venom","shadow","void","light"])
	w._enter_room("forge", true)
	await frames(5)
	w.dragon.position = Fusion.STATION + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	w.hud.show_fusion()
	var button = await action(w, "ResonanceScroll", "ForgeSynthesis", "01-light-void-forge-control")
	if button != null:button.pressed.emit()
	require(w.campaign.synthesis_forged and w.campaign.guardians.has("void") and w.campaign.guardians.has("light"), "actual resonance retains both parents")
	button = await action(w, "ResonanceScroll", "HatchSynthesis", "02-prism-awaken-control")
	if button != null:button.pressed.emit()
	require(w.campaign.guardians.size() == 9 and w.party.states.size() == 2, "actual hatch adds ninth owned guardian without expanding expedition")
	w.hud.close_overlay()
	w.dragon.position = Vector3(6.0, .1, 8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_party()
	await shot("03-nine-guardian-roster")
	var scroll = w.hud.overlay_column.find_child("GuardianScroll", true, false)
	var card = w.hud.overlay_column.find_child("Guardian_synthesis", true, false)
	require(scroll != null and card != null, "Prism has ninth guardian card")
	if scroll != null and card != null:
		scroll.ensure_control_visible(card.find_children("*", "Label", true, false)[0])
		await frames(3)
		scroll.scroll_vertical += roundi(card.get_global_rect().position.y - scroll.get_global_rect().position.y)
		await shot("04-prism-nursery-identity")
	button = await action(w, "GuardianScroll", "EquipReserve_synthesis", "05-prism-nursery-control")
	if button != null:button.pressed.emit()
	w.hud.close_overlay()
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	require(w.swap_guardian("synthesis"), "actual party action selects Prism")
	w.dragon.position = Vector3(0.0, .1, 2.0)
	w.dragon.aim = Vector3.FORWARD
	w.hud.toast_remaining = 0.0
	w.hud.feedback_remaining = 0.0
	await shot("06-prism-gameplay-silhouette")
	w.dragon.set_physics_process(false)
	var foe = Contract.target(w, "synthesis-capture")
	await frames(3)
	w.set_physics_process(false)
	await prepare_capture(w)
	Contract.statuses(foe, 3.0, 4.0, 3)
	var prior = Contract.snapshot(foe)
	var hp: float = foe.hp
	require(w.dragon.try_ability("burst"), "shielded Recompile cast")
	w.dragon.advance_combat(.361)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(foe.hp == hp and Contract.snapshot(foe) == prior and foe.spec.shield, "closed shield preserves all status payoffs")
	paused = true
	await shot("07-recompile-closed-shield")
	paused = false
	await prepare_capture(w)
	foe.brain.open_window(2.0)
	require(w.dragon.try_ability("burst"), "recovery Recompile cast")
	w.dragon.advance_combat(.359)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(foe.hp == hp and Contract.snapshot(foe) == prior, "Recompile windup preserves all payoffs")
	paused = true
	await shot("08-recompile-windup")
	paused = false
	w.dragon.advance_combat(.002)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(is_equal_approx(hp - foe.hp, w.campaign_damage("burst") * 1.75) and foe.toxin == 0 and foe.charged == 4.0 and foe.chilled == 3.0, "strongest Toxin payoff lands and preserves other statuses")
	paused = true
	await shot("09-recompile-septic-bloom")
	paused = false
	for element in ["storm", "fire"]:
		await prepare_capture(w)
		hp = foe.hp
		require(w.dragon.try_ability("burst"), "remaining status Recompile " + element)
		w.dragon.advance_combat(.361)
		w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
		require(is_equal_approx(hp - foe.hp, w.campaign_damage("burst") * (1.5 if element == "storm" else 1.4)), "next strongest remaining payoff " + element)
		paused = true
		await shot("10-recompile-discharge" if element == "storm" else "11-recompile-shatter")
		paused = false
	await prepare_capture(w)
	hp=foe.hp
	require(w.dragon.try_ability("claw"),"Convergence Shard cast")
	w.dragon.advance_combat(.121)
	w.dragon.rig.animate(0.0,0.0,false,w.dragon.state)
	require(foe.hp<hp,"actual Convergence Shard contact lands")
	paused=true
	await shot("12-convergence-shard-contact")
	paused=false
	await prepare_capture(w)
	var at: Vector3 = foe.global_position
	hp = foe.hp
	require(w.dragon.try_ability("breath"), "borrowed Void Rift cast")
	w.dragon.advance_combat(.261)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(foe.hp < hp and is_equal_approx(foe.global_position.distance_to(at), 1.25), "actual Rift contact pushes exposed ordinary target")
	paused = true
	await shot("13-void-rift-push-contact")
	paused = false
	await prepare_capture(w)
	hp = foe.hp
	var fields: int = w.walls.size()
	require(w.dragon.try_ability("wall"), "borrowed Radiant Beam cast")
	w.dragon.advance_combat(.281)
	w.dragon.rig.animate(0.0, 0.0, false, w.dragon.state)
	require(foe.hp < hp and w.walls.size() == fields, "Radiant Beam is a direct contact without field")
	paused = true
	await shot("14-radiant-beam-contact")
	paused = false
	await prepare_capture(w)
	foe.global_position=w.dragon.global_position+Vector3.FORWARD*5.0+Vector3.RIGHT*.69
	hp=foe.hp
	require(w.dragon.try_ability("wall"),"Radiant Beam inside-edge cast")
	w.dragon.advance_combat(.281)
	w.dragon.rig.animate(0.0,0.0,false,w.dragon.state)
	require(foe.hp<hp,"Radiant Beam includes the visible inside edge")
	paused=true
	await shot("15-radiant-beam-inside-edge")
	paused=false
	await prepare_capture(w)
	foe.global_position=w.dragon.global_position+Vector3.FORWARD*5.0+Vector3.RIGHT*.71
	hp=foe.hp
	require(w.dragon.try_ability("wall"),"Radiant Beam outside-edge cast")
	w.dragon.advance_combat(.281)
	w.dragon.rig.animate(0.0,0.0,false,w.dragon.state)
	require(foe.hp==hp,"Radiant Beam excludes the first point outside its visible corridor")
	paused=true
	await shot("16-radiant-beam-outside-edge")
	paused=false
	w.queue_free()
	await frames(4)
	await inspect_clips()
	print("SYNTHESIS_VISUAL: %d failures; %d captures; prepared-state evidence awaits human visual review" % [failures, captured])
	quit(1 if failures else 0)

func inspect_clips():
	var scene = Inspection.new()
	root.add_child(scene)
	var index = Inspection.ACTORS.find("synthesis_guardian")
	if index < 0:
		failures += 1
		scene.queue_free()
		return
	scene.load_actor(index)
	scene.find_children("*", "OptionButton", true, false)[0].select(index)
	scene.playing = false
	scene.cycle_all = false
	scene.orbit = .40
	scene.focus = Vector3(0.0, 1.28, 0.0)
	scene.elevation = .18
	scene.distance = 5.5
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
