class_name SceneFlowService
extends Node

## Owns top-level screen transitions by stable screen ID.
## Instantiates and validates replacement screens before releasing the current one.

signal screen_change_started(result: RefCounted)
signal screen_changed(result: RefCounted)
signal screen_change_failed(result: RefCounted)

const SceneChangeResultResource = preload("res://src/scene_flow/scene_change_result.gd")

const REASON_SUCCESS: StringName = &"success"
const REASON_DUPLICATE_REGISTRATION: StringName = &"duplicate_registration"
const REASON_INVALID_REGISTRATION: StringName = &"invalid_registration"
const REASON_UNREGISTERED_SCREEN_ID: StringName = &"unregistered_screen_id"
const REASON_INSTANTIATION_FAILURE: StringName = &"instantiation_failure"
const REASON_SETUP_FAILURE: StringName = &"setup_failure"
const REASON_TRANSITION_IN_PROGRESS: StringName = &"transition_already_in_progress"
const REASON_FOCUS_RESTORATION_FAILURE: StringName = &"focus_restoration_failure"

var _screens_by_id: Dictionary[StringName, PackedScene] = {}
var _active_screen_id: StringName = &""
var _active_screen: Node = null
var _transition_in_progress: bool = false
var _input_router: Node = null


func set_input_router(input_router: Node) -> void:
	_input_router = input_router


func register_screen(screen_id: StringName, scene: PackedScene, required: bool = true) -> RefCounted:
	if screen_id == &"" or scene == null:
		return _result(
			false,
			REASON_INVALID_REGISTRATION,
			screen_id,
			"Screen registration requires a non-empty ID and PackedScene."
		)
	if _screens_by_id.has(screen_id):
		return _result(
			false,
			REASON_DUPLICATE_REGISTRATION,
			screen_id,
			"Screen ID '%s' is already registered." % screen_id
		)
	_screens_by_id[screen_id] = scene
	return _result(true, REASON_SUCCESS, screen_id, "Screen registered.", null, required)


func change_screen(screen_id: StringName, payload: Variant = null) -> RefCounted:
	if _transition_in_progress:
		return _emit_failure(_result(
			false,
			REASON_TRANSITION_IN_PROGRESS,
			screen_id,
			"Transition already in progress."
		))
	if not _screens_by_id.has(screen_id):
		return _emit_failure(_result(
			false,
			REASON_UNREGISTERED_SCREEN_ID,
			screen_id,
			"Screen ID '%s' is not registered." % screen_id
		))

	_transition_in_progress = true
	var started_result: RefCounted = _result(true, REASON_SUCCESS, screen_id, "Transition started.")
	screen_change_started.emit(started_result)

	var previous_screen: Node = _active_screen
	var previous_screen_id: StringName = _active_screen_id
	var next_screen: Node = _instantiate_screen(screen_id)
	if next_screen == null:
		_transition_in_progress = false
		return _emit_failure(_result(
			false,
			REASON_INSTANTIATION_FAILURE,
			screen_id,
			"PackedScene for '%s' did not instantiate a Node." % screen_id,
			null,
			false,
			previous_screen_id
		))

	add_child(next_screen)
	var setup_result: bool = _setup_screen(next_screen, payload)
	if not setup_result:
		_release_failed_candidate(next_screen)
		_transition_in_progress = false
		return _emit_failure(_result(
			false,
			REASON_SETUP_FAILURE,
			screen_id,
			"Screen '%s' rejected setup." % screen_id,
			null,
			false,
			previous_screen_id
		))

	if not _restore_focus_if_requested(next_screen):
		_release_failed_candidate(next_screen)
		_transition_in_progress = false
		return _emit_failure(_result(
			false,
			REASON_FOCUS_RESTORATION_FAILURE,
			screen_id,
			"Screen '%s' could not restore keyboard/gamepad focus." % screen_id,
			null,
			false,
			previous_screen_id
		))

	_active_screen = next_screen
	_active_screen_id = screen_id
	if previous_screen != null:
		previous_screen.queue_free()
	var success_result: RefCounted = _result(
		true,
		REASON_SUCCESS,
		screen_id,
		"Screen changed.",
		next_screen,
		false,
		previous_screen_id
	)
	_transition_in_progress = false
	screen_changed.emit(success_result)
	return success_result


func get_active_screen_id() -> StringName:
	return _active_screen_id


func get_active_screen() -> Node:
	return _active_screen


func has_registered_screen(screen_id: StringName) -> bool:
	return _screens_by_id.has(screen_id)


func _instantiate_screen(screen_id: StringName) -> Node:
	var scene: PackedScene = _screens_by_id[screen_id]
	if not scene.can_instantiate():
		return null
	var instance: Node = scene.instantiate()
	return instance


func _setup_screen(screen: Node, payload: Variant) -> bool:
	if not screen.has_method("setup_screen"):
		return true
	var result = screen.call("setup_screen", payload)
	if result is bool:
		return result
	return result != null


func _restore_focus_if_requested(screen: Node) -> bool:
	if _input_router == null or not screen.has_method("get_initial_focus_control"):
		return true
	var focus_target = screen.call("get_initial_focus_control")
	if focus_target == null:
		return true
	if not (focus_target is Control):
		return false
	if not _input_router.has_method("restore_focus_after_transition"):
		return false
	return bool(_input_router.call("restore_focus_after_transition", focus_target))


func _release_failed_candidate(screen: Node) -> void:
	if screen.get_parent() == self:
		remove_child(screen)
	screen.free()


func _emit_failure(result: RefCounted) -> RefCounted:
	screen_change_failed.emit(result)
	return result


func _result(
		success: bool,
		reason: StringName,
		screen_id: StringName,
		message: String = "",
		screen: Node = null,
		_unused_required: bool = false,
		previous_screen_id: StringName = &""
) -> RefCounted:
	return SceneChangeResultResource.new().configure(
		success,
		reason,
		screen_id,
		previous_screen_id,
		message,
		screen
	)
