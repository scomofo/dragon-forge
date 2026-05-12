extends RefCounted
class_name TacticalBattle

const DragonData := preload("res://scripts/sim/dragon_data.gd")
const CombatRules := preload("res://scripts/sim/combat_rules.gd")
const TechniqueData := preload("res://scripts/sim/technique_data.gd")

const EnemyData := {
	"firewall_sentinel": {
		"id": "firewall_sentinel",
		"name": "Firewall Sentinel",
		"element": "stone",
		"stats": { "hp": 190, "atk": 25, "def": 22, "spd": 10 },
		"level": 4,
		"code_integrity": 92,
		"reward_scraps": 90,
		"reward_xp": 80,
	},
	"corrupt_drake": {
		"id": "corrupt_drake",
		"name": "Corrupt Drake",
		"element": "glitch",
		"stats": { "hp": 135, "atk": 22, "def": 13, "spd": 18 },
		"level": 3,
		"code_integrity": 58,
		"reward_scraps": 65,
		"reward_xp": 62,
	},
	"search_index_daemon": {
		"id": "search_index_daemon",
		"name": "Search & Index Daemon",
		"element": "static",
		"stats": { "hp": 105, "atk": 18, "def": 10, "spd": 22 },
		"level": 2,
		"code_integrity": 88,
		"reward_scraps": 45,
		"reward_xp": 48,
		"reward_key_item": "indexer_shell_fragment",
		"reward_flag": "search_index_daemon_defeated",
	},
	"scrap_wraith": {
		"id": "scrap_wraith",
		"name": "Scrap-Wraith",
		"element": "shadow",
		"stats": { "hp": 155, "atk": 31, "def": 16, "spd": 24 },
		"level": 7,
		"code_integrity": 41,
		"reward_scraps": 120,
		"reward_xp": 125,
		"reward_key_item": "diagnostic_lens",
		"reward_flag": "stable_connection",
	},
	"lunar_mote": {
		"id": "lunar_mote",
		"name": "Lunar Mote",
		"element": "lunar",
		"stats": { "hp": 175, "atk": 28, "def": 14, "spd": 27 },
		"level": 6,
		"code_integrity": 73,
		"reward_scraps": 105,
		"reward_xp": 105,
	},
	"mirror_admin_projection": {
		"id": "mirror_admin_projection",
		"name": "Mirror Admin Projection",
		"element": "glitch",
		"stats": { "hp": 185, "atk": 29, "def": 18, "spd": 28 },
		"level": 6,
		"code_integrity": 100,
		"reward_scraps": 125,
		"reward_xp": 130,
		"reward_key_item": "parity_trace",
		"reward_flag": "mirror_admin_tundra_repelled",
	},
	"sys_admin": {
		"id": "sys_admin",
		"name": "The Sys-Admin",
		"element": "glitch",
		"stats": { "hp": 240, "atk": 34, "def": 22, "spd": 30 },
		"level": 9,
		"code_integrity": 100,
		"reward_scraps": 180,
		"reward_xp": 180,
		"reward_key_item": "rollback_trace",
		"reward_flag": "sys_admin_defeated_kernel",
	},
}

const INTENT_CYCLES := {
	"firewall_sentinel": [
		{ "kind": "attack", "label": "Crushing packet", "detail": "Incoming direct damage." },
		{ "kind": "guard", "label": "Hardens firewall", "detail": "Next strike is partially reduced." },
		{ "kind": "corrupt", "label": "Corrupting pulse", "detail": "Low damage, drains momentum." },
	],
	"corrupt_drake": [
		{ "kind": "attack", "label": "Checksum bite", "detail": "Snaps at the active dragon's weak side." },
		{ "kind": "corrupt", "label": "Malformed roar", "detail": "A glitchy pulse scrapes HP and focus." },
		{ "kind": "attack", "label": "Tail recursion", "detail": "Loops into a second physical strike." },
	],
	"search_index_daemon": [
		{ "kind": "attack", "label": "Indexing beam", "detail": "A thin white scan line marks the Root Dragon for deletion." },
		{ "kind": "guard", "label": "Catalog shell", "detail": "The daemon sorts incoming damage into a temporary shield." },
		{ "kind": "corrupt", "label": "Search cache flood", "detail": "Static clogs the HUD and drains Focus." },
	],
	"scrap_wraith": [
		{ "kind": "corrupt", "label": "Delete sigil", "detail": "Corrupts momentum and scrapes HP." },
		{ "kind": "attack", "label": "Serrated maintenance arm", "detail": "Fast metallic strike." },
		{ "kind": "guard", "label": "Phase through rack shadow", "detail": "Partially avoids the next hit." },
	],
	"lunar_mote": [
		{ "kind": "corrupt", "label": "Wrong-frequency hum", "detail": "A sour harmonic rattles the dragon's code." },
		{ "kind": "guard", "label": "Silver phase", "detail": "The mote slips between visible frames." },
		{ "kind": "attack", "label": "Crescent impact", "detail": "A fast arc of moonlit force." },
	],
	"mirror_admin_projection": [
		{ "kind": "corrupt", "label": "Parity scan", "detail": "Reads your current dragon form and prepares a mirrored counter." },
		{ "kind": "guard", "label": "QA shield", "detail": "Hardens into a clean-room validation shell." },
		{ "kind": "attack", "label": "Rollback lance", "detail": "A precise admin strike tries to undo your Tundra progress." },
		{ "kind": "corrupt", "label": "Closed ticket", "detail": "Attempts to mark the Great Buffer route as invalid." },
	],
	"sys_admin": [
		{ "kind": "corrupt", "label": "Rollback command", "detail": "Attempts to revert your last repair cycle." },
		{ "kind": "guard", "label": "Quarantine mirror", "detail": "A pristine shell reflects careless attacks." },
		{ "kind": "attack", "label": "Permission strike", "detail": "Executes a direct admin-level hit." },
		{ "kind": "corrupt", "label": "Closed-loop proof", "detail": "Argues the world must remain sealed." },
	],
}

const BASE_COMMANDS := [
	{
		"id": "quickClaw",
		"label": "Quick Claw",
		"description": "Fast reliable hit. Builds Focus.",
		"power": 42,
		"accuracy": 100,
		"focus_gain": 1,
		"stagger": 14,
		"role": "strike",
		"motion": "lunge",
		"vfx": "slash",
	},
	{
		"id": "elementalBreath",
		"label": "Magma Breath",
		"description": "Hard elemental blast. Lower Focus gain.",
		"power": 74,
		"accuracy": 92,
		"focus_gain": 0,
		"stagger": 20,
		"role": "purge",
		"motion": "blast",
		"vfx": "magma",
	},
	{
		"id": "tailCrash",
		"label": "Tail Crash",
		"description": "Risky heavy stagger. Big damage if it lands.",
		"power": 92,
		"accuracy": 78,
		"focus_gain": 1,
		"stagger": 42,
		"role": "break",
		"motion": "shockwave",
		"vfx": "shockwave",
	},
	{
		"id": "guard",
		"label": "Guard",
		"description": "Reduce incoming damage and bank Focus.",
		"power": 0,
		"accuracy": 100,
		"focus_gain": 2,
		"stagger": 0,
		"role": "guard",
		"motion": "guard",
		"vfx": "guard",
	},
	{
		"id": "overcharge",
		"label": "Overcharge",
		"description": "Spend 3 Focus for a massive burst.",
		"power": 116,
		"accuracy": 90,
		"focus_gain": 0,
		"stagger": 34,
		"role": "burst",
		"motion": "blast",
		"vfx": "magma",
	},
]

static func get_battle_commands(_player_id: String = "fire", known_techniques: Array[String] = []) -> Array:
	var commands := BASE_COMMANDS.duplicate(true)
	var breath_names := {
		"fire": "Magma Breath",
		"ice": "Rime Breath",
		"storm": "Storm Breath",
		"stone": "Basalt Breath",
		"venom": "Venom Breath",
		"shadow": "Umbral Breath",
	}
	for command in commands:
		if command["id"] == "elementalBreath":
			command["label"] = breath_names.get(_player_id, "Elemental Breath")
	return commands + TechniqueData.get_known_commands(known_techniques)

static func create_battle(player_id: String = "fire", _known_techniques: Array = [], enemy_id: String = "firewall_sentinel", player_level: int = 1) -> Dictionary:
	var player: Dictionary = DragonData.DRAGONS[player_id]
	var player_stats := DragonData.calculate_stats(player, player_level, false)
	var enemy: Dictionary = EnemyData.get(enemy_id, EnemyData["firewall_sentinel"])
	var first_intent := choose_intent(enemy["id"], 1)
	return {
		"player_id": player_id,
		"player_level": player_level,
		"known_techniques": _typed_string_array(_known_techniques),
		"player_name": player["name"],
		"enemy_id": enemy["id"],
		"enemy_name": enemy["name"],
		"turn": 1,
		"status": "active",
		"focus": 0,
		"enemy_stagger": 0,
		"player_hp": player_stats["hp"],
		"player_max_hp": player_stats["hp"],
		"enemy_hp": enemy["stats"]["hp"],
		"enemy_max_hp": enemy["stats"]["hp"],
		"enemy_intent": first_intent,
		"log": ["%s blocks the sector. Intent: %s." % [enemy["name"], first_intent["label"]]],
	}

static func take_action(battle: Dictionary, action: String, roll: float = 0.0) -> Dictionary:
	if battle["status"] != "active":
		return battle

	var next := battle.duplicate(true)
	var player: Dictionary = DragonData.DRAGONS[next["player_id"]]
	var player_stats := DragonData.calculate_stats(player, int(next.get("player_level", 1)), false)
	var enemy: Dictionary = EnemyData[next["enemy_id"]]
	var turn_log: Array[String] = []
	var focus: int = next["focus"]
	var enemy_stagger: int = next.get("enemy_stagger", 0)
	var enemy_hp: int = next["enemy_hp"]
	var player_hp: int = next["player_hp"]
	var response_role: String = "guard" if action == "guard" else ""

	if action == "overcharge" and focus < 3:
		focus += 1
		turn_log.append("The forge core sputters: not enough Focus. Felix reroutes the surge.")
	elif action == "guard":
		focus = mini(3, focus + 2)
		turn_log.append("%s guards and banks Focus." % next["player_name"])
	else:
		var command := get_command(action, next["player_id"], next["known_techniques"])
		response_role = command.get("role", "strike")
		var stagger_gain: int = int(command.get("stagger", 10))
		var counter: Dictionary = _intent_counter(next["enemy_intent"], response_role)
		var damage_multiplier := 1.0
		if counter["success"]:
			stagger_gain += counter["stagger"]
			damage_multiplier = counter["damage_multiplier"]
			focus = mini(3, focus + counter["focus"])
			turn_log.append(counter["line"])
		if next["enemy_intent"]["kind"] == "guard":
			stagger_gain += 18
		enemy_stagger = mini(100, enemy_stagger + stagger_gain)
		var stagger_break: bool = enemy_stagger >= 100
		var attack := CombatRules.resolve_attack(
			{
				"element": player["element"],
				"atk": player_stats["atk"],
				"stage": DragonData.get_stage_for_level(int(next.get("player_level", 1))),
			},
			{
				"element": enemy["element"],
				"def": enemy["stats"]["def"],
				"hp": enemy_hp,
			},
			{
				"element": player["element"],
				"power": command["power"],
				"accuracy": command["accuracy"],
			},
			roll
		)
		var damage: int = floori(attack["damage"] * damage_multiplier)
		if next["enemy_intent"]["kind"] == "guard" and action != "overcharge" and not stagger_break:
			damage = floori(damage * 0.6)
		if stagger_break:
			damage = ceili(damage * 1.35)
			focus = mini(3, focus + 1)
			enemy_stagger = 35
		enemy_hp = maxi(0, enemy_hp - damage)
		focus = 0 if action == "overcharge" else mini(3, focus + command["focus_gain"] + (1 if attack["effectiveness"] > 1.0 else 0))
		if action == "overcharge":
			turn_log.append("%s releases an Overcharge for %d damage." % [next["player_name"], damage])
		else:
			turn_log.append("%s uses %s for %d damage." % [next["player_name"], command["label"], damage])
		if stagger_break:
			turn_log.append("Stagger break: %s reels, loses guard, and exposes a critical window." % next["enemy_name"])

	if enemy_hp <= 0:
		next["status"] = "victory"
		next["focus"] = focus
		next["enemy_stagger"] = enemy_stagger
		next["enemy_hp"] = enemy_hp
		next["log"] = _tail(next["log"], 3) + turn_log + ["%s fractures into DataScraps." % next["enemy_name"]]
		return next

	var incoming := resolve_enemy_intent_damage(next["enemy_intent"], enemy["stats"]["atk"], action == "guard", response_role)
	player_hp = maxi(0, player_hp - incoming["damage"])
	turn_log.append(incoming["line"])
	if action == "guard" and next["enemy_intent"]["kind"] == "attack":
		focus = mini(3, focus + 1)
		enemy_stagger = mini(100, enemy_stagger + 16)
		turn_log.append("Perfect Guard: impact timing banks extra Focus and shakes the enemy stance.")

	if player_hp <= 0:
		next["status"] = "defeat"
		next["focus"] = focus
		next["enemy_stagger"] = enemy_stagger
		next["player_hp"] = player_hp
		next["enemy_hp"] = enemy_hp
		next["log"] = _tail(next["log"], 3) + turn_log + ["Felix pulls your guardian out before the signal collapses."]
		return next

	var next_turn: int = next["turn"] + 1
	var next_intent := choose_intent(next["enemy_id"], next_turn)
	next["turn"] = next_turn
	next["focus"] = focus
	next["enemy_stagger"] = maxi(0, enemy_stagger - 8)
	next["player_hp"] = player_hp
	next["enemy_hp"] = enemy_hp
	next["enemy_intent"] = next_intent
	next["log"] = _tail(next["log"], 2) + turn_log + ["Next intent: %s." % next_intent["label"]]
	return next

static func choose_intent(enemy_id: String, turn: int) -> Dictionary:
	var cycle: Array = INTENT_CYCLES.get(enemy_id, INTENT_CYCLES["firewall_sentinel"])
	return cycle[(turn - 1) % cycle.size()].duplicate(true)

static func get_command(action: String, player_id: String, known_techniques: Array) -> Dictionary:
	for command in get_battle_commands(player_id, known_techniques):
		if command["id"] == action:
			return command
	return BASE_COMMANDS[0]

static func resolve_enemy_intent_damage(intent: Dictionary, enemy_atk: int, guarded: bool, response_role: String = "") -> Dictionary:
	var base_damage: int = ceili(enemy_atk * 0.55) if intent["kind"] == "corrupt" else (0 if intent["kind"] == "guard" else enemy_atk)
	var damage: int = floori(base_damage * 0.4) if guarded else base_damage

	if intent["kind"] == "guard":
		return { "damage": 0, "line": "The enemy reinforces its shell instead of attacking." }
	if intent["kind"] == "corrupt":
		if response_role == "purge" or response_role == "shadow":
			damage = floori(damage * 0.45)
			return { "damage": damage, "line": "Clean counter: the corrupting pulse is tuned down to %d damage." % damage }
		return { "damage": damage, "line": "A corrupting pulse leaks through for %d damage." % damage }
	if response_role == "strike" and not guarded:
		damage = floori(damage * 0.75)
		return { "damage": damage, "line": "Fast counter: the incoming hit is clipped down to %d damage." % damage }
	return { "damage": damage, "line": "The enemy hits for %d damage." % damage }

static func get_intent_counter_hint(intent: Dictionary) -> String:
	match intent.get("kind", "attack"):
		"attack":
			return "Counter: Guard for Perfect Guard, or Strike to clip damage."
		"guard":
			return "Counter: Break techniques build heavy Stagger through guard."
		"corrupt":
			return "Counter: Purge or Shadow techniques tune down corruption."
		_:
			return "Counter: read the intent and answer with the right technique role."

static func _intent_counter(intent: Dictionary, response_role: String) -> Dictionary:
	var kind: String = intent.get("kind", "attack")
	if kind == "guard" and response_role == "break":
		return {
			"success": true,
			"stagger": 34,
			"focus": 0,
			"damage_multiplier": 1.12,
			"line": "Counter read: a Break technique hammers through the guarded stance.",
		}
	if kind == "corrupt" and (response_role == "purge" or response_role == "shadow"):
		return {
			"success": true,
			"stagger": 10,
			"focus": 1,
			"damage_multiplier": 1.1,
			"line": "Counter read: the hostile frequency is answered cleanly.",
		}
	if kind == "attack" and response_role == "strike":
		return {
			"success": true,
			"stagger": 8,
			"focus": 0,
			"damage_multiplier": 1.08,
			"line": "Counter read: the strike catches the wind-up.",
		}
	return { "success": false, "stagger": 0, "focus": 0, "damage_multiplier": 1.0, "line": "" }

static func get_enemy(enemy_id: String) -> Dictionary:
	return EnemyData.get(enemy_id, EnemyData["firewall_sentinel"]).duplicate(true)

static func get_enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for enemy_id in EnemyData.keys():
		ids.append(str(enemy_id))
	return ids

static func get_victory_reward(enemy_id: String) -> Dictionary:
	var enemy := get_enemy(enemy_id)
	return {
		"scraps": enemy.get("reward_scraps", 0),
		"xp": enemy.get("reward_xp", 0),
		"key_item": enemy.get("reward_key_item", ""),
		"flag": enemy.get("reward_flag", ""),
	}

static func _typed_string_array(values: Array) -> Array[String]:
	var typed: Array[String] = []
	for value in values:
		typed.append(str(value))
	return typed

static func _tail(values: Array, count: int) -> Array:
	var start_index := maxi(0, values.size() - count)
	return values.slice(start_index, values.size())
