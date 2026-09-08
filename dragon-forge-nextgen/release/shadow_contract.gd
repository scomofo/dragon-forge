extends RefCounted
## Shared source/export acceptance probe. Caller supplies a save-isolated Forge world
## with Umbra active. Runs synchronously so no live AI/input can alter the fixtures.
const Combat = preload("res://campaign/guardian_combat.gd")
const Enemy = preload("res://campaign/enemy.gd")
const Patterns = preload("res://campaign/patterns.gd")

static func prepare(w) -> void:
	w.dragon.advance_combat(1.0)
	w.dragon.state.heat = 0.0
	w.dragon.state.cooldowns.clear()
	w.dragon.input_grace = 0.0

static func run(w, check: Callable) -> void:
	var state: Dictionary = w.dragon.state
	var at: Vector3 = w.dragon.global_position
	var shape = Patterns.lock("slam", at + Vector3.FORWARD * 3, at)
	state.phase = 0
	prepare(w)
	w._on_pattern(shape, 10.0)
	var hp: float = state.hp
	w._on_pattern(shape, 10.0)
	check.call(state.hp == hp and state.phase == 0, "Shadow: real post-hit protection grants no Phase")
	prepare(w)
	check.call(Combat.dodge(state), "Shadow: begin dodge for incoming pattern")
	var miss = Patterns.lock("slam", at, at + Vector3.RIGHT * 10)
	w._on_pattern(miss, 10.0)
	check.call(state.phase == 0, "Shadow: missed incoming pattern grants no Phase")
	w._on_pattern(shape, 10.0)
	check.call(state.phase == 1, "Shadow: intersecting pattern during dodge earns Phase")
	w._on_pattern(shape, 10.0)
	check.call(state.phase == 2, "Shadow: second avoided pattern reaches cap")
	prepare(w)
	check.call(w.dragon.try_ability("burst"), "Shadow: begin empty-space Phase Strike")
	w.dragon.advance_combat(.21)
	check.call(state.phase == 2, "Shadow: whiff preserves Phase")
	prepare(w)
	check.call(w.dragon.try_ability("burst"), "Shadow: begin interruptible Phase Strike")
	check.call(Combat.dodge(state), "Shadow: dodge cancels windup")
	w.dragon.advance_combat(.25)
	check.call(state.phase == 2, "Shadow: cancelled windup preserves Phase")
	# Use both the normal enemy path and an actual imported boss identity.
	for id in ["shadow-contract", "outer-boss"]:
		var foe = Enemy.new()
		foe.spec = {"id":id,"name":"Phase acceptance target","hp":900.0,"damage":10.0,"shield":true,"boss":id=="outer-boss","patterns":["slam"],"archetype":"bulwark"}
		foe.target = w.dragon
		foe.navigation = w
		w.level.add_child(foe)
		foe.global_position = at + Vector3.FORWARD * 3
		foe.set_physics_process(false)
		w.enemies = [foe]
		w._select_enemy()
		w.dragon.aim = Vector3.FORWARD
		state.phase = 2
		prepare(w)
		var before: float = foe.hp
		check.call(w.dragon.try_ability("burst"), "Shadow: begin shielded strike " + id)
		w.dragon.advance_combat(.21)
		check.call(foe.hp == before and state.phase == 2, "Shadow: closed shield preserves HP and Phase " + id)
		# Keep spec.shield true. Only the authoritative recovery window opens it.
		foe.brain.open_window(2.0)
		prepare(w)
		var expected: float = w.campaign_damage("burst")
		check.call(w.dragon.try_ability("burst"), "Shadow: begin recovery counter " + id)
		w.dragon.advance_combat(.19)
		check.call(foe.hp == before and state.phase == 2, "Shadow: windup cannot damage or spend Phase " + id)
		w.dragon.advance_combat(.02)
		check.call(is_equal_approx(before - foe.hp, expected) and state.phase == 0, "Shadow: recovery counter deals exact boosted damage and spends Phase " + id)
		w.dragon.advance_combat(.4)
		check.call(is_equal_approx(before - foe.hp, expected), "Shadow: one strike cannot hit again during recovery " + id)
		w.enemies.clear()
		w.enemy = null
		foe.free()
	prepare(w)
