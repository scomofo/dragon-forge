extends RefCounted
class_name FusionEngine

const ALCHEMY: Dictionary = {
	"fire_fire":     "fire",
	"ice_ice":       "ice",
	"storm_storm":   "storm",
	"stone_stone":   "stone",
	"venom_venom":   "venom",
	"shadow_shadow": "shadow",
	"fire_ice":      "storm",
	"fire_storm":    "fire",
	"fire_stone":    "stone",
	"fire_venom":    "shadow",
	"fire_shadow":   "fire",
	"ice_storm":     "ice",
	"ice_stone":     "stone",
	"ice_venom":     "venom",
	"ice_shadow":    "shadow",
	"stone_storm":   "storm",
	"storm_venom":   "venom",
	"shadow_storm":  "shadow",
	"stone_venom":   "venom",
	"shadow_stone":  "stone",
	"shadow_venom":  "shadow",
}

const OPPOSING_PAIRS: Array = [
	["fire",  "ice"],
	["storm", "stone"],
	["venom", "shadow"],
]

static func get_fusion_element(element_a: String, element_b: String) -> String:
	var key: String = _sorted_key(element_a, element_b)
	return ALCHEMY.get(key, element_a)

static func get_stability_tier(element_a: String, element_b: String) -> String:
	if element_a == element_b:
		return "stable"
	for pair in OPPOSING_PAIRS:
		if (element_a == pair[0] and element_b == pair[1]) or \
		   (element_a == pair[1] and element_b == pair[0]):
			return "unstable"
	return "normal"

static func calculate_fusion_stats(stats_a: Dictionary, stats_b: Dictionary, stability_tier: String) -> Dictionary:
	var avg := {
		"hp":  (stats_a.get("hp",  0) + stats_b.get("hp",  0)) / 2.0,
		"atk": (stats_a.get("atk", 0) + stats_b.get("atk", 0)) / 2.0,
		"def": (stats_a.get("def", 0) + stats_b.get("def", 0)) / 2.0,
		"spd": (stats_a.get("spd", 0) + stats_b.get("spd", 0)) / 2.0,
	}

	var fused := {
		"hp":  int(avg["hp"]  * 1.1),
		"atk": int(avg["atk"] * 1.1),
		"def": int(avg["def"] * 1.1),
		"spd": int(avg["spd"] * 1.1),
	}

	match stability_tier:
		"stable":
			fused["hp"]  = int(fused["hp"]  * 1.25)
			fused["atk"] = int(fused["atk"] * 1.25)
			fused["def"] = int(fused["def"] * 1.25)
			fused["spd"] = int(fused["spd"] * 1.25)
		"unstable":
			fused["hp"]  = int(fused["hp"]  * 0.8)
			fused["atk"] = int(fused["atk"] * 1.1)

	return fused

static func execute_fusion(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
	var element:          String     = get_fusion_element(parent_a.get("element", "fire"), parent_b.get("element", "fire"))
	var stability_tier:   String     = get_stability_tier(parent_a.get("element", "fire"), parent_b.get("element", "fire"))
	var fused_base_stats: Dictionary = calculate_fusion_stats(
		parent_a.get("stats", {}), parent_b.get("stats", {}), stability_tier)
	var shiny: bool = parent_a.get("shiny", false) or parent_b.get("shiny", false)

	var both_stage_iii: bool = parent_a.get("level", 0) >= 25 and parent_b.get("level", 0) >= 25
	var level: int = 50 if both_stage_iii else 1

	return {
		"element":          element,
		"stability_tier":   stability_tier,
		"fused_base_stats": fused_base_stats,
		"shiny":            shiny,
		"level":            level,
		"xp":               0,
		"parent_a_id":      parent_a.get("id", ""),
		"parent_b_id":      parent_b.get("id", ""),
	}

static func _sorted_key(a: String, b: String) -> String:
	var parts := [a, b]
	parts.sort()
	return "%s_%s" % [parts[0], parts[1]]
