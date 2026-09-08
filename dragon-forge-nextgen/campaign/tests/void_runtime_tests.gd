extends SceneTree
const Rules = preload("res://campaign/progress.gd")
const Fusion = preload("res://campaign/fusion.gd")
const Combat = preload("res://campaign/guardian_combat.gd")
const World = preload("res://campaign/world.gd")
const Fixture = preload("res://campaign/tests/void_tests.gd")
const VoidContract = preload("res://release/void_contract.gd")
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

func reachable(w, scroll_name: String, control_name: String, label: String):
	await frames(3)
	var scroll = w.hud.overlay_column.find_child(scroll_name, true, false)
	var control = w.hud.overlay_column.find_child(control_name, true, false)
	check(scroll != null and control != null, label + " exists in bounded scroll")
	if scroll == null or control == null:return
	scroll.ensure_control_visible(control)
	await frames(3)
	# Headless DisplayServer reports a 64x64 physical window; the actual HUD is
	# laid out in the project's 1280x720 logical canvas used by rendered builds.
	var viewport: Rect2 = w.hud.root.get_global_rect()
	check(viewport.encloses(scroll.get_global_rect()) and scroll.get_global_rect().encloses(control.get_global_rect()), label + " scrolls fully into viewport (viewport %s, scroll %s, control %s)" % [viewport, scroll.get_global_rect(), control.get_global_rect()])

func run():
	var scene = load("res://campaign/void/void_guardian.glb").instantiate()
	root.add_child(scene)
	var sk = scene.find_child("Skeleton3D", true, false)
	var ap = scene.find_child("AnimationPlayer", true, false)
	check(sk != null and sk.get_bone_count() == 11, "Null imported hollow frame has 11 authored joints")
	check(sk != null and sk.find_bone("Emitter") >= 0, "Null has forward-rim emission joint")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
		check(ap != null and ap.has_animation(clip), "Null imported animation " + clip)
	var timing = {"claw":.29,"breath":.56,"wall":.42,"burst":.64}
	for clip in timing:check(is_equal_approx(ap.get_animation(clip).length, timing[clip]), "Null animation matches authoritative duration " + clip)
	scene.queue_free()
	await frames()
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames(5)
	w.title_open = false
	w.hud.close_overlay()
	w.campaign = Fixture.completed(true)
	w.campaign.finished = false
	w.campaign.guardians.erase("light")
	w._enter_room("singularity", true)
	await frames(5)
	check(is_instance_valid(w.level.void_imprint) and not w.level.void_imprint.visible, "real Singularity hides imprint before stabilization")
	w.dragon.position = w.level.core_node.position + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	check(w._nearest().get("kind") == "finish", "real reconnect station selects ending interaction")
	w.interact()
	await frames(3)
	var recover = w.hud.overlay_column.find_child("StayForVoidImprint", true, false)
	var home = w.hud.overlay_column.find_child("ReturnHomeFromEnding", true, false)
	check(recover != null and home != null, "ending offers both staying for Void imprint and returning home")
	if recover != null and home != null:
		var viewport: Rect2 = w.hud.root.get_global_rect()
		check(viewport.encloses(recover.get_global_rect()) and viewport.encloses(home.get_global_rect()), "both ending actions fit the gameplay viewport")
		check(recover.has_focus(), "ending initially focuses the new Void recovery action")
		var before: Vector3 = w.dragon.position
		recover.pressed.emit()
		check(not paused and not w.hud.overlay.visible and w.campaign.room == "singularity", "ending recovery action resumes play in the chamber")
		check(w.dragon.position == before and not w.campaign.void_imprint_recovered, "ending action guides exploration without teleporting or granting the imprint")
	else:w.hud.close_overlay()
	check(w.campaign.finished and w.level.void_imprint.visible and not w.level.core_node.visible, "ending interaction immediately exposes Void imprint and hides reconnect station")
	check(w.level.void_imprint.position.is_equal_approx(Fusion.VOID_IMPRINT), "runtime imprint uses authored position")
	check(w.guidance().target == Fusion.VOID_IMPRINT and w.guidance().marker == "VOID IMPRINT", "staying after the ending targets the recoverable imprint")
	# The alternate ending action must leave an actionable route for players who
	# return immediately, including campaigns completed before Void was added.
	w.hud.show_ending()
	home = w.hud.overlay_column.find_child("ReturnHomeFromEnding", true, false)
	if home != null:home.pressed.emit()
	else:w.hud.close_overlay()
	await frames(5)
	check(w.campaign.room == "forge" and not w.campaign.void_imprint_recovered, "ending Return home remains available before imprint recovery")
	check(w.guidance().marker == "RETURN TO SINGULARITY  [M]" and "Void imprint" in w.hud.objective.text, "Forge visibly directs a returning finisher back to the unrecovered Void imprint")
	var legacy = Fixture.completed(true)
	legacy.room = "forge"
	legacy.version = 8
	legacy.guardians.erase("light")
	legacy.erase("void_imprint_recovered")
	legacy.erase("void_forged")
	w.campaign = Rules.normalize(legacy)
	w._enter_room("forge", true)
	await frames(5)
	check(w.guidance().target == Vector3(0,0,-14) and "Routes [M]" in w.hud.objective_detail.text, "migrated completed save receives the same actionable Forge route")
	w.hud.show_map()
	var expedition = w.hud.overlay_column.find_child("SingularityExpedition", true, false)
	check(expedition != null and not expedition.disabled, "finished campaign can select the Singularity from Routes")
	if expedition != null:expedition.pressed.emit()
	else:w.hud.close_overlay()
	await frames(5)
	check(w.campaign.room == "singularity" and w.level.void_imprint.visible, "real route button returns existing finishers to the visible imprint")
	w.dragon.position = Fusion.VOID_IMPRINT + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	check(w._nearest().get("kind") == "void_imprint", "Void imprint is reachable through real interaction selection")
	w.interact()
	check(w.campaign.void_imprint_recovered and not w.level.void_imprint.visible, "real interaction recovers and hides imprint once")
	w.hud.close_overlay()
	w.hud.show_ending()
	check(w.hud.overlay_column.find_child("StayForVoidImprint", true, false) == null and w.hud.overlay_column.find_child("ReturnHomeFromEnding", true, false) != null, "ending stops offering a recovered imprint while retaining Return home")
	w.hud.close_overlay()
	check(not Fusion.recover_void(w.campaign), "recovered world imprint cannot be awarded again")
	check(w.travel("forge"), "completed chamber returns to Forge through normal travel")
	await frames(5)
	check(w.guidance().marker == "VOID RESONANCE", "recovery replaces the return-route hint with imprint forging guidance")
	w.dragon.position = Vector3(0.0, .1, 2.0)
	w.dragon.input_grace = 0.0
	check(not w.forge_void(), "Forge action rejects player outside station reach")
	w.dragon.position = Fusion.STATION + Vector3.UP * .1
	var prior_guardians: Array = w.campaign.guardians.duplicate()
	var prior_pair: Array = Fusion.members(w.campaign)
	w.hud.show_fusion()
	await reachable(w, "ResonanceScroll", "StabilizeVoid", "Void forge action")
	check(w.forge_void(), "real Forge stabilizes Void imprint")
	await reachable(w, "ResonanceScroll", "AwakenNull", "Null awakening action")
	check(w.hatch_void(), "real Forge awakens Null")
	w.hud.close_overlay()
	check(w.campaign.guardians == prior_guardians + ["void"] and Fusion.members(w.campaign) == prior_pair, "world recruitment retains all prior guardians and expedition pair")
	check(not Rules.normalize(w.campaign).is_empty(), "world recovery and forging produce save-valid schema 11")
	w.dragon.position = Vector3(6.0, .1, 8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_party()
	await reachable(w, "GuardianScroll", "EquipReserve_void", "Null reserve action in eight-guardian roster")
	check(w.equip_reserve("void"), "Nursery equips Null as reserve")
	w.hud.close_overlay()
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check(w.swap_guardian("void"), "real party swaps to Null")
	check(w.party.states.size() == 2 and w.dragon.guardian == "void", "Void expedition has exactly two runtime guardian states")
	check(w.dragon.rig.skeleton.get_bone_count() == 11 and w.dragon.rig.player.has_animation("burst"), "live controller uses Null imported rig")
	check(w.dragon.rig.muzzle_position().is_finite(), "live Null rig supplies finite emitter position")
	w.dragon.state.hp = 42.0
	w.dragon.state.heat = 31.0
	w.dragon.state.cooldowns.breath = 2.0
	w.dragon.state.null_reflect = 1.0
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check(w.swap_guardian("fire"), "swap away from Null")
	check(w.party.states.void.hp == 42.0 and w.party.states.void.heat == 31.0 and w.party.states.void.cooldowns.breath == 2.0, "swap retains Null health, heat and cooldown commitments")
	check(w.dragon.state.null_reflect == 0.0 and w.party.states.void.null_reflect == 1.0, "Null Reflect stays with Null when swapped away")
	w.party.tick_reserve(.25, 0)
	check(is_equal_approx(w.party.states.void.null_reflect, .75), "reserve Reflect duration continues expiring")
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check(w.swap_guardian("void"), "swap back to Null")
	w.hud.close_overlay()
	VoidContract.run(w, check)
	# Exercise the real deferred death signal and healthy-reserve handoff.
	var source = VoidContract.target(w, "void-fatal-handoff", false)
	VoidContract.prepare(w)
	w.dragon.state.hp = 1.0
	w.dragon.state.null_reflect = 1.2
	var source_hp: float = source.hp
	var fatal_shape = Patterns.lock("slam", source.global_position, w.dragon.global_position)
	w._on_pattern(fatal_shape, 20.0, source)
	check(w.party.states.void.hp == 0.0 and source.hp == source_hp, "fatal reflected hit cannot counter before reserve handoff")
	await frames(3)
	check(w.party.active_id == "fire" and w.dragon.state.hp > 0.0, "actual death signal hands control to healthy reserve")
	check(source.hp == source_hp and w.party.states.void.hp == 0.0, "reserve handoff cannot reflect on behalf of fallen Null")
	VoidContract.discard(w, source)
	# Use the actual authored thermal relay, with the encounter already cleared.
	w.campaign.room = "thaw-junction"
	if not w.campaign.cleared.has("frozen-guardian"):w.campaign.cleared.append("frozen-guardian")
	w._enter_room("thaw-junction", true)
	await frames(4)
	w.party.active_id = "void"
	w.dragon.use_guardian("void", w.party.states.void)
	w.dragon.input_grace = 0.0
	var relay = w.conduits[0]
	w.dragon.position = relay.node.position + Vector3.BACK * 2.0
	w.dragon.aim = Vector3.FORWARD
	w.resolve_ability("breath", w.dragon.position, Vector3.FORWARD)
	check(relay.sim.heat == 0 and not w.campaign.relays.has(relay.id), "Void Rift cannot power thermal relay")
	w.queue_free()
	await frames(4)
	print("VOID_RUNTIME_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
