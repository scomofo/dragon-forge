extends GutTest

const BattleAnimationManifestValidator = preload("res://src/battle/animation/battle_animation_manifest_validator.gd")

const MANIFEST_PATH := "res://assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres"
const BATTLE_PATH := "res://assets/battle/battles/village_edge_admin_protocol.tres"
const MOVE_PATHS := [
	"res://assets/battle/moves/root_spark.tres",
	"res://assets/battle/moves/thorn_surge.tres",
	"res://assets/battle/moves/guarded_spark.tres",
	"res://assets/battle/moves/data_leak.tres",
]


func test_root_admin_animation_manifest_content_validates() -> void:
	var manifest = load(MANIFEST_PATH)
	var battle = load(BATTLE_PATH)
	var moves := _load_moves()

	assert_not_null(manifest, "The Root Wyrmling vs Admin Protocol manifest should load.")
	assert_not_null(battle, "The Village Edge Admin Protocol battle definition should load.")
	assert_eq(moves.size(), MOVE_PATHS.size(), "Every authored move Resource should load.")
	if manifest == null or battle == null or moves.size() != MOVE_PATHS.size():
		return

	var result = BattleAnimationManifestValidator.new().validate(manifest, battle, moves, true)

	assert_true(result.ok, _format_validation_failures(result))
	assert_eq(result.placeholder_bindings.size(), 0)
	assert_eq(result.missing_clip_assets.size(), 0)
	assert_eq(result.missing_preview_evidence.size(), 0)
	assert_eq(result.missing_runtime_capture_evidence.size(), 0)


func test_root_spark_uses_real_frame_sequence_assets() -> void:
	var manifest = load(MANIFEST_PATH)
	assert_not_null(manifest, "The Root Wyrmling vs Admin Protocol manifest should load.")
	if manifest == null:
		return

	var clip = manifest.find_clip(&"root_wyrmling_root_spark")

	assert_not_null(clip, "Root Spark should resolve to a manifest clip.")
	if clip == null:
		return
	assert_eq(clip.playback_mode, &"frame_sequence")
	assert_eq(clip.frame_paths.size(), clip.frame_count)
	assert_eq(clip.frame_paths[0], "res://assets/battle/actors/root_wyrmling/battle/root_spark_0.png")


func test_reaction_clips_are_dedicated_approved_strips() -> void:
	var manifest = load(MANIFEST_PATH)
	assert_not_null(manifest, "The Root Wyrmling vs Admin Protocol manifest should load.")
	if manifest == null:
		return

	for clip_id in [
		&"root_wyrmling_telegraph",
		&"root_wyrmling_hurt",
		&"root_wyrmling_defend_start",
		&"root_wyrmling_defend_hit",
		&"root_wyrmling_ko",
		&"admin_protocol_telegraph",
		&"admin_protocol_hurt",
		&"admin_protocol_defend_start",
		&"admin_protocol_defend_hit",
		&"admin_protocol_ko",
	]:
		var clip = manifest.find_clip(clip_id)
		assert_not_null(clip, "Reaction clip should exist: %s" % clip_id)
		if clip == null:
			continue
		assert_eq(clip.approval_status, &"approved", "Reaction clip should no longer be prototype coverage: %s" % clip_id)
		assert_false(clip.accessibility_notes.contains("prototype"), "Reaction clip notes should not describe prototype coverage: %s" % clip_id)


func _load_moves() -> Dictionary:
	var moves := {}
	for path in MOVE_PATHS:
		var move = load(path)
		assert_not_null(move, "Move Resource should load: %s" % path)
		if move != null:
			moves[move.move_id] = move
	return moves


func _format_validation_failures(result: Object) -> String:
	return "Manifest validation failed: mismatches=%s missing_base=%s missing_bindings=%s wrong_class=%s placeholder=%s missing_assets=%s missing_preview=%s missing_runtime=%s" % [
		result.manifest_id_mismatches,
		result.missing_base_clips,
		result.missing_move_bindings,
		result.wrong_action_class_bindings,
		result.placeholder_bindings,
		result.missing_clip_assets,
		result.missing_preview_evidence,
		result.missing_runtime_capture_evidence,
	]
