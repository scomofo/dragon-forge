extends RefCounted
class_name HatcheryEngine

const GameData = preload("res://scripts/sim/game_data.gd")

static func roll_rarity(pity_counter: int) -> Dictionary:
	if pity_counter >= GameData.PITY_THRESHOLD - 1:
		var rare_and_above: Array = []
		for tier in GameData.RARITY_TIERS:
			if tier["name"] == "Rare" or tier["name"] == "Exotic":
				rare_and_above.append(tier)
		var total_chance: float = 0.0
		for tier in rare_and_above:
			total_chance += tier["chance"]
		var roll: float = randf() * total_chance
		for tier in rare_and_above:
			roll -= tier["chance"]
			if roll <= 0.0:
				return tier
		return rare_and_above[rare_and_above.size() - 1]

	var roll: float = randf()
	for tier in GameData.RARITY_TIERS:
		roll -= tier["chance"]
		if roll <= 0.0:
			return tier
	return GameData.RARITY_TIERS[GameData.RARITY_TIERS.size() - 1]

static func roll_element(rarity_tier: Dictionary) -> String:
	var elements: Array = rarity_tier.get("elements", ["fire"])
	return elements[randi() % elements.size()]

static func roll_shiny(guaranteed_shiny: bool) -> bool:
	if guaranteed_shiny:
		return true
	return randf() < GameData.SHINY_CHANCE

static func execute_pull(pity_counter: int) -> Dictionary:
	var rarity_tier: Dictionary = roll_rarity(pity_counter)
	var element:     String     = roll_element(rarity_tier)
	var shiny:       bool       = roll_shiny(rarity_tier.get("guaranteed_shiny", false))

	var is_rare_plus: bool = rarity_tier["name"] == "Rare" or rarity_tier["name"] == "Exotic"
	var new_pity:     int  = 0 if is_rare_plus else pity_counter + 1

	return {
		"element":           element,
		"rarity_name":       rarity_tier["name"],
		"rarity_multiplier": rarity_tier["multiplier"],
		"shiny":             shiny,
		"new_pity_counter":  new_pity,
	}

static func apply_pull_result(save: Dictionary, pull: Dictionary) -> Dictionary:
	var new_save: Dictionary = save.duplicate(true)
	var dragon:   Dictionary = new_save["dragons"][pull["element"]]
	var is_new:   bool       = false
	var xp_gained: int       = 0

	if not dragon.get("owned", false):
		dragon["owned"] = true
		if pull.get("shiny", false):
			dragon["shiny"] = true
		is_new = true
	else:
		xp_gained = 50 * pull.get("rarity_multiplier", 1)
		dragon["xp"] += xp_gained
		var xp_per_level: int = 100
		while dragon["xp"] >= xp_per_level:
			dragon["xp"]    -= xp_per_level
			dragon["level"] += 1
		if pull.get("shiny", false) and not dragon.get("shiny", false):
			dragon["shiny"] = true

	new_save["pity_counter"] = pull.get("new_pity_counter", 0)

	return { "save": new_save, "is_new": is_new, "xp_gained": xp_gained }
