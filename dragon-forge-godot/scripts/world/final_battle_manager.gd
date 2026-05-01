extends Node
class_name FinalBattleManager

signal override_prompt_requested(prompt: String)
signal deletion_ending_requested
signal stable_hybrid_patch_applied(profile: Dictionary)

const VictoryStateData := preload("res://scripts/sim/victory_state_data.gd")
const MirrorAdminLogic := preload("res://scripts/sim/mirror_admin_logic.gd")

@export var transition_controller_path: NodePath

var mirror_state := MirrorAdminLogic.create_state()
var profile: Dictionary = {}
var has_manual_override := false

func configure(profile_snapshot: Dictionary, manual_override_available: bool) -> void:
	profile = profile_snapshot.duplicate(true)
	has_manual_override = manual_override_available

func on_admin_integrity_changed(packet_integrity: float) -> void:
	mirror_state["packet_integrity"] = packet_integrity
	mirror_state = MirrorAdminLogic.update_phase(mirror_state)
	if not mirror_state.get("hard_reset_active", false):
		return
	var decision := VictoryStateData.evaluate_hard_reset_interrupt(packet_integrity, has_manual_override)
	_start_hard_reset(decision)

func override_pressed() -> void:
	if not has_manual_override:
		deletion_ending_requested.emit()
		return
	var controller := _transition_controller()
	if controller != null and controller.has_method("jam_hard_reset"):
		controller.call("jam_hard_reset")
	mirror_state = MirrorAdminLogic.jam_hard_reset_with_manual(mirror_state, true)
	profile = VictoryStateData.apply_patch_state(profile)
	stable_hybrid_patch_applied.emit(profile.duplicate(true))

func _start_hard_reset(decision: Dictionary) -> void:
	var controller := _transition_controller()
	if controller != null and controller.has_method("trigger_hard_reset"):
		controller.call("trigger_hard_reset", 2.0)
	if decision["state"] == VictoryStateData.MANUAL_OVERRIDE_PROMPT:
		override_prompt_requested.emit(decision["prompt"])
	elif decision["state"] == VictoryStateData.DELETION_ENDING:
		deletion_ending_requested.emit()

func _transition_controller() -> Node:
	if transition_controller_path == NodePath():
		return null
	return get_node_or_null(transition_controller_path)
