extends SceneTree
const Combat = preload("res://campaign/guardian_combat.gd")
const Enemy = preload("res://campaign/enemy.gd")
var checks = 0
var failures = 0

func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func frames(count = 2):
	for i in range(count):await physics_frame

func run():
	var state = Combat.fresh("", "void")
	check(Combat.guardian_name("void") == "NULL", "Void identity is Null")
	check(is_equal_approx(state.max_hp, Combat.fresh().max_hp * .88), "Void health is 88 percent of Fire")
	check(state.null_reflect == 0.0, "fresh Void has no reflection window")
	var names = {"claw":"Rift Shard", "breath":"Void Rift", "wall":"Null Reflect", "burst":"Siphon Rift"}
	for id in Combat.ORDER:
		var active = Combat.fresh("", "void")
		var rule = Combat.rule(active, id)
		check(rule.name == names[id], "Void move identity " + id)
		check(not rule.has("ignore_shield"), "Void move preserves shield authority " + id)
		check(Combat.cast(active, id), "Void cast " + id)
		check(Combat.tick(active, rule.windup + .001) == id, "Void contact " + id)
		check(Combat.tick(active, rule.recovery + .001) == "" and active.action == "", "Void recovers without duplicate contact " + id)
	check(Combat.rule(state, "wall").damage == 0.0 and Combat.rule(state, "wall").radius == 0.0, "Null Reflect creates no damaging field")
	check(Combat.void_displacement("breath") == 1.25 and Combat.void_displacement("burst") == -1.5, "Void displacement signs and bounds")
	check(Combat.void_displacement("claw") == 0.0 and Combat.void_displacement("wall") == 0.0 and Combat.void_displacement("unknown") == 0.0, "only the two rifts request displacement")
	state.null_reflect = Combat.null_reflect_duration()
	var hp: float = state.hp
	var applied = Combat.damage(state, 30.0)
	check(applied == 15.0 and state.hp == hp - 15.0, "active Null Reflect halves landed damage")
	check(Combat.reflected_damage(applied) == 15.0, "reflection uses actual received damage")
	check(Combat.reflected_damage(100.0) == 20.0, "reflection is capped at 20 damage")
	check(Combat.reflected_damage(Combat.damage(state, 30.0)) == 0.0, "post-hit immunity supplies no reflected damage")
	var guarded = Combat.fresh("", "void")
	guarded.guard = true;guarded.null_reflect = Combat.null_reflect_duration()
	var plain_guard = Combat.fresh("", "void");plain_guard.guard = true
	check(is_equal_approx(Combat.damage(guarded, 30.0) * 2.0, Combat.damage(plain_guard, 30.0)), "Null Reflect preserves guard mitigation")
	var warded = Combat.fresh("", "void");warded.ward = 1.0;warded.null_reflect = 1.0
	check(is_equal_approx(Combat.damage(warded, 40.0), 9.0), "Null Reflect preserves existing ward mitigation")
	var dodge = Combat.fresh("", "void");dodge.null_reflect = 1.0;Combat.dodge(dodge)
	check(Combat.reflected_damage(Combat.damage(dodge, 30.0)) == 0.0 and dodge.phase == 0, "dodged Void hits cause no damage, reflection, or Phase")
	var expired = Combat.fresh("", "void");expired.null_reflect = Combat.null_reflect_duration()
	Combat.tick(expired, .6);check(is_equal_approx(expired.null_reflect, .6), "reflection timer counts down")
	Combat.tick(expired, .61);check(expired.null_reflect == 0.0 and Combat.damage(expired, 30.0) == 30.0, "expired reflection restores full incoming damage")
	for guardian in ["fire", "ice", "storm", "stone", "venom", "shadow"]:
		var other = Combat.fresh("", guardian);other.null_reflect = 1.2
		check(Combat.damage(other, 30.0) == 30.0, "Null Reflect cannot reduce another guardian's damage: " + guardian)
	var legacy = Combat.fresh();legacy.erase("null_reflect");Combat.tick(legacy, .1)
	check(legacy.null_reflect == 0.0, "prototype state without timer remains supported")
	for invalid in [0.0, -1.0, NAN, INF, -INF]:
		var clean = Combat.fresh("", "void");clean.null_reflect = 1.2
		hp = clean.hp
		check(Combat.damage(clean, invalid) == 0.0 and clean.hp == hp and Combat.reflected_damage(invalid) == 0.0, "invalid or non-damaging reflection input: " + str(invalid))
	var no_time = Combat.fresh("", "void");no_time.null_reflect = 1.2
	for invalid_delta in [-1.0, NAN, INF]:Combat.tick(no_time, invalid_delta)
	check(no_time.null_reflect == 1.2, "invalid elapsed time cannot advance reflection")
	var dying = Combat.fresh("", "void");dying.hp = 3.0;dying.null_reflect = 1.2
	check(Combat.damage(dying, 100.0) == 3.0 and dying.hp == 0.0, "overkill reports only remaining health lost")
	check(Combat.damage(dying, 10.0) == 0.0, "dead guardian takes no further damage")
	# Shadow's earned Phase remains limited to actual dodge protection.
	var shadow = Combat.fresh("", "shadow");Combat.damage(shadow, 10.0);Combat.damage(shadow, 10.0)
	check(shadow.phase == 0, "Void changes preserve Shadow post-hit Phase regression")
	Combat.tick(shadow, .2);Combat.dodge(shadow);Combat.damage(shadow, 10.0)
	check(shadow.phase == 1, "Void changes preserve Shadow earned dodge Phase")
	await displacement_checks()
	print("VOID_COMBAT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func displacement_checks():
	var arena = Node3D.new();root.add_child(arena)
	var foe = Enemy.new()
	foe.spec = {"id":"void-combat-target", "name":"Void Target", "hp":500.0, "shield":false, "boss":false, "damage":10.0, "patterns":["slam"]}
	foe.set_physics_process(false);arena.add_child(foe);await frames()
	var origin = Vector3(-3.0, 0.0, 0.0)
	check(is_equal_approx(foe.displace_from(origin, 1.25), 1.25) and is_equal_approx(foe.position.x, 1.25), "ordinary foe pushes away from caster")
	check(is_equal_approx(foe.displace_from(origin, -1.5), 1.5) and is_equal_approx(foe.position.x, -.25), "ordinary foe pulls toward caster")
	foe.position = Vector3.ZERO;await frames()
	check(is_equal_approx(foe.displace_from(origin, 99.0), 1.5), "oversized displacement is bounded at 1.5 meters")
	foe.position = Vector3.ZERO;await frames()
	check(is_equal_approx(foe.displace_from(Vector3(-.2, 0.0, 0.0), -1.5), .2), "pull cannot cross the caster origin")
	foe.position = Vector3.ZERO;await frames()
	var before: Vector3 = foe.position
	for invalid in [0.0, NAN, INF, -INF]:
		check(foe.displace_from(origin, invalid) == 0.0 and foe.position == before, "invalid or zero displacement stays anchored: " + str(invalid))
	check(foe.displace_from(Vector3(NAN, 0.0, 0.0), 1.25) == 0.0 and foe.position == before, "nonfinite origin stays anchored")
	check(foe.displace_from(before, 1.25) == 0.0, "coincident foe has no undefined displacement direction")
	foe.boss = true
	check(foe.displace_from(origin, 1.25) == 0.0 and foe.position == before, "bosses remain anchored")
	foe.boss = false;foe.brain.mode = "tell"
	foe.shape = {"origin":Vector3.ZERO, "direction":Vector3.FORWARD, "circles":[Vector3(1.0, 0.0, 0.0)]}
	var locked_shape = foe.shape.duplicate(true)
	check(foe.displace_from(origin, -1.5) == 0.0 and foe.position == before and foe.shape == locked_shape, "locked tells retain position and attack geometry")
	foe.brain.mode = "recover"
	check(foe.displace_from(origin, 1.25) > 0.0 and foe.shape == locked_shape, "recovery displacement does not rewrite previous attack geometry")
	foe.position = Vector3.ZERO;foe.brain.mode = "seek";await frames()
	var wall = StaticBody3D.new();wall.collision_layer = 1;wall.position = Vector3(1.5, 1.2, 0.0)
	var collision = CollisionShape3D.new();var box = BoxShape3D.new();box.size = Vector3(.2, 4.0, 4.0);collision.shape = box;wall.add_child(collision);arena.add_child(wall);await frames()
	var moved = foe.displace_from(origin, 1.25)
	check(moved > .5 and moved < .81 and foe.position.x < .81, "push stops at static world collision")
	foe.position = Vector3.ZERO;wall.position.x = -1.5;await frames()
	moved = foe.displace_from(origin, -1.5)
	check(moved > .5 and moved < .81 and foe.position.x > -.81, "pull stops at static world collision")
	foe.position = Vector3.ZERO;wall.position.x = 1.5;wall.collision_layer = 2;await frames()
	check(foe.displace_from(origin, 1.25) < .81, "displacement respects guardian collision layer")
	foe.spec.shield = true;foe.brain.mode = "seek"
	var hp: float = foe.hp
	check(foe.take_hit(Combat.reflected_damage(15.0)) == 0.0 and foe.hp == hp, "reflected damage cannot bypass a closed shield")
	foe.brain.mode = "recover"
	check(foe.take_hit(Combat.reflected_damage(15.0)) == 15.0 and foe.hp == hp - 15.0, "reflected damage lands through an open shield")
	hp = foe.hp
	for invalid in [NAN, INF, -INF]:check(foe.take_hit(invalid) == 0.0 and foe.hp == hp, "enemy rejects nonfinite damage: " + str(invalid))
	before = foe.position;foe.hp = 0.0
	check(foe.displace_from(origin, 1.25) == 0.0 and foe.position == before, "zero-health enemies remain anchored")
	foe.hp = hp;foe.brain.mode = "dead"
	check(foe.displace_from(origin, 1.25) == 0.0 and foe.position == before, "dead brain remains anchored")
	foe.brain.mode = "recover";foe.queue_free()
	check(foe.displace_from(origin, 1.25) == 0.0 and foe.position == before, "queued enemies remain anchored")
	arena.queue_free();await frames(3)
