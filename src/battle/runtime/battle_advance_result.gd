class_name BattleAdvanceResult
extends RefCounted

## Named result for BattleSession phase advancement.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var state_before: StringName = &""
var state_after: StringName = &""
var completed: bool = false
var payload: BattleEndedPayload = null
var delta: BattleDurableDelta = null
var turn_payload: TurnResolvedPayload = null
