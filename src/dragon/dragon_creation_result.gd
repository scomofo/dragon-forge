class_name DragonCreationResult
extends RefCounted

## Named result for source-specific dragon creation helpers.
## Contains staged-state facts and detached snapshots only; callers still commit through SaveService.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var source_id: StringName = &""
var dragon_id: StringName = &""
var element: StringName = &""
var primary_id: StringName = &""
var secondary_id: StringName = &""
var created: bool = false
var already_present: bool = false
var dragon: DragonRecord = null ## Detached snapshot. Mutating it does not mutate the staged save.
