class_name SemanticEventEmitResult
extends RefCounted

## Named result for semantic event emission attempts.

var success: bool = false
var reason: StringName = &""
var event_id: StringName = &""
var listener_count: int = 0
var payload: RefCounted = null


func configure(
		is_success: bool,
		result_reason: StringName,
		result_event_id: StringName,
		result_listener_count: int = 0,
		result_payload: RefCounted = null
) -> SemanticEventEmitResult:
	success = is_success
	reason = result_reason
	event_id = result_event_id
	listener_count = result_listener_count
	payload = result_payload
	return self
