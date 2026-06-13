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

	# ── S6 sprint pins (Godot tracks A+B) ─────────────────────────────────────

	# Test 13: award_dragon_xp caps at level 50 and zeroes xp at the cap
	var cap_save: Dictionary = DragonProgression.create_profile("fire")
	cap_save = DragonProgression.award_dragon_xp(cap_save, 1000000, "fire")
	var cap_level: int = DragonProgression.get_dragon_level(cap_save, "fire")
	var cap_xp: int = int(cap_save.get("dragon_xp", {}).get("fire", -1))
	if cap_level == 50 and cap_xp == 0:
		print("PASS: award_dragon_xp level-50 cap")
		passed += 1
	else:
		print("FAIL: award_dragon_xp cap — level=%d xp=%d" % [cap_level, cap_xp])
		failed += 1

	# Test 14: hatchery pull XP cannot push a dragon past level 50
	var HatcheryEngine = preload("res://scripts/sim/hatchery_engine.gd")
	var h_save := { "dragons": { "fire": { "owned": true, "level": 49, "xp": 950, "shiny": false } } }
	var h_pull := { "element": "fire", "rarity_name": "Common", "rarity_multiplier": 100, "shiny": false, "new_pity_counter": 0 }
	var h_result: Dictionary = HatcheryEngine.apply_pull_result(h_save, h_pull)
	var h_dragon: Dictionary = h_result["save"]["dragons"]["fire"]
	if int(h_dragon["level"]) == 50 and int(h_dragon["xp"]) == 0:
		print("PASS: hatchery pull level-50 cap")
		passed += 1
	else:
		print("FAIL: hatchery pull cap — level=%d xp=%d" % [int(h_dragon["level"]), int(h_dragon["xp"])])
		failed += 1

	# Test 15: calculate_xp_gain ratio clamped to [0.25, 2.0]
	var BattleEngine = preload("res://scripts/sim/battle_engine.gd")
	var xp_high: int = BattleEngine.calculate_xp_gain(50, 1, 30)
	var xp_low: int  = BattleEngine.calculate_xp_gain(100, 40, 2)
	if xp_high == 100 and xp_low == 25:
		print("PASS: calculate_xp_gain clamp")
		passed += 1
	else:
		print("FAIL: calculate_xp_gain clamp — high=%d (want 100) low=%d (want 25)" % [xp_high, xp_low])
		failed += 1

	# Test 16: SingularityProgress reads the Godot save shape
	var SingularityProgressScript = preload("res://scripts/sim/singularity_progress.gd")
	var sp_save: Dictionary = DragonProgression.create_profile("fire")
	var sp_fresh_locked: bool = not SingularityProgressScript.is_singularity_unlocked(sp_save)
	sp_save["bestiary_defeated"] = { "protocol_vulture": 1 }
	var sp_unlocked: bool = SingularityProgressScript.is_singularity_unlocked(sp_save)
	sp_save["bestiary_defeated"] = {
		"firewall_sentinel": 1, "bit_wraith": 1, "glitch_hydra": 1, "recursive_golem": 1,
	}
	var sp_stage5: bool = SingularityProgressScript.get_singularity_stage(sp_save) == 5
	sp_save["mission_flags"] = ["singularity_defeated"]
	var sp_stage0: bool = SingularityProgressScript.get_singularity_stage(sp_save) == 0
	if sp_fresh_locked and sp_unlocked and sp_stage5 and sp_stage0:
		print("PASS: SingularityProgress godot-shape + post-completion stage 0")
		passed += 1
	else:
		print("FAIL: SingularityProgress — locked=%s unlocked=%s stage5=%s stage0=%s" % [sp_fresh_locked, sp_unlocked, sp_stage5, sp_stage0])
		failed += 1

	# Test 17: fusion table keys normalized; stability matches browser tiers
	# Use FusionEngine pure module directly — avoids the SaveIO autoload issue
	# that makes fusion_screen.gd fail to compile in --script mode.
	var FusionEngine = preload("res://scripts/sim/fusion_engine.gd")
	var t17_ok := true
	for key in FusionEngine.FUSION_TABLE:
		var parts: PackedStringArray = String(key).split("+")
		if FusionEngine.pair_key(parts[0], parts[1]) != key:
			print("FAIL: FUSION_TABLE key not pair_key-normalized: %s" % key)
			t17_ok = false
			break
	if t17_ok and FusionEngine.fuse_elements("venom", "shadow") != "shadow":
		print("FAIL: venom+shadow should fuse to shadow (browser parity)")
		t17_ok = false
	if t17_ok and FusionEngine.fuse_elements("storm", "stone") != "storm":
		print("FAIL: stone+storm should fuse to storm (browser parity)")
		t17_ok = false
	if t17_ok and (FusionEngine.get_stability("fire", "fire") != "stable"
			or FusionEngine.get_stability("shadow", "venom") != "unstable"
			or FusionEngine.get_stability("fire", "storm") != "normal"):
		print("FAIL: stability tiers diverge from browser")
		t17_ok = false
	if t17_ok:
		print("PASS: fusion table + stability browser parity")
		passed += 1
	else:
		failed += 1

	# Test 18: final boss ships 3 phases in singularity_bosses.json
	var sb_file := FileAccess.open("res://data/singularity_bosses.json", FileAccess.READ)
	var t18_ok := sb_file != null
	if t18_ok:
		var sb_parsed: Variant = JSON.parse_string(sb_file.get_as_text())
		sb_file.close()
		t18_ok = typeof(sb_parsed) == TYPE_DICTIONARY \
			and (sb_parsed as Dictionary).get("final_boss", {}).get("phases", []).size() == 3
	if t18_ok:
		print("PASS: final boss has 3 phases")
		passed += 1
	else:
		print("FAIL: final boss phases missing or malformed")
		failed += 1

	# Test 19: protocol_vulture exists and singularity bosses carry browser rewards
	var TacticalBattle3 = preload("res://scripts/sim/tactical_battle.gd")
	var reward_expect := {
		"data_corruption": [100, 200], "memory_leak": [150, 300],
		"stack_overflow": [200, 400], "the_singularity": [500, 1000],
	}
	var t19_ok: bool = TacticalBattle3.EnemyData.has("protocol_vulture")
	if not t19_ok:
		print("FAIL: protocol_vulture missing from EnemyData")
	for boss_id in reward_expect:
		if not t19_ok:
			break
		var e: Dictionary = TacticalBattle3.EnemyData.get(boss_id, {})
		if int(e.get("reward_xp", 0)) != reward_expect[boss_id][0] or int(e.get("reward_scraps", 0)) != reward_expect[boss_id][1]:
			print("FAIL: %s rewards %d/%d diverge from browser %d/%d" % [boss_id, int(e.get("reward_xp", 0)), int(e.get("reward_scraps", 0)), reward_expect[boss_id][0], reward_expect[boss_id][1]])
			t19_ok = false
	if t19_ok:
		print("PASS: protocol_vulture present, boss rewards browser-synced")
		passed += 1
	else:
		failed += 1

	# Test 20: boss progression gates (browser parity)
	var lock_save := { "bestiary_defeated": {} }
	var t20_ok: bool = TacticalBattle3.is_boss_locked(lock_save, "recursive_golem") \
		and TacticalBattle3.is_boss_locked(lock_save, "protocol_vulture")
	lock_save["bestiary_defeated"] = { "firewall_sentinel": 1, "buffer_overflow": 1, "bit_wraith": 1 }
	t20_ok = t20_ok and not TacticalBattle3.is_boss_locked(lock_save, "recursive_golem") \
		and TacticalBattle3.is_boss_locked(lock_save, "protocol_vulture")
	lock_save["bestiary_defeated"]["recursive_golem"] = 1
	t20_ok = t20_ok and not TacticalBattle3.is_boss_locked(lock_save, "protocol_vulture")
	if t20_ok:
		print("PASS: boss progression gates")
		passed += 1
	else:
		print("FAIL: boss progression gates diverge from browser")
		failed += 1

	# Test 21: FusionEngine.execute_fusion result level — both Stage III → 50, else 1
	var FusionEngine2 = preload("res://scripts/sim/fusion_engine.gd")
	var fu_a := {"element": "fire", "level": 25, "stats": {"hp": 120, "atk": 30, "def": 20, "spd": 18}, "shiny": false}
	var fu_b := {"element": "fire", "level": 25, "stats": {"hp": 110, "atk": 28, "def": 22, "spd": 20}, "shiny": false}
	var fu_c := {"element": "fire", "level": 10, "stats": {"hp": 80,  "atk": 20, "def": 15, "spd": 12}, "shiny": false}
	var fu_both: Dictionary = FusionEngine2.execute_fusion(fu_a, fu_b)
	var fu_low:  Dictionary = FusionEngine2.execute_fusion(fu_c, fu_b)
	if fu_both.get("level", -1) == 50 and fu_low.get("level", -1) == 1:
		print("PASS: fusion result level (bothStageIII=50, else=1)")
		passed += 1
	else:
		print("FAIL: fusion result level — bothStageIII=%d oneLow=%d" % [fu_both.get("level", -1), fu_low.get("level", -1)])
		failed += 1

	# Test 22: SingularityProgress._defeated_count reads both Godot dict and legacy array
	var SP2 = preload("res://scripts/sim/singularity_progress.gd")
	var sp_godot_save := { "bestiary_defeated": { "protocol_vulture": 1 } }
	var sp_legacy_save := { "defeatedNpcs": ["protocol_vulture"] }
	var sp_absent_save := {}
	var t22_ok: bool = SP2.is_singularity_unlocked(sp_godot_save) \
		and SP2.is_singularity_unlocked(sp_legacy_save) \
		and not SP2.is_singularity_unlocked(sp_absent_save)
	if t22_ok:
		print("PASS: _defeated_count dual-key lookup (Godot dict + legacy array)")
		passed += 1
	else:
		print("FAIL: _defeated_count dual-key — godot=%s legacy=%s absent=%s" % [
			SP2.is_singularity_unlocked(sp_godot_save),
			SP2.is_singularity_unlocked(sp_legacy_save),
			not SP2.is_singularity_unlocked(sp_absent_save),
		])
		failed += 1

	# ── Summary ───────────────────────────────────────────────────────────────
	print("")
	print("Smoke test complete: %d passed, %d failed" % [passed, failed])
	if failed > 0:
		quit(1)
	else:
		quit(0)
