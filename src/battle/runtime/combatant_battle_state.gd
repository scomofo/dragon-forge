class_name CombatantBattleState
extends RefCounted

## Runtime-only combatant state. Never store this in authored Resource files.

var combatant_id: StringName = &""
var dragon_id: StringName = &""
var element: StringName = &""
var current_hp: int = 0
var max_hp: int = 0
var base_defense: int = 0
var active_status: StatusRuntimeState = null
var pending_skip: StringName = &""
var defend_cooldown_turns: int = 0


## Clears the active status slot and any pending status-driven TELEGRAPH skip.
func clear_status() -> void:
	active_status = null
	pending_skip = &""
