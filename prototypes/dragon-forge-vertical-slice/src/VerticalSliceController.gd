# VERTICAL SLICE - NOT FOR PRODUCTION
# Validation Question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
# Date: 2026-05-26

extends Control

const DRAGON_NAME := "Root Wyrmling"
const STARTING_SCRAPS := 40
const BATTLE_REWARD_SCRAPS := 25
const PLAYER_MAX_HP := 34
const ENEMY_MAX_HP := 28
const PLAYER_ATTACK := 11
const PLAYER_SPECIAL_ATTACK := 16
const PLAYER_DEFEND_ATTACK := 7
const ENEMY_ATTACK := 8

const INK := Color(0.035, 0.039, 0.055)
const PANEL := Color(0.075, 0.078, 0.105)
const PANEL_LIFT := Color(0.12, 0.125, 0.17)
const GOLD := Color(0.95, 0.73, 0.32)
const ROOT_GREEN := Color(0.29, 0.82, 0.46)
const LEAF_DARK := Color(0.10, 0.28, 0.16)
const WARNING := Color(0.95, 0.38, 0.31)
const CYAN := Color(0.25, 0.82, 0.95)
const MAGENTA := Color(0.85, 0.23, 0.94)
const SKY := Color(0.10, 0.16, 0.22)
const EARTH := Color(0.19, 0.15, 0.12)
const MUTED_TEXT := Color(0.74, 0.77, 0.82)
const PIXEL := 4.0
const MUSIC_FORGE_DB := -16.0
const MUSIC_MAP_DB := -15.0
const MUSIC_BATTLE_DB := -14.0
const MUSIC_REWARD_DB := -13.0
const SFX_VOICE_COUNT := 6
const RETRO_FONT_PATH := "res://assets/ui/PressStart2P-Regular.ttf"
const RETRO_FONT_FALLBACK_PATH := "res://assets/ui/dragon_forge_8bit_standin.ttf"
const BATTLE_ANIMATION_MANIFEST_PATH := "res://assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres"
const BATTLE_DEFINITION_PATH := "res://assets/battle/battles/village_edge_admin_protocol.tres"
const MUSIC_FORGE_PATH := "res://assets/audio/music_forge_ready_room.wav"
const MUSIC_MAP_PATH := "res://assets/audio/music_map_node_select.wav"
const MUSIC_BATTLE_PATH := "res://assets/audio/music_battle_data_bout.wav"
const MUSIC_VICTORY_PATH := "res://assets/audio/music_victory_scrap_jingle.wav"
const ENEMY_WARNING_BANNER := "INCOMING: DATA LEAK"
const ENEMY_WARNING_MARKER := "ADMIN WARNING"
const PLAYER_TARGET_MARKER := "YOUR TARGET"
const BATTLE_MOVE_PATHS := [
	"res://assets/battle/moves/root_spark.tres",
	"res://assets/battle/moves/thorn_surge.tres",
	"res://assets/battle/moves/guarded_spark.tres",
	"res://assets/battle/moves/data_leak.tres",
]

var player_hp := PLAYER_MAX_HP
var enemy_hp := ENEMY_MAX_HP
var scraps := STARTING_SCRAPS
var turn_count := 1
var state := "intro"
var visual_mode := "forge"
var battle_phase := "telegraph"
var battle_phase_time := 0.0
var battle_action_lock := false
var player_defending_this_turn := false
var active_move_name := "Root Spark"
var active_move_id: StringName = &"root_spark"
var active_move_fx := ""
var floating_text := ""
var floating_text_side := "enemy"
var floating_text_color := Color.WHITE
var floating_text_time := 0.0
var screen_shake := 0.0
var dialogue_speaker := "Felix"
var dialogue_text := "Skye, if this works, the egg will answer you before the world does."
var anim_time := 0.0
var presentation_time := 0.0
var scene_flash := 0.0
var music_target_db := MUSIC_FORGE_DB
var current_music_key := ""
var sfx_voice_index := 0
var slice_textures: Dictionary = {}
var music_streams: Dictionary = {}
var sfx_streams: Dictionary = {}
var battle_animation_manifest: Resource
var battle_definition: Resource
var battle_move_definitions: Dictionary = {}
var retro_font: Font

var stage_spacer: Control
var title_label: Label
var status_label: Label
var body_label: Label
var dialogue_speaker_label: Label
var dialogue_label: Label
var story_label: Label
var log_label: Label
var primary_button: Button
var secondary_button: Button
var tertiary_button: Button
var sfx_players: Array = []
var music_player: AudioStreamPlayer


func _ready() -> void:
	_load_slice_assets()
	_load_battle_animation_content()
	_load_retro_font()
	_build_audio()
	_build_ui()
	_show_intro()
	set_process(true)


func _exit_tree() -> void:
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	for player in sfx_players:
		if player is AudioStreamPlayer:
			player.stop()
			player.stream = null


func _load_slice_assets() -> void:
	var paths := {
		"forge_hub": "res://assets/slice/forge_hub.png",
		"hatchery": "res://assets/slice/hatchery.png",
		"village_edge_map": "res://assets/slice/village_edge_map.png",
		"battlefield": "res://assets/slice/battlefield.png",
		"victory": "res://assets/slice/victory.png",
		"root_wyrmling": "res://assets/slice/root_wyrmling.png",
		"felix": "res://assets/slice/felix.png",
		"enemy_protocol": "res://assets/slice/enemy_protocol.png",
		"root_egg": "res://assets/slice/root_egg.png",
		"data_scraps": "res://assets/slice/data_scraps.png",
		"felix_portrait": "res://assets/slice/felix_portrait.png",
		"dragonsim_fire": "res://assets/slice/dragonsim_fire.png",
		"dragonsim_ice": "res://assets/slice/dragonsim_ice.png",
		"dragonsim_shadow": "res://assets/slice/dragonsim_shadow.png",
		"dragonsim_stone": "res://assets/slice/dragonsim_stone.png",
		"dragonsim_storm": "res://assets/slice/dragonsim_storm.png",
		"dragonsim_venom": "res://assets/slice/dragonsim_venom.png",
		"npc_logic_bomb": "res://assets/slice/npc_logic_bomb.png",
		"npc_recursive_golem": "res://assets/slice/npc_recursive_golem.png",
		"root_attack_0": "res://assets/slice/root_attack_0.png",
		"root_attack_1": "res://assets/slice/root_attack_1.png",
		"root_attack_2": "res://assets/slice/root_attack_2.png",
		"root_attack_3": "res://assets/slice/root_attack_3.png",
		"enemy_attack_0": "res://assets/slice/enemy_attack_0.png",
		"enemy_attack_1": "res://assets/slice/enemy_attack_1.png",
		"enemy_attack_2": "res://assets/slice/enemy_attack_2.png",
		"enemy_attack_3": "res://assets/slice/enemy_attack_3.png",
		"vfx_root_spark": "res://assets/slice/vfx_root_spark.png",
		"vfx_thorn_surge": "res://assets/slice/vfx_thorn_surge.png",
		"vfx_guarded_spark": "res://assets/slice/vfx_guarded_spark.png",
		"vfx_shadow_burst": "res://assets/slice/vfx_shadow_burst.png",
	}
	for i in range(4):
		paths["root_egg_idle_%d" % i] = "res://assets/slice/root_egg_idle_%d.png" % i
		paths["root_idle_%d" % i] = "res://assets/slice/root_idle_%d.png" % i
		paths["root_idle_battle_%d" % i] = "res://assets/slice/root_idle_battle_%d.png" % i
		paths["enemy_idle_%d" % i] = "res://assets/slice/enemy_idle_%d.png" % i
		paths["enemy_idle_battle_%d" % i] = "res://assets/slice/enemy_idle_battle_%d.png" % i
		paths["data_scraps_pickup_%d" % i] = "res://assets/slice/data_scraps_pickup_%d.png" % i
	for i in range(8):
		paths["hatch_reveal_%d" % i] = "res://assets/slice/hatch_reveal_%d.png" % i
	for key in paths:
		_load_texture_path(key, paths[key])


func _load_texture_path(key: String, path: String) -> void:
	var image := Image.new()
	var err := image.load(ProjectSettings.globalize_path(path))
	if err == OK:
		slice_textures[key] = ImageTexture.create_from_image(image)
	else:
		push_warning("Could not load slice asset %s: %s" % [path, error_string(err)])


func _load_battle_animation_content() -> void:
	battle_animation_manifest = load(BATTLE_ANIMATION_MANIFEST_PATH)
	battle_definition = load(BATTLE_DEFINITION_PATH)
	battle_move_definitions.clear()
	if battle_animation_manifest == null:
		push_warning("Could not load battle animation manifest %s" % BATTLE_ANIMATION_MANIFEST_PATH)
		return
	if battle_definition == null:
		push_warning("Could not load battle definition %s" % BATTLE_DEFINITION_PATH)
	for path in BATTLE_MOVE_PATHS:
		var move = load(path)
		if move == null:
			push_warning("Could not load move definition %s" % path)
			continue
		battle_move_definitions[move.move_id] = move
	_load_battle_manifest_textures()


func _load_battle_manifest_textures() -> void:
	if battle_animation_manifest == null:
		return
	for clip in battle_animation_manifest.global_clips:
		if clip == null:
			continue
		if clip.playback_mode == &"frame_sequence":
			for frame_index in range(clip.frame_paths.size()):
				_load_texture_path("%s_%d" % [clip.clip_id, frame_index], clip.frame_paths[frame_index])
		elif not clip.asset_path.is_empty():
			_load_texture_path(str(clip.clip_id), clip.asset_path)


func _load_retro_font() -> void:
	var font_file := FontFile.new()
	var err := font_file.load_dynamic_font(RETRO_FONT_PATH)
	if err != OK:
		err = font_file.load_dynamic_font(RETRO_FONT_FALLBACK_PATH)
		if err != OK:
			push_warning("Could not load retro font %s or fallback %s: %s" % [RETRO_FONT_PATH, RETRO_FONT_FALLBACK_PATH, error_string(err)])
			return
	font_file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	retro_font = font_file


func _build_audio() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	add_child(music_player)

	for i in range(SFX_VOICE_COUNT):
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	_set_music_for_mode("forge")


func _set_music_for_mode(mode: String) -> void:
	var music_key := _music_key_for_mode(mode)
	_set_music_target_for_mode(music_key)
	if current_music_key == music_key and music_player != null and music_player.playing:
		return
	current_music_key = music_key
	if music_player == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	var stream := _load_music_stream(_music_path_for_mode(music_key), music_key != "victory")
	if stream == null:
		return
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = music_target_db
	music_player.play()


func _music_key_for_mode(mode: String) -> String:
	match mode:
		"battle":
			return "battle"
		"map":
			return "map"
		"victory":
			return "victory"
		_:
			return "forge"


func _music_path_for_mode(mode: String) -> String:
	match _music_key_for_mode(mode):
		"battle":
			return MUSIC_BATTLE_PATH
		"map":
			return MUSIC_MAP_PATH
		"victory":
			return MUSIC_VICTORY_PATH
		_:
			return MUSIC_FORGE_PATH


func _load_music_stream(path: String, should_loop: bool) -> AudioStream:
	if music_streams.has(path):
		return music_streams[path] as AudioStream
	var stream := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
	if stream == null:
		push_warning("Could not load slice music %s" % path)
		return null
	if should_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = maxi(1, int(round(stream.get_length() * float(stream.mix_rate))))
	else:
		stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		stream.loop_begin = 0
		stream.loop_end = 0
	music_streams[path] = stream
	return stream


func _play_sfx(cue: String) -> void:
	if sfx_players.is_empty() or DisplayServer.get_name() == "headless":
		return
	for layer in _sfx_layers_for(cue):
		_play_sfx_layer(str(layer["path"]), float(layer["volume_db"]), float(layer.get("pitch", 1.0)))


func _sfx_layer(path: String, volume_db: float, pitch: float = 1.0) -> Dictionary:
	return {"path": path, "volume_db": volume_db, "pitch": pitch}


func _sfx_layers_for(cue: String) -> Array:
	match cue:
		"select":
			return [_sfx_layer("res://assets/audio/ui_select_ping.wav", -16.0)]
		"hatch_start":
			return [
				_sfx_layer("res://assets/audio/hatch_molecular_hum.wav", -12.0),
				_sfx_layer("res://assets/audio/boss_low_heartbeat.wav", -24.0, 1.10),
			]
		"hatch_complete":
			return [
				_sfx_layer("res://assets/audio/hatch_complete_chime.wav", -9.0),
				_sfx_layer("res://assets/audio/hatch_shiny_sting.wav", -12.0),
			]
		"reward":
			return [
				_sfx_layer("res://assets/audio/forge_energy_surge.wav", -10.0),
				_sfx_layer("res://assets/audio/hatch_shiny_sting.wav", -14.0, 0.92),
			]
		"enemy_down":
			return [
				_sfx_layer("res://assets/audio/mob_decompile.wav", -8.0),
				_sfx_layer("res://assets/audio/forge_quantum_break.wav", -12.0, 0.82),
				_sfx_layer("res://assets/audio/boss_void_glitch.wav", -16.0, 0.88),
			]
		"root_spark":
			return [
				_sfx_layer("res://assets/audio/atk_static_discharge.wav", -8.0),
				_sfx_layer("res://assets/audio/boss_low_heartbeat.wav", -22.0, 1.32),
			]
		"thorn_surge":
			return [
				_sfx_layer("res://assets/audio/atk_fire_slash.wav", -8.0),
				_sfx_layer("res://assets/audio/boss_low_heartbeat.wav", -16.0, 0.72),
				_sfx_layer("res://assets/audio/forge_quantum_break.wav", -22.0, 1.28),
			]
		"guarded_spark":
			return [
				_sfx_layer("res://assets/audio/atk_static_discharge.wav", -9.0, 0.72),
				_sfx_layer("res://assets/audio/hatch_shiny_sting.wav", -18.0, 0.84),
				_sfx_layer("res://assets/audio/boss_low_heartbeat.wav", -20.0, 0.62),
			]
		"data_leak":
			return [
				_sfx_layer("res://assets/audio/boss_void_glitch.wav", -9.0),
				_sfx_layer("res://assets/audio/atk_static_discharge.wav", -14.0, 0.82),
			]
		"impact":
			return [
				_sfx_layer("res://assets/audio/hit_crit_thud.wav", -5.0),
				_sfx_layer("res://assets/audio/atk_glacier_crack.wav", -9.0, 0.88),
				_sfx_layer("res://assets/audio/boss_low_heartbeat.wav", -18.0, 0.55),
			]
		"impact_heavy":
			return [
				_sfx_layer("res://assets/audio/hit_crit_thud.wav", -4.0),
				_sfx_layer("res://assets/audio/atk_glacier_crack.wav", -7.0, 0.76),
				_sfx_layer("res://assets/audio/forge_quantum_break.wav", -12.0, 0.84),
				_sfx_layer("res://assets/audio/boss_low_heartbeat.wav", -14.0, 0.50),
			]
		"impact_guarded":
			return [
				_sfx_layer("res://assets/audio/hit_crit_thud.wav", -8.0, 0.72),
				_sfx_layer("res://assets/audio/atk_static_discharge.wav", -10.0, 1.42),
				_sfx_layer("res://assets/audio/hatch_shiny_sting.wav", -20.0, 0.78),
			]
		"enemy_impact":
			return [
				_sfx_layer("res://assets/audio/hit_crit_thud.wav", -6.0),
				_sfx_layer("res://assets/audio/boss_void_glitch.wav", -11.0, 0.92),
				_sfx_layer("res://assets/audio/atk_glacier_crack.wav", -13.0, 0.70),
			]
		_:
			return []


func _play_sfx_layer(path: String, volume_db: float, pitch_scale: float = 1.0) -> void:
	var stream := _load_sfx_stream(path)
	if stream == null:
		return
	var player := sfx_players[sfx_voice_index % sfx_players.size()] as AudioStreamPlayer
	sfx_voice_index += 1
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()


func _load_sfx_stream(path: String) -> AudioStream:
	if sfx_streams.has(path):
		return sfx_streams[path] as AudioStream
	var stream := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
	if stream == null:
		push_warning("Could not load slice SFX %s" % path)
		return null
	sfx_streams[path] = stream
	return stream


func _process(delta: float) -> void:
	anim_time += delta
	presentation_time += delta
	battle_phase_time += delta
	scene_flash = maxf(0.0, scene_flash - delta * 2.4)
	floating_text_time = maxf(0.0, floating_text_time - delta)
	screen_shake = maxf(0.0, screen_shake - delta * 2.5)
	if music_player != null and music_player.playing:
		music_player.volume_db = lerpf(music_player.volume_db, music_target_db, minf(1.0, delta * 1.8))
	queue_redraw()


func _build_ui() -> void:
	var root := MarginContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("margin_left", 34)
	root.add_theme_constant_override("margin_top", 24)
	root.add_theme_constant_override("margin_right", 34)
	root.add_theme_constant_override("margin_bottom", 24)
	add_child(root)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	root.add_child(layout)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	layout.add_child(header)

	title_label = Label.new()
	_apply_retro_label(title_label, 14, Color(0.96, 0.98, 1.0))
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_label)

	status_label = Label.new()
	_apply_retro_label(status_label, 7, MUTED_TEXT)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(status_label)

	stage_spacer = Control.new()
	stage_spacer.custom_minimum_size = Vector2(0, 300)
	stage_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_spacer.resized.connect(queue_redraw)
	layout.add_child(stage_spacer)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.018, 0.035), Color(0.84, 0.88, 0.96), 2))
	layout.add_child(dialogue_panel)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 3)
	dialogue_box.add_theme_constant_override("margin_left", 0)
	dialogue_panel.add_child(dialogue_box)

	dialogue_speaker_label = Label.new()
	_apply_retro_label(dialogue_speaker_label, 9, CYAN)
	dialogue_box.add_child(dialogue_speaker_label)

	dialogue_label = Label.new()
	_apply_retro_label(dialogue_label, 10, Color(0.96, 0.98, 1.0))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(0, 42)
	dialogue_box.add_child(dialogue_label)

	var story_panel := PanelContainer.new()
	story_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.025, 0.028), ROOT_GREEN, 2))
	layout.add_child(story_panel)

	story_label = Label.new()
	_apply_retro_label(story_label, 9, Color(0.82, 0.95, 0.84))
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.custom_minimum_size = Vector2(0, 36)
	story_panel.add_child(story_label)

	body_label = Label.new()
	_apply_retro_label(body_label, 10, Color(0.92, 0.93, 0.94))
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.custom_minimum_size = Vector2(0, 70)
	layout.add_child(body_label)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 12)
	layout.add_child(button_row)

	primary_button = _make_button()
	secondary_button = _make_button()
	tertiary_button = _make_button()
	button_row.add_child(primary_button)
	button_row.add_child(secondary_button)
	button_row.add_child(tertiary_button)

	var log_panel := PanelContainer.new()
	log_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.018, 0.035), Color(0.42, 0.46, 0.58), 2))
	layout.add_child(log_panel)

	log_label = Label.new()
	_apply_retro_label(log_label, 9, MUTED_TEXT)
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.custom_minimum_size = Vector2(0, 46)
	log_panel.add_child(log_label)

	primary_button.pressed.connect(_on_primary_pressed)
	secondary_button.pressed.connect(_on_secondary_pressed)
	tertiary_button.pressed.connect(_on_tertiary_pressed)


func _panel_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_content_margin_all(9)
	style.set_corner_radius_all(0)
	return style


func _apply_retro_label(label: Label, font_size: int, color: Color) -> void:
	if retro_font != null:
		label.add_theme_font_override("font", retro_font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 1)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	label.add_theme_constant_override("line_spacing", 4)


func _apply_retro_button(button: Button, font_size: int) -> void:
	if retro_font != null:
		button.add_theme_font_override("font", retro_font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0))
	button.add_theme_color_override("font_hover_color", Color(0.96, 1.0, 1.0))
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_color_override("font_pressed_color", GOLD)
	button.add_theme_constant_override("outline_size", 1)
	button.add_theme_color_override("font_outline_color", INK)


func _make_button() -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(250, 42)
	button.focus_mode = Control.FOCUS_ALL
	_apply_retro_button(button, 9)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.015, 0.018, 0.035), Color(0.78, 0.82, 0.92), 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.025, 0.04, 0.07), CYAN, 2))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0.03, 0.045, 0.075), GOLD, 3))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.12, 0.08, 0.02), GOLD, 3))
	return button


func _set_buttons(primary: String, secondary: String = "", tertiary: String = "") -> void:
	primary_button.text = _button_text(primary)
	primary_button.visible = primary != ""
	secondary_button.text = _button_text(secondary)
	secondary_button.visible = secondary != ""
	tertiary_button.text = _button_text(tertiary)
	tertiary_button.visible = tertiary != ""
	primary_button.grab_focus()


func _button_text(text: String) -> String:
	if text == "":
		return ""
	return "> %s" % text.to_upper()


func _set_presentation(mode: String, speaker: String, text: String) -> void:
	visual_mode = mode
	dialogue_speaker = speaker
	dialogue_text = text
	presentation_time = 0.0
	scene_flash = 1.0
	_set_music_for_mode(mode)
	if dialogue_speaker_label != null:
		dialogue_speaker_label.text = dialogue_speaker.to_upper()
	if dialogue_label != null:
		dialogue_label.text = dialogue_text
	queue_redraw()


func _set_music_target_for_mode(mode: String) -> void:
	match _music_key_for_mode(mode):
		"battle":
			music_target_db = MUSIC_BATTLE_DB
		"map":
			music_target_db = MUSIC_MAP_DB
		"victory":
			music_target_db = MUSIC_REWARD_DB
		_:
			music_target_db = MUSIC_FORGE_DB


func _set_story_trace(text: String) -> void:
	if story_label != null:
		story_label.text = "SIGNAL TRACE // %s" % text


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), INK)
	if stage_spacer == null or stage_spacer.size.x <= 0.0:
		return

	var stage := Rect2(stage_spacer.position, stage_spacer.size)
	_draw_stage(stage.grow(-2.0))


func _draw_stage(stage: Rect2) -> void:
	draw_rect(stage, Color(0.06, 0.075, 0.10))
	_draw_pixel_rect(stage.position, stage.size, SKY)
	_draw_dithered_sky(stage)
	draw_rect(Rect2(stage.position + Vector2(0, stage.size.y * 0.66), Vector2(stage.size.x, stage.size.y * 0.34)), EARTH)
	_draw_floor_tiles(stage)

	match visual_mode:
		"forge":
			_draw_forge(stage)
		"egg":
			_draw_egg(stage)
		"map":
			_draw_map(stage)
		"battle":
			_draw_battle(stage)
		"victory":
			_draw_victory(stage)
		_:
			_draw_forge(stage)

	if scene_flash > 0.0:
		draw_rect(stage, Color(CYAN.r, CYAN.g, CYAN.b, scene_flash * 0.10))
	_draw_crt_overlay(stage)
	draw_rect(stage, GOLD, false, 2.0)


func _draw_pixel_rect(pos: Vector2, rect_size: Vector2, color: Color) -> void:
	draw_rect(Rect2(pos.snapped(Vector2.ONE), rect_size.snapped(Vector2.ONE)), color)


func _draw_outline_rect(pos: Vector2, rect_size: Vector2, fill: Color, outline: Color = Color(0.02, 0.02, 0.03)) -> void:
	_draw_pixel_rect(pos, rect_size, outline)
	_draw_pixel_rect(pos + Vector2(PIXEL, PIXEL), rect_size - Vector2(PIXEL * 2.0, PIXEL * 2.0), fill)


func _draw_dithered_sky(stage: Rect2) -> void:
	var p := stage.position
	for i in range(24):
		var x := p.x + float((i * 73) % int(stage.size.x))
		var y := p.y + 18.0 + float((i * 29) % int(stage.size.y * 0.42))
		var color := Color(0.18, 0.30, 0.32, 0.46) if i % 3 == 0 else Color(0.08, 0.11, 0.15, 0.42)
		_draw_pixel_rect(Vector2(x, y).snapped(Vector2(PIXEL, PIXEL)), Vector2(PIXEL * 2.0, PIXEL), color)


func _draw_floor_tiles(stage: Rect2) -> void:
	var p := stage.position
	var floor_y := p.y + stage.size.y * 0.66
	for i in range(18):
		var x := p.x + i * 74.0 - fmod(anim_time * 10.0, 74.0)
		draw_line(Vector2(x, floor_y), Vector2(x - 40.0, stage.end.y), Color(0.11, 0.10, 0.10), 1.0)
	for i in range(4):
		var y := floor_y + 24.0 + i * 24.0
		draw_line(Vector2(p.x, y), Vector2(stage.end.x, y), Color(0.11, 0.10, 0.10), 1.0)


func _draw_crt_overlay(stage: Rect2) -> void:
	for i in range(int(stage.size.y / 6.0)):
		var y := stage.position.y + i * 6.0
		draw_line(Vector2(stage.position.x, y), Vector2(stage.end.x, y), Color(0.0, 0.0, 0.0, 0.12), 1.0)
	for i in range(8):
		var x := stage.position.x + float((i * 157 + int(anim_time * 24.0)) % int(stage.size.x))
		draw_line(Vector2(x, stage.position.y), Vector2(x + 26.0, stage.end.y), Color(CYAN.r, CYAN.g, CYAN.b, 0.035), 1.0)


func _draw_label_chip(pos: Vector2, chip_size: Vector2, accent: Color) -> void:
	_draw_outline_rect(pos, chip_size, Color(0.045, 0.05, 0.065), accent)
	draw_line(pos + Vector2(12, chip_size.y - 12), pos + Vector2(chip_size.x - 12, chip_size.y - 12), accent, 2.0)


func _draw_texture_asset(key: String, rect: Rect2, modulate: Color = Color.WHITE) -> bool:
	var texture := slice_textures.get(key) as Texture2D
	if texture == null:
		return false
	draw_texture_rect(texture, rect, false, modulate)
	return true


func _draw_animation_asset(prefix: String, rect: Rect2, frame_count: int, modulate: Color = Color.WHITE, frame_duration: float = 0.12, elapsed: float = -1.0, loop: bool = true) -> bool:
	if frame_count <= 0:
		return false
	var time := battle_phase_time if elapsed < 0.0 else elapsed
	var frame := int(time / frame_duration)
	if loop:
		frame = frame % frame_count
	else:
		frame = mini(frame, frame_count - 1)
	return _draw_texture_asset("%s_%d" % [prefix, frame], rect, modulate)


func _draw_animation_or_texture(prefix: String, fallback_key: String, rect: Rect2, frame_count: int, modulate: Color = Color.WHITE, frame_duration: float = 0.12, elapsed: float = -1.0, loop: bool = true) -> bool:
	if _draw_animation_asset(prefix, rect, frame_count, modulate, frame_duration, elapsed, loop):
		return true
	return _draw_texture_asset(fallback_key, rect, modulate)


func _draw_readable_animation_or_texture(prefix: String, fallback_key: String, rect: Rect2, frame_count: int, accent: Color, frame_duration: float = 0.12, elapsed: float = -1.0, loop: bool = true, modulate: Color = Color.WHITE) -> bool:
	var shadow_rect := rect.grow(5.0)
	shadow_rect.position += Vector2(4.0, 7.0)
	var glow_rect := rect.grow(3.0)
	var shadow_modulate := Color(0.0, 0.0, 0.0, 0.76)
	var glow_modulate := Color(accent.r, accent.g, accent.b, 0.30)
	if not _draw_animation_asset(prefix, shadow_rect, frame_count, shadow_modulate, frame_duration, elapsed, loop):
		_draw_texture_asset(fallback_key, shadow_rect, shadow_modulate)
	if not _draw_animation_asset(prefix, glow_rect, frame_count, glow_modulate, frame_duration, elapsed, loop):
		_draw_texture_asset(fallback_key, glow_rect, glow_modulate)
	var drawn := _draw_animation_or_texture(prefix, fallback_key, rect, frame_count, modulate, frame_duration, elapsed, loop)
	if drawn:
		_draw_animation_or_texture(prefix, fallback_key, rect, frame_count, modulate, frame_duration, elapsed, loop)
	return drawn


func _draw_readable_manifest_animation(keys: Dictionary, rect: Rect2, accent: Color, elapsed: float = -1.0, modulate: Color = Color.WHITE) -> bool:
	if keys.is_empty():
		return false
	return _draw_readable_animation_or_texture(
		str(keys.get("clip_prefix", "")),
		str(keys.get("fallback_key", "")),
		rect,
		int(keys.get("frame_count", 1)),
		accent,
		float(keys.get("frame_duration", 0.12)),
		elapsed,
		bool(keys.get("loop", false)),
		modulate
	)


func _battle_animation_keys_for_action(actor_set_id: StringName, move_id: StringName) -> Dictionary:
	if battle_animation_manifest == null:
		return {}
	var actor_set = battle_animation_manifest.find_actor_set(actor_set_id)
	if actor_set == null:
		return {}
	var move = battle_move_definitions.get(move_id)
	if move == null:
		return {}
	var binding = actor_set.find_binding_for_move(move.move_id, move.animation_action_id)
	if binding == null:
		return {}
	var clip = battle_animation_manifest.find_clip(binding.clip_id)
	if clip == null:
		return {}
	var keys := _battle_clip_keys(binding.clip_id, _fallback_texture_for_actor(actor_set_id))
	keys["binding_id"] = str(binding.binding_id)
	keys["vfx_key"] = str(binding.vfx_clip_id)
	keys["receive_clip_prefix"] = str(binding.receive_clip_id)
	keys["presentation_event_id"] = str(binding.presentation_event_id)
	return keys


func _battle_clip_keys(clip_id: StringName, fallback_key: String) -> Dictionary:
	if battle_animation_manifest == null:
		return {}
	var clip = battle_animation_manifest.find_clip(clip_id)
	if clip == null:
		return {}
	return {
		"clip_prefix": str(clip.clip_id),
		"fallback_key": fallback_key,
		"frame_count": int(clip.frame_count),
		"frame_duration": max(0.001, float(clip.frame_duration_ms) / 1000.0),
		"loop": bool(clip.loop),
	}


func _fallback_texture_for_actor(actor_set_id: StringName) -> String:
	if actor_set_id == &"admin_protocol":
		return "enemy_protocol"
	return "root_wyrmling"


func _ui_font() -> Font:
	if retro_font != null:
		return retro_font
	return get_theme_default_font()


func _battle_shake_offset() -> Vector2:
	if screen_shake <= 0.0:
		return Vector2.ZERO
	return Vector2(sin(anim_time * 84.0), cos(anim_time * 71.0)) * screen_shake * 5.0


func _draw_battle_banner(stage: Rect2, text: String, accent: Color) -> void:
	var font := _ui_font()
	var font_size := 10
	var banner := Rect2(stage.position + Vector2(stage.size.x * 0.5 - 180.0, 22.0), Vector2(360.0, 38.0))
	draw_rect(banner, Color(0.01, 0.012, 0.024, 0.94))
	draw_rect(banner, Color(0.0, 0.0, 0.0, 1.0), false, 4.0)
	draw_rect(banner.grow(-3.0), accent, false, 2.0)
	draw_string(font, banner.position + Vector2(16.0, 24.0), text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, banner.size.x - 32.0, font_size, accent)


func _battle_banner_text() -> String:
	if battle_phase == "telegraph":
		return ENEMY_WARNING_BANNER
	return active_move_name


func _draw_floating_battle_text(stage: Rect2) -> void:
	if floating_text_time <= 0.0 or floating_text == "":
		return
	var font := _ui_font()
	var side_x := stage.position.x + stage.size.x * (0.72 if floating_text_side == "enemy" else 0.24)
	var rise := (1.0 - floating_text_time) * 26.0
	var pos := Vector2(side_x - 70.0, stage.position.y + stage.size.y * 0.34 - rise)
	draw_string(font, pos + Vector2(2.0, 2.0), floating_text, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 18, Color(0.0, 0.0, 0.0, 0.8))
	draw_string(font, pos, floating_text, HORIZONTAL_ALIGNMENT_CENTER, 140.0, 18, floating_text_color)


func _draw_enemy_telegraph_marker(stage: Rect2, enemy_rect: Rect2, label: String, accent: Color) -> void:
	var pulse := 0.5 + 0.5 * sin(anim_time * 8.0)
	var marker_color := accent.lerp(GOLD, pulse * 0.35)
	var target := enemy_rect.grow(12.0 + pulse * 4.0)
	_draw_corner_brackets(target, Color(0.0, 0.0, 0.0, 0.86), 8.0, 38.0)
	_draw_corner_brackets(target, marker_color, 4.0, 32.0)

	var font := _ui_font()
	var tag_size := Vector2(196.0, 34.0)
	var tag_x: float = clampf(target.position.x + target.size.x * 0.5 - tag_size.x * 0.5, stage.position.x + 12.0, stage.end.x - tag_size.x - 12.0)
	var tag_y: float = maxf(stage.position.y + 10.0, target.position.y - 82.0)
	var tag := Rect2(Vector2(tag_x, tag_y), tag_size)
	draw_rect(tag, Color(0.012, 0.012, 0.022, 0.96))
	draw_rect(tag, Color(0.0, 0.0, 0.0, 1.0), false, 4.0)
	draw_rect(tag.grow(-3.0), marker_color, false, 2.0)
	draw_string(font, tag.position + Vector2(10.0, 22.0), label.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, tag.size.x - 20.0, 9, marker_color)

	var alert := Rect2(Vector2(target.position.x + target.size.x * 0.5 - 20.0, tag.end.y + 7.0), Vector2(40.0, 34.0))
	draw_rect(alert, Color(0.02, 0.014, 0.018, 0.94))
	draw_rect(alert, marker_color, false, 3.0)
	draw_string(font, alert.position + Vector2(0.0, 25.0), "!", HORIZONTAL_ALIGNMENT_CENTER, alert.size.x, 18, marker_color)


func _draw_corner_brackets(rect: Rect2, color: Color, line_width: float, length: float) -> void:
	var left := rect.position.x
	var right := rect.end.x
	var top := rect.position.y
	var bottom := rect.end.y
	draw_line(Vector2(left, top), Vector2(left + length, top), color, line_width)
	draw_line(Vector2(left, top), Vector2(left, top + length), color, line_width)
	draw_line(Vector2(right, top), Vector2(right - length, top), color, line_width)
	draw_line(Vector2(right, top), Vector2(right, top + length), color, line_width)
	draw_line(Vector2(left, bottom), Vector2(left + length, bottom), color, line_width)
	draw_line(Vector2(left, bottom), Vector2(left, bottom - length), color, line_width)
	draw_line(Vector2(right, bottom), Vector2(right - length, bottom), color, line_width)
	draw_line(Vector2(right, bottom), Vector2(right, bottom - length), color, line_width)


func _stage_asset_rect(stage: Rect2, source_size: Vector2) -> Rect2:
	var scale := minf(stage.size.x / source_size.x, stage.size.y / source_size.y)
	var draw_size := source_size * scale
	return Rect2(stage.position + (stage.size - draw_size) * 0.5, draw_size)


func _draw_dragonsim_hologram_row(origin: Vector2, scale: float) -> void:
	var keys := [
		"dragonsim_fire",
		"dragonsim_ice",
		"dragonsim_stone",
		"dragonsim_storm",
		"dragonsim_shadow",
		"dragonsim_venom",
	]
	for i in range(keys.size()):
		var pos := origin + Vector2(i * 82.0, sin(anim_time * 2.4 + i) * 3.0)
		_draw_outline_rect(pos + Vector2(8, 88) * scale, Vector2(76, 22) * scale, Color(0.035, 0.05, 0.065), CYAN)
		_draw_texture_asset(keys[i], Rect2(pos, Vector2(92, 70) * scale), Color(1.0, 1.0, 1.0, 0.78))


func _draw_forge(stage: Rect2) -> void:
	var p := stage.position
	var s := stage.size
	var floor_y := p.y + s.y * 0.70

	if _draw_texture_asset("forge_hub", stage):
		_draw_texture_asset("felix", Rect2(p + Vector2(252, floor_y - 188.0), Vector2(154, 182)))
		var egg_rect := Rect2(p + Vector2(s.x * 0.565, floor_y - 184.0 + sin(anim_time * 2.2) * 4.0), Vector2(150, 150))
		_draw_animation_or_texture("root_egg_idle", "root_egg", egg_rect, 4, Color.WHITE, 0.18, anim_time, true)
		_draw_dragonsim_hologram_row(p + Vector2(56, 28), 0.42)
		_draw_label_chip(p + Vector2(s.x * 0.565, floor_y - 28.0), Vector2(196, 32), ROOT_GREEN)
		return

	_draw_server_bank(p + Vector2(42, 36), Vector2(238, 182))
	_draw_outline_rect(p + Vector2(406, floor_y - 96.0), Vector2(260, 94), Color(0.16, 0.09, 0.06))
	for i in range(11):
		_draw_pixel_rect(p + Vector2(426 + i * 20, floor_y - 78.0 + float((i * 9) % 22)), Vector2(12, 38), Color(0.88, 0.28, 0.12))
	draw_rect(Rect2(p + Vector2(430, floor_y - 38.0), Vector2(210, 18)), Color(0.95, 0.46, 0.18))
	draw_rect(Rect2(p + Vector2(450, floor_y - 72.0), Vector2(170, 6)), GOLD)

	var egg_center := p + Vector2(760, floor_y - 86.0 + sin(anim_time * 2.2) * 4.0)
	for i in range(12):
		var angle := float(i) / 12.0 * TAU + anim_time * 0.18
		draw_line(egg_center, egg_center + Vector2(cos(angle) * 118.0, sin(angle) * 74.0), Color(CYAN.r, CYAN.g, CYAN.b, 0.26), 2.0)
	_draw_egg_shape(egg_center, 46.0, 64.0, Color(0.80, 0.93, 0.70), ROOT_GREEN)
	_draw_label_chip(egg_center + Vector2(-86, 78), Vector2(172, 34), ROOT_GREEN)

	var door_x := p.x + s.x - 246.0
	_draw_outline_rect(Vector2(door_x, floor_y - 160.0), Vector2(172, 160), Color(0.08, 0.10, 0.13))
	for i in range(5):
		_draw_pixel_rect(Vector2(door_x + 24.0, floor_y - 136.0 + i * 24.0), Vector2(124, 10), Color(0.15, 0.19, 0.24))
	_draw_pixel_rect(Vector2(door_x + 56.0, floor_y - 88.0), Vector2(58, 44), Color(0.24, 0.13, 0.08))
	_draw_pixel_rect(Vector2(door_x + 132.0, floor_y - 84.0), Vector2(14, 14), WARNING)


func _draw_egg(stage: Rect2) -> void:
	var p := stage.position
	var floor_y := p.y + stage.size.y * 0.70

	if _draw_texture_asset("hatchery", stage):
		_draw_texture_asset("felix_portrait", Rect2(p + Vector2(stage.size.x - 194.0, 28), Vector2(148, 148)))
		var hatch_rect := Rect2(p + Vector2(stage.size.x * 0.5 - 215.0, floor_y - 220.0), Vector2(430, 242))
		if not _draw_animation_asset("hatch_reveal", hatch_rect, 8, Color.WHITE, 0.12, presentation_time, false):
			_draw_animation_or_texture("root_idle", "root_wyrmling", Rect2(p + Vector2(stage.size.x * 0.5 + 28.0, floor_y - 126.0 + sin(anim_time * 3.0) * 3.0), Vector2(160, 128)), 4, Color.WHITE, 0.16, anim_time, true)
			_draw_animation_or_texture("root_egg_idle", "root_egg", Rect2(p + Vector2(stage.size.x * 0.5 - 176.0, floor_y - 202.0), Vector2(160, 160)), 4, Color.WHITE, 0.18, anim_time, true)
		return

	var ring_center := p + Vector2(230, floor_y - 84.0)
	draw_circle(ring_center, 96, Color(0.08, 0.18, 0.13))
	draw_arc(ring_center, 98, 0.0, TAU, 32, CYAN, 4.0)
	draw_arc(ring_center, 76, anim_time, anim_time + TAU * 0.72, 20, GOLD, 4.0)
	_draw_egg_shape(ring_center, 54.0, 76.0, Color(0.78, 0.93, 0.67), ROOT_GREEN)
	draw_line(ring_center + Vector2(-14, -58), ring_center + Vector2(12, -24), WARNING, 4.0)
	draw_line(ring_center + Vector2(12, -24), ring_center + Vector2(-10, 16), WARNING, 4.0)
	draw_line(ring_center + Vector2(-10, 16), ring_center + Vector2(24, 64), WARNING, 4.0)

	_draw_dragon(p + Vector2(508, floor_y - 20.0), 0.98, ROOT_GREEN)
	for i in range(11):
		var x := p.x + 360.0 + i * 36.0
		var y := p.y + 58.0 + sin(anim_time * 2.2 + float(i) * 0.7) * 18.0
		_draw_pixel_rect(Vector2(x, y), Vector2(8, 8), CYAN if i % 2 == 0 else GOLD)

	_draw_server_bank(p + Vector2(790, 46), Vector2(276, 166))
	_draw_label_chip(p + Vector2(804, 230), Vector2(248, 34), ROOT_GREEN)


func _draw_map(stage: Rect2) -> void:
	var p := stage.position

	if _draw_texture_asset("village_edge_map", stage):
		_draw_animation_or_texture("root_idle", "root_wyrmling", Rect2(p + Vector2(72, stage.size.y - 118.0 + sin(anim_time * 3.0) * 2.0), Vector2(104, 84)), 4, Color.WHITE, 0.16, anim_time, true)
		return

	_draw_pastoral_hills(stage)
	var route := [
		p + Vector2(128, 206),
		p + Vector2(292, 146),
		p + Vector2(470, 168),
		p + Vector2(640, 112),
		p + Vector2(818, 162),
	]

	for i in range(route.size() - 1):
		draw_line(route[i], route[i + 1], Color(0.47, 0.55, 0.47), 10.0)
		draw_line(route[i], route[i + 1], Color(0.18, 0.21, 0.16), 3.0)

	for i in range(route.size()):
		var node_color := ROOT_GREEN if i == 0 else Color(0.35, 0.38, 0.45)
		_draw_outline_rect(route[i] - Vector2(30, 30), Vector2(60, 60), Color(0.08, 0.13, 0.12))
		_draw_pixel_rect(route[i] - Vector2(20, 20), Vector2(40, 40), node_color)
		_draw_pixel_rect(route[i] - Vector2(8, 8), Vector2(16, 16), GOLD if i == 1 else Color(0.15, 0.16, 0.18))

	_draw_outline_rect(p + Vector2(890, 56), Vector2(176, 160), Color(0.18, 0.06, 0.07))
	_draw_pixel_rect(p + Vector2(910, 76), Vector2(136, 120), WARNING)
	_draw_pixel_rect(p + Vector2(930, 96), Vector2(96, 80), Color(0.11, 0.035, 0.045))
	draw_line(p + Vector2(930, 96), p + Vector2(1026, 176), Color(0.95, 0.80, 0.36), 5.0)
	draw_line(p + Vector2(1026, 96), p + Vector2(930, 176), Color(0.95, 0.80, 0.36), 5.0)

	_draw_dragon(p + Vector2(112, 246), 0.60, ROOT_GREEN)
	_draw_outline_rect(p + Vector2(58, 208), Vector2(62, 46), Color(0.12, 0.09, 0.07))
	_draw_pixel_rect(p + Vector2(74, 186), Vector2(30, 26), GOLD)


func _draw_battle(stage: Rect2) -> void:
	var p := stage.position
	var s := stage.size
	var floor_y := p.y + s.y * 0.72

	if _draw_texture_asset("battlefield", stage):
		var shake := _battle_shake_offset()
		var player_recoil := Vector2(-18.0, 4.0) if battle_phase == "enemy_impact" else Vector2.ZERO
		var player_rect := Rect2(p + shake + player_recoil + Vector2(96, floor_y - 144.0 + sin(anim_time * 3.0) * 4.0), Vector2(224, 168))
		if battle_phase == "enemy_impact":
			var player_receive_clip_id := &"root_wyrmling_defend_hit" if player_defending_this_turn else &"root_wyrmling_hurt"
			if player_hp <= 0:
				player_receive_clip_id = &"root_wyrmling_ko"
			if not _draw_readable_manifest_animation(_battle_clip_keys(player_receive_clip_id, "root_wyrmling"), player_rect, WARNING, battle_phase_time):
				_draw_texture_asset("root_wyrmling", player_rect)
		elif battle_phase in ["player_windup", "player_impact"]:
			var lunge := Vector2(34.0 if battle_phase == "player_impact" else 10.0, 0.0)
			var scale_boost := Vector2.ZERO
			if active_move_fx == "thorn":
				lunge = Vector2(54.0, -2.0) if battle_phase == "player_impact" else Vector2(12.0, 2.0)
				scale_boost = Vector2(22.0, 16.0)
			elif active_move_fx == "guard":
				lunge = Vector2(12.0, 18.0) if battle_phase == "player_impact" else Vector2(4.0, 14.0)
				scale_boost = Vector2(-18.0, -14.0)
			var player_action_keys := _battle_animation_keys_for_action(&"root_wyrmling", active_move_id)
			player_action_keys["loop"] = false
			if not _draw_readable_manifest_animation(player_action_keys, Rect2(player_rect.position + lunge, player_rect.size + scale_boost), ROOT_GREEN, battle_phase_time):
				_draw_texture_asset("root_wyrmling", Rect2(player_rect.position + lunge, player_rect.size + scale_boost))
		else:
			if not _draw_readable_manifest_animation(_battle_clip_keys(&"root_wyrmling_idle", "root_wyrmling"), Rect2(p + shake + Vector2(106, floor_y - 136.0 + sin(anim_time * 3.0) * 4.0), Vector2(192, 154)), ROOT_GREEN, anim_time):
				_draw_readable_animation_or_texture("root_idle_battle", "root_wyrmling", Rect2(p + shake + Vector2(106, floor_y - 136.0 + sin(anim_time * 3.0) * 4.0), Vector2(192, 154)), 4, ROOT_GREEN, 0.16, anim_time, true)
		_draw_texture_asset("npc_logic_bomb", Rect2(p + Vector2(s.x - 370.0, floor_y - 112.0 + sin(anim_time * 2.7) * 3.0), Vector2(86, 86)), Color(1.0, 1.0, 1.0, 0.24))
		_draw_texture_asset("npc_recursive_golem", Rect2(p + Vector2(s.x - 126.0, floor_y - 120.0 + cos(anim_time * 2.1) * 3.0), Vector2(86, 94)), Color(1.0, 1.0, 1.0, 0.22))
		var enemy_recoil := Vector2(28.0, -8.0) if battle_phase == "player_impact" else Vector2.ZERO
		var enemy_rect := Rect2(p - shake + enemy_recoil + Vector2(s.x - 300.0 + sin(anim_time * 9.0) * 2.0, floor_y - 174.0), Vector2(188, 166))
		var enemy_modulate := Color(1.0, 0.82, 0.72, 1.0) if battle_phase == "player_impact" else Color.WHITE
		var enemy_base_clip_id := &"admin_protocol_idle"
		if battle_phase in ["telegraph", "enemy_windup"]:
			enemy_base_clip_id = &"admin_protocol_telegraph"
		elif battle_phase == "player_impact":
			enemy_base_clip_id = &"admin_protocol_ko" if enemy_hp <= 0 else &"admin_protocol_hurt"
		if not _draw_readable_manifest_animation(_battle_clip_keys(enemy_base_clip_id, "enemy_protocol"), enemy_rect, MAGENTA, anim_time if battle_phase == "telegraph" else battle_phase_time, enemy_modulate):
			_draw_readable_animation_or_texture("enemy_idle_battle", "enemy_protocol", enemy_rect, 4, MAGENTA, 0.14, anim_time, true, enemy_modulate)
		if battle_phase in ["enemy_windup", "enemy_impact"]:
			var enemy_action_keys := _battle_animation_keys_for_action(&"admin_protocol", &"data_leak")
			enemy_action_keys["loop"] = false
			if not _draw_readable_manifest_animation(enemy_action_keys, Rect2(enemy_rect.position + Vector2(-56.0 if battle_phase == "enemy_impact" else -18.0, -10.0), Vector2(224, 168)), MAGENTA, battle_phase_time, Color(1.0, 1.0, 1.0, 0.86)):
				_draw_texture_asset("enemy_protocol", Rect2(enemy_rect.position + Vector2(-56.0 if battle_phase == "enemy_impact" else -18.0, -10.0), Vector2(224, 168)), Color(1.0, 1.0, 1.0, 0.86))
		if battle_phase == "player_impact":
			var impact_keys := _battle_animation_keys_for_action(&"root_wyrmling", active_move_id)
			var impact_vfx_key := str(impact_keys.get("vfx_key", "vfx_root_spark"))
			if active_move_fx == "guard":
				_draw_texture_asset(impact_vfx_key, Rect2(p + Vector2(144.0, floor_y - 126.0), Vector2(132, 88)), Color(1.0, 1.0, 1.0, 0.76))
			else:
				var vfx_size := Vector2(230, 160) if active_move_fx == "thorn" else Vector2(190, 126)
				_draw_texture_asset(impact_vfx_key, Rect2(p + Vector2(s.x - 360.0, floor_y - 196.0), vfx_size), Color(1.0, 1.0, 1.0, 0.92))
		elif battle_phase == "enemy_impact":
			var enemy_impact_keys := _battle_animation_keys_for_action(&"admin_protocol", &"data_leak")
			_draw_texture_asset(str(enemy_impact_keys.get("vfx_key", "vfx_shadow_burst")), Rect2(p + Vector2(146.0, floor_y - 174.0), Vector2(190, 126)), Color(1.0, 1.0, 1.0, 0.86))
		_draw_hp_bar(p + Vector2(82, 82), 230.0, float(player_hp) / float(PLAYER_MAX_HP), ROOT_GREEN)
		_draw_hp_bar(p + Vector2(s.x - 312.0, 82), 230.0, float(enemy_hp) / float(ENEMY_MAX_HP), WARNING)
		if battle_phase == "telegraph":
			_draw_enemy_telegraph_marker(stage, enemy_rect, ENEMY_WARNING_MARKER, WARNING)
		elif battle_phase == "enemy_windup":
			_draw_enemy_telegraph_marker(stage, enemy_rect, "data leak", WARNING)
		elif battle_phase in ["player_windup", "player_impact"]:
			_draw_enemy_telegraph_marker(stage, enemy_rect, PLAYER_TARGET_MARKER, ROOT_GREEN)
		var phase_label := _battle_banner_text()
		var accent := ROOT_GREEN if battle_phase.begins_with("player") else WARNING if battle_phase.begins_with("enemy") else CYAN
		_draw_battle_banner(stage, phase_label, accent)
		_draw_floating_battle_text(stage)
		return

	_draw_pastoral_hills(stage)
	_draw_outline_rect(p + Vector2(58, 54), Vector2(344, 176), Color(0.07, 0.14, 0.10))
	_draw_dragon(p + Vector2(210, floor_y - 18.0), 1.16, ROOT_GREEN)
	_draw_hp_bar(p + Vector2(118, 92), 220.0, float(player_hp) / float(PLAYER_MAX_HP), ROOT_GREEN)

	var fallback_enemy_rect := Rect2(p + Vector2(s.x - 402, 54), Vector2(344, 176))
	_draw_outline_rect(fallback_enemy_rect.position, fallback_enemy_rect.size, Color(0.17, 0.06, 0.08))
	_draw_enemy(p + Vector2(s.x - 220, floor_y - 36.0))
	_draw_hp_bar(p + Vector2(s.x - 336, 92), 220.0, float(enemy_hp) / float(ENEMY_MAX_HP), WARNING)

	if battle_phase == "telegraph":
		_draw_enemy_telegraph_marker(stage, fallback_enemy_rect, ENEMY_WARNING_MARKER, WARNING)
	elif battle_phase == "enemy_windup":
		_draw_enemy_telegraph_marker(stage, fallback_enemy_rect, "data leak", WARNING)
	elif battle_phase in ["player_windup", "player_impact"]:
		_draw_enemy_telegraph_marker(stage, fallback_enemy_rect, PLAYER_TARGET_MARKER, ROOT_GREEN)
	var fallback_phase_label := _battle_banner_text()
	var fallback_accent := ROOT_GREEN if battle_phase.begins_with("player") else WARNING if battle_phase.begins_with("enemy") else CYAN
	_draw_battle_banner(stage, fallback_phase_label, fallback_accent)
	_draw_floating_battle_text(stage)


func _draw_victory(stage: Rect2) -> void:
	var p := stage.position
	var s := stage.size
	var floor_y := p.y + s.y * 0.70

	if _draw_texture_asset("victory", stage):
		_draw_animation_or_texture("root_idle", "root_wyrmling", Rect2(p + Vector2(88, floor_y - 138.0 + sin(anim_time * 3.0) * 3.0), Vector2(190, 152)), 4, Color.WHITE, 0.16, anim_time, true)
		_draw_animation_or_texture("data_scraps_pickup", "data_scraps", Rect2(p + Vector2(s.x * 0.45, floor_y - 164.0), Vector2(128, 96)), 4, Color.WHITE, 0.14, presentation_time, true)
		for i in range(8):
			var sparkle := p + Vector2(s.x * 0.36 + (i % 4) * 44.0, 58.0 + (i / 4) * 34.0)
			_draw_pixel_rect(sparkle + Vector2(sin(anim_time * 4.0 + i) * 4.0, 0), Vector2(8, 8), GOLD if i % 2 == 0 else CYAN)
		return

	_draw_pastoral_hills(stage)
	_draw_dragon(p + Vector2(170, floor_y - 30.0), 1.18, ROOT_GREEN)
	for i in range(10):
		var sparkle := p + Vector2(218 + (i % 5) * 36, 74 + (i / 5) * 36)
		_draw_pixel_rect(sparkle + Vector2(sin(anim_time * 4.0 + i) * 4.0, 0), Vector2(8, 8), GOLD if i % 2 == 0 else CYAN)

	_draw_outline_rect(p + Vector2(430, 112), Vector2(190, 96), Color(0.13, 0.08, 0.05))
	_draw_outline_rect(p + Vector2(450, 88), Vector2(150, 40), GOLD)
	for i in range(7):
		_draw_pixel_rect(p + Vector2(462 + i * 22, 104 + (i % 2) * 18), Vector2(16, 16), Color(0.95, 0.62, 0.22))

	var route_start := p + Vector2(738, 176)
	for i in range(4):
		var node := route_start + Vector2(i * 86, sin(float(i)) * 20.0)
		if i > 0:
			var prev := route_start + Vector2((i - 1) * 86, sin(float(i - 1)) * 20.0)
			draw_line(prev, node, ROOT_GREEN, 5.0)
		draw_circle(node, 25, ROOT_GREEN)
		draw_circle(node, 9, GOLD)


func _draw_server_bank(pos: Vector2, bank_size: Vector2) -> void:
	_draw_outline_rect(pos, bank_size, Color(0.055, 0.065, 0.08))
	var rack_count := 5
	var rack_w := (bank_size.x - 28.0) / float(rack_count)
	for i in range(rack_count):
		var rack_pos := pos + Vector2(14.0 + i * rack_w, 18.0)
		_draw_outline_rect(rack_pos, Vector2(rack_w - 8.0, bank_size.y - 34.0), Color(0.08, 0.10, 0.12))
		for j in range(5):
			var y := rack_pos.y + 14.0 + j * 22.0
			_draw_pixel_rect(Vector2(rack_pos.x + 10.0, y), Vector2(rack_w - 30.0, 4.0), Color(0.12, 0.16, 0.18))
			var pulse := 0.45 + 0.55 * sin(anim_time * 3.0 + float(i * 2 + j))
			var light_color := CYAN.lerp(GOLD, maxf(0.0, pulse))
			_draw_pixel_rect(Vector2(rack_pos.x + rack_w - 28.0, y - 3.0), Vector2(8.0, 8.0), light_color)

func _draw_pastoral_hills(stage: Rect2) -> void:
	var p := stage.position
	var horizon := p.y + stage.size.y * 0.55
	for i in range(9):
		var x := p.x + i * 158.0 - 60.0
		var hill := PackedVector2Array([
			Vector2(x, horizon + 54.0),
			Vector2(x + 54.0, horizon - 18.0 - float(i % 3) * 10.0),
			Vector2(x + 128.0, horizon + 54.0),
		])
		draw_colored_polygon(hill, Color(0.12, 0.31, 0.18) if i % 2 == 0 else Color(0.10, 0.25, 0.16))
	for i in range(7):
		var trunk := p + Vector2(88.0 + i * 148.0, horizon + 18.0 + float((i * 11) % 18))
		_draw_pixel_rect(trunk, Vector2(12, 42), Color(0.16, 0.09, 0.05))
		_draw_pixel_rect(trunk + Vector2(-22, -26), Vector2(58, 34), Color(0.14, 0.42, 0.22))
		_draw_pixel_rect(trunk + Vector2(-12, -42), Vector2(38, 24), Color(0.22, 0.55, 0.27))


func _draw_hp_bar(origin: Vector2, width: float, ratio: float, fill: Color) -> void:
	var clamped: float = clamp(ratio, 0.0, 1.0)
	draw_rect(Rect2(origin, Vector2(width, 14)), Color(0.03, 0.035, 0.045))
	draw_rect(Rect2(origin, Vector2(width * clamped, 14)), fill)
	draw_rect(Rect2(origin, Vector2(width, 14)), Color(0.78, 0.80, 0.84), false, 1.0)


func _draw_egg_shape(center: Vector2, rx: float, ry: float, shell: Color, core: Color) -> void:
	var points := PackedVector2Array()
	for i in range(32):
		var angle := float(i) / 32.0 * TAU
		var taper: float = 1.0 - max(0.0, -sin(angle)) * 0.22
		points.append(center + Vector2(cos(angle) * rx * taper, sin(angle) * ry))
	draw_colored_polygon(points, shell)
	draw_polyline(points, core, 3.0, true)
	draw_circle(center + Vector2(14, -20), 10, Color(0.94, 1.0, 0.76))


func _draw_dragon(base: Vector2, scale: float, color: Color) -> void:
	var bob := sin(anim_time * 3.0) * 3.0 * scale
	var p := base + Vector2(0, bob)
	var px := PIXEL * scale
	var outline := Color(0.015, 0.025, 0.018)
	var shade := Color(color.r * 0.55, color.g * 0.55, color.b * 0.55)
	var light := Color(minf(color.r + 0.22, 1.0), minf(color.g + 0.16, 1.0), minf(color.b + 0.14, 1.0))

	_draw_outline_rect(p + Vector2(-44, -56) * scale, Vector2(72, 44) * scale, color, outline)
	_draw_outline_rect(p + Vector2(20, -74) * scale, Vector2(44, 36) * scale, color, outline)
	_draw_pixel_rect(p + Vector2(56, -62) * scale, Vector2(8, 8) * scale, Color(0.02, 0.05, 0.03))
	_draw_pixel_rect(p + Vector2(52, -70) * scale, Vector2(12, 6) * scale, light)
	_draw_pixel_rect(p + Vector2(-30, -40) * scale, Vector2(38, 12) * scale, light)
	_draw_pixel_rect(p + Vector2(-42, -22) * scale, Vector2(54, 10) * scale, shade)
	_draw_pixel_rect(p + Vector2(6, -86) * scale, Vector2(12, 24) * scale, LEAF_DARK)
	_draw_pixel_rect(p + Vector2(28, -98) * scale, Vector2(12, 28) * scale, LEAF_DARK)
	_draw_pixel_rect(p + Vector2(-74, -46) * scale, Vector2(40, 10) * scale, LEAF_DARK)
	_draw_pixel_rect(p + Vector2(-88, -36) * scale, Vector2(52, 10) * scale, LEAF_DARK)
	_draw_pixel_rect(p + Vector2(-102, -24) * scale, Vector2(64, 10) * scale, color)
	_draw_pixel_rect(p + Vector2(-112, -14) * scale, Vector2(30, 8) * scale, shade)
	_draw_pixel_rect(p + Vector2(-22, -14) * scale, Vector2(12, 34) * scale, outline)
	_draw_pixel_rect(p + Vector2(14, -14) * scale, Vector2(12, 34) * scale, outline)
	_draw_pixel_rect(p + Vector2(-18, 8) * scale, Vector2(18, 10) * scale, color)
	_draw_pixel_rect(p + Vector2(18, 8) * scale, Vector2(18, 10) * scale, color)
	for i in range(3):
		_draw_pixel_rect(p + Vector2(-12 + i * 14, -66 - i * 2) * scale, Vector2(8, 8) * scale, CYAN)


func _draw_enemy(base: Vector2) -> void:
	var shake := sin(anim_time * 9.0) * 2.0
	var p := base + Vector2(shake, 0)
	var core := Color(0.24, 0.06, 0.09)
	_draw_outline_rect(p + Vector2(-58, -82), Vector2(116, 72), core, Color(0.035, 0.0, 0.01))
	_draw_pixel_rect(p + Vector2(-42, -68), Vector2(84, 14), WARNING)
	_draw_pixel_rect(p + Vector2(-34, -48), Vector2(22, 14), GOLD)
	_draw_pixel_rect(p + Vector2(12, -48), Vector2(22, 14), GOLD)
	_draw_pixel_rect(p + Vector2(-8, -26), Vector2(16, 8), Color(0.03, 0.0, 0.0))
	for i in range(5):
		var x := -74.0 + i * 36.0
		draw_line(p + Vector2(x, -96), p + Vector2(x + 42, 8), WARNING, 4.0)
		draw_line(p + Vector2(x + 42, -96), p + Vector2(x, 8), Color(0.82, 0.12, 0.36), 2.0)
	_draw_pixel_rect(p + Vector2(-42, -10), Vector2(18, 42), WARNING)
	_draw_pixel_rect(p + Vector2(24, -10), Vector2(18, 42), WARNING)


func _show_intro() -> void:
	state = "intro"
	_set_presentation("map", "System", "The sky is still painted blue. The grass below it is already forgetting how to be grass.")
	title_label.text = "Rendered World Failure"
	status_label.text = "MATRIX FAILING | SWEEP INBOUND"
	_set_story_trace("The Rendered World is a pastoral simulation running on buried Astraeus hardware.")
	body_label.text = "Village Edge flickers between pasture, code seam, and deletion warning. The Mirror Admin has started preparing a Great Reset."
	log_label.text = "Signal found: Dragon Forge. Felix is trying to pull Skye out before the first sweep reaches her."
	_set_buttons("Continue")


func _show_intro_felix() -> void:
	state = "intro_felix"
	_play_sfx("select")
	_set_presentation("forge", "Felix", "Skye. Look at me, not the warnings. The Forge still recognizes your hands.")
	title_label.text = "Dragon Forge Signal"
	status_label.text = "SKYE: RESIDENT / OPERATOR"
	_set_story_trace("Skye registers as both resident and operator. The system cannot decide whether to save or erase her.")
	body_label.text = "Felix keeps his voice gentle, but the server bars behind him are dropping. The sealed Bulkhead will not open for him."
	log_label.text = "Felix has one plan left: let the Root Egg choose Skye and prove she belongs to the world."
	_set_buttons("Continue")


func _show_intro_egg() -> void:
	state = "intro_egg"
	_play_sfx("hatch_start")
	_set_presentation("forge", "Felix", "That egg is not a key. It is a frightened little guardian deciding whether to trust you.")
	title_label.text = "Root Egg"
	status_label.text = "ROOT SIGNAL RESPONDING"
	_set_story_trace("Root dragons are living repair protocols. They anchor damaged places long enough for Skye to mend them.")
	body_label.text = "The egg warms under cyan diagnostic light. If it answers, Skye can open Village Edge and fight the first deletion routine."
	log_label.text = "First meaningful action: hatch the Root Egg."
	_set_buttons("Enter Forge Hub")


func _show_hub() -> void:
	state = "hub"
	_play_sfx("select")
	_set_presentation("forge", "Felix", "The Bulkhead is locked until the egg chooses you. Not me. Not the Anvil. You.")
	title_label.text = "Forge Hub"
	status_label.text = "Scraps: %d | Dragon: none | Matrix: unstable" % scraps
	_set_story_trace("Felix is the Forge-keeper. He knows the world is simulated, but treats its people and dragons as alive because they are.")
	body_label.text = "Felix clears a ring of tools from the hatchery bench. The egg pulses in time with the server bars, and the sealed door to Village Edge waits for Skye's impossible operator signature."
	log_label.text = "Next action: hatch the Root Egg to create a bond the Mirror Admin cannot immediately erase."
	_set_buttons("Hatch Root Egg")


func _show_hatched() -> void:
	state = "hatched"
	_play_sfx("hatch_complete")
	_set_presentation("egg", "Felix", "There. Root signature stable. It is small, frightened, and very much alive.")
	title_label.text = "Hatchery Result"
	status_label.text = "Scraps: %d | Dragon: %s | HP: %d/%d" % [scraps, DRAGON_NAME, player_hp, PLAYER_MAX_HP]
	_set_story_trace("Dragons are guardian protocols with teeth, memory, and opinions. Root dragons anchor damaged places long enough for repair.")
	body_label.text = "The shell opens into a tiny green guardian protocol. %s chirps like a modem learning birdsong. The Bulkhead light turns amber: Village Edge is now reachable." % DRAGON_NAME
	log_label.text = "Bond formed: Skye has a companion and the Forge has a living repair key."
	_set_buttons("Enter Village Edge")


func _show_map() -> void:
	state = "map"
	_play_sfx("select")
	_set_presentation("map", "System", "Village Edge hazard detached. Route integrity: amber. Handler authorization required.")
	title_label.text = "Campaign Map: Village Edge"
	status_label.text = "Scraps: %d | Dragon: %s | HP: %d/%d | Node: HAZARD" % [scraps, DRAGON_NAME, player_hp, PLAYER_MAX_HP]
	_set_story_trace("Village Edge is a pastoral route sitting on top of hardware seams. The red node is an Admin quarantine routine wearing the shape of a monster.")
	body_label.text = "A fraying pasture route floats outside the Forge. Wireframe wheat flickers under the grass, and the red hazard tile blocks the first path Felix needs reopened."
	log_label.text = "Route rule: clear the quarantine node so the Forge can reach the wider Rendered World."
	_set_buttons("Start Battle", "Return to Hub")


func _show_battle_start() -> void:
	state = "battle"
	_play_sfx("select")
	_set_presentation("battle", "Felix", "The Admin broadcasts before it strikes. Read the warning, then pick Root Spark, Thorn Surge, or Defend.")
	enemy_hp = ENEMY_MAX_HP
	turn_count = 1
	battle_phase = "telegraph"
	battle_phase_time = 0.0
	battle_action_lock = false
	player_defending_this_turn = false
	active_move_name = ENEMY_WARNING_BANNER
	active_move_id = &"root_spark"
	active_move_fx = ""
	floating_text = ""
	floating_text_time = 0.0
	screen_shake = 0.0
	title_label.text = "Battle: Admin Protocol"
	_set_story_trace("This enemy is a severed deletion routine. Defeating it converts hostile code into Data Scraps the Forge can use.")
	_update_battle_text("INIT complete. Enemy warning detected: Data Leak is incoming.")


func _update_battle_text(event_text: String) -> void:
	_set_presentation("battle", "Battle", "Incoming enemy action: Data Leak. Choose Root Spark, Thorn Surge, or Defend as your response.")
	status_label.text = "ROOT %d/%d | ADMIN %d/%d" % [player_hp, PLAYER_MAX_HP, enemy_hp, ENEMY_MAX_HP]
	body_label.text = "Skye can read the enemy warning before impact. Root Spark repairs by force; Thorn Surge pins the hostile routine long enough to tear data loose."
	log_label.text = event_text
	_set_buttons("Root Spark", "Thorn Surge", "Defend")


func _show_float(text: String, side: String, color: Color) -> void:
	floating_text = text
	floating_text_side = side
	floating_text_color = color
	floating_text_time = 1.0


func _start_battle_action(action: String) -> void:
	if state != "battle" or battle_action_lock:
		return
	battle_action_lock = true
	match action:
		"thorn_surge":
			active_move_name = "Thorn Surge"
			active_move_id = &"thorn_surge"
			active_move_fx = "thorn"
		"defend":
			active_move_name = "Guarded Spark"
			active_move_id = &"guarded_spark"
			active_move_fx = "guard"
		_:
			active_move_name = "Root Spark"
			active_move_id = &"root_spark"
			active_move_fx = "spark"
	_set_buttons("", "", "")
	_play_battle_turn(action)


func _play_battle_turn(action: String) -> void:
	var defending: bool = action == "defend"
	player_defending_this_turn = defending
	var player_damage: int = PLAYER_ATTACK
	if action == "thorn_surge":
		player_damage = PLAYER_SPECIAL_ATTACK
	elif defending:
		player_damage = PLAYER_DEFEND_ATTACK
	var incoming_damage: int = max(2, ENEMY_ATTACK - 5) if defending else ENEMY_ATTACK
	battle_phase = "player_windup"
	battle_phase_time = 0.0
	log_label.text = "%s winds up %s..." % [DRAGON_NAME, active_move_name]
	var windup_cue := "root_spark"
	var windup_duration := 0.24
	if action == "thorn_surge":
		windup_cue = "thorn_surge"
		windup_duration = 0.42
	elif defending:
		windup_cue = "guarded_spark"
		windup_duration = 0.36
	_play_sfx(windup_cue)
	await get_tree().create_timer(windup_duration).timeout

	battle_phase = "player_impact"
	battle_phase_time = 0.0
	enemy_hp = max(0, enemy_hp - player_damage)
	var impact_cue := "impact"
	var impact_duration := 0.34
	var impact_color := ROOT_GREEN
	screen_shake = 0.75
	if action == "thorn_surge":
		impact_cue = "impact_heavy"
		impact_duration = 0.50
		impact_color = GOLD
		screen_shake = 1.35
	elif defending:
		impact_cue = "impact_guarded"
		impact_duration = 0.44
		impact_color = CYAN
		screen_shake = 0.95
	_show_float("-%d" % player_damage, "enemy", impact_color)
	_play_sfx(impact_cue)
	var event_text := "%s uses %s for %d damage." % [DRAGON_NAME, active_move_name, player_damage]
	log_label.text = event_text
	await get_tree().create_timer(impact_duration).timeout

	if enemy_hp <= 0:
		_play_sfx("enemy_down")
		_show_victory(event_text + " The protocol collapses into recoverable Data Scraps.")
		return

	battle_phase = "enemy_windup"
	battle_phase_time = 0.0
	active_move_name = "Data Leak"
	active_move_id = &"data_leak"
	active_move_fx = "shadow"
	log_label.text = "Detached Training Protocol winds up Data Leak..."
	_play_sfx("data_leak")
	await get_tree().create_timer(0.34).timeout

	battle_phase = "enemy_impact"
	battle_phase_time = 0.0
	player_hp = max(0, player_hp - incoming_damage)
	screen_shake = 0.85
	_show_float("-%d" % incoming_damage, "player", WARNING)
	_play_sfx("enemy_impact")
	event_text += " Enemy recoil deals %d damage." % incoming_damage
	log_label.text = event_text
	await get_tree().create_timer(0.36).timeout

	if player_hp <= 0:
		_show_defeat(event_text + " %s drops to 0 HP." % DRAGON_NAME)
		return

	turn_count += 1
	battle_phase = "telegraph"
	battle_phase_time = 0.0
	battle_action_lock = false
	player_defending_this_turn = false
	active_move_name = ENEMY_WARNING_BANNER
	_update_battle_text(event_text)


func _show_victory(event_text: String) -> void:
	state = "victory"
	_play_sfx("reward")
	_set_presentation("victory", "Felix", "Good. The node is quiet again. Bring those Scraps home before the pasture remembers how to scream.")
	scraps += BATTLE_REWARD_SCRAPS
	title_label.text = "Resolution: Victory"
	status_label.text = "Scraps: %d | %s HP: %d/%d | Node cleared" % [scraps, DRAGON_NAME, player_hp, PLAYER_MAX_HP]
	_set_story_trace("A cleared hazard proves Skye can stabilize places the Admin marked for deletion. This is the first tiny argument against the Great Reset.")
	body_label.text = "Village Edge stabilizes. A small cache of Data Scraps drops from the training protocol, and the route line turns green all the way back to the Forge."
	log_label.text = "%s Data Scraps recovered: enough to keep the Forge awake a little longer." % event_text
	_set_buttons("Return to Forge", "Restart Slice")


func _show_defeat(event_text: String) -> void:
	state = "defeat"
	_set_presentation("battle", "Felix", "Back to the Forge. No shame. We only lose the world if we stop learning.")
	title_label.text = "Resolution: Defeat"
	status_label.text = "Scraps: %d | %s HP: 0/%d | Node uncleared" % [scraps, DRAGON_NAME, PLAYER_MAX_HP]
	_set_story_trace("The Admin's deletion routine holds Village Edge for now, but Skye and the dragon survive the failed repair attempt.")
	body_label.text = "The failed attempt resolves cleanly: Skye returns to the Forge without partial rewards. Restart the slice and try Defend on the first TELEGRAPH."
	log_label.text = event_text
	_set_buttons("Restart Slice")


func _show_complete() -> void:
	state = "complete"
	_set_presentation("victory", "Felix", "Hatch, field, fight, return. That is not just a loop, Skye. It is proof the world can answer back.")
	title_label.text = "Slice Loop Complete"
	status_label.text = "Scraps: %d | %s HP: %d/%d | Full loop demonstrated" % [scraps, DRAGON_NAME, player_hp, PLAYER_MAX_HP]
	_set_story_trace("The slice covers the opening promise: bond with a dragon, repair a damaged place, and see the Mirror Admin threat through the system's behavior.")
	body_label.text = "Start -> Hatch -> Map -> Battle -> Reward -> Hub is complete. The next validation step is whether the player can name who Skye is, what Felix wants, what the Admin threatens, and why Data Scraps matter."
	log_label.text = "Record lore clarity in REPORT.md after playtest. A PROCEED verdict requires both loop completion and readable story intent."
	_set_buttons("Restart Slice")


func _restart() -> void:
	player_hp = PLAYER_MAX_HP
	enemy_hp = ENEMY_MAX_HP
	scraps = STARTING_SCRAPS
	turn_count = 1
	battle_phase = "telegraph"
	battle_phase_time = 0.0
	battle_action_lock = false
	active_move_id = &"root_spark"
	floating_text = ""
	floating_text_time = 0.0
	screen_shake = 0.0
	_show_intro()


func _on_primary_pressed() -> void:
	match state:
		"intro":
			_show_intro_felix()
		"intro_felix":
			_show_intro_egg()
		"intro_egg":
			_show_hub()
		"hub":
			_show_hatched()
		"hatched":
			_show_map()
		"map":
			_show_battle_start()
		"battle":
			_start_battle_action("root_spark")
		"victory":
			_show_complete()
		"defeat", "complete":
			_restart()


func _on_secondary_pressed() -> void:
	match state:
		"map":
			_show_hub()
		"battle":
			_start_battle_action("thorn_surge")
		"victory":
			_restart()


func _on_tertiary_pressed() -> void:
	if state == "battle":
		_start_battle_action("defend")
