class_name SemanticEventPayload
extends RefCounted

## Typed payload for cross-system semantic events.

var event_id: StringName = &""
var channel: StringName = &""
var subject_id: StringName = &""
var data: Dictionary = {}
var durable_state: bool = false
var presentation_only: bool = false
var emitted_after_commit: bool = false


func configure(
		payload_event_id: StringName,
		payload_channel: StringName,
		payload_subject_id: StringName,
		payload_data: Dictionary,
		is_durable_state: bool,
		is_presentation_only: bool,
		is_emitted_after_commit: bool
) -> SemanticEventPayload:
	event_id = payload_event_id
	channel = payload_channel
	subject_id = payload_subject_id
	data = payload_data.duplicate(true)
	durable_state = is_durable_state
	presentation_only = is_presentation_only
	emitted_after_commit = is_emitted_after_commit
	return self
