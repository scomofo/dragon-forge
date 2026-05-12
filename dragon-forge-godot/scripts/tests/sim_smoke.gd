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

	# Test 9: data JSON files load with expected structure
	var shop_file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	var t9_ok := shop_file != null
	if t9_ok:
		var shop_parsed: Variant = JSON.parse_string(shop_file.get_as_text())
		shop_file.close()
		t9_ok = typeof(shop_parsed) == TYPE_DICTIONARY and (shop_parsed as Dictionary).has("buy_items") and (shop_parsed as Dictionary).has("forge_recipes")
	if t9_ok:
		print("PASS: shop_items.json structure")
		passed += 1
	else:
		print("FAIL: shop_items.json structure invalid")
		failed += 1

	# ── Plan 7: polish systems smoke checks ───────────────────────────────────

	# Test 10: all Plan 5 screen scenes instantiate without error
	var screen_scenes := [
		"res://scenes/screens/shop_screen.tscn",
		"res://scenes/screens/forge_screen.tscn",
		"res://scenes/screens/journal_screen.tscn",
		"res://scenes/screens/stats_screen.tscn",
		"res://scenes/screens/settings_screen.tscn",
		"res://scenes/screens/singularity_screen.tscn",
		"res://scenes/screens/campaign_map_screen.tscn",
	]
	var t10_ok := true
	for path in screen_scenes:
		var packed: PackedScene = load(path)
		if packed == null:
			print("FAIL: screen scene failed to load: %s" % path)
			t10_ok = false
			failed += 1
			break
		var inst := packed.instantiate()
		if inst == null:
			print("FAIL: screen scene failed to instantiate: %s" % path)
			t10_ok = false
			failed += 1
			inst.free() if inst != null else null
			break
		inst.free()
	if t10_ok:
		print("PASS: all Plan 5 screen scenes instantiate")
		passed += 1

	# Test 11: main.tscn has FadeOverlay node
	var main_packed: PackedScene = load("res://scenes/main.tscn")
	if main_packed != null:
		var main_inst := main_packed.instantiate()
		if main_inst != null and main_inst.has_node("FadeOverlay"):
			print("PASS: main.tscn has FadeOverlay")
			passed += 1
		else:
			print("FAIL: main.tscn missing FadeOverlay node")
			failed += 1
		if main_inst != null:
			main_inst.free()
	else:
		print("FAIL: main.tscn failed to load")
		failed += 1

	# Test 12: TacticalBattle singularity bosses have reward_flag set
	var TacticalBattle2 = preload("res://scripts/sim/tactical_battle.gd")
	var t12_ok := true
	for boss_id in ["data_corruption", "memory_leak", "stack_overflow"]:
		var flag: String = str(TacticalBattle2.EnemyData.get(boss_id, {}).get("reward_flag", ""))
		if not flag.begins_with("singularity_"):
			print("FAIL: boss %s has bad reward_flag: '%s'" % [boss_id, flag])
			t12_ok = false
			failed += 1
			break
	if t12_ok:
		print("PASS: singularity boss reward_flags correct")
		passed += 1

	# ── Summary ───────────────────────────────────────────────────────────────
	print("")
	print("Smoke test complete: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
