class_name DragonValidationResult
extends RefCounted

## Named result for dragon save-load validation, repair, and conflict projection.
## Contains detached snapshots only; callers still own persistence and commit order.

var success: bool = true
var reason: StringName = &"ok"
var error_message: String = ""
var warnings: PackedStringArray = []
var discarded_dragon_ids: Array[StringName] = []
var repaired_dragon_ids: Array[StringName] = []
var selected_source: StringName = &""
var dragon: DragonRecord = null
var stats: DragonStats = null
