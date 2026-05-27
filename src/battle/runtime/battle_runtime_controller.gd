class_name BattleRuntimeController
extends Node

signal battle_completed(payload: BattleEndedPayload, delta: BattleDurableDelta)

const BattleSessionResource = preload("res://src/battle/runtime/battle_session.gd")
const BattleStartResultResource = preload("res://src/battle/runtime/battle_start_result.gd")
const BattleAdvanceResultResource = preload("res://src/battle/runtime/battle_advance_result.gd")
const BattleActionResultResource = preload("res://src/battle/runtime/battle_action_result.gd")

## Scene-owned Battle runtime controller. It owns one RefCounted BattleSession.

var last_completed_payload: BattleEndedPayload = null
var last_completed_delta: BattleDurableDelta = null
var _session: BattleSession = null


## Starts a new runtime-only battle session from read-only setup data.
func start_battle(setup: BattleSetupPayload) -> BattleStartResult:
	var result: BattleStartResult = BattleStartResultResource.new()
	if _session != null and _session.state != BattleRuntimeState.COMPLETE:
		result.success = false
		result.reason = &"session_already_active"
		result.error_message = "BattleRuntimeController already owns an active session."
		result.session = _session
		return result

	_session = BattleSessionResource.new()
	_session.configure(setup)
	last_completed_payload = null
	last_completed_delta = null

	result.success = true
	result.reason = &"ok"
	result.session = _session
	return result


## Submits a gameplay action to the active session.
func submit_action(action: BattleAction) -> BattleActionResult:
	if _session == null:
		var result: BattleActionResult = BattleActionResultResource.new()
		result.success = false
		result.accepted = false
		result.reason = &"missing_session"
		result.error_message = "BattleRuntimeController has no active session."
		return result
	return _session.submit_action(action)


## Advances the active session and emits battle_completed once on completion.
func advance() -> BattleAdvanceResult:
	if _session == null:
		var missing: BattleAdvanceResult = BattleAdvanceResultResource.new()
		missing.success = false
		missing.reason = &"missing_session"
		missing.error_message = "BattleRuntimeController has no active session."
		return missing

	var result: BattleAdvanceResult = _session.advance()
	_emit_completion_if_ready()
	return result


func get_state() -> StringName:
	return _session.state if _session != null else BattleRuntimeState.COMPLETE


func get_session() -> BattleSession:
	return _session


func _emit_completion_if_ready() -> void:
	if not _session.consume_completion_event():
		return
	last_completed_payload = _session.last_completed_payload
	last_completed_delta = _session.last_completed_delta
	battle_completed.emit(last_completed_payload, last_completed_delta)
