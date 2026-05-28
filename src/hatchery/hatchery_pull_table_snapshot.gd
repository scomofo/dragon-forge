class_name HatcheryPullTableSnapshot
extends RefCounted

## Detached runtime copy of authored Hatchery pull table values.
## It intentionally stores scalar/dictionary data only, not Resource references.

var pull_id: StringName
var scrap_cost: int = 0
var shiny_rate_basis_points: int = 0
var required_element_ids: Array[StringName] = []
var rarity_weights: Dictionary = {}
var rarity_xp_multipliers: Dictionary = {}
var element_weights: Dictionary = {}
var element_rarities: Dictionary = {}
var rare_element_id: StringName
var rare_pity_threshold: int = 0
var element_soft_pity_onset: int = 0
var element_soft_pity_guaranteed: int = 0
var tie_break_priority: Array[StringName] = []


func has_standard_element(element_id: StringName) -> bool:
	return element_weights.has(element_id)
