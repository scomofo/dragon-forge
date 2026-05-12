extends RefCounted
class_name DragonProgression

const DragonData = preload("res://scripts/sim/dragon_data.gd")

static func create_profile(starting_dragon_id: String) -> Dictionary:
	var dragon_def: Dictionary = DragonData.DRAGONS.get(starting_dragon_id, {})
	var first_move: String = ""
	if dragon_def.has("move_keys") and dragon_def["move_keys"].size() > 0:
		first_move = dragon_def["move_keys"][0]

	var techniques: Array = []
	if first_move != "":
		techniques = [first_move]

	return {
		"dragon_id": starting_dragon_id,
		"dragon_levels": { starting_dragon_id: 1 },
		"dragon_xp": { starting_dragon_id: 0 },
		"dragon_techniques": { starting_dragon_id: techniques.duplicate() },
		"dragon_loadouts": { starting_dragon_id: techniques.duplicate() },
		"data_scraps": 320,
		"system_credits": 0,
		"known_techniques": techniques.duplicate(),
		"active_techniques": techniques.duplicate(),
		"key_items": [],
		"mission_flags": [],
		"captains_log_fragments": [],
		"equipped_anvil_relics": [],
		"hatchery_state": {
			"opened": false,
			"owned_dragons": [starting_dragon_id],
			"visit_count": 0,
			"last_ring": "",
			"pity_counter": 0,
		},
		"bestiary_seen": {},
		"bestiary_defeated": {},
		"singularity_defeated": [],
	}

static func get_hatchery_state(save: Dictionary) -> Dictionary:
	return save.get("hatchery_state", {
		"opened": false,
		"owned_dragons": [],
		"visit_count": 0,
		"last_ring": "",
		"pity_counter": 0,
	})

static func get_dragon_level(save: Dictionary, dragon_id: String) -> int:
	var levels: Dictionary = save.get("dragon_levels", {})
	return levels.get(dragon_id, 1)

static func get_active_techniques(save: Dictionary) -> Array:
	return save.get("active_techniques", [])

static func award_dragon_xp(save: Dictionary, xp_amount: int) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	var dragon_id: String = result.get("dragon_id", "")
	if dragon_id == "":
		return result

	var xp_map: Dictionary = result.get("dragon_xp", {}).duplicate()
	var level_map: Dictionary = result.get("dragon_levels", {}).duplicate()

	var current_xp: int = int(xp_map.get(dragon_id, 0)) + xp_amount
	var current_level: int = int(level_map.get(dragon_id, 1))

	while current_level < 100:
		var needed: int = xp_to_next_level(current_level)
		if current_xp >= needed:
			current_xp -= needed
			current_level += 1
		else:
			break

	if current_level >= 100:
		current_xp = 0
	xp_map[dragon_id] = current_xp
	level_map[dragon_id] = current_level
	result["dragon_xp"] = xp_map
	result["dragon_levels"] = level_map
	return result

static func award_scraps(save: Dictionary, amount: int) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	result["data_scraps"] = int(result.get("data_scraps", 0)) + amount
	return result

static func record_enemy_defeated(save: Dictionary, npc_id: String) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	var defeated: Dictionary = result.get("bestiary_defeated", {}).duplicate()
	defeated[npc_id] = int(defeated.get(npc_id, 0)) + 1
	result["bestiary_defeated"] = defeated
	return result

static func set_mission_flag(save: Dictionary, flag: String) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	var flags: Array = result.get("mission_flags", []).duplicate()
	if not flags.has(flag):
		flags.append(flag)
	result["mission_flags"] = flags
	return result

static func grant_key_item(save: Dictionary, item_id: String) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	var items: Array = result.get("key_items", []).duplicate()
	if not items.has(item_id):
		items.append(item_id)
	result["key_items"] = items
	return result

static func open_hatchery_ring(save: Dictionary) -> Dictionary:
	var result: Dictionary = save.duplicate(true)
	var hatchery: Dictionary = result.get("hatchery_state", {}).duplicate(true)
	hatchery["opened"] = true
	hatchery["visit_count"] = int(hatchery.get("visit_count", 0)) + 1
	hatchery["pity_counter"] = int(hatchery.get("pity_counter", 0)) + 1
	result["hatchery_state"] = hatchery
	return result

static func xp_to_next_level(_level: int) -> int:
	return 100
