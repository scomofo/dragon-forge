extends SceneTree
const Rules = preload("res://campaign/progress.gd")
const Fusion = preload("res://campaign/fusion.gd")
const Combat = preload("res://campaign/guardian_combat.gd")
const World = preload("res://campaign/world.gd")
const Fixture = preload("res://campaign/tests/light_tests.gd")
const Contract = preload("res://release/light_contract.gd")
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

func run():
	var scene = load("res://campaign/light/light_guardian.glb").instantiate()
	root.add_child(scene)
	var skeleton = scene.find_child("Skeleton3D", true, false)
	var player = scene.find_child("AnimationPlayer", true, false)
	check(skeleton != null and skeleton.get_bone_count() == 25, "Lumen imported biped and articulated wings have 25 joints")
	check(skeleton.find_bone("Head") >= 0 and skeleton.find_bone("Emitter") >= 0, "Lumen has authored head and emission joints")
	for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
		check(player != null and player.has_animation(clip), "Lumen imported animation " + clip)
	for clip in {"claw":.32,"breath":.56,"wall":.68,"burst":.72}:
		var duration: float = {"claw":.32,"breath":.56,"wall":.68,"burst":.72}[clip]
		check(is_equal_approx(player.get_animation(clip).length, duration), "Lumen animation matches authoritative duration " + clip)
	scene.queue_free()
	await frames()
	var w = World.new()
	w.test_mode = true
	root.add_child(w)
	await frames(5)
	w.title_open = false
	w.hud.close_overlay()
	# A lone Magma must receive a live first reserve immediately at completion,
	# without rebuilding/healing the guardian that actually finished the battle.
	w.campaign = Fixture.before_completion()
	w._enter_room("singularity", true)
	await frames(5)
	w.dragon.position = w.level.core_node.position + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	w.dragon.state.hp = 41.0
	w.dragon.state.heat = 28.0
	w.dragon.state.cooldowns.breath = 3.0
	check(w._nearest().get("kind") == "finish", "real ending station is selected")
	w.interact()
	check(w.campaign.finished and w.campaign.guardians == ["fire","light"], "ending grants Lumen directly to lone Magma")
	check(w.party.states.has("light") and w.party.states.size() == 2 and w.party.active_id == "fire", "first Light reserve is synchronized immediately without replacing active guardian")
	check(w.party.states.fire.hp == 41.0 and w.party.states.fire.heat == 28.0 and w.party.states.fire.cooldowns.breath == 3.0, "ending preserves active guardian HP heat and cooldown commitments")
	check(not w.level.core_node.visible and w.level.void_imprint.visible, "ending refresh preserves independent Void imprint recovery")
	await frames(3)
	for name in ["StayForVoidImprint", "ReturnHomeFromEnding"]:
		var ending_button = w.hud.overlay_column.find_child(name, true, false)
		check(ending_button != null and w.hud.root.get_global_rect().encloses(ending_button.get_global_rect()), "combined Light reward and Void ending action remains inside viewport " + name)
	w.hud.close_overlay()
	check(not Rules.finish(w.campaign) and w.campaign.guardians.count("light") == 1, "ending reward cannot duplicate Lumen")
	check(not Rules.normalize(w.campaign).is_empty(), "Fire plus Light ending state is save-valid schema 10")
	# A pre-existing pair must stay selected when Light is awarded to the bench.
	w.campaign = Fixture.before_completion(["fire","ice","storm","stone","venom","shadow"])
	w._enter_room("singularity", true)
	await frames(5)
	var before_guardians: Array = w.campaign.guardians.duplicate()
	var before_pair: Array = Fusion.members(w.campaign)
	var active: String = w.party.active_id
	w.dragon.position = w.level.core_node.position + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	w.dragon.state.hp = 42.0
	w.dragon.state.heat = 27.0
	w.interact()
	check(w.campaign.guardians == before_guardians + ["light"] and w.campaign.finished, "existing roster gains exactly one earned Light guardian")
	check(Fusion.members(w.campaign) == before_pair and w.party.states.keys().size() == 2 and not w.party.states.has("light"), "completion preserves selected two-slot expedition while Lumen joins the bench")
	check(w.party.active_id == active and w.dragon.state.hp == 42.0 and w.dragon.state.heat == 27.0, "completion preserves active identity and combat resources")
	w.hud.close_overlay()
	w.dragon.position = Fusion.VOID_IMPRINT + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	w.interact()
	check(w.campaign.void_imprint_recovered and not w.level.void_imprint.visible, "independent Void imprint remains recoverable after Light reward")
	w.hud.close_overlay()
	check(w.travel("forge"), "completed chamber returns to Forge through real travel")
	await frames(5)
	w.dragon.position = Fusion.STATION + Vector3.UP * .1
	w.dragon.input_grace = 0.0
	check(w.forge_void(), "existing Void forging still works after Light completion")
	check(w.hatch_void(), "Void can join after Lumen without roster-order assumptions")
	w.hud.close_overlay()
	check(w.campaign.guardians.size() == 8 and w.campaign.guardians.count("light") == 1 and Fusion.members(w.campaign) == before_pair, "all eight earned guardians retain original expedition pair")
	check(not Rules.normalize(w.campaign).is_empty(), "eight-guardian world roster is save-valid")
	w.dragon.position = Vector3(6.0, .1, 8.0)
	w.dragon.input_grace = 0.0
	w.hud.show_party()
	await frames(3)
	var scroll = w.hud.overlay_column.find_child("GuardianScroll", true, false)
	var button = w.hud.overlay_column.find_child("EquipReserve_light", true, false)
	check(scroll != null and button != null, "eighth guardian has a reserve action in bounded Nursery scroll")
	if scroll != null and button != null:
		scroll.ensure_control_visible(button)
		await frames(3)
		check(w.hud.root.get_global_rect().encloses(scroll.get_global_rect()) and scroll.get_global_rect().encloses(button.get_global_rect()), "Lumen reserve control scrolls fully into the logical viewport")
		check(not button.disabled, "Nursery makes Lumen's visible reserve control usable")
		button.pressed.emit()
	check(Fusion.members(w.campaign).has("light") and w.party.states.has("light"), "actual Nursery button equips Lumen")
	w.hud.close_overlay()
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check(w.swap_guardian("light"), "normal party action swaps to Lumen")
	check(w.dragon.guardian == "light" and w.dragon.rig.skeleton.get_bone_count() == 25 and w.dragon.rig.player.has_animation("burst"), "active Lumen controller uses imported rig")
	check(w.dragon.rig.muzzle_position().is_finite(), "live Lumen rig has finite emission position")
	Contract.run(w, check)
	# Observe the deferred death signal on real physics frames as well as the
	# synchronous exported contract. A cancelled heal cannot migrate to reserve.
	var reserve: String = w.party.reserve_id()
	var reserve_hp: float = w.party.states[reserve].hp
	Contract.prepare(w)
	w.dragon.state.hp = 1.0
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.2)
	var source = Contract.target(w, "light-deferred-handoff")
	var shape = Patterns.lock("slam", source.global_position, w.dragon.global_position)
	w._on_pattern(shape, 999.0, source)
	await frames(4)
	check(w.party.active_id == reserve and w.party.states.light.hp == 0.0, "real deferred death signal hands control to healthy reserve")
	check(w.dragon.state.hp == reserve_hp and w.party.states.light.action == "", "deferred handoff cannot revive Lumen or complete its cancelled heal on reserve")
	Contract.discard(w, source)
	w.campaign.room = "thaw-junction"
	if not w.campaign.cleared.has("frozen-guardian"):w.campaign.cleared.append("frozen-guardian")
	w._enter_room("thaw-junction", true)
	await frames(4)
	w.party.active_id = "light"
	w.dragon.use_guardian("light", w.party.states.light)
	w.dragon.input_grace = 0.0
	var relay = w.conduits[0]
	w.dragon.position = relay.node.position + Vector3.BACK * 2.0
	w.dragon.aim = Vector3.FORWARD
	for id in ["breath","wall"]:w.resolve_ability(id, w.dragon.position, Vector3.FORWARD)
	check(relay.sim.heat == 0 and not w.campaign.relays.has(relay.id), "Radiant Beam and Solar Flare cannot power thermal relays")
	w.queue_free()
	await frames(4)
	print("LIGHT_RUNTIME_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
