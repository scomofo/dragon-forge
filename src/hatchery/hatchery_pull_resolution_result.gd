class_name HatcheryPullResolutionResult
extends RefCounted

## Pure resolver output for Hatchery rarity, pity, element, and shiny rolls.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var pull_id: StringName = &""
var natural_rarity: StringName = &""
var natural_element: StringName = &""
var final_rarity: StringName = &""
var final_element: StringName = &""
var shiny: bool = false
var pity_forced: bool = false
var element_soft_pity_forced: bool = false
var element_soft_pity_ramped: bool = false
var element_soft_pity_element: StringName = &""
var next_pity_counter: int = 0
var next_drought_counters: Dictionary = {}
var rarity_roll_basis_point: int = -1
var element_roll_basis_point: int = -1
var shiny_roll_basis_point: int = -1
var table_snapshot: HatcheryPullTableSnapshot = null


func fail(failure_reason: StringName, message: String) -> void:
	success = false
	reason = failure_reason
	error_message = message


func mark_success() -> void:
	success = true
	reason = &"ok"
	error_message = ""
