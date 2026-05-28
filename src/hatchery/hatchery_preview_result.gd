class_name HatcheryPreviewResult
extends RefCounted

## Named preview contract for Hatchery pull affordability and visible cost facts.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var pull_id: StringName = &""
var cost: int = 0
var current_scraps: int = 0
var balance_after: int = 0
var affordable: bool = false
var table_snapshot: HatcheryPullTableSnapshot = null
