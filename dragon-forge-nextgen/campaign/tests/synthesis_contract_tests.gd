extends SceneTree
const Synthesis = preload("res://campaign/synthesis_rules.gd")
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
	return {
		"version": 11,
		"finished": true,
		"room": "forge",
		"guardians": ["fire", "ice", "storm", "stone", "venom", "shadow", "void", "light"],
		"active_guardian": "shadow",
		"loadout": ["shadow", "light"],
		"synthesis_forged": false,
		"salvage": 321,
		"installed": ["outer", "frozen", "storm", "admin"],
		"evolutions": {"fire":"flashfire", "ice":"aegis", "storm":"overcharge"}
	}

func run() -> void:
	var c = eligible()
	check(Synthesis.REQUIRED_PARENTS == ["void", "light"], "canonical Light + Void parent set")
	check(Synthesis.reason(c) == "", "eligible completed roster can synthesize")
	var pair = c.loadout.duplicate()
	var guardians = c.guardians.duplicate()
	var salvage = c.salvage
	var evolutions = c.evolutions.duplicate(true)
	check(Synthesis.forge(c), "forge Synthesis once")
	check(not Synthesis.forge(c), "forge is idempotent")
	check(c.guardians == guardians, "forging preserves parents and roster")
	check(c.loadout == pair, "forging preserves expedition pair")
	check(c.salvage == salvage and c.evolutions == evolutions, "forging costs no progress")
	check(Synthesis.hatch(c), "awaken Synthesis")
	check(c.guardians.has("void") and c.guardians.has("light"), "both canonical parents retained")
	check(c.guardians[-1] == "synthesis", "Synthesis joins as owned guardian")
	check(c.loadout == pair, "awakening does not silently change field pair")
	check(not Synthesis.hatch(c), "awakening is idempotent")
	check(Synthesis.validate_owned(c), "earned Synthesis ownership validates")

	var missing_void = eligible(); missing_void.guardians.erase("void")
	check(Synthesis.reason(missing_void).contains("Null"), "Void parent required")
	check(not Synthesis.forge(missing_void), "cannot forge without Void")
	var missing_light = eligible(); missing_light.guardians.erase("light")
	check(Synthesis.reason(missing_light).contains("Lumen"), "Light parent required")
	var unfinished = eligible(); unfinished.finished = false
	check(Synthesis.reason(unfinished).contains("Singularity"), "completion required")
	var remote = eligible(); remote.room = "singularity"
	check(not Synthesis.forge(remote), "forging is Forge-only")
	var unearned = eligible(); unearned.synthesis_forged = true; unearned.guardians.erase("light")
	check(not Synthesis.validate_owned(unearned), "forged flag cannot excuse missing parent progression")

	var sparse = eligible(); sparse.guardians = ["fire", "void", "light"]; sparse.active_guardian = "fire"; sparse.loadout = ["fire", "void"]
	check(Synthesis.forge(sparse) and Synthesis.hatch(sparse), "optional skipped roster still supports canonical final recipe")
	check(sparse.loadout == ["fire", "void"], "sparse roster pair preserved")

	print("SYNTHESIS_CONTRACT_TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
