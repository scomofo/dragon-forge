extends SceneTree
## Light is an earned completion reward. Migration must validate before granting it.
const Rules = preload("res://campaign/progress.gd")
const Fusion = preload("res://campaign/fusion.gd")
const Data = preload("res://campaign/data.gd")
const Store = preload("res://campaign/save_store.gd")
var checks = 0
var failures = 0

func _initialize():call_deferred("run")
func check(ok: bool, label: String):
	checks += 1
	if not ok:failures += 1
	print(("PASS " if ok else "FAIL ") + label)

static func before_completion(roster: Array = ["fire"]) -> Dictionary:
	var c = Rules.fresh()
	Rules.hatch(c)
	c.room = "singularity"
	c.visited = Data.ROOMS.keys()
	c.cleared = ["outer-boss", "frozen-boss", "storm-boss", "admin-boss", "singularity-final"]
	c.cores = ["outer", "frozen", "storm", "admin"]
	c.installed = c.cores.duplicate()
	c.guardians = roster.duplicate()
	c.ice_rescued = roster.has("ice")
	c.lattice_recovered = roster.has("storm")
	c.storm_forged = roster.has("storm")
	c.stone_imprint_recovered = roster.has("stone")
	c.stone_forged = roster.has("stone")
	c.venom_culture_recovered = roster.has("venom")
	c.venom_forged = roster.has("venom")
	c.shadow_forged = roster.has("shadow")
	if roster.has("storm"):c.evolutions = {"fire":"flashfire", "ice":"aegis", "storm":"overcharge"}
	if roster.size() > 1:c.active_guardian = roster[-1]
	if roster.size() > 2:c.loadout = [c.active_guardian, "fire"]
	return c

static func completed(roster: Array = ["fire"]) -> Dictionary:
	var c = before_completion(roster)
	Rules.finish(c)
	return c

static func legacy(version: int, full_roster: bool = false) -> Dictionary:
	var roster = ["fire"]
	if full_roster:
		roster = ["fire", "ice", "storm"]
		if version >= 6:roster.append("stone")
		if version >= 7:roster.append("venom")
		if version >= 8:roster.append("shadow")
	var c = before_completion(roster)
	c.version = version
	c.finished = true
	c.salvage = 327
	c.module = "coolant"
	c.upgrades = {"plating":2, "power":1, "cooling":3}
	c.journals = ["forge", "singularity"]
	c.caches = ["admin-vault"]
	c.relays = ["admin-relay-a"]
	if full_roster and version >= 9:
		c.guardians.append("void")
		c.void_imprint_recovered = true
		c.void_forged = true
		c.active_guardian = "void"
		c.loadout = ["void", "shadow"]
	if version < 9:
		c.erase("void_imprint_recovered");c.erase("void_forged")
	if version < 8:c.erase("shadow_forged")
	if version < 7:
		c.erase("venom_culture_recovered");c.erase("venom_forged")
	if version < 6:
		c.erase("stone_imprint_recovered");c.erase("stone_forged")
	if version < 5:c.evolutions.erase("storm")
	if version < 4:
		c.erase("lattice_recovered");c.erase("storm_forged");c.erase("loadout")
	if version < 3:c.erase("evolutions")
	if version < 2:
		c.erase("guardians");c.erase("active_guardian");c.erase("ice_rescued")
	return c

func clean(path: String):
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func completion_checks():
	var fresh = Rules.fresh()
	check(fresh.version == 10 and Rules.GUARDIAN_IDS.size() == 8, "fresh schema 10 supports eight guardian identities")
	check(not fresh.guardians.has("light") and not fresh.has("light_forged") and not fresh.has("light_imprint_recovered"), "Light adds no saved recipe or imprint flags")
	check(not Rules.normalize(fresh).is_empty(), "new uncompleted campaign remains valid")
	for roster in [["fire"], ["fire", "ice"], ["fire", "stone"], ["fire", "ice", "venom", "shadow"], ["fire", "stone", "ice", "venom", "shadow", "storm"]]:
		var c = before_completion(roster)
		check(not Rules.normalize(c).is_empty(), "valid final-clear checkpoint before stabilization " + str(roster))
		var before = c.duplicate(true)
		var pair = Fusion.members(c)
		check(Rules.finish(c), "stabilization grants Light directly " + str(roster))
		check(c.finished and c.guardians == roster + ["light"], "completion adds exactly the earned Light guardian")
		check(Fusion.members(c) == (pair if pair.size() == 2 else ["fire", "light"]) and c.active_guardian == before.active_guardian, "reward retains active guardian and existing expedition pair")
		if not before.loadout.is_empty():check(c.loadout == before.loadout, "explicit selected loadout is unchanged")
		check(c.keys() == before.keys(), "completion introduces no persisted fields")
		for key in ["salvage", "evolutions", "cleared", "cores", "installed", "upgrades", "module"]:
			check(c[key] == before[key], "Light reward retains " + key)
		check(not Rules.normalize(c).is_empty(), "completed Light roster is saveable")
		var awarded = c.duplicate(true)
		check(not Rules.finish(c) and c == awarded, "repeated stabilization cannot duplicate Light or other rewards")
		c.room = "forge"
		if pair.size() == 2:check(Fusion.equip_reserve(c, "light"), "earned Light can be explicitly selected at Nursery")
		check(Fusion.members(c).has("light") and Fusion.members(c).size() == 2, "Light fits the two-slot expedition")
		check(not Rules.normalize(c).is_empty(), "Light selection remains valid")
	var sparse = completed()
	sparse.room = "forge"
	sparse.ice_rescued = true
	check(Rules.hatch_ice(sparse) and Fusion.members(sparse) == ["fire", "light"], "Rime can join after Light without displacing the earned first reserve")
	sparse.stone_imprint_recovered = true
	check(Fusion.forge_stone(sparse) and Fusion.hatch_stone(sparse), "Cairn can be recruited after completion Light")
	check(not Rules.normalize(sparse).is_empty() and Fusion.members(sparse) == ["fire", "light"], "later optional recruitment preserves a valid Light pair")
	for missing in ["final_clear", "fourth_core", "correct_room"]:
		var c = before_completion()
		if missing == "final_clear":c.cleared.erase("singularity-final")
		elif missing == "fourth_core":c.installed.erase("admin")
		else:c.room = "forge"
		var before = c.duplicate(true)
		check(not Rules.finish(c) and c == before, "Light is not awarded without " + missing)

func migration_checks():
	for version in range(1, 10):
		var old = legacy(version)
		var before = old.duplicate(true)
		var loaded = Rules.normalize(old)
		check(not loaded.is_empty() and loaded.version == 10 and loaded.guardians == ["fire", "light"], "finished schema %d gains earned Light without optional predecessors" % version)
		check(old == before, "schema %d normalization leaves original dictionary unchanged" % version)
		var unfinished = old.duplicate(true)
		unfinished.finished = false
		check(not Rules.normalize(unfinished).get("guardians", []).has("light"), "unfinished schema %d gains no Light" % version)
	for version in [9, 8, 5]:
		var old = legacy(version, true)
		var before = old.duplicate(true)
		var loaded = Rules.normalize(old)
		check(not loaded.is_empty() and loaded.version == 10, "full schema %d campaign migrates" % version)
		if loaded.is_empty():continue
		check(loaded.guardians == old.guardians + ["light"], "schema %d adds exactly the earned completion reward" % version)
		for key in old:
			if key not in ["version", "guardians"]:check(loaded[key] == old[key], "schema %d preserves %s" % [version, key])
		check(old == before and Rules.normalize(loaded) == loaded, "migration is non-mutating and idempotent")
		var store = Store.new()
		store.path = "user://light-migration-%d.json" % version
		store.import_legacy = false
		clean(store.path)
		var bytes = " \n" + JSON.stringify(old, "  ") + "\n"
		var f = FileAccess.open(store.path, FileAccess.WRITE)
		f.store_string(bytes);f.close()
		check(store.read_campaign() == loaded and not store.blocked, "schema %d disk load grants the same earned Light" % version)
		check(FileAccess.get_file_as_string(store.path) == bytes and not FileAccess.file_exists(store.path + ".bak"), "load preserves exact original bytes and creates no backup")
		check(store.write_campaign(loaded), "first schema 10 write succeeds")
		check(FileAccess.get_file_as_string(store.path + ".bak") == bytes, "first write backs up exact legacy bytes")
		check(store.read_campaign() == loaded, "Light and all prior progress survive save/reload")
		clean(store.path)
	var implicit_pair = legacy(9)
	implicit_pair.guardians = ["fire", "stone"]
	implicit_pair.stone_forged = true
	implicit_pair.stone_imprint_recovered = true
	implicit_pair.active_guardian = "stone"
	var loaded = Rules.normalize(implicit_pair)
	check(loaded.get("loadout") == ["fire", "stone"] and loaded.active_guardian == "stone", "migration materializes an existing implicit pair before a third guardian joins")
	check(implicit_pair.loadout.is_empty() and not Rules.normalize(loaded).is_empty(), "implicit-pair migration preserves source and produces valid current state")

func rejection_checks():
	var old = legacy(9, true)
	var invalid = []
	for roster in [["fire", "light"], ["fire", "void", "void"], ["fire", "unknown"], ["void"], ["fire", 42]]:
		var bad = old.duplicate(true)
		bad.guardians = roster
		invalid.append(bad)
	for pair in [[], ["void"], ["void", "void"], ["void", "light"], ["void", "shadow", "fire"], "void"]:
		var bad = old.duplicate(true)
		bad.loadout = pair
		invalid.append(bad)
	var future_active = legacy(9)
	future_active.active_guardian = "light"
	invalid.append(future_active)
	for field in ["void_imprint_recovered", "void_forged", "shadow_forged", "venom_forged", "finished"]:
		var bad = old.duplicate(true)
		bad[field] = false
		invalid.append(bad)
	var missing = old.duplicate(true)
	missing.erase("upgrades")
	invalid.append(missing)
	var unearned_end = old.duplicate(true)
	unearned_end.cleared.erase("singularity-final")
	invalid.append(unearned_end)
	for index in range(invalid.size()):
		var bad: Dictionary = invalid[index]
		var before = bad.duplicate(true)
		check(Rules.normalize(bad).is_empty() and bad == before, "malformed schema 9 is rejected before Light can repair it / %d" % index)
		var store = Store.new()
		store.path = "user://light-malformed-migration.json"
		store.import_legacy = false
		clean(store.path)
		var bytes = JSON.stringify(bad)
		var f = FileAccess.open(store.path, FileAccess.WRITE)
		f.store_string(bytes);f.close()
		store.read_campaign()
		check(store.blocked and not store.write_campaign(Rules.fresh()) and FileAccess.get_file_as_string(store.path) == bytes, "malformed source stays write-blocked with exact bytes / %d" % index)
		clean(store.path)
	var unearned = before_completion()
	unearned.guardians.append("light")
	check(Rules.normalize(unearned).is_empty(), "current schema cannot own Light before completion")
	var missing_reward = before_completion()
	missing_reward.finished = true
	check(Rules.normalize(missing_reward).is_empty(), "current schema requires completed campaigns to own earned Light")
	var future = Rules.fresh()
	future.version = 11
	check(Rules.normalize(future).is_empty(), "future schema is not interpreted as an earned completion")
	for version in range(2, 10):
		var bad = legacy(version)
		bad.guardians = ["fire", "light"]
		bad.loadout = ["fire", "light"]
		check(Rules.normalize(bad).is_empty(), "schema %d cannot smuggle future Light ownership" % version)
	var bad_pair = completed()
	bad_pair.loadout = ["fire", "light", "ice"]
	check(Rules.normalize(bad_pair).is_empty(), "Light does not expand the two-slot expedition limit")

func run():
	completion_checks()
	migration_checks()
	rejection_checks()
	print("LIGHT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
