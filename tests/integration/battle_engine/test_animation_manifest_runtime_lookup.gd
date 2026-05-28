extends GutTest

const BattleRuntimeControllerScript = preload("res://src/battle/runtime/battle_runtime_controller.gd")
const BattleSetupPayloadScript = preload("res://src/battle/runtime/battle_setup_payload.gd")
const BattleActionAnimationBindingScript = preload("res://src/battle/animation/battle_action_animation_binding.gd")
const MoveDefinitionScript = preload("res://src/battle/data/move_definition.gd")

const MANIFEST_PATH := "res://assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres"
const BATTLE_PATH := "res://assets/battle/battles/village_edge_admin_protocol.tres"
const MOVE_PATHS := [
	"res://assets/battle/moves/root_spark.tres",
	"res://assets/battle/moves/thorn_surge.tres",
	"res://assets/battle/moves/guarded_spark.tres",
	"res://assets/battle/moves/data_leak.tres",
]


func test_runtime_resolves_action_and_reaction_clips_from_manifest_ids() -> void:
	var start_result: BattleStartResult = _start_runtime_with_manifest()
	assert_true(start_result.success, start_result.reason)
	if not start_result.success:
		return

	var action_result = start_result.session.resolve_action_animation(&"root_wyrmling", &"root_spark")
	var enemy_action_result = start_result.session.resolve_action_animation(&"admin_protocol", &"data_leak")

	assert_true(action_result.success, action_result.error_message)
	assert_eq(action_result.manifest_id, &"root_wyrmling_vs_admin_protocol")
	assert_eq(action_result.actor_set_id, &"root_wyrmling")
	assert_eq(action_result.move_id, &"root_spark")
	assert_eq(action_result.action_clip.clip_id, &"root_wyrmling_root_spark")
	assert_eq(action_result.vfx_clip.clip_id, &"vfx_root_spark")
	assert_eq(action_result.receive_clip.clip_id, &"admin_protocol_hurt")
	assert_eq(action_result.binding.presentation_event_id, &"battle.root_spark")
	assert_true(enemy_action_result.success, enemy_action_result.error_message)
	assert_eq(enemy_action_result.action_clip.clip_id, &"admin_protocol_data_leak")
	assert_eq(enemy_action_result.receive_clip.clip_id, &"root_wyrmling_hurt")


func test_runtime_resolves_defend_hurt_defend_hit_ko_and_status_receive_clips() -> void:
	var start_result: BattleStartResult = _start_runtime_with_manifest()
	assert_true(start_result.success, start_result.reason)
	if not start_result.success:
		return

	var defend_move_result = start_result.session.resolve_action_animation(&"root_wyrmling", &"guarded_spark")
	var hurt_result = start_result.session.resolve_base_animation(&"root_wyrmling", &"hurt")
	var defend_hit_result = start_result.session.resolve_base_animation(&"root_wyrmling", &"defend_hit")
	var ko_result = start_result.session.resolve_base_animation(&"root_wyrmling", &"ko")
	var status_receive_result = start_result.session.resolve_receive_animation(&"root_wyrmling", &"data_leak")

	assert_true(defend_move_result.success, defend_move_result.error_message)
	assert_eq(defend_move_result.action_class, &"defend")
	assert_eq(defend_move_result.action_clip.clip_id, &"root_wyrmling_guarded_spark")
	assert_true(hurt_result.success, hurt_result.error_message)
	assert_eq(hurt_result.base_clip.clip_id, &"root_wyrmling_hurt")
	assert_true(defend_hit_result.success, defend_hit_result.error_message)
	assert_eq(defend_hit_result.base_clip.clip_id, &"root_wyrmling_defend_hit")
	assert_true(ko_result.success, ko_result.error_message)
	assert_eq(ko_result.base_clip.clip_id, &"root_wyrmling_ko")
	assert_true(status_receive_result.success, status_receive_result.error_message)
	assert_eq(status_receive_result.receive_clip.clip_id, &"root_wyrmling_hurt")


func test_runtime_reports_actionable_errors_for_missing_bindings_before_content_lock() -> void:
	var start_result: BattleStartResult = _start_runtime_with_manifest()
	assert_true(start_result.success, start_result.reason)
	if not start_result.success:
		return

	var missing_actor_result = start_result.session.resolve_action_animation(&"missing_actor", &"root_spark")
	var missing_move_result = start_result.session.resolve_action_animation(&"root_wyrmling", &"missing_move")
	var validation_result = start_result.session.validate_animation_manifest(true)

	assert_false(missing_actor_result.success)
	assert_eq(missing_actor_result.reason, &"missing_actor_set")
	assert_true(missing_actor_result.error_message.contains("missing_actor"))
	assert_false(missing_move_result.success)
	assert_eq(missing_move_result.reason, &"missing_move_definition")
	assert_true(missing_move_result.error_message.contains("missing_move"))
	assert_true(validation_result.ok, "Valid authored fixture should pass production-lock validation.")


func test_missing_manifest_binding_reports_runtime_and_validation_errors() -> void:
	var setup := _make_setup_with_manifest()
	setup.battle_definition = setup.battle_definition.duplicate()
	setup.battle_definition.move_ids.append(&"unbound_move")
	setup.move_definitions[&"unbound_move"] = _make_move(&"unbound_move", &"unbound_action", &"basic_attack")
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var start_result: BattleStartResult = controller.start_battle(setup)
	assert_true(start_result.success, start_result.reason)
	if not start_result.success:
		return

	var missing_binding_result = start_result.session.resolve_action_animation(&"root_wyrmling", &"unbound_move")
	var validation_result = start_result.session.validate_animation_manifest(true)

	assert_false(missing_binding_result.success)
	assert_eq(missing_binding_result.reason, &"missing_action_binding")
	assert_true(missing_binding_result.error_message.contains("unbound_move"))
	assert_false(validation_result.ok)
	assert_true(validation_result.missing_move_bindings.has(&"root_wyrmling:unbound_move"))


func test_runtime_lookup_keeps_configured_id_snapshot_after_setup_mutation() -> void:
	var setup := _make_setup_with_manifest()
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var start_result: BattleStartResult = controller.start_battle(setup)
	setup.battle_definition.animation_manifest_id = &"mutated_manifest"
	setup.move_definitions.clear()

	assert_true(start_result.success, start_result.reason)
	if not start_result.success:
		return

	var action_result = start_result.session.resolve_action_animation(&"root_wyrmling", &"root_spark")

	assert_true(action_result.success, action_result.error_message)
	assert_eq(action_result.manifest_id, &"root_wyrmling_vs_admin_protocol")
	assert_eq(action_result.action_clip.clip_id, &"root_wyrmling_root_spark")


func test_receive_lookup_uses_source_actor_when_move_ids_are_shared() -> void:
	var setup := _make_setup_with_manifest()
	setup.animation_manifest = setup.animation_manifest.duplicate(true)
	var root_actor_set = setup.animation_manifest.find_actor_set(&"root_wyrmling")
	root_actor_set.action_bindings.append(_make_binding(
		&"root_fake_data_leak",
		&"data_leak",
		&"data_leak",
		&"basic_attack",
		&"root_wyrmling_guarded_spark",
		&"vfx_guarded_spark",
		&"root_wyrmling_defend_hit"
	))
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	var start_result: BattleStartResult = controller.start_battle(setup)
	assert_true(start_result.success, start_result.reason)
	if not start_result.success:
		return

	var receive_result = start_result.session.resolve_receive_animation(&"root_wyrmling", &"data_leak", &"admin_protocol")

	assert_true(receive_result.success, receive_result.error_message)
	assert_eq(receive_result.source_actor_set_id, &"admin_protocol")
	assert_eq(receive_result.binding.binding_id, &"admin_protocol_data_leak")
	assert_eq(receive_result.receive_clip.clip_id, &"root_wyrmling_hurt")


func test_battle_runtime_does_not_select_animation_paths_by_hardcoded_move_names() -> void:
	for path in [
		"res://src/battle/runtime/battle_session.gd",
		"res://src/battle/runtime/battle_animation_lookup_result.gd",
		"res://src/battle/runtime/battle_setup_payload.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.contains("root_spark"), "%s must not branch on authored move names." % path)
		assert_false(source.contains("data_leak"), "%s must not branch on authored move names." % path)
		assert_false(source.contains("vfx_root_spark"), "%s must not embed authored VFX IDs." % path)


func _start_runtime_with_manifest() -> BattleStartResult:
	var controller: BattleRuntimeController = add_child_autofree(BattleRuntimeControllerScript.new())
	return controller.start_battle(_make_setup_with_manifest())


func _make_setup_with_manifest() -> BattleSetupPayload:
	var setup: BattleSetupPayload = BattleSetupPayloadScript.new()
	setup.battle_id = &"village_edge_admin_protocol"
	setup.battle_definition = load(BATTLE_PATH)
	setup.animation_manifest = load(MANIFEST_PATH)
	setup.move_definitions = _load_moves()
	return setup


func _load_moves() -> Dictionary:
	var moves := {}
	for path in MOVE_PATHS:
		var move = load(path)
		assert_not_null(move, "Move Resource should load: %s" % path)
		if move != null:
			moves[move.move_id] = move
	return moves


func _make_move(move_id: StringName, animation_action_id: StringName, required_animation_class: StringName) -> MoveDefinition:
	var move: MoveDefinition = MoveDefinitionScript.new()
	move.move_id = move_id
	move.animation_action_id = animation_action_id
	move.required_animation_class = required_animation_class
	return move


func _make_binding(
		binding_id: StringName,
		move_id: StringName,
		animation_action_id: StringName,
		action_class: StringName,
		clip_id: StringName,
		vfx_clip_id: StringName,
		receive_clip_id: StringName
) -> BattleActionAnimationBinding:
	var binding: BattleActionAnimationBinding = BattleActionAnimationBindingScript.new()
	binding.binding_id = binding_id
	binding.move_id = move_id
	binding.animation_action_id = animation_action_id
	binding.action_class = action_class
	binding.clip_id = clip_id
	binding.vfx_clip_id = vfx_clip_id
	binding.receive_clip_id = receive_clip_id
	binding.coverage_status = &"approved"
	return binding
