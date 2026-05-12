extends RefCounted
class_name BattleEngine

const GameData = preload("res://scripts/sim/game_data.gd")

static func get_type_effectiveness(attacker_element: String, defender_element: String) -> float:
	if not GameData.TYPE_CHART.has(attacker_element):
		return 1.0
	var row: Dictionary = GameData.TYPE_CHART[attacker_element]
	return row.get(defender_element, 1.0)

static func calculate_damage(attacker: Dictionary, defender: Dictionary, move: Dictionary) -> Dictionary:
	var accuracy_roll: float = randf() * 100.0
	if accuracy_roll > move.get("accuracy", 100):
		return { "damage": 0, "effectiveness": 1.0, "hit": false, "is_critical": false }

	var stage_mult: float  = GameData.STAGE_MULTIPLIERS.get(attacker.get("stage", 3), 1.0)
	var base_damage: float = (attacker.get("atk", 0) * stage_mult * 2.0) - (defender.get("def", 0) * 0.5)
	var effectiveness: float = get_type_effectiveness(move.get("element", "neutral"), defender.get("element", "neutral"))
	var typed_damage: float = base_damage * effectiveness

	if defender.get("defending", false):
		typed_damage *= 0.5

	var roll: float       = 0.85 + randf() * 0.15
	var final_damage: int = maxi(1, int(typed_damage * roll))

	var is_critical: bool = randf() < GameData.CRIT_CHANCE
	if is_critical:
		final_damage = int(final_damage * GameData.CRIT_MULTIPLIER)

	return { "damage": final_damage, "effectiveness": effectiveness, "hit": true, "is_critical": is_critical }

static func get_stage_for_level(level: int) -> int:
	if level >= GameData.STAGE_THRESHOLDS[4]: return 4
	if level >= GameData.STAGE_THRESHOLDS[3]: return 3
	if level >= GameData.STAGE_THRESHOLDS[2]: return 2
	return 1

static func calculate_xp_gain(base_xp: int, player_level: int, enemy_level: int) -> int:
	var ratio: float = float(enemy_level) / float(player_level)
	return maxi(1, int(base_xp * ratio))

static func calculate_stats_for_level(base_stats: Dictionary, level: int, shiny: bool = false) -> Dictionary:
	var bonus: int   = (level - 1) * 3
	var mult: float  = 1.2 if shiny else 1.0
	return {
		"hp":  int((base_stats.get("hp",  0) + bonus) * mult),
		"atk": int((base_stats.get("atk", 0) + bonus) * mult),
		"def": int((base_stats.get("def", 0) + bonus) * mult),
		"spd": int((base_stats.get("spd", 0) + bonus) * mult),
	}

static func apply_status(move_element: String) -> Variant:
	if not GameData.STATUS_EFFECTS.has(move_element):
		return null
	var effect: Dictionary = GameData.STATUS_EFFECTS[move_element]
	return { "effect": move_element, "turns_left": effect["duration"] }

static func process_status_tick(combatant_state: Dictionary) -> Dictionary:
	var result: Dictionary = combatant_state.duplicate(true)
	if combatant_state.get("status") == null:
		result["status_event"] = null
		return result

	var effect_key: String = combatant_state["status"]["effect"]
	var effect: Dictionary = GameData.STATUS_EFFECTS[effect_key]
	var hp: int            = combatant_state.get("hp", 0)
	var damage: int        = 0
	var turns_left: int    = combatant_state["status"]["turns_left"] - 1
	var expired: bool      = turns_left <= 0

	if effect["type"] == "dot":
		damage = maxi(1, int(combatant_state.get("max_hp", hp) * effect["value"]))
		hp     = maxi(0, hp - damage)

	result["hp"] = hp
	result["status"] = null if expired else { "effect": effect_key, "turns_left": turns_left }
	result["status_event"] = {
		"type":        effect["type"],
		"damage":      damage,
		"effect_name": effect["name"],
		"expired":     expired,
	}
	return result

static func pick_npc_move(npc_move_keys: Array, npc_element: String,
		player_element: String, player_status: Variant) -> String:

	var filtered_keys: Array = []
	for key in npc_move_keys:
		var move: Dictionary = GameData.MOVES.get(key, {})
		if not move.get("is_reflect", false):
			filtered_keys.append(key)

	var available_keys: Array = filtered_keys.duplicate()
	if not available_keys.has("basic_attack"):
		available_keys.append("basic_attack")

	var super_effective: Array = []
	for key in available_keys:
		var move: Dictionary = GameData.MOVES.get(key, {})
		if move.size() > 0 and get_type_effectiveness(move.get("element", "neutral"), player_element) > 1.0:
			super_effective.append(key)

	if super_effective.size() > 0 and randf() < 0.7:
		return super_effective[randi() % super_effective.size()]

	if player_status == null and randf() < 0.4:
		var status_moves: Array = []
		for key in filtered_keys:
			var move: Dictionary = GameData.MOVES.get(key, {})
			if move.get("can_apply_status", false):
				status_moves.append(key)
		if status_moves.size() > 0:
			return status_moves[randi() % status_moves.size()]

	if filtered_keys.size() > 1 and randf() < 0.6:
		var sorted: Array = filtered_keys.duplicate()
		sorted.sort_custom(func(a, b):
			return GameData.MOVES.get(b, {}).get("power", 0) < GameData.MOVES.get(a, {}).get("power", 0)
		)
		return sorted[0]

	var preferred: Array = filtered_keys if filtered_keys.size() > 0 and randf() < 0.7 else available_keys
	return preferred[randi() % preferred.size()]

static func resolve_turn(
		player_state: Dictionary, npc_state: Dictionary,
		player_move_key: String,  npc_move_key: String,
		player_move_keys: Array,  npc_move_keys: Array) -> Dictionary:

	var player: Dictionary = player_state.duplicate(true)
	var npc:    Dictionary = npc_state.duplicate(true)
	player["defending"]  = false
	npc["defending"]     = false
	var events: Array = []

	var player_first: bool = player.get("spd", 0) >= npc.get("spd", 0)

	var first_label:  String = "player" if player_first else "npc"
	var second_label: String = "npc"    if player_first else "player"
	var first_move:   String = player_move_key if player_first else npc_move_key
	var second_move:  String = npc_move_key    if player_first else player_move_key

	var first_state: Dictionary = player if player_first else npc
	if first_state.get("status", null) != null and first_state["status"].get("effect") == "void":
		var glitch_keys: Array = player_move_keys if player_first else npc_move_keys
		if glitch_keys.size() > 0:
			first_move = glitch_keys[randi() % glitch_keys.size()]

	var second_state: Dictionary = npc if player_first else player
	if second_state.get("status", null) != null and second_state["status"].get("effect") == "void":
		var glitch_keys: Array = npc_move_keys if player_first else player_move_keys
		if glitch_keys.size() > 0:
			second_move = glitch_keys[randi() % glitch_keys.size()]

	_resolve_action(first_label, first_move, player, npc, events, player_move_keys, npc_move_keys)

	var first_target: Dictionary = npc if first_label == "player" else player
	if first_target.get("hp", 0) > 0:
		_resolve_action(second_label, second_move, player, npc, events, player_move_keys, npc_move_keys)

	if player.get("hp", 0) > 0 and player.get("status") != null:
		var player_with_max: Dictionary = player.duplicate(true)
		player_with_max["max_hp"] = player_state.get("max_hp", player.get("max_hp", 0))
		var tick := process_status_tick(player_with_max)
		player["hp"]     = tick["hp"]
		player["status"] = tick["status"]
		if tick.get("status_event") != null:
			var ev: Dictionary = tick["status_event"].duplicate()
			ev["attacker"] = "status"
			ev["target"]   = "player"
			events.append(ev)

	if npc.get("hp", 0) > 0 and npc.get("status") != null:
		var npc_with_max: Dictionary = npc.duplicate(true)
		npc_with_max["max_hp"] = npc_state.get("max_hp", npc.get("max_hp", 0))
		var tick := process_status_tick(npc_with_max)
		npc["hp"]     = tick["hp"]
		npc["status"] = tick["status"]
		if tick.get("status_event") != null:
			var ev: Dictionary = tick["status_event"].duplicate()
			ev["attacker"] = "status"
			ev["target"]   = "npc"
			events.append(ev)

	player["reflecting"] = false
	npc["reflecting"]    = false

	return { "player": player, "npc": npc, "events": events }

static func _resolve_action(
		actor_label: String, move_key: String,
		player: Dictionary, npc: Dictionary,
		events: Array,
		player_move_keys: Array, npc_move_keys: Array) -> void:

	var actor_state:  Dictionary = player if actor_label == "player" else npc
	var target_state: Dictionary = npc    if actor_label == "player" else player

	if actor_state.get("status", null) != null and actor_state["status"].get("effect") == "ice":
		events.append({ "attacker": actor_label, "action": "statusSkip", "status_name": "Freeze" })
		return

	if actor_state.get("status", null) != null and actor_state["status"].get("effect") == "storm":
		if randf() < GameData.STATUS_EFFECTS["storm"]["value"]:
			events.append({ "attacker": actor_label, "action": "statusSkip", "status_name": "Paralyze" })
			return

	if move_key == "defend":
		actor_state["defending"] = true
		if actor_label == "player":
			player.merge(actor_state, true)
		else:
			npc.merge(actor_state, true)
		events.append({ "attacker": actor_label, "action": "defend", "damage": 0, "effectiveness": 1.0, "hit": true })
		return

	var move_data: Dictionary = GameData.MOVES.get(move_key, {})
	var move:      Dictionary = move_data if move_data.size() > 0 else GameData.MOVES["basic_attack"]

	if move.get("is_reflect", false):
		actor_state["reflecting"] = true
		if actor_label == "player":
			player.merge(actor_state, true)
		else:
			npc.merge(actor_state, true)
		events.append({
			"attacker": actor_label, "action": "reflect",
			"move_name": move["name"], "move_key": move_key,
			"damage": 0, "effectiveness": 1.0, "hit": true,
		})
		return

	var effective_def: float = target_state.get("def", 0)
	if target_state.get("status", null) != null and target_state["status"].get("effect") == "stone":
		effective_def = int(effective_def * (1.0 - GameData.STATUS_EFFECTS["stone"]["value"]))

	var effective_accuracy: float = move.get("accuracy", 100)
	if actor_state.get("status", null) != null and actor_state["status"].get("effect") == "shadow":
		effective_accuracy = maxf(0.0, effective_accuracy - GameData.STATUS_EFFECTS["shadow"]["value"] * 100.0)

	var damage_result: Dictionary = calculate_damage(
		{ "atk": actor_state.get("atk", 0), "element": actor_state.get("element", "neutral"), "stage": actor_state.get("stage", 3) },
		{ "def": effective_def,              "element": target_state.get("element", "neutral"), "defending": target_state.get("defending", false) },
		{ "element": move.get("element", "neutral"), "power": move.get("power", 40), "accuracy": effective_accuracy }
	)

	if target_state.get("reflecting", false):
		if damage_result["hit"]:
			var new_self_hp: int = maxi(0, actor_state.get("hp", 0) - damage_result["damage"])
			actor_state["hp"] = new_self_hp
			target_state["reflecting"] = false
			if actor_label == "player":
				player.merge(actor_state, true)
				npc.merge(target_state, true)
			else:
				npc.merge(actor_state, true)
				player.merge(target_state, true)
			events.append({
				"attacker": actor_label, "action": "attack",
				"move_name": move["name"], "move_key": move_key,
				"damage": damage_result["damage"], "effectiveness": damage_result["effectiveness"],
				"hit": true, "reflected": true, "is_critical": damage_result["is_critical"],
				"target_hp": new_self_hp,
			})
		else:
			target_state["reflecting"] = false
			if actor_label == "player":
				npc.merge(target_state, true)
			else:
				player.merge(target_state, true)
			events.append({
				"attacker": actor_label, "action": "attack",
				"move_name": move["name"], "move_key": move_key,
				"damage": 0, "effectiveness": damage_result["effectiveness"],
				"hit": false, "target_hp": target_state.get("hp", 0),
			})
		return

	var new_target_hp: int = maxi(0, target_state.get("hp", 0) - damage_result["damage"])
	target_state["hp"] = new_target_hp
	if actor_label == "player":
		npc.merge(target_state, true)
	else:
		player.merge(target_state, true)

	var applied_status_name: Variant = null
	if damage_result["hit"] and move.get("can_apply_status", false) and randf() < GameData.STATUS_APPLY_CHANCE:
		var status: Variant = apply_status(move.get("element", "neutral"))
		if status != null:
			target_state["status"] = status
			if actor_label == "player":
				npc.merge(target_state, true)
			else:
				player.merge(target_state, true)
			applied_status_name = GameData.STATUS_EFFECTS[status["effect"]]["name"]

	events.append({
		"attacker":       actor_label,
		"action":         "attack",
		"move_name":      move["name"],
		"move_key":       move_key,
		"damage":         damage_result["damage"],
		"effectiveness":  damage_result["effectiveness"],
		"hit":            damage_result["hit"],
		"is_critical":    damage_result["is_critical"],
		"target_hp":      new_target_hp,
		"applied_status": applied_status_name,
	})
