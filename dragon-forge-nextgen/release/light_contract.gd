extends RefCounted
## Shared source/export probes. Caller provides an isolated Forge with living
## Light active and one reserve. Targets always retain authoritative shields.
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

static func target(w, id: String = "light-contract"):
	var foe = Enemy.new()
	foe.spec = {"id":id,"name":"Light acceptance target","hp":900.0,"damage":10.0,"shield":true,"boss":id=="outer-boss","patterns":["slam"],"archetype":"bulwark"}
	foe.target = w.dragon
	foe.navigation = w
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

static func attacks(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	var at: Vector3 = w.dragon.global_position
	for id in ["light-contract", "outer-boss"]:
		var foe = target(w, id)
		for ability in ["claw", "breath", "wall"]:
			prepare(w)
			foe.brain.mode = "seek"
			var hp: float = foe.hp
			var position: Vector3 = foe.global_position
			var fields: int = w.walls.size()
			check.call(w.dragon.try_ability(ability), "Light: begin shielded " + ability + " " + id)
			w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
			check.call(foe.hp == hp and foe.global_position == position and foe.spec.shield and not foe.brain.vulnerable(), "Light: closed shield blocks damage without being opened or bypassed " + ability + " " + id)
			check.call(w.walls.size() == fields, "Light: technique creates no persistent damaging field " + ability + " " + id)
			prepare(w)
			state.hp = state.max_hp - 30.0
			var own_hp: float = state.hp
			foe.brain.open_window(2.0)
			check.call(w.dragon.try_ability(ability), "Light: begin recovery counter " + ability + " " + id)
			w.dragon.advance_combat(Combat.rule(state, ability).windup - .001)
			check.call(foe.hp == hp and state.hp == own_hp, "Light: no direct damage or healing during windup " + ability + " " + id)
			w.dragon.advance_combat(.002)
			check.call(is_equal_approx(hp - foe.hp, w.campaign_damage(ability)), "Light: open recovery receives exact contact damage " + ability + " " + id)
			check.call(state.hp == own_hp and foe.global_position == position and foe.toxin == 0 and state.phase == 0 and state.null_reflect == 0.0, "Light: damage grants no siphon, displacement, Toxin, Phase or Reflect " + ability + " " + id)
			check.call(foe.spec.shield and w.walls.size() == fields, "Light: contact preserves shield property and creates no field " + ability + " " + id)
			hp = foe.hp
			w.dragon.advance_combat(.4)
			check.call(foe.hp == hp and state.hp == own_hp, "Light: recovery cannot repeat contact " + ability + " " + id)
			prepare(w)
			check.call(w.dragon.try_ability(ability) and Combat.dodge(state), "Light: dodge cancels windup " + ability + " " + id)
			w.dragon.advance_combat(.5)
			check.call(foe.hp == hp and w.walls.size() == fields, "Light: cancelled attack cannot land or leave a field " + ability + " " + id)
		discard(w, foe)
	prepare(w)
	var foe = target(w, "light-range")
	foe.brain.open_window(2.0)
	for ability in ["claw", "breath", "wall"]:
		var radius: float = {"claw":2.9,"breath":8.0,"wall":4.5}[ability]
		check.call(Combat.rule(state, ability).range == radius, "Light: authored attack reach " + ability)
		for inside in [false, true]:
			prepare(w)
			foe.global_position = at + Vector3.FORWARD * (radius + (-.02 if inside else .02))
			var hp: float = foe.hp
			w.dragon.try_ability(ability)
			w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
			check.call(is_equal_approx(hp - foe.hp, w.campaign_damage(ability) if inside else 0.0), "Light: correct inner/outer range boundary " + ability + " " + str(inside))
		prepare(w)
		foe.global_position = at + Vector3.BACK * 2.5
		var hp: float = foe.hp
		w.dragon.try_ability(ability)
		w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
		check.call(is_equal_approx(hp - foe.hp, w.campaign_damage(ability) if ability == "wall" else 0.0), "Light: Solar Flare is radial while Claw/Beam require facing " + ability)
	# A thin static wall must block all three real world damage routes.
	foe.global_position = at + Vector3.FORWARD * 2.5
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
	check.call(not w.line_clear(at, foe.global_position), "Light: occlusion fixture blocks line of sight")
	for ability in ["claw", "breath", "wall"]:
		prepare(w)
		var hp: float = foe.hp
		w.dragon.try_ability(ability)
		w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
		check.call(foe.hp == hp and foe.spec.shield, "Light: wall occlusion blocks otherwise open-shield " + ability)
	barrier.free()
	discard(w, foe)
	prepare(w)

static func restoration(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	var reserve: String = w.party.reserve_id()
	var other: Dictionary = w.party.states[reserve]
	prepare(w)
	state.hp = state.max_hp * .4
	other.hp = other.max_hp * .5
	var own_hp: float = state.hp
	var reserve_hp: float = other.hp
	var foe = target(w, "light-restoration")
	foe.brain.open_window(2.0)
	var enemy_hp: float = foe.hp
	var fields: int = w.walls.size()
	check.call(w.dragon.try_ability("burst"), "Light: begin Restoration with wounded owner and reserve")
	check.call(is_equal_approx(state.heat, Combat.heat_cost(state, "burst")) and is_equal_approx(state.cooldowns.burst, 12.0), "Light: Restoration commits heat and twelve-second recharge at cast")
	check.call(not w.swap_guardian(reserve), "Light: voluntary swap cannot transfer a pending Restoration")
	w.dragon.advance_combat(.399)
	check.call(state.hp == own_hp and other.hp == reserve_hp, "Light: Restoration windup heals neither owner nor reserve")
	w.dragon.advance_combat(.002)
	check.call(is_equal_approx(state.hp - own_hp, state.max_hp * .25) and other.hp == reserve_hp, "Light: one Restoration heals living owner by exactly 25 percent maximum HP")
	check.call(foe.hp == enemy_hp and foe.spec.shield and w.walls.size() == fields, "Light: Restoration deals no enemy damage and creates no field")
	own_hp = state.hp
	w.dragon.advance_combat(.4)
	check.call(state.hp == own_hp and other.hp == reserve_hp and not w.dragon.try_ability("burst"), "Light: recovery cannot repeat healing or bypass recharge")
	var cooldown: float = state.cooldowns.burst
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check.call(w.swap_guardian(reserve), "Light: completed Restoration permits normal reserve swap")
	check.call(state.hp == own_hp and state.cooldowns.burst == cooldown and other.hp == reserve_hp, "Light: swap preserves restored owner's HP and cooldown without healing reserve")
	w.party.tick_reserve(.25, 0)
	check.call(state.hp == own_hp and is_equal_approx(state.cooldowns.burst, cooldown - .25), "Light: reserve cooldown expires without passive healing")
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check.call(w.swap_guardian("light") and not w.dragon.try_ability("burst"), "Light: swapping back cannot reset Restoration recharge")
	discard(w, foe)
	prepare(w)
	state.hp = state.max_hp - 1.0
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.401)
	check.call(state.hp == state.max_hp and other.hp == reserve_hp, "Light: near-full Restoration caps at maximum HP")
	prepare(w)
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.401)
	check.call(state.hp == state.max_hp and other.hp == reserve_hp, "Light: full-health Restoration cannot overheal or spill into reserve")
	prepare(w)
	state.hp = state.max_hp * .4
	own_hp = state.hp
	w.dragon.try_ability("burst")
	check.call(Combat.dodge(state), "Light: dodge cancels Restoration windup")
	w.dragon.advance_combat(.5)
	check.call(state.hp == own_hp and other.hp == reserve_hp and state.cooldowns.burst > 0.0, "Light: cancelled Restoration heals nobody and retains cooldown cost")
	prepare(w)
	state.hp = 0.0
	check.call(not w.dragon.try_ability("burst"), "Light: dead owner cannot begin Restoration")
	w.resolve_ability("burst", w.dragon.global_position, Vector3.FORWARD)
	check.call(state.hp == 0.0 and other.hp == reserve_hp, "Light: direct Restoration routing cannot revive a fallen owner")
	prepare(w)
	other.hp = 0.0
	state.hp = state.max_hp * .5
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.401)
	check.call(other.hp == 0.0 and is_equal_approx(state.hp, state.max_hp * .75), "Light: Restoration cannot revive a fallen reserve")
	other.hp = reserve_hp
	prepare(w)
	state.hp = 1.0
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.2)
	foe = target(w, "light-forced-handoff")
	var payload = Patterns.lock("slam", foe.global_position, w.dragon.global_position)
	w._on_pattern(payload, 999.0, foe)
	check.call(state.hp == 0.0 and state.action == "", "Light: lethal impact cancels pending Restoration")
	w._on_guardian_down()
	check.call(w.party.active_id == reserve and other.hp == reserve_hp, "Light: real forced handoff selects a living reserve without restoring it")
	w.dragon.advance_combat(.8)
	w.party.tick_reserve(.25, 0)
	check.call(state.hp == 0.0 and other.hp == reserve_hp, "Light: old Restoration cannot heal after forced handoff")
	# Restore only the isolated fixture, then leave the caller with Light active.
	state.hp = state.max_hp
	w.party.swap_remaining = 0.0
	w.dragon.input_grace = 0.0
	check.call(w.swap_guardian("light"), "Light: acceptance fixture returns to Lumen")
	discard(w, foe)
	prepare(w)

static func run(w, check: Callable) -> void:
	check.call(w.test_mode and w.campaign.room == "forge" and w.party.active_id == "light" and w.party.states.size() == 2, "Light: acceptance uses isolated Forge and two-slot Light expedition")
	w.hud.close_overlay()
	w.dragon.global_position = Vector3(0.0, .1, 2.0)
	attacks(w, check)
	restoration(w, check)
