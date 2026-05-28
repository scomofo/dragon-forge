class_name FocusNavigationContract
extends RefCounted

## Foundation navigation contract for required d-pad plus confirm/cancel flows.

const ROW_BEHAVIOR_STOP: StringName = &"stop"
const ROW_BEHAVIOR_WRAP: StringName = &"wrap"

const FLOW_CONTRACTS: Dictionary[StringName, Dictionary] = {
	&"hub": {
		"flow_id": &"hub",
		"actions": [&"ui_left", &"ui_right", &"ui_confirm", &"ui_cancel"],
		"row_behavior": ROW_BEHAVIOR_WRAP,
		"hover_required": false,
	},
	&"shop": {
		"flow_id": &"shop",
		"actions": [&"ui_left", &"ui_right", &"ui_confirm", &"ui_cancel"],
		"row_behavior": ROW_BEHAVIOR_STOP,
		"hover_required": false,
	},
	&"campaign_map": {
		"flow_id": &"campaign_map",
		"actions": [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_confirm", &"ui_cancel", &"map_pan"],
		"row_behavior": ROW_BEHAVIOR_STOP,
		"hover_required": false,
	},
	&"battle_telegraph": {
		"flow_id": &"battle_telegraph",
		"actions": [&"ui_up", &"ui_down", &"ui_confirm", &"ui_cancel", &"battle_attack", &"battle_defend", &"battle_status", &"battle_consumable"],
		"row_behavior": ROW_BEHAVIOR_STOP,
		"hover_required": false,
	},
	&"crown": {
		"flow_id": &"crown",
		"actions": [&"ui_left", &"ui_right", &"ui_confirm", &"ui_cancel"],
		"row_behavior": ROW_BEHAVIOR_STOP,
		"hover_required": false,
	},
	&"terminals": {
		"flow_id": &"terminals",
		"actions": [&"ui_up", &"ui_down", &"ui_confirm", &"ui_cancel"],
		"row_behavior": ROW_BEHAVIOR_STOP,
		"hover_required": false,
	},
}


func has_flow_contract(flow_id: StringName) -> bool:
	return FLOW_CONTRACTS.has(flow_id)


func get_flow_contract(flow_id: StringName) -> Dictionary:
	return FLOW_CONTRACTS.get(flow_id, {}).duplicate(true)


func get_required_flow_ids() -> Array[StringName]:
	return FLOW_CONTRACTS.keys()


func move_row_focus(flow_id: StringName, current_index: int, item_count: int, direction: StringName) -> int:
	if item_count <= 0:
		return -1
	var clamped_index: int = clampi(current_index, 0, item_count - 1)
	var delta: int = _direction_delta(direction)
	if delta == 0:
		return clamped_index
	var next_index: int = clamped_index + delta
	var flow: Dictionary = get_flow_contract(flow_id)
	var row_behavior: StringName = flow.get("row_behavior", ROW_BEHAVIOR_STOP)
	if row_behavior == ROW_BEHAVIOR_WRAP:
		return posmod(next_index, item_count)
	return clampi(next_index, 0, item_count - 1)


func _direction_delta(direction: StringName) -> int:
	if direction == &"left" or direction == &"up":
		return -1
	if direction == &"right" or direction == &"down":
		return 1
	return 0
