extends RefCounted
## Shared source/export acceptance. Caller provides a save-isolated, Void-active
## Forge world. Synchronous probes keep live input and AI outside the fixtures.
const Combat = preload("res://campaign/guardian_combat.gd")
const Enemy = preload("res://campaign/enemy.gd")
const Patterns = preload("res://campaign/patterns.gd")

static func prepare(w) -> void:
	w.dragon.advance_combat(2.0)
	w.dragon.state.heat = 0.0
	w.dragon.state.cooldowns.clear()
	w.dragon.input_grace = 0.0
	w.dragon.state.guard = false
	w.dragon.state.hp = w.dragon.state.max_hp

static func target(w, id: String = "void-contract", shielded: bool = true):
	var foe = Enemy.new()
	foe.spec = {"id":id,"name":"Void acceptance target","hp":900.0,"damage":10.0,"shield":shielded,"boss":id=="outer-boss","patterns":["slam"],"archetype":"bulwark"}
	foe.target = w.dragon
	foe.navigation = w
	w.level.add_child(foe)
	foe.global_position = w.dragon.global_position + Vector3.FORWARD * 3.0
	foe.set_physics_process(false)
	w.enemies = [foe]
	w._select_enemy()
	w.dragon.aim = Vector3.FORWARD
	return foe

static func discard(w, foe) -> void:
	w.enemies.clear()
	w.enemy = null
	if is_instance_valid(foe):foe.free()

static func reflect(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	for id in ["void-contract", "outer-boss"]:
		var foe = target(w, id)
		var shape = Patterns.lock("slam", foe.global_position, w.dragon.global_position)
		prepare(w)
		var walls_before: int = w.walls.size()
		var hp: float = foe.hp
		check.call(w.dragon.try_ability("wall"), "Void: begin Null Reflect " + id)
		w.dragon.advance_combat(.179)
		check.call(state.null_reflect == 0.0 and foe.hp == hp, "Void: Reflect windup grants no protection or direct damage " + id)
		w.dragon.advance_combat(.002)
		check.call(is_equal_approx(state.null_reflect, 1.2) and w.walls.size() == walls_before and foe.hp == hp, "Void: contact grants 1.2 second Reflect without a damaging field " + id)
		var own_hp: float = state.hp
		w._on_pattern(shape, 20.0, foe)
		check.call(is_equal_approx(own_hp - state.hp, 10.0) and foe.hp == hp, "Void: closed shield blocks counter while incoming damage is halved " + id)
		check.call(foe.spec.shield and not foe.brain.vulnerable(), "Void: Reflect never opens or removes shield " + id)
		prepare(w)
		foe.brain.open_window(2.0)
		state.null_reflect = 1.2
		own_hp = state.hp
		w._on_pattern(shape, 20.0, foe)
		check.call(is_equal_approx(own_hp - state.hp, 10.0) and is_equal_approx(hp - foe.hp, 10.0), "Void: recovery counter equals actual received damage " + id)
		var after_hp: float = foe.hp
		own_hp = state.hp
		w._on_pattern(shape, 20.0, foe)
		check.call(state.hp == own_hp and foe.hp == after_hp, "Void: post-hit protection yields no duplicate counter or bounce " + id)
		prepare(w)
		state.null_reflect = 1.2
		own_hp = state.hp
		after_hp = foe.hp
		w._on_pattern(shape, 80.0, foe)
		check.call(is_equal_approx(own_hp - state.hp, 40.0) and is_equal_approx(after_hp - foe.hp, 20.0), "Void: counter is capped at 20 actual damage " + id)
		prepare(w)
		state.null_reflect = 1.2
		state.guard = true
		own_hp = state.hp
		after_hp = foe.hp
		w._on_pattern(shape, 20.0, foe)
		var received: float = own_hp - state.hp
		check.call(received > 0.0 and received < 10.0 and is_equal_approx(after_hp - foe.hp, received), "Void: guard reduction is applied before calculating counter " + id)
		prepare(w)
		state.null_reflect = 1.2
		own_hp = state.hp
		after_hp = foe.hp
		var miss = Patterns.lock("slam", foe.global_position, w.dragon.global_position + Vector3.RIGHT * 10.0)
		w._on_pattern(miss, 20.0, foe)
		check.call(state.hp == own_hp and foe.hp == after_hp, "Void: missed pattern cannot reflect " + id)
		for amount in [0.0, -2.0, NAN, INF]:
			w._on_pattern(shape, amount, foe)
			check.call(state.hp == own_hp and foe.hp == after_hp, "Void: nonpositive/nonfinite incoming damage cannot reflect " + id + " " + str(amount))
		check.call(Combat.dodge(state), "Void: begin dodge during Null Reflect " + id)
		w._on_pattern(shape, 20.0, foe)
		check.call(state.hp == own_hp and foe.hp == after_hp and state.phase == 0, "Void: dodge earns neither reflection nor Phase " + id)
		prepare(w)
		state.null_reflect = 1.2
		w.dragon.advance_combat(1.21)
		own_hp = state.hp
		after_hp = foe.hp
		w._on_pattern(shape, 20.0, foe)
		check.call(is_equal_approx(own_hp - state.hp, 20.0) and foe.hp == after_hp, "Void: expired Reflect neither halves nor counters " + id)
		prepare(w)
		state.null_reflect = 1.2
		own_hp = state.hp
		after_hp = foe.hp
		w._on_pattern(shape, 20.0)
		check.call(is_equal_approx(own_hp - state.hp, 10.0) and foe.hp == after_hp, "Void: sourceless damage cannot invent a reflection target " + id)
		prepare(w)
		state.null_reflect = 1.2
		state.hp = 1.0
		after_hp = foe.hp
		w._on_pattern(shape, 20.0, foe)
		check.call(state.hp == 0.0 and foe.hp == after_hp, "Void: lethal incoming hit cannot counter after guardian death " + id)
		w._on_pattern(shape, 20.0, foe)
		check.call(state.hp == 0.0 and foe.hp == after_hp, "Void: dead guardian cannot reflect later hits " + id)
		prepare(w)
		discard(w, foe)

static func attacks(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	var at: Vector3 = w.dragon.global_position
	for id in ["void-contract", "outer-boss"]:
		var foe = target(w, id)
		for ability in ["breath", "burst"]:
			prepare(w)
			state.hp = state.max_hp - 30.0
			var own_hp: float = state.hp
			var hp: float = foe.hp
			var position: Vector3 = foe.global_position
			check.call(w.dragon.try_ability(ability), "Void: begin shielded " + ability + " " + id)
			w.dragon.advance_combat(Combat.rule(state, ability).windup + .001)
			check.call(foe.hp == hp and foe.global_position.is_equal_approx(position) and state.hp == own_hp, "Void: closed shield blocks damage, displacement and siphon " + ability + " " + id)
		foe.brain.open_window(2.0)
		for ability in ["breath", "burst"]:
			prepare(w)
			state.hp = state.max_hp - 30.0
			foe.global_position = at + Vector3.FORWARD * 3.0
			var own_hp: float = state.hp
			var hp: float = foe.hp
			var distance: float = foe.global_position.distance_to(at)
			check.call(w.dragon.try_ability(ability), "Void: begin recovery " + ability + " " + id)
			w.dragon.advance_combat(Combat.rule(state, ability).windup - .001)
			check.call(foe.hp == hp and is_equal_approx(foe.global_position.distance_to(at), distance) and state.hp == own_hp, "Void: no damage, movement or healing before contact " + ability + " " + id)
			w.dragon.advance_combat(.002)
			var dealt: float = hp - foe.hp
			check.call(is_equal_approx(dealt, w.campaign_damage(ability)), "Void: exact positive damage through open shield " + ability + " " + id)
			var expected_distance: float = distance if foe.boss else distance + (1.25 if ability == "breath" else -1.5)
			check.call(is_equal_approx(foe.global_position.distance_to(at), expected_distance), "Void: boss stays fixed; ordinary foe obeys push/pull " + ability + " " + id)
			var healed: float = minf(30.0, dealt * .4) if ability == "burst" else 0.0
			check.call(is_equal_approx(state.hp - own_hp, healed), "Void: healing uses actual Siphon damage only " + ability + " " + id)
			check.call(foe.toxin == 0 and state.phase == 0 and foe.spec.shield, "Void: contact grants no Toxin or Phase and preserves shield property " + ability + " " + id)
			var after_hp: float = foe.hp
			var after_position: Vector3 = foe.global_position
			own_hp = state.hp
			w.dragon.advance_combat(.4)
			check.call(foe.hp == after_hp and state.hp == own_hp and foe.global_position.is_equal_approx(after_position), "Void: one contact cannot damage, move or heal again " + ability + " " + id)
		discard(w, foe)
	var foe = target(w, "void-overkill", false)
	prepare(w)
	state.hp = state.max_hp - 30.0
	foe.hp = 5.0
	var own_hp: float = state.hp
	check.call(w.dragon.try_ability("burst"), "Void: begin low-health Siphon target")
	w.dragon.advance_combat(.301)
	check.call(foe.hp == 0.0 and is_equal_approx(state.hp - own_hp, 2.0), "Void: overkill siphon heals 40 percent of actual remaining HP")
	discard(w, foe)
	foe = target(w, "void-heal-cap", false)
	prepare(w)
	state.hp = state.max_hp - 1.0
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.301)
	check.call(state.hp == state.max_hp, "Void: Siphon healing caps at maximum health")
	discard(w, foe)
	prepare(w)
	state.hp = state.max_hp - 20.0
	own_hp = state.hp
	w.dragon.try_ability("burst")
	w.dragon.advance_combat(.301)
	check.call(state.hp == own_hp, "Void: empty-space Siphon cannot heal")
	prepare(w)
	state.hp = state.max_hp - 20.0
	own_hp = state.hp
	foe = target(w, "void-cancelled", false)
	var hp: float = foe.hp
	var position: Vector3 = foe.global_position
	w.dragon.try_ability("burst")
	check.call(Combat.dodge(state), "Void: dodge cancels Siphon windup")
	w.dragon.advance_combat(.301)
	check.call(foe.hp == hp and state.hp == own_hp and foe.global_position.is_equal_approx(position), "Void: cancelled contact has no damage, movement or healing")
	discard(w, foe)
	prepare(w)

static func displacement(w, check: Callable) -> void:
	var foe = target(w, "void-displacement", false)
	var origin: Vector3 = w.dragon.global_position
	var position: Vector3 = foe.global_position
	foe.brain.mode = "tell"
	foe.shape = Patterns.lock("slam", position, origin)
	var locked: Dictionary = foe.shape.duplicate(true)
	check.call(foe.displace_from(origin, 1.25) == 0.0 and foe.global_position == position and foe.shape == locked, "Void: locked enemy tell and geometry cannot be displaced")
	foe.brain.kill()
	check.call(foe.displace_from(origin, -1.5) == 0.0 and foe.global_position == position, "Void: dead enemy cannot be displaced")
	foe.brain.mode = "seek"
	var wall = StaticBody3D.new()
	wall.collision_layer = 1
	var collision = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(6.0, 4.0, .20)
	collision.shape = box
	wall.add_child(collision)
	w.level.add_child(wall)
	wall.global_position = position + Vector3.FORWARD * 1.0 + Vector3.UP
	wall.force_update_transform()
	var moved: float = foe.displace_from(origin, 1.25)
	check.call(moved > 0.0 and moved < .8 and foe.global_position.z > wall.global_position.z, "Void: push uses collision body and cannot tunnel through wall (travel %.3f, foe z %.3f, wall z %.3f)" % [moved, foe.global_position.z, wall.global_position.z])
	foe.global_position = position
	wall.global_position = position + Vector3.BACK * 1.0 + Vector3.UP
	wall.force_update_transform()
	moved = foe.displace_from(origin, -1.5)
	check.call(moved > 0.0 and moved < .8 and foe.global_position.z < wall.global_position.z, "Void: pull uses collision body and cannot tunnel through wall")
	wall.free()
	discard(w, foe)

static func run(w, check: Callable) -> void:
	check.call(w.test_mode and w.campaign.room == "forge" and w.party.active_id == "void", "Void: acceptance uses isolated live Forge and active Null")
	w.dragon.global_position = Vector3(0.0, .1, 2.0)
	reflect(w, check)
	attacks(w, check)
	displacement(w, check)
	prepare(w)
