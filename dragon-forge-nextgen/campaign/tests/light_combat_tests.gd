extends SceneTree
const Combat = preload("res://campaign/guardian_combat.gd")
const Modules = preload("res://sim/forge_modules.gd")
var checks = 0
var failures = 0

func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run():
	var light = Combat.fresh("", "light")
	check(Combat.guardian_name("light") == "LUMEN", "Light identity is Lumen")
	check(light.max_hp == Combat.fresh().max_hp, "Lumen shares Fire's baseline health")
	for module in Modules.ORDER:
		check(Combat.fresh(module, "light").max_hp == Combat.fresh(module, "fire").max_hp, "Light preserves module health scaling: " + module)
	var expected = {
		"claw":["Prism Claw", 22.0, 0.0, .55, 2.9, .20, .12, .20],
		"breath":["Radiant Beam", 36.0, 22.0, 2.8, 8.0, .86, .26, .30],
		"wall":["Solar Flare", 42.0, 32.0, 7.5, 4.5, -1.0, .32, .36],
		"burst":["Restoration", 0.0, 34.0, 12.0, 0.0, -1.0, .40, .32],
	}
	var keys = ["name", "damage", "heat", "cooldown", "range", "cone", "windup", "recovery"]
	for id in Combat.ORDER:
		var state = Combat.fresh("", "light")
		var move = Combat.rule(state, id)
		for i in range(keys.size()):
			check(move[keys[i]] == expected[id][i], "Light " + id + " contract " + keys[i])
		check(not move.has("ignore_shield"), "Light move keeps shield authority: " + id)
		check(Combat.cast(state, id), "Light cast accepted: " + id)
		check(state.heat == move.heat and state.cooldowns[id] == move.cooldown, "Light cast pays heat and cooldown immediately: " + id)
		check(Combat.tick(state, move.windup - .001) == "" and not state.action_hit, "Light has no early contact: " + id)
		check(Combat.tick(state, .001) == id and state.action_hit, "Light contacts at exact windup: " + id)
		check(Combat.tick(state, move.recovery - .001) == "" and state.action == id, "Light recovery emits no second contact: " + id)
		check(Combat.tick(state, .001) == "" and state.action == "", "Light action ends at exact recovery: " + id)
		check(not Combat.cast(state, id) and Combat.rejection(state, id) == "Recharging", "Light recovery does not reset cooldown: " + id)
	var flare = Combat.rule(light, "wall")
	check(not flare.has("radius") and flare.cone == -1.0, "Solar Flare is one radial contact without a field definition")
	check(Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3.BACK * 4.5, flare.range, flare.cone), "Solar Flare includes exposed targets behind Lumen")
	check(not Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3.BACK * 4.51, flare.range, flare.cone), "Solar Flare excludes targets outside its radius")
	var beam = Combat.rule(light, "breath")
	check(Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3.FORWARD * 8.0, beam.range, beam.cone), "Radiant Beam reaches its forward boundary")
	check(not Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3.RIGHT * 2.0, beam.range, beam.cone), "Radiant Beam remains directional")
	restoration_checks()
	interruption_checks()
	regression_checks()
	print("LIGHT_COMBAT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func restoration_checks():
	var state = Combat.fresh("", "light")
	state.hp = state.max_hp * .25
	var reserve = Combat.fresh("", "fire");reserve.hp = 1.0
	var reserve_before = reserve.duplicate(true)
	var hp: float = state.hp
	check(Combat.restore(state) == state.max_hp * .25 and state.hp == hp + state.max_hp * .25, "Restoration heals one quarter of owner's maximum health")
	check(reserve == reserve_before, "Restoration leaves the reserve untouched")
	state.hp = state.max_hp - 3.0
	check(Combat.restore(state) == 3.0 and state.hp == state.max_hp, "Restoration returns actual healing and stops at maximum health")
	check(Combat.restore(state) == 0.0 and state.hp == state.max_hp, "full health receives no healing")
	state.max_hp = 260.0;state.hp = 100.0
	check(Combat.restore(state) == 65.0 and state.hp == 165.0, "Restoration uses the owner's current upgraded maximum health")
	state.hp = 50.0;state.heat = 42.0;state.cooldowns = {"burst":11.6, "breath":1.3}
	state.action = "burst";state.action_time = .4;state.action_hit = true
	state.iframes = .16;state.dodge_iframes = .20;state.dash = .18;state.dodge_cd = .65
	state.guard = true;state.ward = 2.0;state.null_reflect = 1.2;state.phase = 2;state.resolve = 3
	var unchanged = state.duplicate(true)
	var healed = Combat.restore(state);unchanged.hp += healed
	check(state == unchanged, "Restoration changes HP only, preserving heat, cooldowns, action, immunity and statuses")
	for values in [[0.0, 100.0], [-1.0, 100.0], [10.0, 0.0], [10.0, -1.0], [101.0, 100.0], [NAN, 100.0], [INF, 100.0], [-INF, 100.0], [10.0, NAN], [10.0, INF], [10.0, -INF]]:
		var invalid = {"guardian":"light", "hp":values[0], "max_hp":values[1]}
		var before = var_to_bytes(invalid)
		check(Combat.restore(invalid) == 0.0 and var_to_bytes(invalid) == before, "Restoration rejects dead or invalid health without mutation: " + str(values))
	for incomplete in [{}, {"guardian":"light"}, {"guardian":"light", "hp":1.0}, {"guardian":"light", "max_hp":100.0}]:
		var before = incomplete.duplicate(true)
		check(Combat.restore(incomplete) == 0.0 and incomplete == before, "Restoration rejects incomplete state without mutation: " + str(before))
	for guardian in ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]:
		var other = Combat.fresh("", guardian);other.hp = 1.0
		var before = other.duplicate(true)
		check(Combat.restore(other) == 0.0 and other == before, "Restoration cannot heal a different guardian: " + guardian)

func interruption_checks():
	var state = Combat.fresh("", "light");state.hp = 1.0
	check(Combat.cast(state, "burst") and state.hp == 1.0, "Restoration windup starts without healing")
	var contacts = 0
	for elapsed in [.20, .19, .01, .01, .31, 1.0]:
		if Combat.tick(state, elapsed) == "burst":
			contacts += 1;Combat.restore(state)
	check(contacts == 1 and state.hp == 1.0 + state.max_hp * .25, "one Restoration cast heals exactly once at contact")
	var skipped = Combat.fresh("", "light");skipped.hp = 1.0;Combat.cast(skipped, "burst")
	check(Combat.tick(skipped, 1.0) == "burst" and Combat.tick(skipped, 1.0) == "", "long frame still delivers only one Restoration contact")
	var canceled = Combat.fresh("", "light");canceled.hp = 1.0;Combat.cast(canceled, "burst")
	var spent_heat: float = canceled.heat;var remaining_cd: float = canceled.cooldowns.burst
	Combat.cancel_action(canceled)
	check(canceled.heat == spent_heat and canceled.cooldowns.burst == remaining_cd, "canceling Restoration refunds neither heat nor cooldown")
	check(Combat.tick(canceled, .5) == "" and canceled.hp == 1.0, "canceled windup delivers no heal contact")
	var dodged = Combat.fresh("", "light");dodged.hp = 1.0;Combat.cast(dodged, "burst")
	check(Combat.dodge(dodged) and dodged.action == "" and dodged.heat == 44.0 and dodged.cooldowns.burst == 12.0, "dodge cancels Restoration while preserving its cost")
	check(Combat.tick(dodged, .5) == "" and dodged.hp == 1.0, "dodge cancellation cannot deliver a delayed heal")
	var dead = Combat.fresh("", "light");dead.hp = 1.0;Combat.cast(dead, "burst");Combat.damage(dead, 2.0)
	check(Combat.tick(dead, .5) == "" and Combat.restore(dead) == 0.0 and dead.hp == 0.0, "lethal damage cancels Restoration and cannot be undone by its helper")
	var hot = Combat.fresh("", "light");hot.heat = 67.0
	check(not Combat.cast(hot, "burst") and hot.cooldowns.is_empty() and hot.heat == 67.0, "overheated Restoration is rejected without spending resources")
	var limit = Combat.fresh("", "light");limit.heat = 66.0
	check(Combat.cast(limit, "burst") and limit.heat == 100.0, "Restoration accepts the exact heat limit")
	var invalid_time = Combat.fresh("", "light");invalid_time.hp = 1.0;Combat.cast(invalid_time, "burst")
	for elapsed in [-1.0, NAN, INF]:check(Combat.tick(invalid_time, elapsed) == "" and invalid_time.action_time == 0.0 and invalid_time.hp == 1.0, "invalid elapsed time cannot trigger Restoration: " + str(elapsed))

func regression_checks():
	var shadow = Combat.fresh("", "shadow")
	Combat.damage(shadow, 10.0);Combat.damage(shadow, 10.0)
	check(shadow.phase == 0, "Light preserves Shadow's post-hit immunity Phase regression")
	Combat.tick(shadow, .2);Combat.dodge(shadow);Combat.damage(shadow, 10.0)
	check(shadow.phase == 1, "Light preserves Shadow's earned dodge Phase")
	check(Combat.technique_damage(shadow, "burst") == 65.0 and not Combat.rule(shadow, "burst").has("ignore_shield"), "Light preserves Phase damage and shield semantics")
	var void_state = Combat.fresh("", "void");void_state.null_reflect = Combat.null_reflect_duration()
	check(Combat.damage(void_state, 30.0) == 15.0 and Combat.reflected_damage(30.0) == 20.0, "Light preserves Void reduction and reflection cap")
	check(Combat.void_displacement("breath") == 1.25 and Combat.void_displacement("burst") == -1.5, "Light preserves Void displacement bounds")
	var light = Combat.fresh("", "light");light.null_reflect = 1.2
	check(Combat.damage(light, 30.0) == 30.0 and light.phase == 0, "Light does not inherit Void mitigation or Shadow Phase")
	for guardian in ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]:
		check(Combat.rule({"guardian":guardian}, "burst").name != "Restoration", "existing guardian retains its own burst: " + guardian)
