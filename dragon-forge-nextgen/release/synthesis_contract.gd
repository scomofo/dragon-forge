extends RefCounted
## Shared source/export contract. Caller supplies a save-isolated Forge with
## Prism active and a living reserve. Every fixture retains its real shield.
const Combat = preload("res://campaign/guardian_combat.gd")
const Enemy = preload("res://campaign/enemy.gd")
const Patterns = preload("res://campaign/patterns.gd")

static func prepare(w) -> void:
	w.dragon.advance_combat(2.0)
	w.dragon.state.heat = 0.0
	w.dragon.state.cooldowns.clear()
	w.dragon.state.hp = w.dragon.state.max_hp
	w.dragon.state.guard = false
	w.dragon.input_grace = 0.0

static func target(w, id: String = "synthesis-contract"):
	var foe = Enemy.new()
	foe.spec = {"id":id,"name":"Synthesis acceptance target","hp":5000.0,"damage":10.0,"shield":true,"boss":id=="outer-boss","patterns":["slam"],"archetype":"bulwark"}
	foe.target = w.dragon
	foe.navigation = w
	foe.hit_feedback.connect(w._hit_feedback)
	w.level.add_child(foe)
	foe.global_position = w.dragon.global_position + Vector3.FORWARD * 2.5
	foe.set_physics_process(false)
	w.enemies = [foe]
	w._select_enemy()
	w.dragon.aim = Vector3.FORWARD
	return foe

static func discard(w, foe) -> void:
	w.enemies.clear()
	w.enemy = null
	if is_instance_valid(foe):foe.free()

static func statuses(foe, chill: float, charge: float, toxin: int) -> void:
	foe.chilled = chill
	foe.charged = charge
	foe.toxin = toxin
	foe.toxin_time = 5.0 if toxin > 0 else 0.0
	foe.toxin_tick = .75 if toxin > 0 else 1.0

static func snapshot(foe) -> Array:
	return [foe.chilled, foe.charged, foe.toxin, foe.toxin_time, foe.toxin_tick]

static func recompile(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	# Explicit expected outcomes avoid deriving the acceptance result from the
	# selector being tested. Storm and two Toxin stacks exercise a real tie.
	var cases = [
		{"name":"neutral", "chill":0.0, "charge":0.0, "toxin":0, "chosen":"synthesis", "factor":1.0},
		{"name":"Chill", "chill":3.0, "charge":0.0, "toxin":0, "chosen":"fire", "factor":1.4},
		{"name":"Charge", "chill":0.0, "charge":4.0, "toxin":0, "chosen":"storm", "factor":1.5},
		{"name":"Toxin one", "chill":0.0, "charge":0.0, "toxin":1, "chosen":"venom", "factor":1.25},
		{"name":"Toxin two", "chill":0.0, "charge":0.0, "toxin":2, "chosen":"venom", "factor":1.5},
		{"name":"Toxin three", "chill":0.0, "charge":0.0, "toxin":3, "chosen":"venom", "factor":1.75},
		{"name":"Chill beats weak Toxin", "chill":3.0, "charge":0.0, "toxin":1, "chosen":"fire", "factor":1.4},
		{"name":"Storm wins equal Toxin", "chill":3.0, "charge":4.0, "toxin":2, "chosen":"storm", "factor":1.5},
		{"name":"strongest Toxin wins", "chill":3.0, "charge":4.0, "toxin":3, "chosen":"venom", "factor":1.75},
	]
	for id in ["synthesis-contract", "outer-boss"]:
		var foe = target(w, id)
		for option in cases:
			prepare(w)
			statuses(foe, option.chill, option.charge, option.toxin)
			foe.brain.mode = "seek"
			var prior = snapshot(foe)
			var hp: float = foe.hp
			var position: Vector3 = foe.global_position
			var fields: int = w.walls.size()
			var label: String = option.name + " / " + id
			check.call(w.dragon.try_ability("burst"), "Synthesis: begin shielded Recompile " + label)
			w.dragon.advance_combat(.361)
			check.call(foe.hp == hp and snapshot(foe) == prior and foe.spec.shield and not foe.brain.vulnerable(), "Synthesis: closed shield preserves every status and HP " + label)
			prepare(w)
			state.hp = state.max_hp - 30.0
			var own_hp: float = state.hp
			foe.brain.open_window(2.0)
			check.call(w.dragon.try_ability("burst"), "Synthesis: begin recovery Recompile " + label)
			w.dragon.advance_combat(.359)
			check.call(foe.hp == hp and snapshot(foe) == prior, "Synthesis: windup cannot damage or consume a status " + label)
			w.dragon.advance_combat(.002)
			check.call(is_equal_approx(hp - foe.hp, w.campaign_damage("burst") * option.factor), "Synthesis: exact strongest existing multiplier " + label)
			var expected: Array = prior.duplicate()
			match option.chosen:
				"fire":expected[0] = 0.0
				"storm":expected[1] = 0.0
				"venom":expected[2] = 0; expected[3] = 0.0; expected[4] = 1.0
			check.call(snapshot(foe) == expected, "Synthesis: only the selected landed status is consumed " + label)
			check.call(state.hp == own_hp and foe.global_position == position and w.walls.size() == fields and state.phase == 0 and state.null_reflect == 0.0 and foe.spec.shield, "Synthesis: Recompile grants no drain, healing, displacement, field, Phase or Reflect " + label)
			hp = foe.hp
			w.dragon.advance_combat(.5)
			check.call(foe.hp == hp and snapshot(foe) == expected and state.hp == own_hp, "Synthesis: recovery cannot repeat damage or consume another status " + label)
		# Out-of-range and interrupted contacts preserve all three statuses.
		for cancelled in [false, true]:
			prepare(w)
			statuses(foe, 3.0, 4.0, 3)
			var prior = snapshot(foe)
			var hp: float = foe.hp
			foe.global_position = w.dragon.global_position + Vector3.FORWARD * (2.5 if cancelled else 5.02)
			w.dragon.try_ability("burst")
			if cancelled:check.call(Combat.dodge(state), "Synthesis: dodge cancels Recompile " + id)
			w.dragon.advance_combat(.5)
			check.call(foe.hp == hp and snapshot(foe) == prior, "Synthesis: cancelled or missed Recompile spends no status " + id + " " + str(cancelled))
		discard(w, foe)
	prepare(w)
	var first = target(w, "synthesis-multi-chill")
	var second = target(w, "synthesis-multi-toxin")
	first.global_position = w.dragon.global_position + Vector3.FORWARD * 2.5
	second.global_position = w.dragon.global_position + Vector3.RIGHT * 3.0
	first.brain.open_window(2.0)
	second.brain.open_window(2.0)
	statuses(first, 3.0, 0.0, 0)
	statuses(second, 0.0, 4.0, 3)
	w.enemies = [first, second]
	var first_hp: float = first.hp
	var second_hp: float = second.hp
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.361)
	check.call(is_equal_approx(first_hp - first.hp, w.campaign_damage("burst") * 1.4) and is_equal_approx(second_hp - second.hp, w.campaign_damage("burst") * 1.75), "Synthesis: radial Recompile chooses the strongest status separately for each target")
	check.call(first.chilled == 0.0 and second.toxin == 0 and second.charged == 4.0, "Synthesis: multi-target contact does not share or erase unrelated statuses")
	discard(w, first)
	discard(w, second)
	prepare(w)

static func borrowed_attacks(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	var at: Vector3 = w.dragon.global_position
	for id in ["synthesis-contract", "outer-boss"]:
		var foe = target(w, id)
		for ability in ["claw", "breath", "wall"]:
			prepare(w)
			statuses(foe, 3.0, 4.0, 3)
			var prior = snapshot(foe)
			foe.brain.mode = "seek"
			var hp: float = foe.hp
			var position: Vector3 = foe.global_position
			var fields: int = w.walls.size()
			w.dragon.try_ability(ability)
			w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
			check.call(foe.hp == hp and foe.global_position == position and snapshot(foe) == prior and foe.spec.shield, "Synthesis: shield blocks borrowed damage and push " + ability + " " + id)
			prepare(w)
			state.hp = state.max_hp - 25.0
			var own_hp: float = state.hp
			foe.brain.open_window(2.0)
			w.dragon.try_ability(ability)
			w.dragon.advance_combat(Combat.rule(state, ability).windup - .001)
			check.call(foe.hp == hp and foe.global_position == position, "Synthesis: borrowed windup has no damage or movement " + ability + " " + id)
			w.dragon.advance_combat(.002)
			check.call(is_equal_approx(hp - foe.hp, w.campaign_damage(ability)) and snapshot(foe) == prior, "Synthesis: only Recompile adapts or consumes existing statuses " + ability + " " + id)
			var movement: float = 1.25 if ability == "breath" and not foe.boss else 0.0
			check.call(is_equal_approx(foe.global_position.distance_to(position), movement), "Synthesis: Void Rift pushes ordinary exposed foes but never bosses " + ability + " " + id)
			check.call(state.hp == own_hp and state.phase == 0 and state.null_reflect == 0.0 and w.walls.size() == fields, "Synthesis: borrowed attacks create no heal, Phase, Reflect or field " + ability + " " + id)
			hp = foe.hp
			position = foe.global_position
			w.dragon.advance_combat(.4)
			check.call(foe.hp == hp and foe.global_position == position and snapshot(foe) == prior, "Synthesis: borrowed contact occurs exactly once " + ability + " " + id)
			foe.global_position = at + Vector3.FORWARD * 2.5
		discard(w, foe)
	prepare(w)
	var foe = target(w, "synthesis-beam-range")
	foe.brain.open_window(2.0)
	for inside in [false, true]:
		prepare(w)
		foe.global_position = at + Vector3.FORWARD * (7.98 if inside else 8.02)
		var hp: float = foe.hp
		w.dragon.try_ability("wall")
		w.dragon.advance_combat(.281)
		check.call(is_equal_approx(hp - foe.hp, w.campaign_damage("wall") if inside else 0.0), "Synthesis: Radiant Beam respects eight-meter range " + str(inside))
	prepare(w)
	foe.global_position = at + Vector3.BACK * 2.5
	var hp: float = foe.hp
	w.dragon.try_ability("wall")
	w.dragon.advance_combat(.281)
	check.call(foe.hp == hp, "Synthesis: Radiant Beam is directional, not a radial field")
	var barrier = StaticBody3D.new()
	barrier.collision_layer = 1
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(5.0, 4.0, .2)
	collision.shape = shape
	barrier.add_child(collision)
	w.level.add_child(barrier)
	barrier.global_position = at + Vector3.FORWARD * 1.3 + Vector3.UP
	barrier.force_update_transform()
	foe.global_position = at + Vector3.FORWARD * 2.5
	statuses(foe, 3.0, 4.0, 3)
	for ability in ["breath", "wall", "burst"]:
		prepare(w)
		var prior = snapshot(foe)
		hp = foe.hp
		w.dragon.try_ability(ability)
		w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
		check.call(foe.hp == hp and snapshot(foe) == prior, "Synthesis: occluding geometry blocks damage and status spending " + ability)
	# Move the obstacle behind the target: the hit is clear, but its push must stop.
	barrier.global_position = at + Vector3.FORWARD * 3.5 + Vector3.UP
	barrier.force_update_transform()
	prepare(w)
	hp = foe.hp
	var position: Vector3 = foe.global_position
	w.dragon.try_ability("breath")
	w.dragon.advance_combat(.261)
	var moved: float = foe.global_position.distance_to(position)
	check.call(foe.hp < hp and moved > 0.0 and moved < .8 and foe.global_position.z > barrier.global_position.z, "Synthesis: successful Rift push cannot tunnel through collision geometry")
	foe.brain.mode = "tell"
	position = foe.global_position
	foe.shape = Patterns.lock("slam", position, at)
	var locked = foe.shape.duplicate(true)
	check.call(foe.displace_from(at, 1.25) == 0.0 and foe.global_position == position and foe.shape == locked, "Synthesis: locked enemy tells remain anchored")
	barrier.free()
	discard(w, foe)
	prepare(w)

static func party(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	var reserve: String = w.party.reserve_id()
	prepare(w)
	state.hp = state.max_hp * .5
	var hp: float = state.hp
	w.dragon.try_ability("burst")
	check.call(not w.swap_guardian(reserve), "Synthesis: voluntary swap cannot transfer pending Recompile")
	w.dragon.advance_combat(.761)
	var heat: float = state.heat
	var cooldown: float = state.cooldowns.burst
	check.call(state.hp == hp, "Synthesis: empty Recompile has no Restoration or drain")
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check.call(w.swap_guardian(reserve), "Synthesis: finished technique permits reserve swap")
	check.call(state.hp == hp and state.heat == heat and state.cooldowns.burst == cooldown, "Synthesis: swap preserves Prism health heat and recharge")
	w.party.tick_reserve(.25, 0)
	check.call(state.hp == hp and is_equal_approx(state.cooldowns.burst, cooldown - .25), "Synthesis: reserve cooldown expires without passive healing")
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check.call(w.swap_guardian("synthesis") and not w.dragon.try_ability("burst"), "Synthesis: swapping back cannot reset Recompile recharge")
	prepare(w)
	var foe = target(w, "synthesis-dodge")
	var before: float = foe.hp
	hp = state.hp
	check.call(Combat.dodge(state), "Synthesis: begins ordinary dodge")
	w._on_pattern(Patterns.lock("slam", foe.global_position, w.dragon.global_position), 20.0, foe)
	check.call(state.hp == hp and foe.hp == before and state.phase == 0 and state.null_reflect == 0.0, "Synthesis: dodge grants neither Phase nor reflected damage")
	discard(w, foe)
	prepare(w)

static func run(w, check: Callable) -> void:
	check.call(w.test_mode and w.campaign.room == "forge" and w.party.active_id == "synthesis" and w.party.states.size() == 2, "Synthesis: isolated live Forge and two-slot Prism expedition")
	w.hud.close_overlay()
	w.dragon.global_position = Vector3(0.0, .1, 2.0)
	recompile(w, check)
	borrowed_attacks(w, check)
	party(w, check)
