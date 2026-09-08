extends SceneTree
## Synthesis is earned Light + Void resonance; migration never creates its reward.
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

static func ready(roster: Array = ["fire", "light", "void"]) -> Dictionary:
	var c = Rules.fresh()
	Rules.hatch(c)
	c.finished = true
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
	c.void_imprint_recovered = roster.has("void")
	c.void_forged = roster.has("void")
	if roster.has("storm"):c.evolutions = {"fire":"flashfire", "ice":"aegis", "storm":"overcharge"}
	if roster.size() > 1:c.active_guardian = roster[-1]
	if roster.size() > 2:c.loadout = [c.active_guardian, "fire"]
	c.salvage = 327
	c.module = "coolant"
	c.upgrades = {"plating":2, "power":1, "cooling":3}
	c.journals = ["forge", "singularity"]
	c.caches = ["admin-vault"]
	c.relays = ["admin-relay-a"]
	return c

static func legacy(version: int, full_roster: bool = false) -> Dictionary:
	var roster = ["fire"]
	if full_roster:
		if version >= 2:roster.append("ice")
		if version >= 4:roster.append("storm")
		if version >= 6:roster.append("stone")
		if version >= 7:roster.append("venom")
		if version >= 8:roster.append("shadow")
		if version >= 9:roster.append("void")
	if version >= 10:roster.append("light")
	var c = ready(roster)
	c.version = version
	c.erase("synthesis_forged")
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

func write_bytes(path: String, bytes: String):
	var f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string(bytes);f.close()

func progression_checks():
	var fresh = Rules.fresh()
	check(fresh.version == 11 and Rules.GUARDIAN_IDS.size() == 9, "fresh schema 11 supports nine guardian identities")
	check(fresh.synthesis_forged == false and not fresh.guardians.has("synthesis"), "new campaign has no Synthesis reward")
	check(not Rules.normalize(fresh).is_empty(), "fresh schema 11 is valid")
	var untouched = fresh.duplicate(true)
	check(Fusion.synthesis_reason(fresh) != "" and not Fusion.forge_synthesis(fresh) and not Fusion.hatch_synthesis(fresh) and fresh == untouched, "fresh campaign cannot forge or hatch Prism")
	for roster in [["fire", "light", "void"], ["void", "fire", "light"], ["fire", "stone", "light", "void"], ["fire", "ice", "venom", "shadow", "light", "void", "stone", "storm"]]:
		for selected in [["light", "void"], ["void", "light"], ["fire", "light"], ["void", "fire"]]:
			var c = ready(roster)
			c.loadout = selected.duplicate()
			c.active_guardian = selected[0]
			check(not Rules.normalize(c).is_empty(), "optional recruitment order and selected pair are valid: %s / %s" % [roster, selected])
			check(Fusion.synthesis_reason(c) == "", "owned parents enable resonance independently of selected pair")
			var before = c.duplicate(true)
			check(not Fusion.hatch_synthesis(c) and c == before, "Prism cannot hatch before resonance is forged")
			check(Fusion.forge_synthesis(c) and c.synthesis_forged, "Light plus Void creates Synthesis resonance")
			var forged = before.duplicate(true)
			forged.synthesis_forged = true
			check(c == forged, "forging changes only the earned Synthesis flag")
			check(not Rules.normalize(c).is_empty(), "forged resonance is saveable before hatching")
			check(not Fusion.forge_synthesis(c) and c == forged, "repeated forge cannot duplicate or spend progress")
			check(Fusion.hatch_synthesis(c), "forged resonance awakens Prism")
			check(c.guardians == roster + ["synthesis"], "hatching retains both parents and the original owned order")
			check(c.loadout == selected and Fusion.members(c) == selected and c.active_guardian == before.active_guardian, "recruitment retains the exact two-slot pair and active guardian")
			var expected = forged.duplicate(true)
			expected.guardians.append("synthesis")
			check(c == expected, "hatching spends no salvage, evolutions, modules, cores or upgrades")
			check(not Fusion.hatch_synthesis(c) and not Fusion.forge_synthesis(c) and c == expected, "repeated hatch and forge are idempotent")
			check(not Rules.normalize(c).is_empty(), "recruited Synthesis is a valid current save")
			check(Fusion.equip_reserve(c, "synthesis") and Fusion.members(c) == [before.active_guardian, "synthesis"], "Prism enters the expedition only after explicit reserve selection")
			check(not Rules.normalize(c).is_empty(), "Synthesis reserve keeps a valid two-slot loadout")
	for field in ["hatched", "finished", "light", "void", "void_forged", "void_imprint_recovered"]:
		var c = ready()
		if field in ["light", "void"]:c.guardians.erase(field)
		else:c[field] = false
		var before = c.duplicate(true)
		check(Fusion.synthesis_reason(c) != "" and not Fusion.forge_synthesis(c) and c == before, "resonance requires earned dependency " + field)
		c.synthesis_forged = true
		before = c.duplicate(true)
		check(not Fusion.hatch_synthesis(c) and c == before, "hatch rechecks earned dependency " + field)
	var away = ready()
	away.room = "singularity"
	var before = away.duplicate(true)
	check(not Fusion.forge_synthesis(away) and away == before, "resonance can only be forged at the Forge")
	away.synthesis_forged = true
	before = away.duplicate(true)
	check(not Fusion.hatch_synthesis(away) and away == before, "Prism can only hatch at the Forge")
	var late = ready()
	Fusion.forge_synthesis(late);Fusion.hatch_synthesis(late)
	late.ice_rescued = true
	var pair = Fusion.members(late)
	check(Rules.hatch_ice(late) and Fusion.members(late) == pair and not Rules.normalize(late).is_empty(), "Rime can join after Prism without a new mandatory recruitment order")

func migration_checks():
	for version in range(1, 11):
		var old = legacy(version)
		var before = old.duplicate(true)
		var migrated = Rules.normalize(old)
		check(not migrated.is_empty() and migrated.version == 11 and not migrated.synthesis_forged, "finished schema %d migrates without forging Synthesis" % version)
		check(migrated.get("guardians") == ["fire", "light"] and not migrated.guardians.has("synthesis"), "schema %d retains Light completion reward without Synthesis auto-grant" % version)
		check(old == before and Rules.normalize(migrated) == migrated, "schema %d migration is non-mutating and idempotent" % version)
		var unfinished = old.duplicate(true)
		unfinished.finished = false
		if version == 10:
			unfinished.guardians = ["fire"]
			unfinished.active_guardian = "fire"
		var unfinished_loaded = Rules.normalize(unfinished)
		check(not unfinished_loaded.is_empty() and unfinished_loaded.guardians == ["fire"] and not unfinished_loaded.synthesis_forged, "unfinished schema %d grants neither Light nor Synthesis" % version)
	for version in [10, 9, 8, 5]:
		var old = legacy(version, true)
		var before = old.duplicate(true)
		var migrated = Rules.normalize(old)
		check(not migrated.is_empty(), "full schema %d campaign migrates" % version)
		if migrated.is_empty():continue
		check(migrated.guardians == old.guardians + (["light"] if version < 10 else []), "schema %d migration only grants the historical Light reward" % version)
		for key in old:
			if key not in ["version", "guardians"]:check(migrated[key] == old[key], "schema %d preserves %s" % [version, key])
		check(old == before and not migrated.synthesis_forged and not migrated.guardians.has("synthesis"), "eligible migration never forges or owns Synthesis")
		var store = Store.new()
		store.path = "user://synthesis-migration-%d.json" % version
		store.import_legacy = false
		clean(store.path)
		var bytes = " \n" + JSON.stringify(old, "  ") + "\n"
		write_bytes(store.path, bytes)
		check(store.read_campaign() == migrated and not store.blocked, "schema %d disk load migrates in memory" % version)
		check(FileAccess.get_file_as_string(store.path) == bytes and not FileAccess.file_exists(store.path + ".bak"), "reading preserves exact source bytes without creating backup")
		check(store.write_campaign(migrated), "first schema 11 write succeeds")
		check(FileAccess.get_file_as_string(store.path + ".bak") == bytes, "first schema 11 write backs up exact source bytes")
		check(store.read_campaign() == migrated, "all migrated progress survives disk reload")
		clean(store.path)
	var implicit = legacy(9)
	implicit.guardians = ["fire", "void"]
	implicit.void_imprint_recovered = true
	implicit.void_forged = true
	implicit.active_guardian = "void"
	var migrated = Rules.normalize(implicit)
	check(migrated.get("loadout") == ["fire", "void"] and migrated.active_guardian == "void" and migrated.guardians == ["fire", "void", "light"], "older implicit pair is preserved before Light retrogrant")
	check(implicit.loadout.is_empty() and not migrated.synthesis_forged and not Rules.normalize(migrated).is_empty(), "older two-parent result remains valid without Synthesis auto-grant")
	var raw_store = Store.new()
	raw_store.path = "user://synthesis-raw-v10-write.json"
	raw_store.import_legacy = false
	clean(raw_store.path)
	var raw_v10 = legacy(10,true)
	var raw_before = raw_v10.duplicate(true)
	check(raw_store.write_campaign(raw_v10), "direct valid schema-10 write succeeds through normalization")
	var raw_disk = JSON.parse_string(FileAccess.get_file_as_string(raw_store.path))
	check(raw_disk is Dictionary and raw_disk.version == Rules.SAVE_VERSION and raw_disk.get("synthesis_forged") == false, "direct legacy write commits current schema 11 bytes")
	check(raw_v10 == raw_before and raw_store.read_campaign() == Rules.normalize(raw_v10), "legacy write does not mutate its caller and round-trips normalized progress")
	clean(raw_store.path)
	var store = Store.new()
	store.path = "user://synthesis-earned-roundtrip.json"
	store.import_legacy = false
	clean(store.path)
	var c = ready()
	Fusion.forge_synthesis(c)
	check(store.write_campaign(c) and store.read_campaign() == c, "forged but unhatched Synthesis survives save/reload")
	c = store.read_campaign()
	check(Fusion.hatch_synthesis(c), "persisted resonance can hatch after reload")
	Fusion.equip_reserve(c, "synthesis")
	check(store.write_campaign(c) and store.read_campaign() == c, "owned Prism and selected pair survive save/reload")
	clean(store.path)

func rejection_checks():
	var owned = ready()
	Fusion.forge_synthesis(owned);Fusion.hatch_synthesis(owned)
	var invalid = []
	for value in [null, 0, 1, "false", [], {}]:
		var bad = owned.duplicate(true)
		bad.synthesis_forged = value
		invalid.append(bad)
	var missing = owned.duplicate(true)
	missing.erase("synthesis_forged")
	invalid.append(missing)
	for field in ["synthesis_forged", "finished", "hatched", "void_forged", "void_imprint_recovered"]:
		var bad = owned.duplicate(true)
		bad[field] = false
		invalid.append(bad)
	for parent in ["light", "void"]:
		var bad = owned.duplicate(true)
		bad.guardians.erase(parent)
		bad.loadout = ["fire", "synthesis"]
		bad.active_guardian = "fire"
		invalid.append(bad)
	for roster in [["fire", "light", "void", "synthesis", "synthesis"], ["fire", "light", "void", "unknown"], ["light", "void", "synthesis"], ["fire", "light", "void", 42]]:
		var bad = owned.duplicate(true)
		bad.guardians = roster
		invalid.append(bad)
	for pair in [[], ["synthesis"], ["synthesis", "synthesis"], ["synthesis", "ice"], ["fire", "void", "synthesis"], "synthesis"]:
		var bad = owned.duplicate(true)
		bad.loadout = pair
		invalid.append(bad)
	var inactive = owned.duplicate(true)
	inactive.active_guardian = "synthesis"
	invalid.append(inactive)
	for version in [10, 11]:
		var missing_light = ready(["fire", "void"])
		missing_light.version = version
		if version == 10:missing_light.erase("synthesis_forged")
		invalid.append(missing_light)
	for version in range(1, 11):
		var bad = legacy(version)
		bad.guardians = ["fire", "synthesis"]
		invalid.append(bad)
	for value in [false, true, null, "false"]:
		var bad = legacy(10, true)
		bad.synthesis_forged = value
		invalid.append(bad)
	for injected in [{"guardians":["fire"]}, {"guardians":[]}, {"guardians":["ice"]}, {"guardians":"fire"}, {"active_guardian":"fire"}, {"ice_rescued":false}]:
		var bad = legacy(1)
		for key in injected:bad[key] = injected[key]
		invalid.append(bad)
	for version in [9, 10]:
		for pair in [[], ["void"], ["void", "void"], ["void", "synthesis"], ["void", "light", "fire"], "void"]:
			var bad = legacy(version, true)
			bad.loadout = pair
			invalid.append(bad)
		for field in ["void_forged", "void_imprint_recovered", "finished"]:
			var bad = legacy(version, true)
			bad[field] = false
			invalid.append(bad)
	var future = owned.duplicate(true)
	future.version = 12
	invalid.append(future)
	var unfinished = ready(["fire", "light"])
	unfinished.finished = false
	invalid.append(unfinished)
	var invalid_final = legacy(10, true)
	invalid_final.cleared.erase("singularity-final")
	invalid.append(invalid_final)
	for index in range(invalid.size()):
		var bad: Dictionary = invalid[index]
		var before = bad.duplicate(true)
		check(Rules.normalize(bad).is_empty() and bad == before, "invalid ownership, dependency, pair or migration is rejected without repair / %d" % index)
		var store = Store.new()
		store.path = "user://synthesis-malformed.json"
		store.import_legacy = false
		clean(store.path)
		var bytes = " \n" + JSON.stringify(bad, " ") + "\n"
		write_bytes(store.path, bytes)
		store.read_campaign()
		check(store.blocked and not store.write_campaign(Rules.fresh()) and FileAccess.get_file_as_string(store.path) == bytes and not FileAccess.file_exists(store.path + ".bak"), "invalid source stays write-blocked with original bytes / %d" % index)
		clean(store.path)

func run():
	progression_checks()
	migration_checks()
	rejection_checks()
	print("SYNTHESIS_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
