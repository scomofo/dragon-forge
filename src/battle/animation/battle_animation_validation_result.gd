class_name BattleAnimationValidationResult
extends RefCounted

var ok: bool = true
var manifest_id: StringName
var manifest_id_mismatches: PackedStringArray = []
var missing_actor_sets: Array[StringName] = []
var missing_base_clips: Array[StringName] = []
var missing_move_bindings: Array[StringName] = []
var wrong_action_class_bindings: Array[StringName] = []
var placeholder_bindings: Array[StringName] = []
var missing_clip_assets: PackedStringArray = []
var missing_preview_evidence: PackedStringArray = []
var missing_runtime_capture_evidence: PackedStringArray = []
var accessibility_warnings: PackedStringArray = []


func fail() -> void:
	ok = false


func add_manifest_id_mismatch(expected_manifest_id: StringName, actual_manifest_id: StringName) -> void:
	var message := "expected:%s actual:%s" % [expected_manifest_id, actual_manifest_id]
	if not manifest_id_mismatches.has(message):
		manifest_id_mismatches.append(message)
	fail()


func add_missing_actor_set(actor_set_id: StringName) -> void:
	if not missing_actor_sets.has(actor_set_id):
		missing_actor_sets.append(actor_set_id)
	fail()


func add_missing_base_clip(base_clip_key: StringName) -> void:
	if not missing_base_clips.has(base_clip_key):
		missing_base_clips.append(base_clip_key)
	fail()


func add_missing_move_binding(binding_key: StringName) -> void:
	if not missing_move_bindings.has(binding_key):
		missing_move_bindings.append(binding_key)
	fail()


func add_wrong_action_class(binding_key: StringName) -> void:
	if not wrong_action_class_bindings.has(binding_key):
		wrong_action_class_bindings.append(binding_key)
	fail()


func add_placeholder_binding(binding_key: StringName) -> void:
	if not placeholder_bindings.has(binding_key):
		placeholder_bindings.append(binding_key)
	fail()


func add_missing_clip_asset(path: String) -> void:
	if not missing_clip_assets.has(path):
		missing_clip_assets.append(path)
	fail()


func add_missing_preview(path_or_clip_id: String) -> void:
	if not missing_preview_evidence.has(path_or_clip_id):
		missing_preview_evidence.append(path_or_clip_id)
	fail()


func add_missing_runtime_capture(path_or_clip_id: String) -> void:
	if not missing_runtime_capture_evidence.has(path_or_clip_id):
		missing_runtime_capture_evidence.append(path_or_clip_id)
	fail()


func add_accessibility_warning(message: String) -> void:
	if not accessibility_warnings.has(message):
		accessibility_warnings.append(message)
