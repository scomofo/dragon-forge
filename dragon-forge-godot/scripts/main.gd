extends Node

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const WorldScene := preload("res://scenes/world/world_scene.tscn")
const BattleScene := preload("res://scenes/battle/battle_scene.tscn")
const HardwareDungeonScene := preload("res://scenes/dungeon/hardware_dungeon_scene.tscn")
const OpeningSequenceOverlay := preload("res://scripts/world/opening_sequence_overlay.gd")
const SAVE_PATH := "user://dragon_forge_save.json"

var world_scene: Control
var battle_scene: Control
var dungeon_scene: Control
var opening_overlay
var player_profile := DragonProgression.create_profile("fire")

func _ready() -> void:
	world_scene = WorldScene.instantiate()
	battle_scene = BattleScene.instantiate()
	dungeon_scene = HardwareDungeonScene.instantiate()
	add_child(world_scene)
	add_child(battle_scene)
	add_child(dungeon_scene)
	battle_scene.visible = false
	dungeon_scene.visible = false
	opening_overlay = OpeningSequenceOverlay.new()
	add_child(opening_overlay)

	world_scene.set_profile(player_profile)
	world_scene.encounter_requested.connect(_on_encounter_requested)
	world_scene.dungeon_requested.connect(_on_dungeon_requested)
	world_scene.profile_changed.connect(_on_profile_changed)
	world_scene.save_requested.connect(_save_game)
	world_scene.load_requested.connect(_load_game)
	battle_scene.profile_changed.connect(_on_profile_changed)
	battle_scene.battle_closed.connect(_on_battle_closed)
	dungeon_scene.dungeon_closed.connect(_on_dungeon_closed)
	opening_overlay.completed.connect(_on_opening_sequence_completed)
	if opening_overlay.should_show_for_profile(player_profile):
		opening_overlay.start(player_profile)

func _unhandled_input(event: InputEvent) -> void:
	if opening_overlay != null and opening_overlay.is_sequence_active() and event.is_pressed():
		if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
			opening_overlay.advance()
			get_viewport().set_input_as_handled()

func _on_encounter_requested(enemy_id: String, context: Dictionary = {}) -> void:
	world_scene.visible = false
	battle_scene.visible = true
	battle_scene.start_battle(player_profile, enemy_id, context)

func _on_dungeon_requested(dungeon_id: String, context: Dictionary = {}) -> void:
	world_scene.visible = false
	battle_scene.visible = false
	dungeon_scene.visible = true
	dungeon_scene.start_dungeon(dungeon_id, player_profile)
	var belt: Dictionary = context.get("utility_belt", {})
	if not belt.is_empty():
		dungeon_scene.configure_utility_belt(belt.get("equipped_tools", []), int(belt.get("slot_count", 2)))

func _on_profile_changed(next_profile: Dictionary) -> void:
	player_profile = next_profile.duplicate(true)

func _on_opening_sequence_completed(next_profile: Dictionary) -> void:
	player_profile = next_profile.duplicate(true)
	world_scene.set_profile(player_profile)

func _on_battle_closed() -> void:
	battle_scene.visible = false
	world_scene.visible = true
	world_scene.set_profile(player_profile)

func _on_dungeon_closed(next_profile: Dictionary, result: Dictionary) -> void:
	player_profile = next_profile.duplicate(true)
	dungeon_scene.visible = false
	world_scene.visible = true
	world_scene.set_profile(player_profile)
	world_scene.apply_dungeon_result(result)

func _save_game() -> void:
	var state: Dictionary = world_scene.export_state()
	state["profile"] = player_profile.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(state, "\t"))
	file.close()

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		push_warning("No Dragon Forge save found.")
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not read save file: %s" % SAVE_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Dragon Forge save file is invalid.")
		return
	world_scene.import_state(parsed)
	player_profile = parsed.get("profile", player_profile).duplicate(true)
