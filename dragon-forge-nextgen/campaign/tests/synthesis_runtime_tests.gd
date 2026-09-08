extends SceneTree
const Rules = preload("res://campaign/progress.gd")
const Fusion = preload("res://campaign/fusion.gd")
const World = preload("res://campaign/world.gd")
const Fixture = preload("res://campaign/tests/synthesis_tests.gd")
const Contract = preload("res://release/synthesis_contract.gd")
const Patterns = preload("res://campaign/patterns.gd")
var checks = 0
var failures = 0
func _initialize():
	root.size = Vector2i(1280,720)
	call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func frames(n: int = 3):
	for i in range(n):await physics_frame

func control(w, scroll_name: String, button_name: String):
	await frames()
	var scroll = w.hud.overlay_column.find_child(scroll_name, true, false)
	var button = w.hud.overlay_column.find_child(button_name, true, false)
	check(scroll != null and button != null, "Synthesis: real scroll action exists " + button_name)
	if scroll == null or button == null:return null
	var initial_focus = w.hud.get_viewport().gui_get_focus_owner()
	check(initial_focus != null and scroll.is_ancestor_of(initial_focus), "Synthesis: controller-opened overlay seeds focus inside " + scroll_name)
	scroll.ensure_control_visible(button)
	await frames()
	check(w.hud.root.get_global_rect().encloses(scroll.get_global_rect()) and scroll.get_global_rect().encloses(button.get_global_rect()), "Synthesis: action is fully reachable in logical viewport " + button_name)
	check(not button.disabled, "Synthesis: reached action is usable " + button_name)
	return button

func run():
	var scene = load("res://campaign/synthesis/synthesis_guardian.glb").instantiate()
	root.add_child(scene)
	var skeleton = scene.find_child("Skeleton3D", true, false)
	var player = scene.find_child("AnimationPlayer", true, false)
	check(skeleton != null and skeleton.get_bone_count() == 15, "Prism imported Void frame and inset Light panes have 15 joints")
	check(skeleton.find_bone("Head") < 0 and skeleton.find_bone("Emitter") >= 0, "Prism retains non-anatomical frame-rim emission joint")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
		check(player != null and player.has_animation(clip), "Prism imported animation " + clip)
	for clip in {"claw":.32,"breath":.56,"wall":.60,"burst":.76}:
		check(is_equal_approx(player.get_animation(clip).length, {"claw":.32,"breath":.56,"wall":.60,"burst":.76}[clip]), "Prism clip matches authoritative duration " + clip)
	scene.queue_free()
	await frames()
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames(5)
	w.title_open = false
	w.hud.close_overlay()
	w.campaign = Fixture.ready(["fire","ice","storm","stone","venom","shadow","void","light"])
	w._enter_room("forge", true)
	await frames(5)
	var before: Dictionary = w.campaign.duplicate(true)
	var pair: Array = Fusion.members(w.campaign)
	w.dragon.position = Vector3(6.0, .1, 8.0)
	w.dragon.input_grace = 0.0
	check(not w.forge_synthesis() and w.campaign == before, "Synthesis: live forging requires physical Resonance Fusion proximity")
	w.dragon.position = Fusion.STATION + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	w.hud.show_fusion()
	var button = await control(w, "ResonanceScroll", "ForgeSynthesis")
	if button != null:button.pressed.emit()
	check(w.campaign.synthesis_forged and w.campaign.guardians == before.guardians, "Synthesis: real Forge button creates resonance without consuming parents")
	check(Fusion.members(w.campaign) == pair and w.campaign.salvage == before.salvage and w.campaign.evolutions == before.evolutions, "Synthesis: forging retains expedition resources and growth")
	button = await control(w, "ResonanceScroll", "HatchSynthesis")
	if button != null:button.pressed.emit()
	check(w.campaign.guardians == before.guardians + ["synthesis"] and w.campaign.guardians.size() == 9, "Synthesis: real hatch button adds exactly the ninth guardian")
	check(Fusion.members(w.campaign) == pair and w.party.states.size() == 2 and not w.party.states.has("synthesis"), "Synthesis: awakening retains selected pair and leaves Prism on bench")
	check(not w.forge_synthesis() and not w.hatch_synthesis() and w.campaign.guardians.count("synthesis") == 1, "Synthesis: repeat Forge and hatch cannot duplicate reward")
	check(not Rules.normalize(w.campaign).is_empty(), "Synthesis: live nine-guardian state is valid schema 11")
	w.hud.close_overlay()
	check(w.travel("singularity"), "Synthesis: completed route remains available after awakening")
	await frames(4)
	check(Fusion.members(w.campaign) == pair and w.party.states.size() == 2, "Synthesis: canonical resonance does not expand expedition size")
	check(w.travel("forge"), "Synthesis: player can return to Nursery through real travel")
	await frames(4)
	w.dragon.position = Vector3(6.0, .1, 8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_party()
	button = await control(w, "GuardianScroll", "EquipReserve_synthesis")
	if button != null:button.pressed.emit()
	check(Fusion.members(w.campaign).has("synthesis") and w.party.states.has("synthesis"), "Synthesis: actual ninth Nursery control equips Prism")
	w.hud.close_overlay()
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check(w.swap_guardian("synthesis"), "Synthesis: normal party action takes point")
	check(w.dragon.guardian == "synthesis" and w.dragon.rig.skeleton.get_bone_count() == 15 and w.dragon.rig.player.has_animation("burst"), "Synthesis: live controller uses imported frame and pane rig")
	check(w.dragon.rig.muzzle_position().is_finite(), "Synthesis: live authored emitter has finite world position")
	Contract.run(w, check)
	var reserve: String = w.party.reserve_id()
	var reserve_hp: float = w.party.states[reserve].hp
	Contract.prepare(w)
	var source = Contract.target(w, "synthesis-deferred-handoff")
	source.brain.open_window(2.0)
	Contract.statuses(source, 3.0, 4.0, 3)
	var prior = Contract.snapshot(source)
	var hp: float = source.hp
	w.dragon.state.hp = 1.0
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.2)
	w._on_pattern(Patterns.lock("slam", source.global_position, w.dragon.global_position), 999.0, source)
	await frames(4)
	check(w.party.active_id == reserve and w.party.states.synthesis.hp == 0.0, "Synthesis: real deferred death hands control to living reserve")
	check(w.dragon.state.hp == reserve_hp and w.party.states.synthesis.action == "" and source.hp == hp and Contract.snapshot(source) == prior, "Synthesis: cancelled fatal windup cannot spend status or heal reserve")
	Contract.discard(w, source)
	w.campaign.room = "thaw-junction"
	if not w.campaign.cleared.has("frozen-guardian"):w.campaign.cleared.append("frozen-guardian")
	w._enter_room("thaw-junction", true)
	await frames(4)
	w.party.active_id = "synthesis"
	w.dragon.use_guardian("synthesis", w.party.states.synthesis)
	w.dragon.input_grace = 0.0
	var relay = w.conduits[0]
	w.dragon.position = relay.node.position + Vector3.BACK * 2.0
	w.dragon.aim = Vector3.FORWARD
	for id in ["breath","wall","burst"]:w.resolve_ability(id, w.dragon.position, Vector3.FORWARD)
	check(relay.sim.heat == 0 and not w.campaign.relays.has(relay.id), "Synthesis: borrowed Light and Void attacks cannot power thermal relays")
	w.queue_free()
	await frames(4)
	print("SYNTHESIS_RUNTIME_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
