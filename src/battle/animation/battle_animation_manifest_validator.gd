class_name BattleAnimationManifestValidator
extends RefCounted

const BattleAnimationValidationResultScript = preload("res://src/battle/animation/battle_animation_validation_result.gd")


func validate(
		manifest: BattleAnimationManifest,
		battle_definition: BattleDefinition,
		move_definitions: Dictionary,
		production_lock: bool = true
) -> BattleAnimationValidationResult:
	var result := BattleAnimationValidationResultScript.new()
	if manifest == null:
		result.add_missing_clip_asset("manifest:<null>")
		return result

	result.manifest_id = manifest.manifest_id
	if battle_definition == null:
		result.add_missing_clip_asset("battle_definition:<null>")
		return result

	if battle_definition.animation_manifest_id != manifest.manifest_id:
		result.add_manifest_id_mismatch(manifest.manifest_id, battle_definition.animation_manifest_id)

	_validate_actor_moves(manifest, battle_definition.player_actor_animation_set_id, battle_definition.move_ids, move_definitions, production_lock, result)
	_validate_actor_moves(manifest, battle_definition.enemy_actor_animation_set_id, battle_definition.enemy_move_ids, move_definitions, production_lock, result)

	for actor_set_id in battle_definition.support_actor_animation_set_ids:
		_validate_actor_base_coverage(manifest, actor_set_id, result)
	for actor_set_id in battle_definition.boss_phase_animation_set_ids:
		_validate_actor_base_coverage(manifest, actor_set_id, result)

	return result


func _validate_actor_moves(
		manifest: BattleAnimationManifest,
		actor_set_id: StringName,
		move_ids: Array[StringName],
		move_definitions: Dictionary,
		production_lock: bool,
		result: BattleAnimationValidationResult
) -> void:
	if actor_set_id == &"":
		return

	var actor_set := manifest.find_actor_set(actor_set_id)
	if actor_set == null:
		result.add_missing_actor_set(actor_set_id)
		return

	_validate_actor_base_clips(manifest, actor_set, result)

	for move_id in move_ids:
		var move = move_definitions.get(move_id)
		if move == null:
			result.add_missing_move_binding(_binding_key(actor_set.actor_id, move_id))
			continue

		var binding := actor_set.find_binding_for_move(move.move_id, move.animation_action_id)
		if binding == null:
			result.add_missing_move_binding(_binding_key(actor_set.actor_id, move.move_id))
			continue

		_validate_binding(manifest, actor_set, move, binding, production_lock, result)


func _validate_actor_base_coverage(
		manifest: BattleAnimationManifest,
		actor_set_id: StringName,
		result: BattleAnimationValidationResult
) -> void:
	if actor_set_id == &"":
		return

	var actor_set := manifest.find_actor_set(actor_set_id)
	if actor_set == null:
		result.add_missing_actor_set(actor_set_id)
		return

	_validate_actor_base_clips(manifest, actor_set, result)


func _validate_actor_base_clips(
		manifest: BattleAnimationManifest,
		actor_set: BattleActorAnimationSet,
		result: BattleAnimationValidationResult
) -> void:
	var slots := actor_set.required_base_clip_slots()
	for slot_id in slots:
		var clip_id: StringName = slots[slot_id]
		if clip_id == &"":
			result.add_missing_base_clip(_binding_key(actor_set.actor_id, slot_id))
			continue
		_validate_clip(manifest, clip_id, result)


func _validate_binding(
		manifest: BattleAnimationManifest,
		actor_set: BattleActorAnimationSet,
		move: MoveDefinition,
		binding: BattleActionAnimationBinding,
		production_lock: bool,
		result: BattleAnimationValidationResult
) -> void:
	var key := _binding_key(actor_set.actor_id, move.move_id)
	if binding.action_class != move.required_animation_class:
		result.add_wrong_action_class(key)
	if production_lock and binding.is_placeholder():
		result.add_placeholder_binding(key)
	_validate_clip(manifest, binding.clip_id, result)
	_validate_clip(manifest, binding.vfx_clip_id, result)
	_validate_clip(manifest, binding.receive_clip_id, result)


func _validate_clip(
		manifest: BattleAnimationManifest,
		clip_id: StringName,
		result: BattleAnimationValidationResult
) -> void:
	if clip_id == &"":
		return

	var clip := manifest.find_clip(clip_id)
	if clip == null:
		result.add_missing_clip_asset("clip_id:%s" % clip_id)
		return

	if clip.asset_path.is_empty() or not FileAccess.file_exists(clip.asset_path):
		result.add_missing_clip_asset(clip.asset_path if not clip.asset_path.is_empty() else "clip_id:%s" % clip_id)
	if clip.playback_mode == &"frame_sequence":
		_validate_frame_sequence(clip, result)
	if not clip.has_preview_evidence():
		result.add_missing_preview(str(clip.clip_id))
	elif not FileAccess.file_exists(clip.preview_sheet_path):
		result.add_missing_preview(clip.preview_sheet_path)
	if not clip.has_runtime_capture_evidence():
		result.add_missing_runtime_capture(str(clip.clip_id))
	for capture_path in clip.runtime_capture_paths:
		if capture_path.is_empty() or not FileAccess.file_exists(capture_path):
			result.add_missing_runtime_capture(capture_path if not capture_path.is_empty() else str(clip.clip_id))


func _validate_frame_sequence(clip: BattleAnimationClip, result: BattleAnimationValidationResult) -> void:
	if clip.frame_paths.size() != clip.frame_count:
		result.add_missing_clip_asset("clip_id:%s:frame_count:%d actual:%d" % [clip.clip_id, clip.frame_count, clip.frame_paths.size()])
	for frame_path in clip.frame_paths:
		if frame_path.is_empty() or not FileAccess.file_exists(frame_path):
			result.add_missing_clip_asset(frame_path if not frame_path.is_empty() else "clip_id:%s:empty_frame_path" % clip.clip_id)


func _binding_key(actor_id: StringName, move_id: StringName) -> StringName:
	return StringName("%s:%s" % [actor_id, move_id])
