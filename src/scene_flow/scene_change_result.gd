class_name SceneChangeResult
extends RefCounted

## Named result returned by SceneFlowService registration and transition calls.

var success: bool = false
var reason: StringName = &""
var screen_id: StringName = &""
var previous_screen_id: StringName = &""
var message: String = ""
var screen: Node = null


func configure(
		is_success: bool,
		result_reason: StringName,
		target_screen_id: StringName,
		source_screen_id: StringName = &"",
		result_message: String = "",
		result_screen: Node = null
) -> SceneChangeResult:
	success = is_success
	reason = result_reason
	screen_id = target_screen_id
	previous_screen_id = source_screen_id
	message = result_message
	screen = result_screen
	return self
