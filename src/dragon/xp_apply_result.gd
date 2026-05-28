class_name XPApplyResult
extends RefCounted

## Named result for staged XP application.
## Contains only staged-state facts and pending events; it does not publish signals.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var dragon_id: StringName = &""
var element: StringName = &""
var source_id: StringName = &""
var xp_requested: int = 0
var xp_awarded: int = 0
var levels_gained: int = 0
var xp_remainder: int = 0
var charges_consumed: int = 0
var shiny_requested: bool = false
var shiny_upgraded: bool = false
var shiny: bool = false
var stats: DragonStats = null
var pending_events: Array[DragonProgressionEvent] = []
