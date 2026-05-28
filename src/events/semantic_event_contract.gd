class_name SemanticEventContract
extends Node

## Shared semantic event contract harness.
## It defines stable event examples and enforces commit-before-durable-event ordering.

signal presentation_event(payload: RefCounted)
signal committed_state_event(payload: RefCounted)

const SemanticEventPayloadResource = preload("res://src/events/semantic_event_payload.gd")
const SemanticEventEmitResultResource = preload("res://src/events/semantic_event_emit_result.gd")

const CHANNEL_COMMITTED_STATE: StringName = &"committed_state"
const CHANNEL_PRESENTATION: StringName = &"presentation"

const EVENT_DEFINITIONS: Dictionary[StringName, Dictionary] = {
	&"save_committed": {
		"event_id": &"save_committed",
		"channel": CHANNEL_COMMITTED_STATE,
		"owner": &"save",
		"payload": &"SaveCommitResult",
	},
	&"screen_changed": {
		"event_id": &"screen_changed",
		"channel": CHANNEL_PRESENTATION,
		"owner": &"scene_flow",
		"payload": &"SceneChangeResult",
	},
	&"battle_ended": {
		"event_id": &"battle_ended",
		"channel": CHANNEL_PRESENTATION,
		"owner": &"battle",
		"payload": &"BattleEndedPayload",
	},
	&"journal_entry_available": {
		"event_id": &"journal_entry_available",
		"channel": CHANNEL_COMMITTED_STATE,
		"owner": &"journal",
		"payload": &"JournalEntryPayload",
	},
	&"corruption_class_changed": {
		"event_id": &"corruption_class_changed",
		"channel": CHANNEL_COMMITTED_STATE,
		"owner": &"singularity",
		"payload": &"CorruptionClassPayload",
	},
	&"ending_resolved": {
		"event_id": &"ending_resolved",
		"channel": CHANNEL_COMMITTED_STATE,
		"owner": &"singularity",
		"payload": &"EndingResolvedPayload",
	},
}


func has_event_definition(event_id: StringName) -> bool:
	return EVENT_DEFINITIONS.has(event_id)


func get_event_definition(event_id: StringName) -> Dictionary:
	return EVENT_DEFINITIONS.get(event_id, {}).duplicate(true)


func emit_presentation_event(
		event_id: StringName,
		subject_id: StringName = &"",
		data: Dictionary = {}
) -> RefCounted:
	var validation_failure: RefCounted = _validate_event(event_id, CHANNEL_PRESENTATION)
	if validation_failure != null:
		return validation_failure
	var payload: RefCounted = SemanticEventPayloadResource.new().configure(
		event_id,
		CHANNEL_PRESENTATION,
		subject_id,
		data,
		false,
		true,
		false
	)
	var listener_count: int = _listener_count(presentation_event)
	presentation_event.emit(payload)
	return _result(true, &"emitted", event_id, listener_count, payload)


func emit_committed_state_event_after_commit(
		event_id: StringName,
		subject_id: StringName,
		data: Dictionary,
		commit_result: RefCounted
) -> RefCounted:
	var validation_failure: RefCounted = _validate_event(event_id, CHANNEL_COMMITTED_STATE)
	if validation_failure != null:
		return validation_failure
	if commit_result == null or not commit_result.get("success"):
		return _result(false, &"commit_failed", event_id)
	var payload: RefCounted = SemanticEventPayloadResource.new().configure(
		event_id,
		CHANNEL_COMMITTED_STATE,
		subject_id,
		data,
		true,
		false,
		true
	)
	var listener_count: int = _listener_count(committed_state_event)
	committed_state_event.emit(payload)
	return _result(true, &"emitted_after_commit", event_id, listener_count, payload)


func _validate_event(event_id: StringName, expected_channel: StringName) -> RefCounted:
	if not has_event_definition(event_id):
		return _result(false, &"unknown_event", event_id)
	var definition: Dictionary = get_event_definition(event_id)
	if definition.get("channel", &"") != expected_channel:
		return _result(false, &"wrong_event_channel", event_id)
	return null


func _listener_count(signal_value: Signal) -> int:
	return signal_value.get_connections().size()


func _result(
		success: bool,
		reason: StringName,
		event_id: StringName,
		listener_count: int = 0,
		payload: RefCounted = null
) -> RefCounted:
	return SemanticEventEmitResultResource.new().configure(
		success,
		reason,
		event_id,
		listener_count,
		payload
	)
