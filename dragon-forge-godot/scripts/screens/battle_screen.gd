extends Control

signal navigate(target: String, payload: Variant)

const DragonData       = preload("res://scripts/sim/dragon_data.gd")
const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const TacticalBattle   = preload("res://scripts/sim/tactical_battle.gd")
const BattleEngine     = preload("res://scripts/sim/battle_engine.gd")
const TechniqueData    = preload("res://scripts/sim/technique_data.gd")
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
var _player_move_keys: Array = []
var _npc_move_keys: Array = []
var _player_stage: int = 1
var _player_status: Variant = null
var _npc_status: Variant = null
var _player_defending: bool = false
var _npc_defending: bool = false
var _player_reflecting: bool = false
var _npc_reflecting: bool = false
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
	var npc_id: String    = str(_config.get("npc_id", "firewall_sentinel"))
	_npc_data = TacticalBattle.EnemyData.get(npc_id, {}).duplicate(true)

	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {}).duplicate(true)
	var level: int = DragonProgression.get_dragon_level(_save, dragon_id)
	_player_element = str(dragon_def.get("element", "fire"))
	_npc_element    = str(_npc_data.get("element", "fire"))
	_player_stage   = DragonData.get_stage_for_level(level)

	_player_stats = DragonData.calculate_stats(dragon_def, level)
	_player_stats["element"] = _player_element
	var npc_raw: Dictionary = _npc_data.get("stats", {})
	_npc_stats = npc_raw.duplicate(true)
	_npc_stats["element"] = _npc_element

	_player_max_hp = int(_player_stats.get("hp", 100))
	_npc_max_hp    = int(npc_raw.get("hp", 100))
	_player_hp     = _player_max_hp
	_npc_hp        = _npc_max_hp

	_player_move_keys = Array(DragonProgression.get_active_techniques(_save))
	if _player_move_keys.is_empty():
		_player_move_keys = Array(dragon_def.get("move_keys", ["basic_attack"]))
	_npc_move_keys = _derive_npc_move_keys(_npc_element)

	_player_moves.clear()
	for key in _player_move_keys:
		var t: Dictionary = TechniqueData.get_technique(key)
		if not t.is_empty():
			_player_moves.append(t)

	player_sprite.set_dragon(dragon_id, _player_stage)
	npc_sprite.set_dragon(npc_id, 1)
	player_name.text = str(dragon_def.get("name", dragon_id))
	npc_name.text    = str(_npc_data.get("name", npc_id))
	header_label.text = "%s  VS  %s" % [player_name.text, npc_name.text]
	_update_hp_display()

func _derive_npc_move_keys(element: String) -> Array:
	var table := {
		"fire":   ["magma_breath", "flame_wall"],
		"ice":    ["frost_bite", "blizzard"],
		"storm":  ["lightning_strike", "thunder_clap"],
		"stone":  ["rock_slide", "earthquake"],
		"venom":  ["acid_spit", "toxic_cloud"],
		"shadow": ["shadow_strike", "void_pulse"],
		"void":   ["void_rift", "null_reflect"],
	}
	return table.get(element, ["basic_attack"])

func _build_state(side: String) -> Dictionary:
	var is_player := side == "player"
	var stats: Dictionary = _player_stats if is_player else _npc_stats
	return {
		"hp":        _player_hp if is_player else _npc_hp,
		"max_hp":    _player_max_hp if is_player else _npc_max_hp,
		"atk":       int(stats.get("atk", 20)),
		"def":       int(stats.get("def", 15)),
		"spd":       int(stats.get("spd", 15)),
		"element":   _player_element if is_player else _npc_element,
		"stage":     _player_stage if is_player else BattleEngine.get_stage_for_level(int(_npc_data.get("level", 1))),
		"defending": _player_defending if is_player else _npc_defending,
		"reflecting": _player_reflecting if is_player else _npc_reflecting,
		"status":    _player_status if is_player else _npc_status,
	}

func _build_move_buttons() -> void:
	for c in move_buttons.get_children(): c.queue_free()

	for move in _player_moves:
		var btn := Button.new()
		btn.text = str(move.get("label", move.get("id", "?")))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key: String = str(move.get("id", "basic_attack"))
		btn.pressed.connect(func(): _execute_turn(key))
		move_buttons.add_child(btn)

	var basic := Button.new()
	basic.text = "Basic Attack"
	basic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	basic.pressed.connect(func(): _execute_turn("basic_attack"))
	move_buttons.add_child(basic)

	var defend_btn := Button.new()
	defend_btn.text = "Defend"
	defend_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	defend_btn.pressed.connect(func(): _execute_turn("defend"))
	move_buttons.add_child(defend_btn)

func _set_buttons_disabled(disabled: bool) -> void:
	for btn in move_buttons.get_children():
		if btn is Button:
			btn.disabled = disabled

func _execute_turn(player_move_key: String) -> void:
	if _battle_over:
		return
	_set_buttons_disabled(true)

	var player_state := _build_state("player")
	var npc_state    := _build_state("npc")
	var npc_key: String = BattleEngine.pick_npc_move(
		_npc_move_keys, _npc_element, _player_element, _player_status
	)

	var result: Dictionary = BattleEngine.resolve_turn(
		player_state, npc_state,
		player_move_key, npc_key,
		_player_move_keys, _npc_move_keys
	)

	for event in result.get("events", []):
		await _play_event(event)
		_update_hp_display()
		if _npc_hp <= 0 or _player_hp <= 0:
			break

	var fp: Dictionary = result.get("player", {})
	var fn: Dictionary = result.get("npc", {})
	_player_hp        = int(fp.get("hp", _player_hp))
	_npc_hp           = int(fn.get("hp", _npc_hp))
	_player_status    = fp.get("status", null)
	_npc_status       = fn.get("status", null)
	_player_defending = bool(fp.get("defending", false))
	_npc_defending    = bool(fn.get("defending", false))
	_player_reflecting = bool(fp.get("reflecting", false))
	_npc_reflecting   = bool(fn.get("reflecting", false))

	_update_hp_display()
	_update_status_icons()

	if _npc_hp <= 0:
		await _end_battle(true)
		return
	if _player_hp <= 0:
		await _end_battle(false)
		return

	_set_buttons_disabled(false)

func _play_event(event: Dictionary) -> void:
	var attacker: String = str(event.get("attacker", "player"))
	var action: String   = str(event.get("action",   "attack"))

	# Status-tick events (attacker == "status")
	if attacker == "status":
		var dmg: int = int(event.get("damage", 0))
		var target: String = str(event.get("target", "player"))
		var effect_name: String = str(event.get("effect_name", ""))
		if dmg > 0:
			if target == "player":
				_player_hp = maxi(0, _player_hp - dmg)
				_spawn_damage_number(player_sprite.global_position, dmg, false, false)
			else:
				_npc_hp = maxi(0, _npc_hp - dmg)
				_spawn_damage_number(npc_sprite.global_position, dmg, false, false)
			_append_log("[color=#cc88ff]%s takes %d damage from %s.[/color]" % [
				("You" if target == "player" else npc_name.text), dmg, effect_name
			])
		if event.get("expired", false) and effect_name != "":
			_append_log("%s status faded." % effect_name)
		await get_tree().create_timer(0.15).timeout
		return

	match action:
		"statusSkip":
			var who: String = npc_name.text if attacker == "npc" else "You"
			var status_name: String = str(event.get("status_name", "status"))
			_append_log("[color=#8fb0ff]%s is held by %s — can't move![/color]" % [who, status_name])
			await get_tree().create_timer(0.3).timeout
			return
		"defend":
			var who: String = npc_name.text if attacker == "npc" else "You"
			_append_log("%s braces for impact. DEF boosted this turn." % who)
			await get_tree().create_timer(0.3).timeout
			return
		"reflect":
			var who: String = npc_name.text if attacker == "npc" else "You"
			_append_log("%s sets up Null Reflect." % who)
			await get_tree().create_timer(0.3).timeout
			return

	# attack action
	var hit: bool          = bool(event.get("hit", false))
	var damage: int        = int(event.get("damage", 0))
	var effectiveness: float = float(event.get("effectiveness", 1.0))
	var move_name: String  = str(event.get("move_name", "Attack"))
	var reflected: bool    = bool(event.get("reflected", false))

	await _play_attack_animation(attacker, {})

	if hit and damage > 0:
		var target_hp: int = int(event.get("target_hp", -1))
		if reflected:
			# damage bounced back to the attacker
			if attacker == "player":
				_player_hp = maxi(0, target_hp if target_hp >= 0 else _player_hp - damage)
				_spawn_damage_number(player_sprite.global_position, damage, false, false)
			else:
				_npc_hp = maxi(0, target_hp if target_hp >= 0 else _npc_hp - damage)
				_spawn_damage_number(npc_sprite.global_position, damage, false, false)
			_append_log("[color=#cc88ff]%s is reflected back![/color]" % move_name)
		else:
			var target_sprite: Control = player_sprite if attacker == "npc" else npc_sprite
			var target_el: String = _player_element if attacker == "npc" else _npc_element
			var effective := effectiveness > 1.0
			var resisted  := effectiveness < 1.0

			if target_hp >= 0:
				if attacker == "player":
					_npc_hp = target_hp
				else:
					_player_hp = target_hp

			_spawn_damage_number(target_sprite.global_position, damage, effective, resisted)
			_add_trauma(0.18 if effective else 0.1)
			_trigger_hit_particles(target_sprite.global_position, target_el)

			if effective:
				_append_log("[color=#ffcc00]%s hits for %d! Super effective![/color]" % [move_name, damage])
			elif resisted:
				_append_log("[color=#8fb0ff]%s hits for %d. Not very effective.[/color]" % [move_name, damage])
			else:
				_append_log("%s hits for %d damage." % [move_name, damage])

			if event.get("is_critical", false):
				_append_log("[color=#ffcc00]Critical hit![/color]")

			var applied: Variant = event.get("applied_status", null)
			if applied != null:
				var target_name: String = str(_npc_data.get("name", "NPC")) if attacker == "player" else "You"
				_append_log("[color=#cc88ff]%s is now afflicted by %s![/color]" % [target_name, str(applied)])

		var eff_str: float = effectiveness
		if (_npc_hp <= 0 and attacker == "player") or (_player_hp <= 0 and attacker == "npc"):
			_rumble(0.6, 1.0, 0.5)
		else:
			_rumble(0.4 if eff_str > 1.0 else 0.2, 0.8 if eff_str > 1.0 else 0.3, 0.15)
	elif not hit:
		_append_log("%s missed!" % move_name)

	await get_tree().create_timer(0.25).timeout

func _play_attack_animation(side: String, _move: Dictionary) -> void:
	var target_node: Control = player_sprite if side == "player" else npc_sprite
	var direction: float     = 1.0 if side == "player" else -1.0
	var original_x: float    = target_node.position.x
	var tween := create_tween()
	tween.tween_property(target_node, "position:x", original_x + 30.0 * direction, 0.1)
	tween.tween_property(target_node, "position:x", original_x, 0.12)
	var hit_target: Control  = npc_sprite if side == "player" else player_sprite
	var orig_hit_x: float    = hit_target.position.x
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
		hit_particles.amount      = int(cfg.get("amount", 24))
		hit_particles.lifetime    = float(cfg.get("lifetime", 0.6))
		hit_particles.speed_scale = float(cfg.get("speed_scale", 1.0))
	if hit_particles.process_material is ParticleProcessMaterial:
		hit_particles.process_material.color  = color
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
	player_hp_bar.value     = _player_hp
	player_hp_label.text    = "%d / %d" % [_player_hp, _player_max_hp]
	npc_hp_bar.max_value    = _npc_max_hp
	npc_hp_bar.value        = _npc_hp
	npc_hp_label.text       = "%d / %d" % [_npc_hp, _npc_max_hp]

func _update_status_icons() -> void:
	for c in player_status_icons.get_children(): c.queue_free()
	if _player_status != null and _player_status is Dictionary:
		var effect: String = str(_player_status.get("effect", ""))
		if effect != "":
			var lbl := Label.new()
			lbl.text = "[%s]" % effect.to_upper()
			lbl.add_theme_font_size_override("font_size", 10)
			player_status_icons.add_child(lbl)

func _append_log(text: String) -> void:
	battle_log.append_text(text + "\n")

func _end_battle(player_won: bool) -> void:
	_battle_over = true
	_set_buttons_disabled(true)

	if player_won:
		var dragon_id: String    = str(_config.get("dragon_id", _save.get("dragon_id", "fire")))
		var reward_xp: int       = int(_npc_data.get("reward_xp", 50))
		var reward_scraps: int   = int(_npc_data.get("reward_scraps", 30))
		var npc_id: String       = str(_config.get("npc_id", ""))

		_save = DragonProgression.award_dragon_xp(_save, reward_xp, dragon_id)
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
	SaveIO.flush(_save)
