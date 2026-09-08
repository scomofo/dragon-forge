extends SceneTree
const Synthesis = preload("res://campaign/synthesis_rules.gd")
const Fusion = preload("res://campaign/fusion.gd")
const Rules = preload("res://campaign/progress.gd")
const Data = preload("res://campaign/data.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func eligible() -> Dictionary:
	var c = Rules.fresh()
	c.merge({
		"version": 11,
		"hatched": true,
		"finished": true,
		"room": "forge",
		"guardians": ["fire", "ice", "storm", "stone", "venom", "shadow", "void", "light"],
		"active_guardian": "shadow",
		"loadout": ["shadow", "light"],
		"ice_rescued": true,
		"lattice_recovered": true,
		"storm_forged": true,
		"stone_imprint_recovered": true,
		"stone_forged": true,
		"venom_culture_recovered": true,
		"venom_forged": true,
		"shadow_forged": true,
		"void_imprint_recovered": true,
		"void_forged": true,
		"synthesis_forged": false,
		"salvage": 321,
		"visited": Data.ROOMS.keys(),
		"cleared": ["outer-boss", "frozen-boss", "storm-boss", "admin-boss", "singularity-final"],
		"cores": ["outer", "frozen", "storm", "admin"],
		"installed": ["outer", "frozen", "storm", "admin"],
		"evolutions": {"fire":"flashfire", "ice":"aegis", "storm":"overcharge"}
	}, true)
	return c

func run() -> void:
	var c = eligible()
	check(Synthesis.REQUIRED_PARENTS == ["void", "light"], "canonical Light + Void parent set")
	check(not Rules.normalize(c).is_empty(), "contract fixture is legitimate earned campaign progress")
	check(Synthesis.reason(c) == "", "eligible completed roster can synthesize")
	var before = c.duplicate(true)
	check(Synthesis.can_forge(c) and not Synthesis.can_hatch(c) and c == before, "eligibility probes leave caller progress unchanged")
	var pair = c.loadout.duplicate()
	var guardians = c.guardians.duplicate()
	var salvage = c.salvage
	var evolutions = c.evolutions.duplicate(true)
	check(Synthesis.forge(c), "forge Synthesis once")
	check(not Synthesis.forge(c), "forge is idempotent")
	check(c.guardians == guardians, "forging preserves parents and roster")
	check(c.loadout == pair, "forging preserves expedition pair")
	check(c.salvage == salvage and c.evolutions == evolutions, "forging costs no progress")
	before = c.duplicate(true)
	check(not Synthesis.can_forge(c) and Synthesis.can_hatch(c) and c == before, "forged eligibility matches hatch state without mutation")
	check(Synthesis.hatch(c), "awaken Synthesis")
	check(c.guardians.has("void") and c.guardians.has("light"), "both canonical parents retained")
	check(c.guardians[-1] == "synthesis", "Synthesis joins as owned guardian")
	check(c.loadout == pair, "awakening does not silently change field pair")
	check(not Synthesis.hatch(c), "awakening is idempotent")
	check(Synthesis.validate_owned(c), "earned Synthesis ownership validates")
	check(not Rules.normalize(c).is_empty(), "facade result satisfies canonical campaign validation")
	check(not Synthesis.can_forge(c) and not Synthesis.can_hatch(c), "recruited guardian offers neither duplicate operation")

	var missing_void = eligible(); missing_void.guardians.erase("void")
	check(Synthesis.reason(missing_void).contains("Null"), "Void parent required")
	check(not Synthesis.forge(missing_void), "cannot forge without Void")
	var missing_light = eligible(); missing_light.guardians.erase("light")
	check(Synthesis.reason(missing_light).contains("Lumen"), "Light parent required")
	var unfinished = eligible(); unfinished.finished = false
	check(Synthesis.reason(unfinished).contains("Singularity"), "completion required")
	var remote = eligible(); remote.room = "singularity"
	check(not Synthesis.forge(remote), "forging is Forge-only")
	remote.synthesis_forged = true
	check(not Synthesis.can_hatch(remote) and not Synthesis.hatch(remote), "awakening is Forge-only")
	var unearned = eligible(); unearned.synthesis_forged = true; unearned.guardians.erase("light")
	check(not Synthesis.validate_owned(unearned), "forged flag cannot excuse missing parent progression")

	for flag in ["hatched", "finished", "void_forged", "void_imprint_recovered"]:
		for missing in [false, true]:
			var invalid = eligible()
			if missing:invalid.erase(flag)
			else:invalid[flag] = false
			before = invalid.duplicate(true)
			check(Synthesis.reason(invalid) == Fusion.synthesis_reason(invalid) and Synthesis.reason(invalid) != "", "facade keeps canonical prerequisite guidance: %s missing=%s" % [flag, missing])
			check(not Synthesis.can_forge(invalid) and not Synthesis.forge(invalid) and invalid == before, "missing earned prerequisite cannot create resonance")
			invalid.synthesis_forged = true
			before = invalid.duplicate(true)
			check(not Synthesis.can_hatch(invalid) and not Synthesis.hatch(invalid) and invalid == before, "hatch rechecks the same earned prerequisite")
			check(not Synthesis.validate_owned(invalid), "saved resonance cannot bypass the earned prerequisite")
	for flag in ["synthesis_forged", "hatched", "finished", "void_forged", "void_imprint_recovered"]:
		for value in [0, 1, "true", null]:
			var malformed = eligible()
			malformed.synthesis_forged = true
			malformed[flag] = value
			check(not Synthesis.validate_owned(malformed), "ownership rejects non-boolean earned flags: " + flag)
	var unearned_owned = eligible(); unearned_owned.guardians.append("synthesis")
	check(not Synthesis.validate_owned(unearned_owned), "ownership requires forged resonance")
	var malformed_roster = eligible(); malformed_roster.guardians = "synthesis"
	check(not Synthesis.validate_owned(malformed_roster), "ownership rejects malformed roster type")

	var sparse = eligible(); sparse.guardians = ["fire", "void", "light"]; sparse.active_guardian = "fire"; sparse.loadout = ["fire", "void"]
	sparse.evolutions = {"fire":"", "ice":"", "storm":""}
	sparse.storm_forged = false; sparse.venom_forged = false; sparse.shadow_forged = false
	check(not Rules.normalize(sparse).is_empty(), "optional skipped roster is legitimate campaign progress")
	check(Synthesis.forge(sparse) and Synthesis.hatch(sparse), "optional skipped roster still supports canonical final recipe")
	check(sparse.loadout == ["fire", "void"], "sparse roster pair preserved")
	check(not Rules.normalize(sparse).is_empty(), "sparse facade result is saveable")

	print("SYNTHESIS_CONTRACT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
