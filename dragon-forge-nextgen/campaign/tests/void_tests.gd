extends SceneTree
const Rules = preload("res://campaign/progress.gd")
const Fusion = preload("res://campaign/fusion.gd")
const Combat = preload("res://campaign/guardian_combat.gd")
const Store = preload("res://campaign/save_store.gd")
const Data = preload("res://campaign/data.gd")
var checks = 0
var failures = 0
func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ") + label)

static func completed(optional_guardians: bool = false) -> Dictionary:
	var c = Rules.fresh()
	Rules.hatch(c)
	c.cleared = ["outer-boss","frozen-boss","storm-boss","admin-boss","singularity-final"]
	c.cores = ["outer","frozen","storm","admin"]
	c.installed = c.cores.duplicate()
	c.visited = Data.ROOMS.keys()
	c.finished = true
	c.room = "singularity"
	if optional_guardians:
		c.guardians = ["fire","ice","storm","stone","venom","shadow"]
		c.ice_rescued = true
		c.lattice_recovered = true
		c.storm_forged = true
		c.stone_imprint_recovered = true
		c.stone_forged = true
		c.venom_culture_recovered = true
		c.venom_forged = true
		c.shadow_forged = true
		c.evolutions = {"fire":"flashfire","ice":"aegis","storm":"overcharge"}
		c.loadout = ["fire","shadow"]
	return c

func migration():
	var old = completed(true)
	old.version = 8
	old.erase("void_imprint_recovered")
	old.erase("void_forged")
	old.salvage = 327
	old.upgrades = {"plating":2,"power":1,"cooling":3}
	old.module = "coolant"
	old.journals = ["forge","singularity"]
	old.caches = ["admin-vault"]
	old.relays = ["admin-relay-a"]
	var migrated = Rules.normalize(old)
	check(not migrated.is_empty() and migrated.get("version") == 9, "valid schema 8 reaches schema 9")
	if migrated.is_empty():return
	check(not migrated.void_imprint_recovered and not migrated.void_forged and not migrated.guardians.has("void"), "migration grants no Void progress or guardian")
	for key in old:
		if key != "version":check(migrated[key] == old[key], "schema 8 migration preserves " + key)
	check(old.version == 8 and not old.has("void_forged"), "normalization leaves caller's schema 8 state unchanged")
	var store = Store.new()
	store.import_legacy = false
	store.path = "user://void-test-schema8.json"
	clean_store(store.path)
	var bytes = " \n" + JSON.stringify(old, "  ") + "\n"
	var file = FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string(bytes)
	file.close()
	var loaded = store.read_campaign()
	check(not store.blocked and loaded.version == 9, "schema 8 disk load migrates in memory")
	check(FileAccess.get_file_as_string(store.path) == bytes and not FileAccess.file_exists(store.path + ".bak"), "loading never writes or rotates original save bytes")
	check(store.write_campaign(loaded), "first explicit schema 9 save succeeds")
	check(FileAccess.get_file_as_string(store.path + ".bak") == bytes, "first migration backup preserves exact schema 8 bytes")
	check(store.read_campaign() == loaded, "schema 9 persisted state round-trips")
	clean_store(store.path)
	var malformed = old.duplicate(true)
	malformed.guardians.append("void")
	file = FileAccess.open(store.path, FileAccess.WRITE)
	var malformed_bytes = JSON.stringify(malformed)
	file.store_string(malformed_bytes)
	file.close()
	store.read_campaign()
	check(store.blocked and not store.write_campaign(Rules.fresh()), "invalid old ownership blocks subsequent overwrite")
	check(FileAccess.get_file_as_string(store.path) == malformed_bytes, "invalid old ownership preserves original bytes")
	clean_store(store.path)
	for version in range(2,9):
		var bad = Rules.fresh()
		bad.version = version
		bad.guardians = ["fire","void"]
		bad.loadout = ["fire","void"]
		if version <= 4:bad.evolutions = {"fire":"","ice":""}
		check(Rules.normalize(bad).is_empty(), "legacy schema %d cannot smuggle future Void ownership" % version)
	var future = Rules.fresh()
	future.version = 10
	check(Rules.normalize(future).is_empty(), "future schema remains rejected")

func clean_store(path: String):
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func recruitment():
	check(Fusion.VOID_IMPRINT == Vector3(-5,0,-4), "Void imprint has authored Singularity position")
	for optional_guardians in [false, true]:
		var c = completed(optional_guardians)
		check(not Rules.normalize(c).is_empty(), "completed fixture valid, optional guardians " + str(optional_guardians))
		var before_finish = c.duplicate(true)
		before_finish.finished = false
		check(not Fusion.recover_void(before_finish), "final enemy clear alone cannot recover unstabilized imprint")
		var wrong_room = c.duplicate(true)
		wrong_room.room = "forge"
		check(not Fusion.recover_void(wrong_room), "imprint cannot be recovered outside Singularity")
		check(not Fusion.forge_void(wrong_room) and not Fusion.hatch_void(wrong_room), "Forge requires recovered imprint")
		check(Fusion.recover_void(c) and not Fusion.recover_void(c), "completed Singularity yields imprint exactly once")
		check(Fusion.void_reason(c) == "", "Void needs completed imprint without an invented guardian pair")
		check(not Fusion.forge_void(c) and not Fusion.hatch_void(c), "Void forging and hatching require Forge room")
		c.room = "forge"
		var guardians: Array = c.guardians.duplicate()
		var pair = Fusion.members(c)
		check(not Fusion.hatch_void(c), "Void cannot hatch before forging")
		check(Fusion.forge_void(c) and not Fusion.forge_void(c), "Void imprint forging is one-time")
		check(Fusion.hatch_void(c) and not Fusion.hatch_void(c), "Null recruitment is one-time")
		check(c.guardians == guardians + ["void"], "Void recruitment preserves every prior guardian")
		var expected_pair: Array = pair if pair.size() == 2 else ["fire","void"]
		check(Fusion.members(c) == expected_pair and c.active_guardian == "fire", "Void recruitment preserves expedition members and fills a lone empty reserve")
		check(not Rules.normalize(c).is_empty(), "new earned Void roster persists")
		if optional_guardians:check(Fusion.equip_reserve(c, "void"), "Null can replace selected reserve at Forge")
		check(Fusion.members(c) == ["fire","void"], "Null fits two-slot expedition")
		if not optional_guardians:
			check(not c.ice_rescued and not c.storm_forged and not c.stone_forged and not c.venom_forged and not c.shadow_forged, "Void unlock does not grant or require skipped optional guardians")
			c.ice_rescued = true
			check(Rules.hatch_ice(c), "Rime can be recruited after Null")
			check(c.guardians == ["fire","void","ice"] and not Rules.normalize(c).is_empty(), "earned roster accepts later recruitment without exact ordering")
		else:
			c.guardians = ["fire","void","shadow","venom","stone","storm","ice"]
			check(not Rules.normalize(c).is_empty(), "all seven earned guardians normalize as a unique set")
		for roster in [["fire","void","void"], ["fire","unknown"], ["void"]]:
			var bad = c.duplicate(true)
			bad.guardians = roster
			check(Rules.normalize(bad).is_empty(), "malformed guardian ownership rejected " + str(roster))
		for flag in ["void_imprint_recovered", "void_forged", "finished"]:
			var bad = c.duplicate(true)
			bad[flag] = false
			check(Rules.normalize(bad).is_empty(), "Void ownership requires earned " + flag)
		var unvisited = c.duplicate(true)
		unvisited.visited.erase("singularity")
		check(Rules.normalize(unvisited).is_empty(), "Void imprint requires visited Singularity")
		var too_many = c.duplicate(true)
		too_many.loadout = ["fire","void","ice"]
		check(Rules.normalize(too_many).is_empty(), "three-slot expedition rejected")

func combat():
	var s = Combat.fresh("", "void")
	check(Combat.guardian_name("void") == "NULL", "Void guardian identity is Null")
	var names = {"claw":"Rift Shard","breath":"Void Rift","wall":"Null Reflect","burst":"Siphon Rift"}
	var damage = {"claw":24.0,"breath":32.0,"wall":0.0,"burst":44.0}
	var durations = {"claw":.29,"breath":.56,"wall":.42,"burst":.64}
	for id in Combat.ORDER:
		var move = Combat.rule(s, id)
		check(move.name == names[id] and move.damage == damage[id], "Void move name and base damage " + id)
		check(is_equal_approx(move.windup + move.recovery, durations[id]), "Void authored action duration " + id)
		var state = Combat.fresh("", "void")
		check(Combat.cast(state, id) and Combat.tick(state, move.windup - .001) == "", "Void cast awaits contact " + id)
		check(Combat.tick(state, .002) == id and Combat.tick(state, move.recovery) == "", "Void emits one contact " + id)
		check(not move.has("ignore_shield"), "Void move has no shield bypass " + id)
	check(is_equal_approx(Combat.null_reflect_duration(), 1.2), "Null Reflect duration is 1.2 seconds")
	s.null_reflect = 1.2
	var hp: float = s.hp
	check(Combat.damage(s, 20.0) == 10.0 and s.hp == hp - 10.0, "Null Reflect halves landed incoming damage")
	check(Combat.damage(s, 20.0) == 0.0, "post-hit protection prevents duplicate incoming damage")
	Combat.tick(s, 1.21)
	check(Combat.damage(s, 20.0) == 20.0, "Reflect expiration restores ordinary incoming damage")
	var other = Combat.fresh("", "fire")
	other.null_reflect = 1.2
	check(Combat.damage(other, 20.0) == 20.0, "Reflect status cannot protect a different guardian")
	check(Combat.reflected_damage(8.0) == 8.0 and Combat.reflected_damage(80.0) == 20.0, "reflection helper uses actual damage capped at 20")
	for amount in [0.0, -1.0, NAN, INF]:check(Combat.reflected_damage(amount) == 0.0, "invalid reflected damage rejected " + str(amount))
	check(Combat.void_displacement("claw") == 0.0 and Combat.void_displacement("wall") == 0.0, "only Rift attacks displace")
	check(Combat.void_displacement("breath") == 1.25 and Combat.void_displacement("burst") == -1.5, "Void Rift pushes 1.25 and Siphon pulls 1.5")

func run():
	var fresh = Rules.fresh()
	check(fresh.version == 9 and not fresh.void_imprint_recovered and not fresh.void_forged, "fresh schema 9 has unearned Void flags")
	migration()
	recruitment()
	combat()
	print("VOID_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
