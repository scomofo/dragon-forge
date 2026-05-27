class_name CombatantBattleState
extends RefCounted

## Runtime-only combatant state. Never store this in authored Resource files.

var combatant_id: StringName = &""
var dragon_id: StringName = &""
var element: StringName = &""
var current_hp: int = 0
var max_hp: int = 0
var base_defense: int = 0
var active_status: RefCounted = null
var pending_skip: StringName = &""


func clear_status() -> void:
	active_status = null
	pending_skip = &""
