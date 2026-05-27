class_name BattleStatusApplyResult
extends RefCounted

## Named result for deterministic status application.

var success: bool = true
var applied: bool = false
var status_id: StringName = &""
var reason: StringName = &"ok"
var error_message: String = ""
var roll: float = 0.0
var duration_turns: int = 0
