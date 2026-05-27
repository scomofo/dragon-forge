class_name BattleActionResult
extends RefCounted

## Named result for BattleSession action submission.

var success: bool = false
var accepted: bool = false
var reason: StringName = &""
var error_message: String = ""
var state_before: StringName = &""
var state_after: StringName = &""
var action_id: StringName = &""
