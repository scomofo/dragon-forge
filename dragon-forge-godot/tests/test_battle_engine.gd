extends GutTest

const BattleEngine = preload("res://scripts/sim/battle_engine.gd")
const GameData     = preload("res://scripts/sim/game_data.gd")

func test_fire_super_effective_vs_ice() -> void:
	assert_eq(BattleEngine.get_type_effectiveness("fire", "ice"), 2.0)

func test_fire_not_effective_vs_stone() -> void:
	assert_eq(BattleEngine.get_type_effectiveness("fire", "stone"), 0.5)

func test_neutral_attacker_returns_1() -> void:
	assert_eq(BattleEngine.get_type_effectiveness("neutral", "fire"), 1.0)

func test_unknown_defender_returns_1() -> void:
	assert_eq(BattleEngine.get_type_effectiveness("fire", "neutral"), 1.0)

func test_void_attacking_any_is_neutral() -> void:
	for el in ["fire", "ice", "shadow", "void"]:
		assert_eq(BattleEngine.get_type_effectiveness("void", el), 1.0,
				  "void vs %s should be 1.0" % el)

func test_any_attacking_void_is_neutral() -> void:
	for el in ["fire", "ice", "shadow"]:
		assert_eq(BattleEngine.get_type_effectiveness(el, "void"), 1.0,
				  "%s vs void should be 1.0" % el)

func test_super_effective_damage_range() -> void:
	var attacker := { "atk": 28, "element": "fire", "stage": 3 }
	var defender := { "def": 20, "element": "ice", "defending": false }
	var move     := { "element": "fire", "power": 65, "accuracy": 100 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_true(result.hit, "should hit at accuracy 100")
	assert_eq(result.effectiveness, 2.0)
	assert_true(result.damage >= 78 and result.damage <= 138,
				"damage %d should be in [78,138]" % result.damage)

func test_defending_halves_damage() -> void:
	var attacker := { "atk": 28, "element": "fire", "stage": 3 }
	var defender := { "def": 20, "element": "ice", "defending": true }
	var move     := { "element": "fire", "power": 65, "accuracy": 100 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_true(result.damage >= 39 and result.damage <= 69,
				"defending damage %d should be in [39,69]" % result.damage)

func test_stage_multiplier_applied() -> void:
	var attacker := { "atk": 28, "element": "fire", "stage": 1 }
	var defender := { "def": 20, "element": "ice", "defending": false }
	var move     := { "element": "fire", "power": 65, "accuracy": 100 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_true(result.damage >= 30 and result.damage <= 54,
				"stage 1 damage %d should be in [30,54]" % result.damage)

func test_minimum_1_damage() -> void:
	var attacker := { "atk": 1,   "element": "fire", "stage": 1 }
	var defender := { "def": 100, "element": "fire", "defending": true }
	var move     := { "element": "fire", "power": 65, "accuracy": 100 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_eq(result.damage, 1)

func test_accuracy_zero_always_misses() -> void:
	var attacker := { "atk": 28, "element": "fire", "stage": 3 }
	var defender := { "def": 20, "element": "ice",  "defending": false }
	var move     := { "element": "fire", "power": 65, "accuracy": 0 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_false(result.hit)
	assert_eq(result.damage, 0)

func test_is_critical_is_bool() -> void:
	var attacker := { "atk": 28, "element": "fire", "stage": 3 }
	var defender := { "def": 20, "element": "ice",  "defending": false }
	var move     := { "element": "fire", "power": 65, "accuracy": 100 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_true(result.is_critical == true or result.is_critical == false)

func test_miss_cannot_be_critical() -> void:
	var attacker := { "atk": 28, "element": "fire", "stage": 3 }
	var defender := { "def": 20, "element": "ice",  "defending": false }
	var move     := { "element": "fire", "power": 65, "accuracy": 0 }
	var result   := BattleEngine.calculate_damage(attacker, defender, move)
	assert_false(result.is_critical)

func test_stage_1_below_10() -> void:
	assert_eq(BattleEngine.get_stage_for_level(1), 1)
	assert_eq(BattleEngine.get_stage_for_level(9), 1)

func test_stage_2_levels_10_to_24() -> void:
	assert_eq(BattleEngine.get_stage_for_level(10), 2)
	assert_eq(BattleEngine.get_stage_for_level(24), 2)

func test_stage_3_levels_25_to_49() -> void:
	assert_eq(BattleEngine.get_stage_for_level(25), 3)
	assert_eq(BattleEngine.get_stage_for_level(49), 3)

func test_stage_4_level_50_plus() -> void:
	assert_eq(BattleEngine.get_stage_for_level(50), 4)
	assert_eq(BattleEngine.get_stage_for_level(99), 4)

func test_xp_equal_levels() -> void:
	assert_eq(BattleEngine.calculate_xp_gain(50, 10, 10), 50)

func test_xp_higher_enemy() -> void:
	assert_eq(BattleEngine.calculate_xp_gain(50, 5, 10), 100)

func test_xp_lower_enemy() -> void:
	assert_eq(BattleEngine.calculate_xp_gain(50, 10, 5), 25)

func test_xp_minimum_1() -> void:
	assert_true(BattleEngine.calculate_xp_gain(50, 99, 1) >= 1)

func test_stats_at_level_1() -> void:
	var base   := { "hp": 110, "atk": 28, "def": 20, "spd": 18 }
	var result := BattleEngine.calculate_stats_for_level(base, 1, false)
	assert_eq(result, { "hp": 110, "atk": 28, "def": 20, "spd": 18 })

func test_stats_level_5_adds_12_each() -> void:
	var base   := { "hp": 110, "atk": 28, "def": 20, "spd": 18 }
	var result := BattleEngine.calculate_stats_for_level(base, 5, false)
	assert_eq(result, { "hp": 122, "atk": 40, "def": 32, "spd": 30 })

func test_shiny_1_2x_multiplier_level_1() -> void:
	var base   := { "hp": 100, "atk": 20, "def": 20, "spd": 20 }
	var result := BattleEngine.calculate_stats_for_level(base, 1, true)
	assert_eq(result, { "hp": 120, "atk": 24, "def": 24, "spd": 24 })

func test_shiny_after_level_scaling() -> void:
	var base   := { "hp": 100, "atk": 20, "def": 20, "spd": 20 }
	var result := BattleEngine.calculate_stats_for_level(base, 5, true)
	assert_eq(result, { "hp": 134, "atk": 38, "def": 38, "spd": 38 })

func test_non_shiny_no_change() -> void:
	var base   := { "hp": 100, "atk": 20, "def": 20, "spd": 20 }
	var result := BattleEngine.calculate_stats_for_level(base, 1, false)
	assert_eq(result, { "hp": 100, "atk": 20, "def": 20, "spd": 20 })

func test_apply_burn_from_fire() -> void:
	var result: Variant = BattleEngine.apply_status("fire")
	assert_eq(result, { "effect": "fire", "turns_left": 2 })

func test_apply_status_neutral_returns_null() -> void:
	assert_eq(BattleEngine.apply_status("neutral"), null)

func test_apply_freeze_1_turn() -> void:
	var result: Variant = BattleEngine.apply_status("ice")
	assert_eq(result, { "effect": "ice", "turns_left": 1 })

func test_burn_dot_damage() -> void:
	var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "fire", "turns_left": 2 } }
	var result := BattleEngine.process_status_tick(state)
	assert_eq(result.hp, 92)
	assert_eq(result.status.turns_left, 1)
	assert_eq(result.status_event, { "type": "dot", "damage": 8, "effect_name": "Burn", "expired": false })

func test_poison_dot_damage() -> void:
	var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "venom", "turns_left": 2 } }
	var result := BattleEngine.process_status_tick(state)
	assert_eq(result.hp, 94)
	assert_eq(result.status.turns_left, 1)

func test_status_expires_at_zero_turns() -> void:
	var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "fire", "turns_left": 1 } }
	var result := BattleEngine.process_status_tick(state)
	assert_eq(result.hp, 92)
	assert_eq(result.status, null)
	assert_true(result.status_event.expired)

func test_no_status_returns_unchanged() -> void:
	var state  := { "hp": 100, "max_hp": 100, "status": null }
	var result := BattleEngine.process_status_tick(state)
	assert_eq(result.hp, 100)
	assert_eq(result.status_event, null)

func test_non_dot_status_no_damage() -> void:
	var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "stone", "turns_left": 2 } }
	var result := BattleEngine.process_status_tick(state)
	assert_eq(result.hp, 100)
	assert_eq(result.status.turns_left, 1)

func test_pick_npc_move_returns_valid_key() -> void:
	var keys   := ["rock_slide", "earthquake"]
	var result := BattleEngine.pick_npc_move(keys, "stone", "fire", null)
	assert_true(["rock_slide", "earthquake", "basic_attack"].has(result),
				"pick_npc_move returned unknown key: %s" % result)

func test_pick_npc_move_favors_super_effective() -> void:
	var keys := ["rock_slide", "earthquake"]
	var super_effective_count := 0
	for _i in range(50):
		var key: String = BattleEngine.pick_npc_move(keys, "stone", "fire", null)
		var move: Dictionary = GameData.MOVES.get(key, GameData.MOVES["basic_attack"])
		var eff  := BattleEngine.get_type_effectiveness(move["element"], "fire")
		if eff > 1.0:
			super_effective_count += 1
	assert_true(super_effective_count > 25,
				"super-effective moves chosen only %d/50 times" % super_effective_count)

func _player_state() -> Dictionary:
	return {
		"name": "Magma Dragon", "element": "fire", "stage": 3,
		"hp": 100, "max_hp": 110, "atk": 28, "def": 20, "spd": 18, "defending": false,
		"status": null, "reflecting": false,
	}

func _npc_state() -> Dictionary:
	return {
		"name": "Firewall Sentinel", "element": "stone", "stage": 3,
		"hp": 130, "max_hp": 130, "atk": 18, "def": 32, "spd": 8, "defending": false,
		"status": null, "reflecting": false,
	}

func test_resolve_turn_returns_player_npc_events() -> void:
	var result := BattleEngine.resolve_turn(
		_player_state(), _npc_state(), "magma_breath", "rock_slide", [], [])
	assert_true(result.has("player"))
	assert_true(result.has("npc"))
	assert_true(result.has("events"))
	assert_true(result.events.size() >= 2)

func test_faster_combatant_attacks_first() -> void:
	var result := BattleEngine.resolve_turn(
		_player_state(), _npc_state(), "magma_breath", "rock_slide", [], [])
	assert_eq(result.events[0].attacker, "player")
	assert_eq(result.events[1].attacker, "npc")

func test_defend_action_sets_event() -> void:
	var result := BattleEngine.resolve_turn(
		_player_state(), _npc_state(), "defend", "rock_slide", [], [])
	var defend_event: Variant = null
	for ev in result.events:
		if ev.get("action") == "defend":
			defend_event = ev
			break
	assert_not_null(defend_event, "no defend event found")

func test_ko_stops_second_attack() -> void:
	var weak_npc := _npc_state()
	weak_npc.hp = 1
	var result := BattleEngine.resolve_turn(
		_player_state(), weak_npc, "basic_attack", "rock_slide", [], [])
	assert_eq(result.npc.hp, 0)
	var npc_attacks := 0
	for ev in result.events:
		if ev.get("attacker") == "npc" and ev.get("action") == "attack":
			npc_attacks += 1
	assert_eq(npc_attacks, 0, "NPC should not attack after being KO'd")

func _void_player() -> Dictionary:
	return {
		"name": "Void Dragon", "element": "void", "stage": 3,
		"hp": 75, "max_hp": 75, "atk": 34, "def": 12, "spd": 30,
		"status": null, "defending": false, "reflecting": false,
	}

func _fire_npc() -> Dictionary:
	return {
		"name": "Test NPC", "element": "fire", "stage": 3,
		"hp": 100, "max_hp": 100, "atk": 20, "def": 20, "spd": 10,
		"status": null, "defending": false, "reflecting": false,
	}

func test_null_reflect_reflects_damage() -> void:
	var result := BattleEngine.resolve_turn(
		_void_player(), _fire_npc(), "null_reflect", "basic_attack", [], [])
	var reflect_event: Variant = null
	var npc_attack_event: Variant = null
	for ev in result.events:
		if ev.get("action") == "reflect":
			reflect_event = ev
		if ev.get("attacker") == "npc" and ev.get("action") == "attack":
			npc_attack_event = ev
	assert_not_null(reflect_event, "no reflect event found")
	assert_eq(reflect_event.attacker, "player")
	assert_not_null(npc_attack_event, "no npc attack event found")
	assert_true(npc_attack_event.get("reflected", false), "attack should be reflected")
	assert_eq(result.player.hp, 75, "player hp unchanged — damage reflected away")
	assert_true(result.npc.hp < 100, "npc takes reflected damage")

func test_reflect_vs_defend_no_damage() -> void:
	var result := BattleEngine.resolve_turn(
		_void_player(), _fire_npc(), "null_reflect", "defend", [], [])
	assert_eq(result.player.hp, 75)
	assert_eq(result.npc.hp, 100)

func test_glitch_turn_resolves_normally() -> void:
	var player := _player_state()
	player.status = { "effect": "void", "turns_left": 1 }
	var npc := _npc_state()
	var result := BattleEngine.resolve_turn(
		player, npc, "basic_attack", "basic_attack",
		["magma_breath", "flame_wall"], ["rock_slide"])
	assert_true(result.events.size() > 0)
	var player_event: Variant = null
	for ev in result.events:
		if ev.get("attacker") == "player":
			player_event = ev
			break
	assert_not_null(player_event, "player should have acted even under Glitch")
