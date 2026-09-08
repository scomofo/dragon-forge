extends SceneTree
const Combat = preload("res://campaign/guardian_combat.gd")
var checks = 0
var failures = 0

# Exercise the real Enemy/Brain damage implementation without imported presentation.
class RuleTarget:
	extends "res://campaign/enemy.gd"
	func _ready() -> void:
		spec = {"id":"synthesis-rules-target", "name":"Recompile Target", "shield":true}
		max_hp = 1000.0;hp = max_hp;set_physics_process(false)

func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run():
	var prism = Combat.fresh("", "synthesis")
	check(Combat.guardian_name("synthesis") == "PRISM", "Synthesis guardian identity is Prism")
	check(is_equal_approx(prism.max_hp, Combat.fresh().max_hp * .95), "Prism has 95 percent of Fire's maximum health")
	var expected = {
		"claw":["Convergence Shard", 26.0, 0.0, .55, 3.0, .20, .12, .20],
		"breath":["Void Rift", 32.0, 22.0, 3.0, 7.8, .82, .26, .30],
		"wall":["Radiant Beam", 36.0, 26.0, 4.0, 8.0, .86, .28, .32],
		"burst":["Recompile", 46.0, 38.0, 9.0, 5.0, -1.0, .36, .40],
	}
	var keys = ["name", "damage", "heat", "cooldown", "range", "cone", "windup", "recovery"]
	for id in Combat.ORDER:
		var state = Combat.fresh("", "synthesis")
		var move = Combat.rule(state, id)
		for i in range(keys.size()):check(move[keys[i]] == expected[id][i], "Synthesis " + id + " contract " + keys[i])
		check(not move.has("ignore_shield"), "Synthesis move preserves shield authority: " + id)
		check(Combat.cast(state, id) and state.heat == move.heat and state.cooldowns[id] == move.cooldown, "Synthesis cast pays its heat and cooldown: " + id)
		check(Combat.tick(state, move.windup - .001) == "", "Synthesis move does not contact early: " + id)
		check(Combat.tick(state, .001) == id, "Synthesis move contacts at exact windup: " + id)
		check(Combat.tick(state, move.recovery - .001) == "" and state.action == id, "Synthesis move retains recovery: " + id)
		check(Combat.tick(state, .001) == "" and state.action == "", "Synthesis move ends without a second contact: " + id)
	check(not Combat.rule(prism, "wall").has("radius"), "Synthesis Radiant Beam has no persistent-field definition")
	check(Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3.BACK * 5.0, 5.0, -1.0), "Recompile reaches exposed targets behind Prism")
	check(not Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3.BACK * 5.01, 5.0, -1.0), "Recompile excludes targets outside five meters")
	selection_checks()
	enemy_checks()
	interruption_checks()
	print("SYNTHESIS_COMBAT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func selection_checks():
	var cases = [
		[0.0, 0.0, 0, "synthesis", "clean target is neutral"],
		[4.0, 0.0, 0, "fire", "Chill selects Shatter"],
		[0.0, 4.0, 0, "storm", "Charge selects Discharge"],
		[0.0, 0.0, 1, "venom", "one Toxin selects Bloom"],
		[0.0, 0.0, 2, "venom", "two Toxin selects Bloom"],
		[0.0, 0.0, 3, "venom", "three Toxin selects Bloom"],
		[4.0, 4.0, 0, "storm", "Discharge beats Shatter"],
		[4.0, 0.0, 1, "fire", "Shatter beats one Toxin"],
		[4.0, 0.0, 2, "venom", "two Toxin beats Shatter"],
		[4.0, 4.0, 1, "storm", "Discharge beats Chill and one Toxin"],
		[4.0, 4.0, 2, "storm", "equal 1.5 payoff retains Storm before Venom"],
		[4.0, 4.0, 3, "venom", "three Toxin beats both other statuses"],
		[4.0, 4.0, 999, "venom", "oversized Toxin uses the bounded three-stack payoff"],
		[-1.0, -1.0, -99, "synthesis", "negative statuses are inactive"],
		[NAN, INF, 0, "synthesis", "nonfinite timers are inactive"],
		[INF, 4.0, 0, "storm", "invalid Chill cannot mask valid Charge"],
		[4.0, NAN, 1, "fire", "invalid Charge cannot mask valid Chill"],
		[-INF, NAN, 3, "venom", "invalid timers cannot mask valid Toxin"],
	]
	for data in cases:check(Combat.recompile_element(data[0], data[1], data[2]) == data[3], data[4])
	for repeat in range(3):check(Combat.recompile_element(4.0, 4.0, 2) == "storm", "Recompile tie selection is deterministic: " + str(repeat))

func prepare(target, chilled: float, charged: float, stacks: int, open: bool = true):
	target.hp = 1000.0;target.chilled = chilled;target.charged = charged;target.toxin = stacks
	target.toxin_time = 4.0 if stacks > 0 else 0.0;target.toxin_tick = .4
	target.brain.mode = "seek";target.brain.timer = 0.0
	if open:target.brain.open_window(2.0)

func snapshot(target) -> PackedByteArray:
	return var_to_bytes([target.hp, target.chilled, target.charged, target.toxin, target.toxin_time, target.toxin_tick])

func enemy_checks():
	var target = RuleTarget.new();root.add_child(target)
	# Input statuses, expected damage multiplier, and the one selected status to consume.
	var cases = [
		[0.0, 0.0, 0, 1.0, "synthesis"],
		[4.0, 0.0, 0, 1.4, "fire"],
		[0.0, 4.0, 0, 1.5, "storm"],
		[0.0, 0.0, 1, 1.25, "venom"],
		[0.0, 0.0, 2, 1.5, "venom"],
		[0.0, 0.0, 3, 1.75, "venom"],
		[4.0, 4.0, 1, 1.5, "storm"],
		[4.0, 4.0, 2, 1.5, "storm"],
		[4.0, 4.0, 3, 1.75, "venom"],
		[4.0, 0.0, 1, 1.4, "fire"],
		[4.0, 0.0, 2, 1.5, "venom"],
		[4.0, 4.0, 999, 1.75, "venom"],
	]
	for data in cases:
		prepare(target, data[0], data[1], data[2], false)
		var before = snapshot(target)
		check(target.element_hit(46.0, "synthesis", "burst") == 0.0 and snapshot(target) == before, "closed shield preserves all Recompile statuses: " + str(data))
		target.brain.open_window(2.0)
		var actual = target.element_hit(46.0, "synthesis", "burst")
		check(target.spec.shield and target.brain.vulnerable() and is_equal_approx(actual, 46.0 * data[3]), "enabled shield's open window permits selected Recompile payoff: " + str(data))
		check(target.chilled == (0.0 if data[4] == "fire" else data[0]) and target.charged == (0.0 if data[4] == "storm" else data[1]) and target.toxin == (0 if data[4] == "venom" else data[2]), "Recompile consumes only its selected status: " + str(data))
		check(target.toxin_time == (0.0 if data[4] == "venom" or data[2] == 0 else 4.0) and target.toxin_tick == (1.0 if data[4] == "venom" else .4), "unselected Toxin timer and cadence stay intact: " + str(data))
	for id in ["claw", "breath", "wall"]:
		prepare(target, 4.0, 4.0, 3)
		var rule = Combat.rule({"guardian":"synthesis"}, id)
		check(target.element_hit(rule.damage, "synthesis", id) == rule.damage and target.chilled == 4.0 and target.charged == 4.0 and target.toxin == 3, "ordinary Synthesis hit neither adapts nor consumes statuses: " + id)
		prepare(target, 0.0, 0.0, 0)
		check(target.element_hit(rule.damage, "synthesis", id) == rule.damage and target.chilled == 0.0 and target.charged == 0.0 and target.toxin == 0, "ordinary Synthesis hit applies no invented status: " + id)
	for invalid in [0.0, -1.0, NAN, INF, -INF]:
		prepare(target, 4.0, 4.0, 3)
		var before = snapshot(target)
		check(target.element_hit(invalid, "synthesis", "burst") == 0.0 and snapshot(target) == before, "invalid damage cannot consume any selected payoff: " + str(invalid))
	prepare(target, INF, NAN, 0)
	check(target.element_hit(46.0, "synthesis", "burst") == 46.0 and is_inf(target.chilled) and is_nan(target.charged), "nonfinite status timers cannot generate bonus damage")
	# Re-select independently on each target and each contact; never cache a prior advantage.
	prepare(target, 4.0, 4.0, 3)
	var sequence: Array[float] = []
	for i in range(4):sequence.append(target.element_hit(46.0, "synthesis", "burst"))
	check(is_equal_approx(sequence[0], 80.5) and is_equal_approx(sequence[1], 69.0) and is_equal_approx(sequence[2], 64.4) and sequence[3] == 46.0, "successive Recompile hits recompute remaining Toxin, Charge, Chill, then neutral")
	prepare(target, 4.0, 4.0, 3)
	var other = RuleTarget.new();root.add_child(other);prepare(other, 4.0, 0.0, 1)
	check(is_equal_approx(target.element_hit(46.0, "synthesis", "burst"), 80.5) and is_equal_approx(other.element_hit(46.0, "synthesis", "burst"), 64.4), "Recompile selects a separate payoff for each target")
	check(target.chilled == 4.0 and target.charged == 4.0 and other.toxin == 1, "separate target choices preserve their unselected statuses")
	other.free()
	prepare(target, 4.0, 4.0, 3)
	check(is_equal_approx(target.element_hit(46.0, "fire", "burst"), 64.4) and target.charged == 4.0 and target.toxin == 3, "Fire retains Shatter rather than adopting Recompile's strongest payoff")
	prepare(target, 4.0, 4.0, 3)
	check(target.element_hit(46.0, "shadow", "burst") == 46.0 and target.chilled == 4.0 and target.charged == 4.0 and target.toxin == 3, "Shadow damage does not acquire Synthesis adaptation")
	prepare(target, 4.0, 4.0, 3);target.hp = 5.0
	check(target.element_hit(46.0, "synthesis", "burst") == 5.0 and target.hp == 0.0 and target.toxin == 0 and target.chilled == 4.0 and target.charged == 4.0, "lethal Recompile reports actual health lost and consumes only its chosen payoff")
	var dead_before = snapshot(target)
	check(target.element_hit(46.0, "synthesis", "burst") == 0.0 and snapshot(target) == dead_before, "dead or queued target cannot spend another status")
	root.remove_child(target);target.free()

func interruption_checks():
	var state = Combat.fresh("", "synthesis")
	check(Combat.cast(state, "burst"), "Recompile starts windup")
	Combat.cancel_action(state)
	check(state.heat == 38.0 and state.cooldowns.burst == 9.0 and Combat.tick(state, .5) == "", "canceled Recompile keeps its paid cost and emits no contact")
	state = Combat.fresh("", "synthesis");Combat.cast(state, "burst");state.hp = 0.0
	check(Combat.tick(state, .5) == "" and state.action == "", "dead Prism cannot deliver a pending Recompile")
	state = Combat.fresh("", "synthesis");state.null_reflect = 1.2
	check(Combat.damage(state, 30.0) == 30.0 and state.phase == 0, "Prism has no inherited reflection or Phase")
	state.hp = 1.0
	check(Combat.restore(state) == 0.0 and state.hp == 1.0, "Prism does not inherit Light Restoration")
