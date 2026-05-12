extends Control

signal navigate(target: String, payload: Variant)

const DragonData = preload("res://scripts/sim/dragon_data.gd")
const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const TacticalBattle = preload("res://scripts/sim/tactical_battle.gd")
const CombatRules = preload("res://scripts/sim/combat_rules.gd")
const TechniqueData = preload("res://scripts/sim/technique_data.gd")
const DamageNumberScene = preload("res://scenes/components/damage_number.tscn")

const ELEMENT_COLORS := {
	"fire":   Color("#ff6b35"),
	"ice":    Color("#58dbff"),
	"storm":  Color("#c3a6ff"),
	"stone":  Color("#a0956a"),
	"venom":  Color("#70ff8f"),
	"shadow": Color("#b084ff"),
	"glitch": Color("#ff4daa"),
	"static": Color("#fffaaa"),
	"lunar":  Color("#e8d5ff"),
}

const PARTICLE_CONFIG := {
	"fire":   { "amount": 40, "lifetime": 0.6, "speed_scale": 1.4, "spread": 45.0 },
	"ice":    { "amount": 30, "lifetime": 0.8, "speed_scale": 0.8, "spread": 30.0 },
	"storm":  { "amount": 50, "lifetime": 0.4, "speed_scale": 1.8, "spread": 60.0 },
	"stone":  { "amount": 25, "lifetime": 1.0, "speed_scale": 0.6, "spread": 20.0 },
	"venom":  { "amount": 35, "lifetime": 0.7, "speed_scale": 1.0, "spread": 40.0 },
	"shadow": { "amount": 45, "lifetime": 0.9, "speed_scale": 1.2, "spread": 50.0 },
}

const CORRUPTION_TINT := Color("#2a0020")

@onready var camera: Camera2D = $Camera2D
@onready var corruption_modulate: CanvasModulate = $CorruptionModulate
@onready var header_label: Label = $VBoxContainer/HeaderLabel
@onready var player_sprite: Control = $VBoxContainer/CombatRow/PlayerSide/PlayerSprite
@onready var player_name: Label = $VBoxContainer/CombatRow/PlayerSide/PlayerName
@onready var player_hp_bar: ProgressBar = $VBoxContainer/CombatRow/PlayerSide/PlayerHP
@onready var player_hp_label: Label = $VBoxContainer/CombatRow/PlayerSide/PlayerHPLabel
@onready var player_status_icons: HBoxContainer = $VBoxContainer/CombatRow/PlayerSide/StatusIcons
@onready var npc_sprite: Control = $VBoxContainer/CombatRow/NpcSide/NpcSprite
@onready var npc_name: Label = $VBoxContainer/CombatRow/NpcSide/NpcName
@onready var npc_hp_bar: ProgressBar = $VBoxContainer/CombatRow/NpcSide/NpcHP
@onready var npc_hp_label: Label = $VBoxContainer/CombatRow/NpcSide/NpcHPLabel
@onready var battle_log: RichTextLabel = $VBoxContainer/BattleLog
@onready var move_buttons: HBoxContainer = $VBoxContainer/MoveButtons
@onready var hit_particles: GPUParticles2D = $HitParticles
@onready var damage_layer: Node2D = $DamageNumberLayer

var _save: Dictionary = {}
var _config: Dictionary = {}

var _player_hp: int = 0
var _player_max_hp: int = 0
var _npc_hp: int = 0
var _npc_max_hp: int = 0
var _player_stats: Dictionary = {}
var _npc_stats: Dictionary = {}
var _player_element: String = ""
var _npc_element: String = ""
var _npc_data: Dictionary = {}
var _player_moves: Array = []
var _status_effects: Dictionary = { "player": [], "npc": [] }
var _battle_over: bool = false
var _trauma: float = 0.0

func setup(save: Dictionary, config: Dictionary) -> void:
	_save = save.duplicate(true)
	_config = config.duplicate(true)

func _ready() -> void:
	_init_battle()
	_build_move_buttons()
	if _config.get("is_singularity", false):
		corruption_modulate.color = CORRUPTION_TINT

func _process(delta: float) -> void:
	if _trauma > 0.0:
		_trauma = maxf(0.0, _trauma - delta * 2.5)
		var shake := _trauma * _trauma
		camera.offset = Vector2(
			randf_range(-12.0, 12.0) * shake,
			randf_range(-8.0, 8.0) * shake
		)
	else:
		camera.offset = Vector2.ZERO

func _init_battle() -> void:
	var dragon_id: String = str(_config.get("dragon_id", _save.get("dragon_id", "fire")))
	var npc_id: String = str(_config.get("npc_id", "firewall_sentinel"))
	_npc_data = TacticalBattle.EnemyData.get(npc_id, {}).duplicate(true)

	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {}).duplicate(true)
	var level: int = DragonProgression.get_dragon_level(_save, dragon_id)
	_player_element = str(dragon_def.get("element", "fire"))
	_npc_element = str(_npc_data.get("element", "fire"))

	_player_stats = DragonData.calculate_stats(dragon_def.get("base_stats", {}), level)
	_player_stats["element"] = _player_element
	var npc_raw: Dictionary = _npc_data.get("stats", {})
	_npc_stats = npc_raw.duplicate(true)
	_npc_stats["element"] = _npc_element

	_player_max_hp = int(_player_stats.get("hp", 100))
	_npc_max_hp = int(npc_raw.get("hp", 100))
	_player_hp = _player_max_hp
	_npc_hp = _npc_max_hp

	player_sprite.set_dragon(dragon_id, DragonData.get_stage_for_level(level))
	npc_sprite.set_dragon(npc_id, 1)

	player_name.text = str(dragon_def.get("name", dragon_id))
	npc_name.text = str(_npc_data.get("name", npc_id))
	header_label.text = "%s  VS  %s" % [player_name.text, npc_name.text]

	var active_ids: Array = DragonProgression.get_active_techniques(_save)
	_player_moves.clear()
	for t_id in active_ids:
		var t: Dictionary = TechniqueData.get_technique(t_id)
		if not t.is_empty():
			_player_moves.append(t)

	_update_hp_display()

func _build_move_buttons() -> void:
	for c in move_buttons.get_children(): c.queue_free()

	for move in _player_moves:
		var btn := Button.new()
		btn.text = str(move.get("label", move.get("id", "?")))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var move_copy := move.duplicate(true)
		btn.pressed.connect(func(): _on_player_move(move_copy))
		move_buttons.add_child(btn)

	var basic := Button.new()
	basic.text = "Basic Attack"
	basic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic.pressed.connect(_on_player_basic_attack)
	move_buttons.add_child(basic)

	var defend := Button.new()
	defend.text = "Defend"
	defend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defend.pressed.connect(_on_player_defend)
	move_buttons.add_child(defend)

func _set_buttons_disabled(disabled: bool) -> void:
	for btn in move_buttons.get_children():
		if btn is Button:
			btn.disabled = disabled

func _on_player_basic_attack() -> void:
	var basic_move := {
		"id": "basic",
		"label": "Basic Attack",
		"element": _player_element,
		"power": 40,
		"accuracy": 100,
		"motion": "lunge",
	}
	_on_player_move(basic_move)

func _on_player_defend() -> void:
	_set_buttons_disabled(true)
	_append_log("You brace for impact. DEF +50% this turn.")
	if not _status_effects["player"].has("defend"):
		_status_effects["player"].append("defend")
	_update_status_icons()
	await get_tree().create_timer(0.5).timeout
	await _run_npc_turn()
	_status_effects["player"].erase("defend")
	_update_status_icons()
	_set_buttons_disabled(false)

func _on_player_move(move: Dictionary) -> void:
	if _battle_over:
		return
	_set_buttons_disabled(true)

	var attacker := _build_fighter_dict(_player_stats, _player_element, _player_hp)
	var defender := _build_fighter_dict(_npc_stats, _npc_element, _npc_hp)

	var roll := randf()
	var result := CombatRules.resolve_attack(attacker, defender, move, roll)

	await _play_attack_animation("player", move)
	if result["hit"]:
		var dmg: int = int(result["damage"])
		_npc_hp = int(result["remaining_hp"])
		var effective := float(result["effectiveness"]) > 1.0
		var resisted := float(result["effectiveness"]) < 1.0
		_spawn_damage_number(npc_sprite.global_position, dmg, effective, resisted)
		_add_trauma(0.18 if effective else 0.1)
		_trigger_hit_particles(npc_sprite.global_position, _npc_element)
		if _npc_hp <= 0:
			_rumble(0.6, 1.0, 0.5)
		elif effective:
			_rumble(0.4, 0.8, 0.25)
		else:
			_rumble(0.2, 0.3, 0.1)
		if effective:
			_append_log("[color=#ffcc00]%s hits for %d! Super effective![/color]" % [str(move.get("label", "?")), dmg])
		elif resisted:
			_append_log("[color=#8fb0ff]%s hits for %d. Not very effective.[/color]" % [str(move.get("label", "?")), dmg])
		else:
			_append_log("%s hits for %d damage." % [str(move.get("label", "?")), dmg])
	else:
		_append_log("%s missed!" % str(move.get("label", "?")))

	_update_hp_display()

	if _npc_hp <= 0:
		await _end_battle(true)
		return

	await get_tree().create_timer(0.4).timeout
	await _run_npc_turn()

func _run_npc_turn() -> void:
	if _battle_over:
		return
	var npc_move := {
		"id": "npc_basic",
		"label": "Strike",
		"element": _npc_element,
		"power": 35,
		"accuracy": 90,
		"motion": "lunge",
	}
	var attacker := _build_fighter_dict(_npc_stats, _npc_element, _npc_hp)
	var def_bonus: float = 1.5 if _status_effects["player"].has("defend") else 1.0
	var player_dict := _build_fighter_dict(_player_stats, _player_element, _player_hp)
	player_dict["def"] = int(float(player_dict["def"]) * def_bonus)

	var roll := randf()
	var result := CombatRules.resolve_attack(attacker, player_dict, npc_move, roll)

	await _play_attack_animation("npc", npc_move)
	if result["hit"]:
		var dmg: int = int(result["damage"])
		_player_hp = int(result["remaining_hp"])
		_spawn_damage_number(player_sprite.global_position, dmg, false, false)
		_add_trauma(0.12)
		_trigger_hit_particles(player_sprite.global_position, _player_element)
		_append_log("%s strikes for %d damage." % [str(_npc_data.get("name", "NPC")), dmg])
	else:
		_append_log("%s missed!" % str(_npc_data.get("name", "NPC")))

	_update_hp_display()

	if _player_hp <= 0:
		await _end_battle(false)
		return

	_set_buttons_disabled(false)

func _play_attack_animation(side: String, _move: Dictionary) -> void:
	var target_node: Control = player_sprite if side == "player" else npc_sprite
	var direction: float = 1.0 if side == "player" else -1.0
	var original_x: float = target_node.position.x
	var tween := create_tween()
	tween.tween_property(target_node, "position:x", original_x + 30.0 * direction, 0.1)
	tween.tween_property(target_node, "position:x", original_x, 0.12)
	var hit_target: Control = npc_sprite if side == "player" else player_sprite
	var orig_hit_x: float = hit_target.position.x
	tween.tween_property(hit_target, "position:x", orig_hit_x + 6.0, 0.04)
	tween.tween_property(hit_target, "position:x", orig_hit_x - 6.0, 0.04)
	tween.tween_property(hit_target, "position:x", orig_hit_x, 0.04)
	await tween.finished

func _trigger_hit_particles(world_pos: Vector2, element: String) -> void:
	if hit_particles == null:
		return
	hit_particles.global_position = world_pos
	var color: Color = ELEMENT_COLORS.get(element, Color.WHITE)
	var cfg: Dictionary = PARTICLE_CONFIG.get(element, PARTICLE_CONFIG.get("fire", {}))
	if not cfg.is_empty():
		hit_particles.amount = int(cfg.get("amount", 24))
		hit_particles.lifetime = float(cfg.get("lifetime", 0.6))
		hit_particles.speed_scale = float(cfg.get("speed_scale", 1.0))
	if hit_particles.process_material is ParticleProcessMaterial:
		hit_particles.process_material.color = color
		hit_particles.process_material.spread = float(cfg.get("spread", 45.0))
	hit_particles.restart()

func _rumble(weak: float, strong: float, duration: float) -> void:
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)

func _spawn_damage_number(world_pos: Vector2, value: int, effective: bool, resisted: bool) -> void:
	var inst: Node2D = DamageNumberScene.instantiate()
	damage_layer.add_child(inst)
	inst.global_position = world_pos + Vector2(randf_range(-20, 20), -40)
	inst.spawn(value, effective, resisted)

func _add_trauma(amount: float) -> void:
	_trauma = minf(1.0, _trauma + amount)

func _update_hp_display() -> void:
	player_hp_bar.max_value = _player_max_hp
	player_hp_bar.value = _player_hp
	player_hp_label.text = "%d / %d" % [_player_hp, _player_max_hp]
	npc_hp_bar.max_value = _npc_max_hp
	npc_hp_bar.value = _npc_hp
	npc_hp_label.text = "%d / %d" % [_npc_hp, _npc_max_hp]

func _update_status_icons() -> void:
	for c in player_status_icons.get_children(): c.queue_free()
	for effect in _status_effects["player"]:
		var lbl := Label.new()
		lbl.text = "[%s]" % str(effect).to_upper()
		lbl.add_theme_font_size_override("font_size", 10)
		player_status_icons.add_child(lbl)

func _append_log(text: String) -> void:
	battle_log.append_text(text + "\n")

func _build_fighter_dict(stats: Dictionary, element: String, current_hp: int) -> Dictionary:
	return {
		"hp": current_hp,
		"atk": int(stats.get("atk", 20)),
		"def": int(stats.get("def", 15)),
		"spd": int(stats.get("spd", 15)),
		"element": element,
		"stage": 1,
	}

func _end_battle(player_won: bool) -> void:
	_battle_over = true
	_set_buttons_disabled(true)

	if player_won:
		var dragon_id: String = str(_config.get("dragon_id", _save.get("dragon_id", "fire")))
		var reward_xp: int = int(_npc_data.get("reward_xp", 50))
		var reward_scraps: int = int(_npc_data.get("reward_scraps", 30))
		var npc_id: String = str(_config.get("npc_id", ""))

		_save = DragonProgression.award_dragon_xp(_save, reward_xp)
		_save = DragonProgression.award_scraps(_save, reward_scraps)
		_save = DragonProgression.record_enemy_defeated(_save, npc_id)

		var reward_flag: String = str(_npc_data.get("reward_flag", ""))
		if reward_flag != "":
			_save = DragonProgression.set_mission_flag(_save, reward_flag)

		var reward_key_item: String = str(_npc_data.get("reward_key_item", ""))
		if reward_key_item != "":
			_save = DragonProgression.grant_key_item(_save, reward_key_item)

		_append_log("[color=#ffcc00]Victory! +%d XP, +%d scraps[/color]" % [reward_xp, reward_scraps])
	else:
		_append_log("[color=#ff4d4d]Defeated. Returning...[/color]")

	_write_save()
	await get_tree().create_timer(1.8).timeout
	var return_screen: String = str(_config.get("return_screen", "battleSelect"))
	navigate.emit(return_screen, null)

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
