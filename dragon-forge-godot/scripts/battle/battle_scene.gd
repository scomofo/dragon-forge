extends Control

signal battle_closed
signal profile_changed(profile: Dictionary)

const TacticalBattle := preload("res://scripts/sim/tactical_battle.gd")
const BattleBackdrop := preload("res://scripts/battle/battle_backdrop.gd")
const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const VisualSystemData := preload("res://scripts/sim/visual_system_data.gd")
const BattleVfxData := preload("res://scripts/sim/battle_vfx_data.gd")
const ProceduralVfxOverlay := preload("res://scripts/vfx/procedural_vfx_overlay.gd")

const PLAYER_DRAGON_TEXTURE := "res://assets/dragons/fire_stage1.png"
const PLAYER_DRAGON_TEXTURES := {
	"fire": "res://assets/dragons/fire_stage1.png",
	"shadow": "res://assets/dragons/shadow_stage1.png",
}
const ENEMY_TEXTURE := "res://assets/npc/firewall_sentinel_sprites.png"
const ENEMY_TINTS := {
	"firewall_sentinel": Color.WHITE,
	"corrupt_drake": Color("#d56c5e"),
	"scrap_wraith": Color("#8d92a1"),
	"lunar_mote": Color("#c0c8ff"),
	"sys_admin": Color("#e7f7ff"),
}
const VFX_FRAME_COUNT := 4

var battle: Dictionary
var profile: Dictionary
var battle_context: Dictionary = {}
var battle_intro_active := false
var victory_reward_awarded := false
var backdrop: BattleBackdrop
var flash_rect: ColorRect
var title_label: Label
var status_label: Label
var action_label: Label
var log_label: Label
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var focus_label: Label
var command_box: VBoxContainer
var player_sprite: TextureRect
var enemy_sprite: TextureRect
var vfx_sprite: TextureRect
var vfx_atlas: AtlasTexture
var procedural_vfx: ProceduralVfxOverlay
var player_frames: Array[Texture2D] = []
var idle_frame_index := 0
var command_buttons: Array[Button] = []
var active_tweens: Array[Tween] = []

func _ready() -> void:
	_build_ui()

func start_battle(profile_snapshot: Dictionary, enemy_id: String = "firewall_sentinel", context: Dictionary = {}) -> void:
	profile = profile_snapshot.duplicate(true)
	profile = DragonProgression.record_enemy_seen(profile, enemy_id)
	profile_changed.emit(profile.duplicate(true))
	battle_context = context.duplicate(true)
	battle = TacticalBattle.create_battle(profile["dragon_id"], DragonProgression.get_active_techniques(profile), enemy_id, DragonProgression.get_dragon_level(profile))
	battle_intro_active = true
	victory_reward_awarded = false
	player_frames = _dragon_sheet_frames(_player_texture_path(), _fallback_dragon_texture(profile.get("dragon_id", "fire")))
	player_sprite.texture = _dragon_frame(0)
	enemy_sprite.texture = _texture_from_png(ENEMY_TEXTURE, _fallback_enemy_texture(enemy_id))
	enemy_sprite.modulate = _enemy_modulate(enemy_id, 1)
	backdrop.set_context(battle_context, enemy_id)
	var opening_bark := _lore_bark_for_enemy(enemy_id)
	if opening_bark != "":
		battle["log"].append(opening_bark)
	_stop_idle_animation()
	_refresh()
	_start_idle_animation()
	call_deferred("_play_battle_intro")

func _build_ui() -> void:
	backdrop = BattleBackdrop.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	procedural_vfx = ProceduralVfxOverlay.new()
	procedural_vfx.set_anchors_preset(Control.PRESET_FULL_RECT)
	procedural_vfx.z_index = 12
	add_child(procedural_vfx)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 32
	root.offset_top = 24
	root.offset_right = -32
	root.offset_bottom = -24
	root.add_theme_constant_override("separation", 14)
	add_child(root)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", Color("#f3ead7"))
	root.add_child(title_label)

	var stage := HBoxContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.add_theme_constant_override("separation", 36)
	root.add_child(stage)

	var player_col := _build_combatant_panel("Guardian")
	player_sprite = player_col["sprite"]
	player_bar = player_col["bar"]
	stage.add_child(player_col["panel"])

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_theme_constant_override("separation", 14)
	stage.add_child(center)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 19)
	status_label.add_theme_color_override("font_color", Color("#f3ead7"))
	center.add_child(status_label)

	action_label = Label.new()
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action_label.add_theme_font_size_override("font_size", 28)
	action_label.add_theme_color_override("font_color", Color("#f0b66c"))
	action_label.modulate.a = 0.0
	center.add_child(action_label)

	vfx_sprite = TextureRect.new()
	vfx_sprite.visible = false
	vfx_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	vfx_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vfx_sprite.custom_minimum_size = Vector2(380, 150)
	center.add_child(vfx_sprite)

	command_box = VBoxContainer.new()
	command_box.add_theme_constant_override("separation", 8)
	center.add_child(command_box)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_label.add_theme_color_override("font_color", Color("#d6c7b0"))
	center.add_child(log_label)

	var enemy_col := _build_combatant_panel("Firewall Sentinel")
	enemy_sprite = enemy_col["sprite"]
	enemy_bar = enemy_col["bar"]
	stage.add_child(enemy_col["panel"])

	focus_label = Label.new()
	focus_label.add_theme_color_override("font_color", Color("#f3ead7"))
	root.add_child(focus_label)

	var close := Button.new()
	close.text = "Return to Overworld"
	close.pressed.connect(func() -> void:
		_stop_idle_animation()
		battle_closed.emit()
	)
	root.add_child(close)

	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.z_index = 40
	flash_rect.color = Color("#ffffff", 0.0)
	add_child(flash_rect)

func _build_combatant_panel(label_text: String) -> Dictionary:
	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(310, 0)
	panel.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 20)
	panel.add_child(label)

	var sprite := TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.custom_minimum_size = Vector2(300, 300)
	panel.add_child(sprite)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(300, 26)
	panel.add_child(bar)

	return { "panel": panel, "sprite": sprite, "bar": bar }

func _rebuild_commands() -> void:
	for child in command_box.get_children():
		child.queue_free()
	command_buttons.clear()

	for command in TacticalBattle.get_battle_commands(battle["player_id"], battle["known_techniques"]):
		var button := Button.new()
		button.text = "%s  |  %s" % [command["label"], _command_tag(command)]
		button.tooltip_text = command["description"]
		button.disabled = battle["status"] != "active" or battle_intro_active
		button.pressed.connect(_on_command_pressed.bind(command["id"]))
		command_buttons.append(button)
		command_box.add_child(button)

func _on_command_pressed(action: String) -> void:
	_stop_idle_animation()
	for button in command_buttons:
		button.disabled = true
	var previous_battle: Dictionary = battle.duplicate(true)
	var previous_intent: Dictionary = battle["enemy_intent"].duplicate(true)
	await _play_attack_cinematic(action)
	battle = TacticalBattle.take_action(battle, action, 0.0)
	if _latest_log_contains("Counter read"):
		_spawn_float_text("COUNTER", enemy_sprite, Color("#8fe6ff"))
	if _latest_log_contains("Stagger break"):
		_spawn_float_text("STAGGER BREAK", enemy_sprite, Color("#fff05a"))
	var enemy_damage: int = previous_battle["enemy_hp"] - battle["enemy_hp"]
	if enemy_damage > 0:
		_spawn_float_text("-%d" % enemy_damage, enemy_sprite, Color("#f0b66c"))
	elif action != "guard":
		_spawn_float_text("MISS", enemy_sprite, Color("#b8b1a4"))
	if battle["status"] == "active" or battle["status"] == "defeat":
		await _play_enemy_intent_cinematic(previous_intent, action == "guard")
		var player_damage: int = previous_battle["player_hp"] - battle["player_hp"]
		if player_damage > 0:
			_spawn_float_text("-%d" % player_damage, player_sprite, Color("#d85f48"))
	if battle["status"] == "active":
		await _apply_arena_rule(action)
	_maybe_award_victory()
	_refresh()
	if battle["status"] == "active":
		_start_idle_animation()

func _play_battle_intro() -> void:
	if battle.is_empty():
		return
	for button in command_buttons:
		button.disabled = true
	var location: String = battle_context.get("location_label", "Open Field")
	var intro := "%s\n%s approaches" % [location, battle["enemy_name"]] if battle_context.get("is_arena", false) else "%s\n%s appears" % [battle_context.get("title", "Wild Encounter"), battle["enemy_name"]] if battle_context.get("is_wild", false) else "%s appears" % battle["enemy_name"]
	action_label.text = intro
	action_label.scale = Vector2(0.84, 0.84)
	action_label.modulate.a = 0.0
	await _flash_screen(Color("#f0b66c", 0.18), 0.18)
	await _play_enemy_entrance()
	var tween := create_tween()
	tween.tween_property(action_label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(action_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(0.42)
	tween.tween_property(action_label, "modulate:a", 0.0, 0.18)
	await tween.finished
	battle_intro_active = false
	_rebuild_commands()

func _play_attack_cinematic(action: String) -> void:
	var command := _get_command(action)
	var motion: String = command.get("motion", "lunge")
	var vfx: String = command.get("vfx", "slash")
	var vfx_profile := BattleVfxData.get_attack_vfx_profile(vfx)
	await _show_action_label(command["label"])
	await _flash_screen(vfx_profile.get("anticipation_tint", Color("#ffffff", 0.0)), 0.08)

	if motion == "guard":
		await _play_guard_pulse()
		return
	if motion == "lunge":
		await _play_lunge()
	elif motion == "blink":
		await _play_blink_strike()
	elif motion == "shockwave":
		await _play_ground_slam()
	else:
		await _play_breath_pose()

	_spawn_vfx_afterimages(player_sprite, int(vfx_profile.get("afterimage_count", 2)), vfx_profile.get("impact_flash", Color("#f8de9a", 0.2)))
	_emit_procedural_vfx(str(vfx_profile.get("burst_kind", vfx)), enemy_sprite, vfx_profile)
	var strip_path := str(vfx_profile.get("strip_path", ""))
	if strip_path != "":
		await _play_sprite_strip(strip_path)
		if vfx == "shockwave":
			_spawn_ground_cracks(int(vfx_profile.get("ground_crack_count", 0)))
	elif vfx == "shockwave":
		_spawn_ground_cracks(int(vfx_profile.get("ground_crack_count", 0)))
		await _play_hit_flash(enemy_sprite, Color("#f8de9a"))
	else:
		await _play_hit_flash(enemy_sprite, Color("#f8de9a"))

	_spawn_residual_particles(enemy_sprite, str(vfx_profile.get("residual_particles", "arc_sparks")), int(vfx_profile.get("afterimage_count", 2)) + 4)
	_emit_screen_effect_for_attack(vfx_profile)
	await _flash_screen(vfx_profile.get("impact_flash", Color("#f8de9a", 0.16)), 0.12)
	await _screen_shake(float(vfx_profile.get("shake_amount", 6.0)), float(vfx_profile.get("shake_duration", 0.18)))

func _show_action_label(text: String) -> void:
	action_label.text = text
	action_label.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.tween_property(action_label, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(action_label, "scale", Vector2.ONE, 0.08)
	tween.tween_interval(0.18)
	tween.tween_property(action_label, "modulate:a", 0.0, 0.14)
	await tween.finished

func _play_enemy_intent_cinematic(intent: Dictionary, guarded: bool) -> void:
	var intent_profile := BattleVfxData.get_intent_vfx_profile(str(intent.get("kind", "attack")))
	await _flash_screen(intent_profile.get("telegraph_tint", Color("#ffffff", 0.0)), 0.08)
	if intent["kind"] == "guard":
		await _play_enemy_guard_pose()
		await _play_hit_flash(enemy_sprite, Color("#8ea6a8"))
		return

	if intent["kind"] == "corrupt":
		await _play_enemy_corrupt_cast()
		var intent_strip := str(intent_profile.get("strip_path", ""))
		if intent_strip != "":
			await _play_sprite_strip(intent_strip)
		await _play_hit_flash(player_sprite, Color("#7d5fa4"))
	else:
		await _play_enemy_lunge()
		await _play_hit_flash(player_sprite, Color("#d85f48"))
	_spawn_residual_particles(player_sprite, str(intent_profile.get("residual_particles", "red_warning_bits")), 6)
	if str(intent.get("kind", "attack")) == "corrupt":
		_emit_procedural_vfx(str(intent_profile.get("burst_kind", "corrupt")), player_sprite, intent_profile)
		if procedural_vfx != null:
			procedural_vfx.emit_screen_effect("chromatic_glitch", float(intent_profile.get("chromatic_split", 1.0)) / 3.0, 0.34)
		backdrop.set_vfx_pressure("corrupt", 0.58, 0.32)

	if not guarded:
		await _flash_screen(intent_profile.get("impact_flash", Color("#d85f48", 0.12)), 0.1)
		await _screen_shake(float(intent_profile.get("shake_amount", 4.0)), 0.14)

func _play_enemy_entrance() -> void:
	var start := enemy_sprite.position
	enemy_sprite.position = start + Vector2(80, -10)
	enemy_sprite.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "position", start, 0.28).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(enemy_sprite, "modulate:a", 1.0, 0.18)
	await tween.finished

func _play_enemy_lunge() -> void:
	_spawn_afterimage(enemy_sprite, Color("#d85f48", 0.22))
	var start := enemy_sprite.position
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "position", start + Vector2(-50, 2), 0.08).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(enemy_sprite, "scale", Vector2(1.07, 0.96), 0.08)
	tween.tween_property(enemy_sprite, "position", start, 0.16).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(enemy_sprite, "scale", Vector2.ONE, 0.16)
	await tween.finished

func _play_enemy_corrupt_cast() -> void:
	_spawn_afterimage(enemy_sprite, Color("#7d5fa4", 0.26))
	var start := enemy_sprite.position
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "position", start + Vector2(0, -16), 0.09).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(enemy_sprite, "modulate", Color("#b084ff"), 0.09)
	tween.tween_property(enemy_sprite, "position", start, 0.13).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(enemy_sprite, "modulate", Color.WHITE, 0.13)
	await tween.finished

func _play_enemy_guard_pose() -> void:
	var tween := create_tween()
	tween.tween_property(enemy_sprite, "scale", Vector2(0.9, 1.08), 0.1)
	tween.parallel().tween_property(enemy_sprite, "modulate", Color("#9bd4ff"), 0.1)
	tween.tween_property(enemy_sprite, "scale", Vector2.ONE, 0.18)
	tween.parallel().tween_property(enemy_sprite, "modulate", Color.WHITE, 0.18)
	await tween.finished

func _play_lunge() -> void:
	await _play_player_frames([0, 1, 2], 0.055)
	var start := player_sprite.position
	var tween := create_tween()
	tween.tween_property(player_sprite, "position", start + Vector2(54, -8), 0.1).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(player_sprite, "scale", Vector2(1.08, 1.08), 0.1)
	tween.tween_property(player_sprite, "position", start, 0.16).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(player_sprite, "scale", Vector2.ONE, 0.16)
	await tween.finished
	player_sprite.texture = _dragon_frame(0)

func _play_blink_strike() -> void:
	await _play_player_frames([3, 4, 5], 0.045)
	var start := player_sprite.position
	var tween := create_tween()
	tween.tween_property(player_sprite, "modulate:a", 0.1, 0.06)
	tween.tween_property(player_sprite, "position", start + Vector2(80, -18), 0.01)
	tween.tween_property(player_sprite, "modulate:a", 1.0, 0.05)
	tween.tween_property(player_sprite, "position", start, 0.14).set_trans(Tween.TRANS_BACK)
	await tween.finished
	player_sprite.texture = _dragon_frame(3)

func _play_ground_slam() -> void:
	await _play_player_frames([6, 7, 8], 0.06)
	var start := player_sprite.position
	var tween := create_tween()
	tween.tween_property(player_sprite, "position", start + Vector2(24, -34), 0.12).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(player_sprite, "position", start + Vector2(40, 16), 0.07).set_trans(Tween.TRANS_EXPO)
	tween.tween_property(player_sprite, "position", start, 0.12)
	await tween.finished
	player_sprite.texture = _dragon_frame(6)

func _play_breath_pose() -> void:
	await _play_player_frames([9, 10, 11], 0.055)
	var tween := create_tween()
	tween.tween_property(player_sprite, "scale", Vector2(1.08, 0.96), 0.08)
	tween.tween_property(player_sprite, "scale", Vector2(1.02, 1.05), 0.12)
	tween.tween_property(player_sprite, "scale", Vector2.ONE, 0.14)
	await tween.finished
	player_sprite.texture = _dragon_frame(0)

func _play_guard_pulse() -> void:
	await _play_player_frames([3, 4], 0.075)
	var tween := create_tween()
	tween.tween_property(player_sprite, "modulate", Color("#9bd4ff"), 0.08)
	tween.parallel().tween_property(player_sprite, "scale", Vector2(1.06, 1.06), 0.08)
	tween.tween_property(player_sprite, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(player_sprite, "scale", Vector2.ONE, 0.18)
	await tween.finished
	player_sprite.texture = _dragon_frame(3)

func _play_hit_flash(target: TextureRect, color: Color) -> void:
	var tween := create_tween()
	tween.tween_property(target, "modulate", color, 0.06)
	tween.tween_property(target, "modulate", Color.WHITE, 0.14)
	await tween.finished

func _apply_arena_rule(action: String) -> void:
	var rule: String = battle_context.get("arena_rule", "")
	if rule == "":
		return
	_play_arena_vfx(rule)

	if rule == "checksum_flux":
		if battle["turn"] % 2 != 0:
			return
		await _show_action_label("Checksum Flux")
		battle["enemy_hp"] = maxi(0, battle["enemy_hp"] - 10)
		battle["focus"] = mini(3, battle["focus"] + 1)
		battle["log"].append("Checksum Flux lashes the hostile process for 10 and banks 1 Focus.")
		_spawn_float_text("-10", enemy_sprite, Color("#f0b66c"))
		await _play_hit_flash(enemy_sprite, Color("#f0b66c"))
	elif rule == "scrap_surge":
		await _show_action_label("Scrap Surge")
		battle["enemy_hp"] = maxi(0, battle["enemy_hp"] - 6)
		battle["player_hp"] = maxi(0, battle["player_hp"] - 4)
		battle["log"].append("Scrap Surge rattles the pit: enemy -6, guardian -4.")
		_spawn_float_text("-6", enemy_sprite, Color("#d6d0bc"))
		_spawn_float_text("-4", player_sprite, Color("#d85f48"))
		await _flash_screen(Color("#d6d0bc", 0.12), 0.08)
		await _screen_shake(5.0, 0.14)
	elif rule == "lunar_resonance":
		if action == "guard":
			await _show_action_label("Harmonic Guard")
			var healed: int = mini(8, battle["player_max_hp"] - battle["player_hp"])
			battle["player_hp"] += healed
			battle["focus"] = mini(3, battle["focus"] + 1)
			battle["log"].append("Lunar Resonance rewards the guard: +%d HP and +1 Focus." % healed)
			if healed > 0:
				_spawn_float_text("+%d" % healed, player_sprite, Color("#8fe6ff"))
			await _play_hit_flash(player_sprite, Color("#c0c8ff"))
		elif battle["turn"] % 3 == 0:
			await _show_action_label("Silver Repair")
			var repaired: int = mini(10, battle["enemy_max_hp"] - battle["enemy_hp"])
			battle["enemy_hp"] += repaired
			battle["log"].append("The Resonance Bowl repairs the mote for %d HP." % repaired)
			if repaired > 0:
				_spawn_float_text("+%d" % repaired, enemy_sprite, Color("#c0c8ff"))
			await _play_hit_flash(enemy_sprite, Color("#c0c8ff"))

	_resolve_arena_rule_status()

func _resolve_arena_rule_status() -> void:
	if battle["enemy_hp"] <= 0:
		battle["status"] = "victory"
		battle["log"].append("%s fractures under the arena rule." % battle["enemy_name"])
	elif battle["player_hp"] <= 0:
		battle["status"] = "defeat"
		battle["log"].append("The arena overwhelms the guardian. Felix yanks the signal back.")

func _screen_shake(amount: float, duration: float) -> void:
	var start := position
	var steps := 4
	for i in steps:
		position = start + Vector2(randf_range(-amount, amount), randf_range(-amount * 0.5, amount * 0.5))
		await get_tree().create_timer(duration / steps).timeout
	position = start

func _flash_screen(color: Color, duration: float) -> void:
	if flash_rect == null:
		return
	flash_rect.color = color
	var tween := create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, duration).set_trans(Tween.TRANS_QUAD)
	await tween.finished

func _start_idle_animation() -> void:
	if player_sprite == null or enemy_sprite == null:
		return
	if not active_tweens.is_empty():
		return
	_add_idle_tween(player_sprite, Vector2(1.02, 0.98), 0.9)
	_add_idle_tween(enemy_sprite, Vector2(0.98, 1.03), 1.1)
	_add_enemy_idle_tween()
	_add_idle_frame_tween()

func _add_idle_tween(target: Control, target_scale: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(target, "scale", target_scale, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tweens.append(tween)

func _add_enemy_idle_tween() -> void:
	var base_y := enemy_sprite.position.y
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(enemy_sprite, "position:y", base_y - 6.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(enemy_sprite, "position:y", base_y, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	active_tweens.append(tween)

func _add_idle_frame_tween() -> void:
	var tween := create_tween()
	tween.set_loops()
	for frame in [0, 1, 2, 1]:
		tween.tween_callback(_set_player_frame.bind(frame))
		tween.tween_interval(0.28)
	active_tweens.append(tween)

func _stop_idle_animation() -> void:
	for tween in active_tweens:
		if is_instance_valid(tween):
			tween.kill()
	active_tweens.clear()
	if player_sprite != null:
		player_sprite.scale = Vector2.ONE
		player_sprite.texture = _dragon_frame(0)
	if enemy_sprite != null:
		enemy_sprite.scale = Vector2.ONE
		enemy_sprite.modulate.a = 1.0

func _spawn_afterimage(target: TextureRect, color: Color) -> void:
	if target.texture == null:
		return
	var ghost := TextureRect.new()
	ghost.texture = target.texture
	ghost.expand_mode = target.expand_mode
	ghost.stretch_mode = target.stretch_mode
	ghost.size = target.size
	ghost.custom_minimum_size = target.custom_minimum_size
	ghost.global_position = target.global_position
	ghost.scale = target.scale
	ghost.modulate = color
	ghost.z_index = target.z_index - 1
	add_child(ghost)
	var tween := create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.22)
	tween.parallel().tween_property(ghost, "global_position", ghost.global_position + Vector2(20, -8), 0.22)
	tween.finished.connect(ghost.queue_free)

func _spawn_vfx_afterimages(target: TextureRect, count: int, color: Color) -> void:
	for i in count:
		var next_color := color
		next_color.a = maxf(0.08, color.a * (1.0 - float(i) * 0.13))
		_spawn_afterimage(target, next_color)

func _spawn_residual_particles(target: Control, particle_id: String, count: int) -> void:
	var colors := {
		"embers": Color("#ff7a35", 0.72),
		"stone_sparks": Color("#f7e7b0", 0.62),
		"arc_sparks": Color("#9bd4ff", 0.65),
		"void_bits": Color("#b084ff", 0.66),
		"red_warning_bits": Color("#ff4a3d", 0.62),
		"shield_pixels": Color("#8fe6ff", 0.58),
	}
	var color: Color = colors.get(particle_id, Color("#f8de9a", 0.6))
	for i in count:
		var label := Label.new()
		label.text = "." if i % 2 == 0 else "*"
		label.z_index = 18
		label.add_theme_font_size_override("font_size", 18 + (i % 3) * 4)
		label.add_theme_color_override("font_color", color)
		add_child(label)
		var offset := Vector2(float((i % 5) - 2) * 18.0, float(i % 4) * 10.0)
		label.global_position = target.global_position + target.size * 0.45 + offset
		var tween := create_tween()
		tween.tween_property(label, "global_position", label.global_position + Vector2(offset.x * 0.8, -34.0 - float(i % 4) * 9.0), 0.42)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 0.42)
		tween.finished.connect(label.queue_free)

func _spawn_ground_cracks(count: int) -> void:
	for i in count:
		var crack := ColorRect.new()
		crack.color = Color("#f7e7b0", 0.55)
		crack.z_index = 16
		crack.size = Vector2(74 + i * 16, 3)
		add_child(crack)
		crack.global_position = enemy_sprite.global_position + Vector2(-70 + i * 42, enemy_sprite.size.y * 0.78 + i * 5)
		crack.rotation = deg_to_rad(-8 + i * 7)
		var tween := create_tween()
		tween.tween_property(crack, "modulate:a", 0.0, 0.36)
		tween.finished.connect(crack.queue_free)

func _play_arena_vfx(rule: String) -> void:
	var profile := BattleVfxData.get_arena_vfx_profile(rule)
	if profile.is_empty():
		return
	_spawn_residual_particles(enemy_sprite, "stone_sparks", int(profile.get("debris_count", 0)))
	if procedural_vfx != null:
		procedural_vfx.emit_burst("arena", size * 0.5, profile)
		if bool(profile.get("scanline_burst", false)):
			procedural_vfx.emit_screen_effect("scanline_burst", 0.56, 0.28)
	backdrop.set_vfx_pressure(str(profile.get("palette_jolt", "")), 0.62, 0.35)
	var pulse: Color = profile.get("ring_pulse", Color("#ffffff", 0.12))
	_flash_screen(pulse, 0.1)

func _emit_procedural_vfx(kind: String, target: Control, profile: Dictionary) -> void:
	if procedural_vfx == null:
		return
	var origin := target.global_position + target.size * 0.5
	procedural_vfx.emit_burst(kind, origin, profile)

func _emit_screen_effect_for_attack(profile: Dictionary) -> void:
	if procedural_vfx == null:
		return
	match str(profile.get("screen_distortion", "")):
		"heat_bloom":
			procedural_vfx.emit_screen_effect("heat_haze", 0.68, 0.42)
			backdrop.set_vfx_pressure("magma", 0.64, 0.34)
		"radial_ripple":
			procedural_vfx.emit_screen_effect("impact_freeze", 0.72, 0.12)
			procedural_vfx.emit_screen_effect("scanline_burst", 0.5, 0.24)
			backdrop.set_vfx_pressure("scrap_gold", 0.72, 0.28)
		"slice_shear":
			procedural_vfx.emit_screen_effect("chromatic_glitch", 0.28, 0.16)
			backdrop.set_vfx_pressure("checksum_orange", 0.38, 0.18)

func _spawn_float_text(text: String, target: Control, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 20
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	label.global_position = target.global_position + target.size * 0.45
	label.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.05)
	tween.parallel().tween_property(label, "global_position", label.global_position + Vector2(0, -42), 0.42).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.16)
	tween.finished.connect(label.queue_free)

func _play_sprite_strip(path: String) -> void:
	var texture: Texture2D = _texture_from_png(path, null)
	if texture == null:
		await _play_hit_flash(enemy_sprite, Color("#f8de9a"))
		return

	if vfx_atlas == null:
		vfx_atlas = AtlasTexture.new()
	vfx_atlas.atlas = texture
	vfx_sprite.texture = vfx_atlas
	vfx_sprite.visible = true
	vfx_sprite.modulate = Color.WHITE

	var frame_width := float(texture.get_width()) / VFX_FRAME_COUNT
	for frame in VFX_FRAME_COUNT:
		vfx_atlas.region = Rect2(frame_width * frame, 0.0, frame_width, texture.get_height())
		await get_tree().create_timer(0.075).timeout

	vfx_sprite.visible = false

func _get_command(action: String) -> Dictionary:
	for command in TacticalBattle.get_battle_commands(battle["player_id"], battle["known_techniques"]):
		if command["id"] == action:
			return command
	return TacticalBattle.get_battle_commands(battle["player_id"], battle["known_techniques"])[0]

func _command_tag(command: Dictionary) -> String:
	if command["id"] == "guard":
		return "+%d Focus / guard" % command["focus_gain"]
	var focus_text := "+%d Focus" % command["focus_gain"] if command["focus_gain"] > 0 else "no Focus"
	return "PWR %d / ACC %d / STG %d / %s / %s" % [
		command["power"],
		command["accuracy"],
		command.get("stagger", 0),
		focus_text,
		str(command.get("role", "strike")).to_upper(),
	]

func _refresh() -> void:
	if battle.is_empty():
		return
	var location: String = battle_context.get("location_label", "Battle Arena")
	var prefix := "%s | " % location if battle_context.get("is_arena", false) else "%s | " % battle_context.get("title", "Wild Encounter") if battle_context.get("is_wild", false) else ""
	title_label.text = "%s%s vs %s" % [prefix, battle["player_name"], battle["enemy_name"]]
	var rule_text: String = battle_context.get("arena_rule_label", "")
	var arena_suffix := "\nArena Rule: %s" % rule_text if rule_text != "" else ""
	status_label.text = "Turn %d | Enemy intent: %s - %s\n%s%s" % [
		battle["turn"],
		battle["enemy_intent"]["label"],
		battle["enemy_intent"]["detail"],
		TacticalBattle.get_intent_counter_hint(battle["enemy_intent"]),
		arena_suffix,
	]
	player_bar.max_value = battle["player_max_hp"]
	player_bar.value = battle["player_hp"]
	enemy_bar.max_value = battle["enemy_max_hp"]
	enemy_bar.value = battle["enemy_hp"]
	focus_label.text = "Focus: %d / 3 | Enemy Stagger: %d / 100 | DataScraps: %d | Status: %s" % [battle["focus"], battle.get("enemy_stagger", 0), profile.get("data_scraps", 0), battle["status"]]
	log_label.text = "\n".join(battle["log"])

	if player_sprite.texture == null:
		player_sprite.texture = _dragon_frame_texture(_player_texture_path(), _fallback_dragon_texture(profile.get("dragon_id", "fire")))
	if enemy_sprite.texture == null:
		enemy_sprite.texture = _texture_from_png(ENEMY_TEXTURE, _fallback_enemy_texture(battle.get("enemy_id", "firewall_sentinel")))
	enemy_sprite.modulate = _enemy_modulate(battle.get("enemy_id", "firewall_sentinel"), battle.get("turn", 1))
	_rebuild_commands()

func _enemy_modulate(enemy_id: String, turn: int) -> Color:
	var base: Color = ENEMY_TINTS.get(enemy_id, Color.WHITE)
	if enemy_id == "sys_admin":
		return VisualSystemData.mirror_parity_tint(base, VisualSystemData.dragon_element_color(profile.get("dragon_id", "fire")), turn)
	return base

func _player_texture_path() -> String:
	return PLAYER_DRAGON_TEXTURES.get(profile.get("dragon_id", "fire"), PLAYER_DRAGON_TEXTURE)

func _dragon_frame(index: int) -> Texture2D:
	if player_frames.is_empty():
		return _fallback_dragon_texture(profile.get("dragon_id", "fire"))
	return player_frames[clampi(index, 0, player_frames.size() - 1)]

func _set_player_frame(index: int) -> void:
	if player_sprite != null:
		player_sprite.texture = _dragon_frame(index)

func _play_player_frames(frames: Array, frame_duration: float) -> void:
	for frame in frames:
		_set_player_frame(int(frame))
		await get_tree().create_timer(frame_duration).timeout

func _texture_from_png(path: String, fallback: Texture2D) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error == OK:
		return ImageTexture.create_from_image(image)
	return fallback

func _dragon_frame_texture(path: String, fallback: Texture2D) -> Texture2D:
	return _dragon_sheet_frames(path, fallback)[0]

func _dragon_sheet_frames(path: String, fallback: Texture2D) -> Array[Texture2D]:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		return [fallback]
	var frame_width := floori(float(image.get_width()) / 3.0)
	var frame_height := floori(float(image.get_height()) / 4.0)
	var frames: Array[Texture2D] = []
	for row in 4:
		for column in 3:
			var frame := image.get_region(Rect2i(column * frame_width, row * frame_height, frame_width, frame_height))
			_chroma_key_green(frame)
			frames.append(ImageTexture.create_from_image(frame))
	return frames

func _chroma_key_green(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var color := image.get_pixel(x, y)
			if color.g > 0.62 and color.r < 0.35 and color.b < 0.35:
				color.a = 0.0
				image.set_pixel(x, y, color)

func _fallback_dragon_texture(dragon_id: String) -> Texture2D:
	var image := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var body := Color("#d65c2c") if dragon_id == "fire" else Color("#5b5572")
	for y in range(34, 156):
		for x in range(24, 156):
			var dx := (float(x) - 86.0) / 62.0
			var dy := (float(y) - 96.0) / 54.0
			if dx * dx + dy * dy < 1.0:
				image.set_pixel(x, y, body)
	for y in range(58, 112):
		for x in range(122, 176):
			var dx := (float(x) - 144.0) / 36.0
			var dy := (float(y) - 82.0) / 24.0
			if dx * dx + dy * dy < 1.0:
				image.set_pixel(x, y, body.lightened(0.12))
	for y in range(120, 170):
		for x in range(8, 72):
			if abs((x - 8) - (170 - y)) < 18:
				image.set_pixel(x, y, body.darkened(0.18))
	for point in [Vector2i(142, 72), Vector2i(154, 72)]:
		image.set_pixel(point.x, point.y, Color("#fff3cf"))
		image.set_pixel(point.x + 1, point.y, Color("#fff3cf"))
	return ImageTexture.create_from_image(image)

func _fallback_enemy_texture(enemy_id: String) -> Texture2D:
	var image := Image.create(180, 180, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var body: Color = ENEMY_TINTS.get(enemy_id, Color("#9b9b9b"))
	for y in range(36, 150):
		for x in range(34, 146):
			var dx := (float(x) - 90.0) / 52.0
			var dy := (float(y) - 94.0) / 58.0
			if dx * dx + dy * dy < 1.0:
				image.set_pixel(x, y, body)
	for y in range(22, 74):
		for x in range(70, 112):
			if abs(x - 91) + abs(y - 52) < 34:
				image.set_pixel(x, y, body.lightened(0.18))
	for y in range(72, 136):
		for x in range(20, 44):
			if (x + y) % 3 != 0:
				image.set_pixel(x, y, body.darkened(0.22))
	for y in range(72, 136):
		for x in range(136, 160):
			if (x + y) % 3 != 0:
				image.set_pixel(x, y, body.darkened(0.22))
	return ImageTexture.create_from_image(image)

func _maybe_award_victory() -> void:
	if victory_reward_awarded or battle["status"] != "victory":
		return
	victory_reward_awarded = true
	var reward := TacticalBattle.get_victory_reward(battle["enemy_id"])
	var old_level := DragonProgression.get_dragon_level(profile)
	profile = DragonProgression.record_enemy_defeated(profile, battle["enemy_id"])
	profile = DragonProgression.award_scraps(profile, reward["scraps"])
	profile = DragonProgression.award_dragon_xp(profile, reward["xp"])
	var new_level := DragonProgression.get_dragon_level(profile)
	if reward["key_item"] != "":
		profile = DragonProgression.grant_key_item(profile, reward["key_item"])
	if reward["flag"] != "":
		profile = DragonProgression.set_mission_flag(profile, reward["flag"])
	if battle_context.get("is_arena", false):
		var location_id: String = battle_context.get("location_id", "")
		var clear_flag := "arena_cleared_%s" % location_id
		if location_id != "" and not DragonProgression.has_mission_flag(profile, clear_flag):
			_apply_arena_clear_reward()
			profile = DragonProgression.set_mission_flag(profile, "arena_cleared_%s" % location_id)
	profile_changed.emit(profile.duplicate(true))
	battle["log"].append("Recovered %d DataScraps and %d dragon XP from the fractured process." % [reward["scraps"], reward["xp"]])
	if new_level > old_level:
		battle["log"].append("%s reaches level %d. Its combat stats will rise in the next encounter." % [battle["player_name"], new_level])
	if battle_context.get("is_arena", false):
		battle["log"].append("%s is marked clear on the overworld map." % battle_context.get("location_label", "Arena"))
	if reward["key_item"] == "diagnostic_lens":
		battle["log"].append("B.I.O.S. unlocks the Diagnostic Lens overlay.")
	var victory_bark := _lore_bark_for_enemy(str(battle["enemy_id"]), true)
	if victory_bark != "":
		battle["log"].append(victory_bark)

func get_lore_bark_for_test(enemy_id: String, victory: bool = false) -> String:
	return _lore_bark_for_enemy(enemy_id, victory)

func _lore_bark_for_enemy(enemy_id: String, victory: bool = false) -> String:
	if not enemy_id.contains("mirror") and not enemy_id.contains("daemon") and not enemy_id.contains("sentinel"):
		return ""
	if victory:
		return "Skye forced one more route to stay real."
	return "Mirror Admin pressure rising. Guardian protocol handshake required."

func _latest_log_contains(fragment: String) -> bool:
	for line in battle.get("log", []):
		if str(line).contains(fragment):
			return true
	return false

func _apply_arena_clear_reward() -> void:
	var reward: Dictionary = battle_context.get("arena_reward", {})
	if reward.is_empty():
		return
	var scraps: int = reward.get("scraps", 0)
	if scraps > 0:
		profile = DragonProgression.award_scraps(profile, scraps)
		battle["log"].append("Arena clear bonus: %d DataScraps." % scraps)
	var key_item: String = reward.get("key_item", "")
	if key_item != "":
		profile = DragonProgression.grant_key_item(profile, key_item)
		battle["log"].append("Arena clear reward installed: %s." % reward.get("label", key_item))
	var technique_id: String = reward.get("technique_id", "")
	if technique_id != "":
		profile = DragonProgression.grant_technique(profile, technique_id)
		battle["log"].append("Arena clear reward learned: %s." % reward.get("label", technique_id))
