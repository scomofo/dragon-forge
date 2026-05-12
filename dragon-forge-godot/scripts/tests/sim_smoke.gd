extends SceneTree

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const DragonData = preload("res://scripts/sim/dragon_data.gd")
const CombatRules = preload("res://scripts/sim/combat_rules.gd")

func _init() -> void:
	var passed := 0
	var failed := 0

	# ── Plan 4: slice-screens smoke checks ────────────────────────────────────

	# Test 1: default save shape has required keys
	var profile: Dictionary = DragonProgression.create_profile("fire")
	var required_keys := [
		"dragon_id", "dragon_levels", "dragon_xp", "data_scraps",
		"hatchery_state", "bestiary_seen", "bestiary_defeated",
	]
	var t1_ok := true
	for key in required_keys:
		if not profile.has(key):
			print("FAIL: default save shape — missing key: %s" % key)
			t1_ok = false
			failed += 1
			break
	if t1_ok:
		print("PASS: default save shape")
		passed += 1

	# Test 2: combat rules resolve_attack returns expected keys
	var attacker := {"hp": 100, "atk": 28, "def": 20, "spd": 18, "element": "fire", "stage": 1}
	var defender := {"hp": 190, "atk": 25, "def": 22, "spd": 10, "element": "stone", "stage": 1}
	var move := {"element": "fire", "power": 88, "accuracy": 95}
	var result: Dictionary = CombatRules.resolve_attack(attacker, defender, move, 0.0)
	if result.has("hit") and result.has("damage") and result.has("remaining_hp") and result.has("effectiveness"):
		print("PASS: combat rules resolve keys")
		passed += 1
	else:
		print("FAIL: combat rules resolve keys — got: %s" % str(result.keys()))
		failed += 1

	# Test 3: dragon stats scale with level
	var fire_def: Dictionary = DragonData.DRAGONS.get("fire", {})
	var stats_l1: Dictionary = DragonData.calculate_stats(fire_def.get("base_stats", {}), 1)
	var stats_l10: Dictionary = DragonData.calculate_stats(fire_def.get("base_stats", {}), 10)
	if stats_l10.get("atk", 0) > stats_l1.get("atk", 0):
		print("PASS: stat scaling")
		passed += 1
	else:
		print("FAIL: stat scaling — l1 atk=%d l10 atk=%d" % [stats_l1.get("atk", 0), stats_l10.get("atk", 0)])
		failed += 1

	# Test 4: hatchery state owned_dragons not empty after create_profile
	var state: Dictionary = DragonProgression.get_hatchery_state(profile)
	if state.get("owned_dragons", []).size() > 0:
		print("PASS: hatchery state init")
		passed += 1
	else:
		print("FAIL: hatchery state init — owned_dragons is empty")
		failed += 1

	# ── Summary ───────────────────────────────────────────────────────────────
	print("")
	print("Smoke test complete: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
