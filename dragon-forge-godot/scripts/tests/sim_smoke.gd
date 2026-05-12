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

	# ── Plan 5: supporting systems smoke checks ───────────────────────────────

	# Test 5: SaveHelper count_battles_won returns int for empty save
	var empty_save: Dictionary = {}
	var SaveHelper = preload("res://scripts/sim/save_helper.gd")
	var battles_won: int = SaveHelper.count_battles_won(empty_save)
	if typeof(battles_won) == TYPE_INT and battles_won == 0:
		print("PASS: SaveHelper.count_battles_won empty")
		passed += 1
	else:
		print("FAIL: SaveHelper.count_battles_won — got: %s" % str(battles_won))
		failed += 1

	# Test 6: SaveHelper milestone claim/check round-trip
	var ms_save: Dictionary = { "data_scraps": 100 }
	SaveHelper.claim_milestone(ms_save, "test_ms")
	if SaveHelper.is_milestone_claimed(ms_save, "test_ms") and not SaveHelper.is_milestone_claimed(ms_save, "other_ms"):
		print("PASS: SaveHelper milestone claim round-trip")
		passed += 1
	else:
		print("FAIL: SaveHelper milestone claim round-trip")
		failed += 1

	# Test 7: SaveHelper inventory add/get/remove
	var inv_save: Dictionary = {}
	SaveHelper.add_inventory_item(inv_save, "xp_boost_charges", 3)
	var count_before: int = SaveHelper.get_inventory_count(inv_save, "xp_boost_charges")
	SaveHelper.remove_inventory_item(inv_save, "xp_boost_charges", 1)
	var count_after: int = SaveHelper.get_inventory_count(inv_save, "xp_boost_charges")
	if count_before == 3 and count_after == 2:
		print("PASS: SaveHelper inventory add/get/remove")
		passed += 1
	else:
		print("FAIL: SaveHelper inventory — before=%d after=%d" % [count_before, count_after])
		failed += 1

	# Test 8: TacticalBattle includes singularity bosses
	var TacticalBattle = preload("res://scripts/sim/tactical_battle.gd")
	var sb_ids := ["data_corruption", "memory_leak", "stack_overflow", "the_singularity"]
	var t8_ok := true
	for sb_id in sb_ids:
		if not TacticalBattle.EnemyData.has(sb_id):
			print("FAIL: TacticalBattle missing singularity boss: %s" % sb_id)
			t8_ok = false
			failed += 1
			break
	if t8_ok:
		print("PASS: TacticalBattle singularity bosses present")
		passed += 1

	# Test 9: DEFAULT_SAVE in main.gd has Plan 5 keys
	var main_script = preload("res://scripts/main.gd")
	var main_inst = main_script.new()
	var p5_keys := ["inventory", "stats", "records", "journal", "settings_music", "settings_sfx"]
	var t9_ok := true
	for key in p5_keys:
		if not main_inst.DEFAULT_SAVE.has(key):
			print("FAIL: DEFAULT_SAVE missing Plan 5 key: %s" % key)
			t9_ok = false
			failed += 1
			break
	main_inst.free()
	if t9_ok:
		print("PASS: DEFAULT_SAVE Plan 5 keys")
		passed += 1

	# ── Summary ───────────────────────────────────────────────────────────────
	print("")
	print("Smoke test complete: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
