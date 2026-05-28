extends SceneTree

const BattleActionAnimationBinding = preload("res://src/battle/animation/battle_action_animation_binding.gd")
const BattleActorAnimationSet = preload("res://src/battle/animation/battle_actor_animation_set.gd")
const BattleAnimationClip = preload("res://src/battle/animation/battle_animation_clip.gd")
const BattleAnimationManifest = preload("res://src/battle/animation/battle_animation_manifest.gd")
const BattleDefinition = preload("res://src/battle/data/battle_definition.gd")
const MoveDefinition = preload("res://src/battle/data/move_definition.gd")

const ROOT_DIR := "res://assets/battle/actors/root_wyrmling/battle"
const ADMIN_DIR := "res://assets/battle/actors/admin_protocol/battle"
const PREVIEW_DIR := "res://assets/battle/previews"
const CAPTURE_DIR := "res://assets/battle/runtime_captures/village_edge_admin_protocol"
const VFX_DIR := "res://assets/battle/vfx"


func _init() -> void:
	var manifest := _make_manifest()
	_save(manifest, "res://assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres")
	_save(_make_battle_definition(), "res://assets/battle/battles/village_edge_admin_protocol.tres")
	_save(_make_move(&"root_spark", &"Root", &"attack", &"", &"root_spark", &"basic_attack", &"root_spark"), "res://assets/battle/moves/root_spark.tres")
	_save(_make_move(&"thorn_surge", &"Root", &"attack", &"", &"thorn_surge", &"heavy_attack", &"thorn_surge"), "res://assets/battle/moves/thorn_surge.tres")
	_save(_make_move(&"guarded_spark", &"Root", &"defend", &"", &"guarded_spark", &"defend", &"guarded_spark"), "res://assets/battle/moves/guarded_spark.tres")
	_save(_make_move(&"data_leak", &"Shadow", &"attack", &"", &"data_leak", &"basic_attack", &"data_leak"), "res://assets/battle/moves/data_leak.tres")
	print("Authored Root Wyrmling vs Admin Protocol battle animation content.")
	quit(0)


func _make_manifest() -> BattleAnimationManifest:
	var manifest := BattleAnimationManifest.new()
	manifest.manifest_id = &"root_wyrmling_vs_admin_protocol"
	manifest.schema_version = 1
	manifest.reduced_motion_profile_id = &"slice_reduced_motion"
	manifest.fallback_policy = &"content_lock_error"
	manifest.notes = "First validated slice-content manifest. Attack and reaction clips use dedicated frame-sequence strips with preview sheets and runtime capture evidence."

	for clip in _make_root_clips():
		manifest.global_clips.append(clip)
	for clip in _make_admin_clips():
		manifest.global_clips.append(clip)
	for clip in _make_vfx_clips():
		manifest.global_clips.append(clip)

	manifest.actor_sets.append(_make_root_actor_set())
	manifest.actor_sets.append(_make_admin_actor_set())
	return manifest


func _make_root_actor_set() -> BattleActorAnimationSet:
	var actor_set := BattleActorAnimationSet.new()
	actor_set.actor_id = &"root_wyrmling"
	actor_set.actor_kind = &"dragon"
	actor_set.element = &"Root"
	actor_set.stage_id = &"I"
	actor_set.variant_id = &"slice"
	actor_set.facing = &"right"
	actor_set.frame_slot_size = Vector2i(224, 168)
	actor_set.anchor = Vector2(112, 168)
	actor_set.idle_clip_id = &"root_wyrmling_idle"
	actor_set.telegraph_clip_id = &"root_wyrmling_telegraph"
	actor_set.hurt_clip_id = &"root_wyrmling_hurt"
	actor_set.defend_start_clip_id = &"root_wyrmling_defend_start"
	actor_set.defend_hit_clip_id = &"root_wyrmling_defend_hit"
	actor_set.ko_clip_id = &"root_wyrmling_ko"
	actor_set.action_bindings.append(_binding(&"root_wyrmling_root_spark", &"root_spark", &"root_spark", &"basic_attack", &"root_wyrmling_root_spark", &"vfx_root_spark", &"admin_protocol_hurt", &"battle.root_spark"))
	actor_set.action_bindings.append(_binding(&"root_wyrmling_thorn_surge", &"thorn_surge", &"thorn_surge", &"heavy_attack", &"root_wyrmling_thorn_surge", &"vfx_thorn_surge", &"admin_protocol_hurt", &"battle.thorn_surge"))
	actor_set.action_bindings.append(_binding(&"root_wyrmling_guarded_spark", &"guarded_spark", &"guarded_spark", &"defend", &"root_wyrmling_guarded_spark", &"vfx_guarded_spark", &"admin_protocol_hurt", &"battle.guarded_spark"))
	return actor_set


func _make_admin_actor_set() -> BattleActorAnimationSet:
	var actor_set := BattleActorAnimationSet.new()
	actor_set.actor_id = &"admin_protocol"
	actor_set.actor_kind = &"support_enemy"
	actor_set.element = &"Shadow"
	actor_set.stage_id = &"protocol"
	actor_set.variant_id = &"slice"
	actor_set.facing = &"left"
	actor_set.frame_slot_size = Vector2i(224, 168)
	actor_set.anchor = Vector2(112, 168)
	actor_set.idle_clip_id = &"admin_protocol_idle"
	actor_set.telegraph_clip_id = &"admin_protocol_telegraph"
	actor_set.hurt_clip_id = &"admin_protocol_hurt"
	actor_set.defend_start_clip_id = &"admin_protocol_defend_start"
	actor_set.defend_hit_clip_id = &"admin_protocol_defend_hit"
	actor_set.ko_clip_id = &"admin_protocol_ko"
	actor_set.action_bindings.append(_binding(&"admin_protocol_data_leak", &"data_leak", &"data_leak", &"basic_attack", &"admin_protocol_data_leak", &"vfx_shadow_burst", &"root_wyrmling_hurt", &"battle.data_leak"))
	return actor_set


func _make_root_clips() -> Array:
	return [
		_sequence_clip(&"root_wyrmling_idle", ROOT_DIR, "root_idle", 4, 130, Vector2i(192, 144), "%s/root_wyrmling_root_idle_sheet.png" % PREVIEW_DIR, ["%s/08_battle_telegraph.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_telegraph", ROOT_DIR, "root_telegraph", 4, 95, Vector2i(224, 168), "%s/root_wyrmling_root_telegraph_sheet.png" % PREVIEW_DIR, ["%s/08_battle_telegraph.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_hurt", ROOT_DIR, "root_hurt", 4, 90, Vector2i(192, 144), "%s/root_wyrmling_root_hurt_sheet.png" % PREVIEW_DIR, ["%s/10_enemy_data_leak.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_defend_start", ROOT_DIR, "root_defend_start", 4, 90, Vector2i(224, 168), "%s/root_wyrmling_root_defend_start_sheet.png" % PREVIEW_DIR, ["%s/12_guarded_spark_counter.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_defend_hit", ROOT_DIR, "root_defend_hit", 4, 90, Vector2i(224, 168), "%s/root_wyrmling_root_defend_hit_sheet.png" % PREVIEW_DIR, ["%s/12_guarded_spark_counter.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_ko", ROOT_DIR, "root_ko", 4, 110, Vector2i(224, 168), "%s/root_wyrmling_root_ko_sheet.png" % PREVIEW_DIR, ["%s/10_enemy_data_leak.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_root_spark", ROOT_DIR, "root_spark", 6, 85, Vector2i(224, 168), "%s/root_wyrmling_root_spark_sheet.png" % PREVIEW_DIR, ["%s/09_root_spark_impact.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_thorn_surge", ROOT_DIR, "thorn_surge", 6, 95, Vector2i(224, 168), "%s/root_wyrmling_thorn_surge_sheet.png" % PREVIEW_DIR, ["%s/11_thorn_surge_impact.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"root_wyrmling_guarded_spark", ROOT_DIR, "guarded_spark", 6, 90, Vector2i(224, 168), "%s/root_wyrmling_guarded_spark_sheet.png" % PREVIEW_DIR, ["%s/12_guarded_spark_counter.png" % CAPTURE_DIR], &"approved"),
	]


func _make_admin_clips() -> Array:
	return [
		_sequence_clip(&"admin_protocol_idle", ADMIN_DIR, "admin_idle", 4, 130, Vector2i(192, 176), "%s/admin_protocol_idle_sheet.png" % PREVIEW_DIR, ["%s/08_battle_telegraph.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"admin_protocol_telegraph", ADMIN_DIR, "admin_telegraph", 4, 95, Vector2i(224, 168), "%s/admin_protocol_telegraph_sheet.png" % PREVIEW_DIR, ["%s/08_battle_telegraph.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"admin_protocol_hurt", ADMIN_DIR, "admin_hurt", 4, 90, Vector2i(224, 168), "%s/admin_protocol_hurt_sheet.png" % PREVIEW_DIR, ["%s/09_root_spark_impact.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"admin_protocol_defend_start", ADMIN_DIR, "admin_defend_start", 4, 90, Vector2i(192, 176), "%s/admin_protocol_defend_start_sheet.png" % PREVIEW_DIR, ["%s/08_battle_telegraph.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"admin_protocol_defend_hit", ADMIN_DIR, "admin_defend_hit", 4, 90, Vector2i(224, 168), "%s/admin_protocol_defend_hit_sheet.png" % PREVIEW_DIR, ["%s/11_thorn_surge_impact.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"admin_protocol_ko", ADMIN_DIR, "admin_ko", 4, 110, Vector2i(224, 168), "%s/admin_protocol_ko_sheet.png" % PREVIEW_DIR, ["%s/12_guarded_spark_counter.png" % CAPTURE_DIR], &"approved"),
		_sequence_clip(&"admin_protocol_data_leak", ADMIN_DIR, "data_leak", 6, 85, Vector2i(224, 168), "%s/admin_protocol_data_leak_sheet.png" % PREVIEW_DIR, ["%s/10_enemy_data_leak.png" % CAPTURE_DIR], &"approved"),
	]


func _make_vfx_clips() -> Array:
	return [
		_vfx_clip(&"vfx_root_spark", "%s/vfx_root_spark.png" % VFX_DIR, "%s/09_root_spark_impact.png" % CAPTURE_DIR),
		_vfx_clip(&"vfx_thorn_surge", "%s/vfx_thorn_surge.png" % VFX_DIR, "%s/11_thorn_surge_impact.png" % CAPTURE_DIR),
		_vfx_clip(&"vfx_guarded_spark", "%s/vfx_guarded_spark.png" % VFX_DIR, "%s/12_guarded_spark_counter.png" % CAPTURE_DIR),
		_vfx_clip(&"vfx_shadow_burst", "%s/vfx_shadow_burst.png" % VFX_DIR, "%s/10_enemy_data_leak.png" % CAPTURE_DIR),
	]


func _sequence_clip(
		clip_id: StringName,
		base_dir: String,
		prefix: String,
		frame_count: int,
		frame_duration_ms: int,
		slot_size: Vector2i,
		preview_sheet_path: String,
		runtime_capture_paths: Array,
		approval_status: StringName
) -> BattleAnimationClip:
	var clip := BattleAnimationClip.new()
	clip.clip_id = clip_id
	clip.asset_path = "%s/%s_0.png" % [base_dir, prefix]
	clip.frame_count = frame_count
	clip.frame_duration_ms = frame_duration_ms
	clip.frame_paths = _frame_paths(base_dir, prefix, frame_count)
	clip.loop = clip_id in [&"root_wyrmling_idle", &"admin_protocol_idle"]
	clip.anchor = Vector2(slot_size.x / 2.0, slot_size.y)
	clip.slot_size = slot_size
	clip.playback_mode = &"frame_sequence"
	clip.preview_sheet_path = preview_sheet_path
	clip.runtime_capture_paths = PackedStringArray(runtime_capture_paths)
	clip.approval_status = approval_status
	clip.accessibility_notes = "Reviewed against runtime capture; VFX/readability must remain visible without relying on color alone."
	return clip


func _vfx_clip(clip_id: StringName, path: String, runtime_capture_path: String) -> BattleAnimationClip:
	var clip := BattleAnimationClip.new()
	clip.clip_id = clip_id
	clip.asset_path = path
	clip.frame_count = 1
	clip.frame_duration_ms = 100
	clip.frame_paths = PackedStringArray([path])
	clip.anchor = Vector2(112, 84)
	clip.slot_size = Vector2i(224, 168)
	clip.playback_mode = &"vfx_overlay"
	clip.preview_sheet_path = path
	clip.runtime_capture_paths = PackedStringArray([runtime_capture_path])
	clip.approval_status = &"approved"
	clip.accessibility_notes = "Overlay is validated by runtime capture; presentation adapter must preserve HP and TELEGRAPH readability."
	return clip


func _frame_paths(base_dir: String, prefix: String, frame_count: int) -> PackedStringArray:
	var paths := PackedStringArray()
	for index in range(frame_count):
		paths.append("%s/%s_%d.png" % [base_dir, prefix, index])
	return paths


func _binding(
		binding_id: StringName,
		move_id: StringName,
		animation_action_id: StringName,
		action_class: StringName,
		clip_id: StringName,
		vfx_clip_id: StringName,
		receive_clip_id: StringName,
		presentation_event_id: StringName
) -> BattleActionAnimationBinding:
	var binding := BattleActionAnimationBinding.new()
	binding.binding_id = binding_id
	binding.move_id = move_id
	binding.animation_action_id = animation_action_id
	binding.action_class = action_class
	binding.clip_id = clip_id
	binding.impact_frame_index = 3
	binding.vfx_clip_id = vfx_clip_id
	binding.receive_clip_id = receive_clip_id
	binding.presentation_event_id = presentation_event_id
	binding.coverage_status = &"approved"
	return binding


func _make_move(
		move_id: StringName,
		element: StringName,
		move_kind: StringName,
		status_id: StringName,
		animation_action_id: StringName,
		required_animation_class: StringName,
		presentation_profile_id: StringName
) -> MoveDefinition:
	var move := MoveDefinition.new()
	move.move_id = move_id
	move.element = element
	move.move_kind = move_kind
	move.status_id = status_id
	move.animation_action_id = animation_action_id
	move.required_animation_class = required_animation_class
	move.presentation_profile_id = presentation_profile_id
	return move


func _make_battle_definition() -> BattleDefinition:
	var battle := BattleDefinition.new()
	battle.battle_id = &"village_edge_admin_protocol"
	battle.move_ids.append(&"root_spark")
	battle.move_ids.append(&"thorn_surge")
	battle.move_ids.append(&"guarded_spark")
	battle.enemy_move_ids.append(&"data_leak")
	battle.animation_manifest_id = &"root_wyrmling_vs_admin_protocol"
	battle.player_actor_animation_selector = &"active_dragon"
	battle.player_actor_animation_set_id = &"root_wyrmling"
	battle.enemy_actor_animation_set_id = &"admin_protocol"
	return battle


func _save(resource: Resource, path: String) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("Could not save %s: %s" % [path, error_string(err)])
		quit(1)
