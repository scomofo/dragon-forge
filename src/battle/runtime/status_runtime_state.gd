class_name StatusRuntimeState
extends RefCounted

## Runtime-only status state owned by BattleSession combatants.

var status_id: StringName = &""
var duration_turns: int = 0


func copy() -> RefCounted:
	var status: RefCounted = get_script().new()
	status.status_id = status_id
	status.duration_turns = duration_turns
	return status
