extends SceneTree
## Player-reachable optional recruitment orders must remain writable at every step.
const Rules = preload("res://campaign/progress.gd")
const Fusion = preload("res://campaign/fusion.gd")
const Growth = preload("res://campaign/growth.gd")
const Store = preload("res://campaign/save_store.gd")
const Party = preload("res://campaign/party.gd")
var checks = 0
var failures = 0

func _initialize():
	call_deferred("run")

func check(ok: bool, label: String):
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func eligible() -> Dictionary:
	var c = Rules.fresh()
	Rules.hatch(c)
	c.ice_rescued = true
	c.lattice_recovered = true
	c.stone_imprint_recovered = true
	c.venom_culture_recovered = true
	c.cleared = ["outer-boss", "frozen-boss", "storm-boss"]
	c.cores = ["outer", "frozen", "storm"]
	c.installed = c.cores.duplicate()
	c.visited.append_array(["frozen-vault", "capacitor-cache", "admin-vault"])
	return c

func recruit(c: Dictionary, id: String) -> void:
	if id == "ice":
		check(Rules.hatch_ice(c), "Rime can join when rescued")
		return
	var forged = false
	if id == "storm":
		Growth.select(c, "fire", "flashfire")
		Growth.select(c, "ice", "aegis")
		forged = Fusion.forge(c)
	elif id == "stone": forged = Fusion.forge_stone(c)
	elif id == "venom": forged = Fusion.forge_venom(c)
	elif id == "shadow": forged = Fusion.forge_shadow(c)
	check(forged, "recipe permits " + id + " in this recruitment order")
	check(not Rules.normalize(c).is_empty(), "forged " + id + " remains saveable")
	var hatched = false
	if id == "storm": hatched = Fusion.hatch(c)
	elif id == "stone": hatched = Fusion.hatch_stone(c)
	elif id == "venom": hatched = Fusion.hatch_venom(c)
	elif id == "shadow": hatched = Fusion.hatch_shadow(c)
	check(hatched, "awaken " + id + " in this recruitment order")

func clean_store(store) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(store.path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path + suffix))

func round_trip(c: Dictionary) -> void:
	var store = Store.new()
	store.path = "user://shadow-recruitment-test.json"
	store.import_legacy = false
	clean_store(store)
	check(store.write_campaign(c), "optional roster writes to campaign save " + str(c.guardians))
	check(store.read_campaign() == c and not store.blocked, "optional roster round-trips without losing progress")
	clean_store(store)

func migration(c: Dictionary, version: int) -> void:
	var old = c.duplicate(true)
	old.version = version
	old.erase("shadow_forged")
	if version == 6:
		old.erase("venom_culture_recovered")
		old.erase("venom_forged")
	var before = old.duplicate(true)
	var in_memory = Rules.normalize(old)
	check(old == before and not in_memory.is_empty(), "in-memory migration preserves its source dictionary")
	var store = Store.new()
	store.path = "user://shadow-recruitment-migration-%d.json" % version
	store.import_legacy = false
	clean_store(store)
	var bytes = JSON.stringify(old, "  ") + "\n"
	var f = FileAccess.open(store.path, FileAccess.WRITE)
	f.store_string(bytes)
	f.close()
	var loaded = store.read_campaign()
	check(not store.blocked and loaded.version == 8, "schema %d accepts legitimate optional roster" % version)
	check(loaded == in_memory, "disk and in-memory migration produce identical progress")
	for key in old:
		if key != "version": check(loaded.get(key) == old[key], "schema %d preserves %s" % [version, key])
	check(not loaded.shadow_forged, "migration grants no Shadow resonance")
	check(FileAccess.get_file_as_string(store.path) == bytes, "migration leaves original save bytes unchanged")
	check(store.write_campaign(loaded), "migrated optional roster can be saved")
	check(FileAccess.get_file_as_string(store.path + ".bak") == bytes, "first migration write preserves exact original backup")
	check(store.read_campaign() == loaded, "migrated optional roster round-trips")
	clean_store(store)

func run() -> void:
	var full = {}
	for order in [
		["ice", "venom", "shadow"],
		["stone"],
		["stone", "ice", "venom", "shadow", "storm"],
		["ice", "venom", "shadow", "stone", "storm"],
		["ice", "storm", "venom", "shadow", "stone"],
		["ice", "stone", "storm", "venom", "shadow"],
	]:
		var c = eligible()
		check(not Rules.normalize(c).is_empty(), "three-core Magma-only fixture is a valid campaign")
		for id in order:
			var pair = Fusion.members(c)
			var before = c.duplicate(true)
			recruit(c, id)
			check(not Rules.normalize(c).is_empty(), "earned roster stays saveable after " + str(c.guardians))
			check(Fusion.members(c) == (c.guardians if pair.size() == 1 else pair), "recruitment preserves the selected pair or adds the first reserve")
			check(c.salvage == before.salvage and c.cleared == before.cleared and c.cores == before.cores and c.installed == before.installed, "recruitment retains earned campaign progress")
		var party = Party.new()
		party.rebuild(c)
		check(party.states.size() == 2 and party.states.keys() == Fusion.members(c), "only the selected two guardians receive live combat state")
		round_trip(c)
		if order == ["stone"]: migration(c, 6)
		if order == ["ice", "venom", "shadow"]:
			var no_shadow = c.duplicate(true)
			no_shadow.guardians.erase("shadow")
			migration(no_shadow, 7)
		if c.guardians.size() == 6: full = c

	# Order is presentation only. Neither normalization nor loading silently sorts it.
	var reordered = full.duplicate(true)
	reordered.guardians = ["shadow", "venom", "stone", "storm", "ice", "fire"]
	check(Rules.normalize(reordered).get("guardians") == reordered.guardians, "valid ownership order is retained with Magma anywhere in the set")
	round_trip(reordered)
	for roster in [[], ["fire", "fire"], ["fire", "unknown"], ["fire", 42], ["ice", "venom"], ["fire", "ice", "storm", "stone", "venom", "shadow", "fire"], "fire"]:
		var bad = full.duplicate(true)
		bad.guardians = roster
		check(Rules.normalize(bad).is_empty(), "malformed/duplicate/unknown/Magma-free roster rejected: " + str(roster))
	for flag in ["ice_rescued", "storm_forged", "stone_forged", "venom_forged", "shadow_forged", "lattice_recovered", "stone_imprint_recovered", "venom_culture_recovered"]:
		var bad = full.duplicate(true)
		bad[flag] = false
		check(Rules.normalize(bad).is_empty(), "ownership still requires earned prerequisite " + flag)
	for pair in [[], ["fire"], ["fire", "fire"], ["fire", "unknown"], ["ice", "venom"], ["fire", "ice", "shadow"]]:
		var bad = full.duplicate(true)
		bad.loadout = pair
		check(Rules.normalize(bad).is_empty(), "two-slot active-inclusive loadout remains strict: " + str(pair))
	for version in [2, 3, 4, 5, 6, 7]:
		var bad = eligible()
		bad.version = version
		var future_guardian = "storm" if version <= 3 else ("stone" if version <= 5 else ("venom" if version == 6 else "shadow"))
		bad.guardians = ["fire", future_guardian]
		check(Rules.normalize(bad).is_empty(), "schema %d rejects a later guardian even below its roster size cap" % version)
	print("RECRUITMENT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
