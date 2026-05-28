class_name HatcheryPullResult
extends RefCounted

## Named pull contract for later Hatchery execution stories.
## This story defines the fields only; pull resolution and mutation happen later.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var pull_id: StringName = &""
var source_id: StringName = &""
var cost: int = 0
var element_id: StringName = &""
var rarity_id: StringName = &""
var shiny: bool = false
var duplicate: bool = false
var xp_awarded: int = 0
var pity_forced: bool = false
var element_soft_pity_forced: bool = false
var rarity_roll_basis_point: int = -1
var element_roll_basis_point: int = -1
var shiny_roll_basis_point: int = -1
var table_snapshot: HatcheryPullTableSnapshot = null
