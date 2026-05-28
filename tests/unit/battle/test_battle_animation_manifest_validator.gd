extends GutTest

const BattleAnimationClip = preload("res://src/battle/animation/battle_animation_clip.gd")
const BattleActionAnimationBinding = preload("res://src/battle/animation/battle_action_animation_binding.gd")
const BattleActorAnimationSet = preload("res://src/battle/animation/battle_actor_animation_set.gd")
const BattleAnimationManifest = preload("res://src/battle/animation/battle_animation_manifest.gd")
const BattleAnimationManifestValidator = preload("res://src/battle/animation/battle_animation_manifest_validator.gd")
const BattleDefinition = preload("res://src/battle/data/battle_definition.gd")
const MoveDefinition = preload("res://src/battle/data/move_definition.gd")


func test_valid_manifest_resolves_move_definition_bindings() -> void:
	var manifest := _make_manifest()
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_true(result.ok, "A complete manifest should validate for the battle's move definitions.")
	assert_eq(result.missing_move_bindings.size(), 0)
	assert_eq(result.missing_clip_assets.size(), 0)


func test_missing_action_binding_fails_content_validation() -> void:
	var manifest := _make_manifest()
	manifest.actor_sets[0].action_bindings.clear()
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "A battle move without an actor binding must fail validation.")
	assert_true(result.missing_move_bindings.has(&"root_wyrmling:root_spark"))


func test_wrong_action_class_fails_content_validation() -> void:
	var manifest := _make_manifest()
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"status_move"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "A status move must not bind to a basic attack clip.")
	assert_true(result.wrong_action_class_bindings.has(&"root_wyrmling:root_spark"))


func test_placeholder_binding_fails_production_lock() -> void:
	var manifest := _make_manifest()
	manifest.actor_sets[0].action_bindings[0].coverage_status = &"placeholder"
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "Production validation should reject placeholder animation bindings.")
	assert_true(result.placeholder_bindings.has(&"root_wyrmling:root_spark"))


func test_manifest_id_mismatch_is_reported_explicitly() -> void:
	var manifest := _make_manifest()
	var battle := _make_battle_definition()
	battle.animation_manifest_id = &"wrong_manifest"
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "A BattleDefinition should not validate against the wrong animation manifest.")
	assert_true(result.manifest_id_mismatches.has("expected:slice_combat actual:wrong_manifest"))


func test_missing_preview_file_fails_content_validation() -> void:
	var manifest := _make_manifest()
	manifest.global_clips[0].preview_sheet_path = "res://missing-preview-sheet.png"
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "Preview evidence must point to an existing file.")
	assert_true(result.missing_preview_evidence.has("res://missing-preview-sheet.png"))


func test_missing_required_base_clip_fails_content_validation() -> void:
	var manifest := _make_manifest()
	manifest.actor_sets[0].hurt_clip_id = &""
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "Battle-capable actors require base reaction coverage.")
	assert_true(result.missing_base_clips.has(&"root_wyrmling:hurt"))


func test_frame_sequence_missing_frame_fails_content_validation() -> void:
	var manifest := _make_manifest()
	manifest.global_clips[6].playback_mode = &"frame_sequence"
	manifest.global_clips[6].frame_count = 2
	manifest.global_clips[6].frame_paths = PackedStringArray(["res://project.godot", "res://missing-root-spark-frame.png"])
	var battle := _make_battle_definition()
	var moves := {
		&"root_spark": _make_move(&"root_spark", &"root_spark", &"basic_attack"),
	}

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_false(result.ok, "Frame sequence clips must validate every referenced frame.")
	assert_true(result.missing_clip_assets.has("res://missing-root-spark-frame.png"))


func _make_manifest() -> Resource:
	var manifest = BattleAnimationManifest.new()
	manifest.manifest_id = &"slice_combat"
	for clip in [
		_make_clip(&"root_idle"),
		_make_clip(&"root_telegraph"),
		_make_clip(&"root_hurt"),
		_make_clip(&"root_defend_start"),
		_make_clip(&"root_defend_hit"),
		_make_clip(&"root_ko"),
		_make_clip(&"root_spark_clip"),
	]:
		manifest.global_clips.append(clip)
	manifest.actor_sets.append(_make_actor_set())
	return manifest


func _make_actor_set() -> Resource:
	var actor_set = BattleActorAnimationSet.new()
	actor_set.actor_id = &"root_wyrmling"
	actor_set.actor_kind = &"dragon"
	actor_set.element = &"Root"
	actor_set.stage_id = &"I"
	actor_set.frame_slot_size = Vector2i(224, 168)
	actor_set.anchor = Vector2(112, 168)
	actor_set.idle_clip_id = &"root_idle"
	actor_set.telegraph_clip_id = &"root_telegraph"
	actor_set.hurt_clip_id = &"root_hurt"
	actor_set.defend_start_clip_id = &"root_defend_start"
	actor_set.defend_hit_clip_id = &"root_defend_hit"
	actor_set.ko_clip_id = &"root_ko"
	actor_set.action_bindings.append(_make_binding(&"root_spark", &"root_spark", &"basic_attack", &"root_spark_clip"))
	return actor_set


func _make_binding(move_id: StringName, animation_action_id: StringName, action_class: StringName, clip_id: StringName) -> Resource:
	var binding = BattleActionAnimationBinding.new()
	binding.binding_id = &"root_spark_binding"
	binding.move_id = move_id
	binding.animation_action_id = animation_action_id
	binding.action_class = action_class
	binding.clip_id = clip_id
	binding.coverage_status = &"approved"
	return binding


func _make_clip(clip_id: StringName) -> Resource:
	var clip = BattleAnimationClip.new()
	clip.clip_id = clip_id
	clip.asset_path = "res://project.godot"
	clip.frame_count = 4
	clip.frame_duration_ms = 100
	clip.anchor = Vector2(112, 168)
	clip.slot_size = Vector2i(224, 168)
	clip.preview_sheet_path = "res://project.godot"
	clip.runtime_capture_paths = PackedStringArray(["res://project.godot"])
	clip.approval_status = &"approved"
	return clip


func _make_move(move_id: StringName, animation_action_id: StringName, required_animation_class: StringName) -> Resource:
	var move = MoveDefinition.new()
	move.move_id = move_id
	move.element = &"Root"
	move.move_kind = &"attack"
	move.animation_action_id = animation_action_id
	move.required_animation_class = required_animation_class
	move.presentation_profile_id = &"root_spark"
	return move


func _make_battle_definition() -> Resource:
	var battle = BattleDefinition.new()
	battle.battle_id = &"slice_training"
	battle.move_ids.append(&"root_spark")
	battle.animation_manifest_id = &"slice_combat"
	battle.player_actor_animation_set_id = &"root_wyrmling"
	return battle
