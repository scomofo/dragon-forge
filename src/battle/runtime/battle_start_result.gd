class_name BattleStartResult
extends RefCounted

## Named result for BattleRuntimeController.start_battle().

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var session: BattleSession = null
