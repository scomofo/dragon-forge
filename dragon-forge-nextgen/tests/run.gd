extends SceneTree
const Combat = preload("res://sim/combat.gd")
const Progress = preload("res://sim/progression.gd")
const Brain = preload("res://sim/enemy_brain.gd")
const Conduit = preload("res://sim/conduit.gd")
const Store = preload("res://sim/save_store.gd")
const Prefs = preload("res://sim/preferences.gd")
const Main = preload("res://world/main.tscn")
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
	print(("PASS " if condition else "FAIL ") + label)

func _run() -> void:
	_rules()
	_progression()
	_storage()
	_action_contract()
	_preferences()
	await _integration()
	await _presence()
	print("NEXTGEN_TESTS: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _rules() -> void:
	var state = Combat.fresh()
	check(not Combat.cast(state, "missing"), "unknown ability rejected")
	check(Combat.cast(state, "breath"), "first breath accepted")
	check(state.heat == 24.0, "breath heat cost")
	check(not Combat.cast(state, "breath") and state.heat == 24.0, "cooldown does not double-spend")
	Combat.tick(state, -1.0)
	check(state.heat == 24.0, "negative delta cannot create heat")
	Combat.tick(state, 2.4)
	check(Combat.cast(state, "breath"), "cooldown expires")
	state.heat = 90.0
	check(not Combat.cast(state, "burst"), "heat budget enforced")
	state = Combat.fresh()
	check(is_equal_approx(Combat.damage(state, 22), 22.0), "ordinary damage")
	check(Combat.damage(state, 22) == 0.0, "brief contact invulnerability prevents duplicate hit")
	state = Combat.fresh()
	Combat.tick(state, 0.0, true)
	check(is_equal_approx(Combat.damage(state, 22), 5.5), "guard reduces damage to quarter")
	check(not Combat.cast(state, "claw"), "cannot attack through guard")
	state = Combat.fresh()
	check(Combat.dodge(state), "dodge starts")
	check(Combat.damage(state, 100) == 0.0, "dodge grants actual invulnerability")
	check(not Combat.dodge(state), "cannot spam dodge")
	Combat.tick(state, 0.25)
	check(Combat.damage(state, 10) == 10.0, "dodge invulnerability ends")
	state.hp = 0.0
	check(not Combat.cast(state, "claw") and not Combat.dodge(state), "dead actors cannot act")
	state = Combat.fresh()
	state.heat = 91.0
	check(not Combat.dodge(state), "dodge obeys heat cap")
	check(Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -6), 7, 0.65), "forward cone hit")
	check(not Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3(6, 0, 0), 7, 0.65), "side target excluded")
	check(not Combat.in_cone(Vector3.ZERO, Vector3.FORWARD, Vector3(0, 0, -8), 7, 0.65), "range enforced")
	var conduit = Conduit.new()
	check(not conduit.add_heat(38.0), "one breath does not overload")
	conduit.tick(2.4)
	check(conduit.add_heat(38.0), "two properly timed breaths overload")
	check(conduit.heat == 0.0 and conduit.cooldown == 6.0, "overload resets heat and starts cooldown")
	check(not conduit.add_heat(100.0), "overload cannot retrigger on same frame")
	conduit.tick(6.0)
	check(not conduit.add_heat(59) and conduit.add_heat(1), "exact heat threshold")
	var brain = Brain.new()
	var first = Vector3(1, 0, 2)
	check(brain.tick(0, 3, first) == "tell", "sentinel begins visible tell")
	brain.tick(0.1, 3, Vector3(9, 0, 9))
	check(brain.locked_target == first, "tell does not track a dodging player")
	check(brain.tick(1.35, 3, Vector3.ZERO) == "slam", "tell resolves one slam")
	check(brain.tick(0.1, 3, Vector3.ZERO) == "" and brain.vulnerable(), "recovery opens shield without a second slam")
	brain.open_window(2.4)
	check(brain.timer >= 2.4, "guard/overload extends counter window")
	brain.kill()
	brain.open_window(5)
	check(brain.tick(10, 0, Vector3.ZERO) == "" and brain.mode == "dead", "dead enemy cannot restart")

func _progression() -> void:
	var state = Progress.fresh()
	check(Progress.validate(state), "fresh schema is valid")
	check(not Progress.advance(state, "gate"), "cannot open gate before hatch")
	check(not Progress.advance(state, "install"), "cannot install an unearned core")
	check(Progress.advance(state, "hatch"), "hatch milestone")
	check(not Progress.advance(state, "hatch"), "hatch is idempotent")
	check(Progress.advance(state, "gate"), "gate milestone")
	check(not Progress.advance(state, "clear", 2), "cannot skip encounters")
	for i in range(3):
		check(Progress.advance(state, "clear", i), "clear encounter %d" % i)
		check(not Progress.advance(state, "clear", i), "duplicate defeat %d ignored" % i)
	check(Progress.advance(state, "core"), "core recovered only after warden")
	check(not Progress.advance(state, "core"), "core cannot be farmed by repeated input")
	check(Progress.advance(state, "install"), "core installation")
	check(not Progress.advance(state, "install") and Progress.validate(state), "upgrade exactly once")
	var invalid = state.duplicate(true)
	invalid.clears = 1
	check(not Progress.validate(invalid), "inconsistent progress rejected")
	invalid = state.duplicate(true)
	invalid.version = 99
	check(not Progress.validate(invalid), "future save schema not silently overwritten")

func _storage() -> void:
	var store = Store.new()
	store.path = "user://nextgen-test-%d.json" % Time.get_ticks_usec()
	var state = Progress.fresh()
	check(store.read_progress() == state, "missing save loads defaults")
	check(store.write_progress(state), "checked save write")
	Progress.advance(state, "hatch")
	check(store.write_progress(state), "second write with backup")
	check(FileAccess.file_exists(store.path + ".bak"), "previous write retained")
	check(store.read_progress() == state, "save roundtrip")
	var corrupt = FileAccess.open(store.path, FileAccess.WRITE)
	corrupt.store_string("not-json-do-not-overwrite")
	corrupt.close()
	store.read_progress()
	check(store.blocked and not store.write_progress(state), "corrupt save blocks overwrite")
	check(FileAccess.get_file_as_string(store.path) == "not-json-do-not-overwrite", "corrupt bytes retained")
	for suffix in ["", ".bak", ".tmp"]:
		var path = ProjectSettings.globalize_path(store.path + suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _integration() -> void:
	var world = Main.instantiate()
	world.test_mode = true
	root.add_child(world)
	await process_frame
	await physics_frame
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	check(not world.dragon.active, "scene starts before hatch")
	check(InputMap.has_action("ng_breath") and InputMap.action_get_events("ng_breath").size() >= 2, "keyboard and controller actions installed")
	world.interact()
	world.dragon.input_grace = 0.0
	check(world.progress.hatched and world.dragon.active, "actual hatch interaction activates dragon")
	world.dragon.global_position = Vector3(0, 0.1, 4.5)
	world.dragon.aim = Vector3.LEFT
	check(world.dragon.try_ability("breath"), "actual ability begins windup")
	world.dragon.advance_combat(Combat.ABILITIES.breath.windup)
	Combat.tick(world.dragon.state, 2.5)
	check(world.dragon.try_ability("breath"), "second actual breath")
	world.dragon.advance_combat(Combat.ABILITIES.breath.windup)
	check(world.progress.gate_open and not world.gate.visible, "breaths open gate via heat simulation")
	await physics_frame
	check(world.line_clear(Vector3(0, 0, 4.5), Vector3(0, 0, 0)), "gate no longer blocks collision queries")
	world.dragon.global_position = Vector3(0, 0.1, -5)
	world.start_encounter()
	await process_frame
	world.enemy.set_physics_process(false)
	check(is_instance_valid(world.enemy), "arena entry spawns encounter")
	check(world.enemy.take_hit(25) == 0.0, "closed shield blocks actual actor damage")
	world.enemy.brain.open_window(10)
	world.dragon.global_position = world.enemy.global_position + Vector3.BACK * 1.8
	world.dragon.aim = Vector3.FORWARD
	world.dragon.state = Combat.fresh()
	check(world.dragon.try_ability("claw") and world.enemy.hp == 100.0, "claw does not hit before contact")
	world.dragon.advance_combat(Combat.ABILITIES.claw.windup)
	check(world.enemy.hp == 76.0, "spatial claw damages exposed actor on contact")
	world.dragon.global_position = world.enemy.global_position + Vector3.BACK * 4.0
	world.dragon.state = Combat.fresh()
	world.dragon.try_ability("wall")
	world.dragon.advance_combat(Combat.ABILITIES.wall.windup)
	check(world.walls.size() == 1, "flame wall has persistent world state")
	var previous_hp: float = world.enemy.hp
	world._tick_walls(0.1)
	check(world.enemy.hp < previous_hp, "flame wall applies actual periodic damage")
	world.dragon.state.heat = 65.0
	world.set_physics_process(true)
	world.dragon.set_physics_process(true)
	world.hud.set_pause(true)
	var before: Dictionary = world.dragon.state.duplicate(true)
	await create_timer(0.12, true).timeout
	check(world.dragon.state == before, "pause freezes simulation state")
	world.hud.set_pause(false)
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	for level in range(4):
		world.set_quality(level)
		check(world.dragon.state == before, "quality %d cannot change combat state" % level)
	world.set_reduced_motion(true)
	check(world.dragon.state == before and world.camera_rig.reduced_motion, "reduced motion preserves combat")
	world.dragon.state.iframes = 0.0
	world.dragon.receive_damage(999)
	check(world.dragon.state.hp == 0.0, "actual actor death")
	world.retry()
	await process_frame
	check(world.dragon.state.hp == 120.0 and world.progress.gate_open and world.walls.is_empty(), "retry preserves milestones and clears hazards")
	for i in range(3):
		world.interwave_delay = 0.0
		world.dragon.global_position = Vector3(0, 0.1, -5)
		world.start_encounter()
		await process_frame
		world.enemy.set_physics_process(false)
		world.enemy.take_hit(999, true)
		check(world.progress.clears == i + 1, "actual encounter completion %d" % i)
		await process_frame
	world.dragon.global_position = world.CORE
	world.interact()
	check(world.progress.core, "actual core pickup")
	world.dragon.global_position = world.SOCKET
	world.interact()
	check(world.progress.upgraded and world.restored_core.visible, "core visibly upgrades Forge")
	world.interact()
	check(world.progress.clears == 3 and world.progress.upgraded, "repeat interaction cannot duplicate progress")
	world.new_expedition()
	check(world.progress == Progress.fresh() and not world.restored_core.visible, "explicit new expedition resets only prototype")
	world.queue_free()
	await process_frame

func _action_contract() -> void:
	for id in Combat.ORDER:
		var rule: Dictionary = Combat.ABILITIES[id]
		var state = Combat.fresh()
		Combat.cast(state, id)
		check(Combat.tick(state, rule.windup * 0.5) == "" and not state.action_hit, id + " waits for contact")
		check(not Combat.cast(state, "claw"), id + " prevents overlapping actions")
		check(Combat.tick(state, rule.windup * 0.5) == id and state.action_hit, id + " emits one contact")
		check(Combat.tick(state, 0.0) == "", id + " cannot repeat contact on zero delta")
		check(Combat.tick(state, rule.recovery + 0.01) == "" and state.action == "", id + " recovery completes")
		state = Combat.fresh()
		Combat.cast(state, id)
		check(Combat.tick(state, 2.0) == id and Combat.tick(state, 2.0) == "", id + " long frame neither loses nor duplicates contact")
	var state = Combat.fresh()
	Combat.cast(state, "breath")
	Combat.tick(state, -10.0)
	check(state.action_time == 0.0, "negative time cannot advance attack")
	Combat.tick(state, NAN)
	check(state.action_time == 0.0, "nonfinite time cannot poison attack state")
	Combat.tick(state, 0.05, true)
	check(not state.guard, "guard cannot simultaneously protect a committed attack")
	check(Combat.dodge(state) and state.action == "", "dodge cancels windup")
	check(Combat.tick(state, 1.0) == "", "cancelled attack has no ghost contact")
	check(state.cooldowns.breath > 0.0, "dodge cancellation does not refund cooldown")
	state = Combat.fresh()
	Combat.cast(state, "burst")
	Combat.damage(state, 999.0)
	check(Combat.tick(state, 2.0) == "", "death cancels pending contact")
	var brain = Brain.new()
	brain.boss = true
	brain.tick(0.0, 3.0, Vector3.ZERO)
	brain.enraged = true
	check(brain.locked_duration == 1.35, "enrage cannot rescale an already locked tell")

func _preferences() -> void:
	var store = Prefs.new()
	store.path = "user://prefs-test-%d.json" % Time.get_ticks_usec()
	check(store.read_values() == Prefs.defaults(), "missing settings use safe defaults")
	var wanted = {"version": 1, "quality": 3, "reduced_motion": true}
	check(store.write_values(wanted) and store.read_values() == wanted, "graphics and motion roundtrip")
	wanted.quality = 0
	check(store.write_values(wanted) and store.read_values().quality == 0, "settings replace previous file")
	check(not Prefs.valid({"version": 1, "quality": 1.5, "reduced_motion": false}), "fractional quality rejected")
	check(not Prefs.valid({"version": 1, "quality": 99, "reduced_motion": false}), "out of range quality rejected")
	check(not Prefs.valid({"version": 2, "quality": 1, "reduced_motion": false}), "future settings version rejected")
	var file = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("keep-corrupt-preferences")
	file.close()
	store.read_values()
	check(store.blocked and not store.write_values(wanted), "unreadable preferences block overwrite")
	check(FileAccess.get_file_as_string(store.path) == "keep-corrupt-preferences", "unreadable preferences bytes retained")
	for suffix in ["", ".tmp"]:
		if FileAccess.file_exists(store.path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path + suffix))

func _presence() -> void:
	var world = Main.instantiate()
	world.test_mode = true
	root.add_child(world)
	await process_frame
	world.set_physics_process(false)
	world.dragon.set_physics_process(false)
	world.interact()
	var actor = world.dragon
	actor.input_grace = 0.0
	var contacts: Array = []
	actor.ability_used.connect(func(id, at, direction): contacts.append([id, at, direction]))
	actor.aim = Vector3.LEFT
	actor.try_ability("breath")
	actor.aim = Vector3.RIGHT
	actor.advance_combat(0.21)
	check(contacts.is_empty(), "actor does not resolve damage in anticipation")
	actor.advance_combat(0.02)
	check(contacts.size() == 1 and contacts[0][2] == Vector3.LEFT, "contact retains the committed direction")
	actor.advance_combat(1.0)
	check(contacts.size() == 1, "actor emits contact exactly once")
	actor.state = Combat.fresh()
	actor.try_ability("claw")
	actor.advance_combat(0.17)
	check(not actor.try_ability("breath") and actor.buffered_id == "breath", "near-recovery input is buffered without spending heat")
	actor.advance_combat(0.12)
	check(actor.state.action == "breath" and actor.buffered_id == "", "buffer starts exactly one next ability")
	actor.advance_combat(0.36)
	actor.try_ability("wall")
	check(actor.buffered_id == "wall", "recovery can accept a new buffered command")
	world.hud.set_pause(true)
	check(actor.buffered_id == "", "pause discards buffered input")
	world.hud.set_pause(false)
	actor.input_grace = 0.0
	actor.state = Combat.fresh()
	actor.try_ability("burst")
	actor.advance_combat(0.62)
	actor.try_ability("breath")
	actor.advance_combat(0.30)
	check(actor.buffered_id == "" and actor.state.action == "", "expired buffer cannot fire a late attack")
	actor.state = Combat.fresh()
	actor.input_grace = 0.2
	check(not actor.try_ability("claw"), "resume grace blocks HUD and keyboard casts alike")
	var pose_samples: Array = []
	for id in Combat.ORDER:
		var state = Combat.fresh()
		Combat.cast(state, id)
		Combat.tick(state, Combat.ABILITIES[id].windup * 0.8)
		var before = state.duplicate(true)
		actor.rig.animate(0.0, 0.0, false, state)
		pose_samples.append([actor.rig.torso.rotation, actor.rig.right_arm.rotation, actor.rig.jaw.rotation])
		actor.rig.animate(0.0, 0.0, true, state)
		check(state == before, id + " pose sampling never mutates combat")
	check(pose_samples[0] != pose_samples[1] and pose_samples[1] != pose_samples[2] and pose_samples[2] != pose_samples[3], "four abilities have distinct sampled joint poses")
	check(actor.rig.tail_joints.size() == 6, "dragon has a segmented articulated tail")
	world.set_quality(0)
	check(not world.dressing.details.visible, "low quality omits optional ornament")
	world.set_quality(3)
	check(world.dressing.details.visible, "high quality enables batched ornament")
	for i in range(40):
		world.effects.pulse(Vector3.ZERO, 1.0)
	check(world.effects.transients.size() <= world.effects.MAX_TRANSIENTS, "transient visual budget enforced")
	world.set_reduced_motion(true)
	check(world.effects.transients.is_empty(), "reduced motion clears in-flight decorative effects")
	await process_frame
	# Let owned tween lifetimes elapse; errors from freed targets must fail CI.
	await create_timer(0.85).timeout
	world.queue_free()
	await process_frame
