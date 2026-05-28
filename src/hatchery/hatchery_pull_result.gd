class_name HatcheryPullResult
extends RefCounted

## Named pull contract for Hatchery execution stories.
## Carries transaction, resolver, dragon creation, and duplicate XP outcome facts.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var pull_id: StringName = &""
var source_id: StringName = &""
var cost: int = 0
var balance_before: int = 0
var balance_after: int = 0
var element_id: StringName = &""
var rarity_id: StringName = &""
var shiny: bool = false
var dragon_id: StringName = &""
var duplicate: bool = false
var xp_awarded: int = 0
var shiny_upgraded: bool = false
var pity_forced: bool = false
var element_soft_pity_forced: bool = false
var rarity_roll_basis_point: int = -1
var element_roll_basis_point: int = -1
var shiny_roll_basis_point: int = -1
var next_pity_counter: int = 0
var next_drought_counters: Dictionary[StringName, int] = {}
var resolution_result: HatcheryPullResolutionResult = null
var creation_result: DragonCreationResult = null
var xp_result: XPApplyResult = null
var economy_result: EconomyResult = null
var save_commit_result: SaveCommitResult = null
var table_snapshot: HatcheryPullTableSnapshot = null
