extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const DragonData = preload("res://scripts/sim/dragon_data.gd")
const TacticalBattle = preload("res://scripts/sim/tactical_battle.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY",   "target": "hatchery"},
	{"label": "BATTLE",     "target": "battleSelect"},
	{"label": "FUSION",     "target": "fusion"},
]

@onready var dragon_scroll: VBoxContainer = $VBoxContainer/HBoxContainer/DragonList/ScrollContainer/DragonScroll
@onready var enemy_scroll: VBoxContainer = $VBoxContainer/HBoxContainer/EnemyList/ScrollContainer/EnemyScroll
@onready var fight_button: Button = $VBoxContainer/FightButton
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _selected_dragon: String = ""
var _selected_enemy: String = ""

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	fight_button.pressed.connect(_on_fight_pressed)
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	fight_button.visible = false
	_build_lists()

func _build_lists() -> void:
	for c in dragon_scroll.get_children(): c.queue_free()
	for c in enemy_scroll.get_children(): c.queue_free()

	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})

	for dragon_id in owned:
		var btn := _make_dragon_btn(dragon_id, levels)
		dragon_scroll.add_child(btn)

	var defeated: Dictionary = _save.get("bestiary_defeated", {})
	for enemy_id in TacticalBattle.EnemyData.keys():
		var btn := _make_enemy_btn(enemy_id, defeated)
		enemy_scroll.add_child(btn)

func _make_dragon_btn(dragon_id: String, levels: Dictionary) -> Button:
	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
	var level: int = int(levels.get(dragon_id, 1))
	var btn := Button.new()
	btn.text = "%s  LV %d" % [str(dragon_def.get("name", dragon_id)), level]
	btn.toggle_mode = true
	btn.pressed.connect(func():
		_selected_dragon = dragon_id
		_refresh_fight_button()
		for sibling in dragon_scroll.get_children():
			if sibling != btn and sibling is Button:
				sibling.button_pressed = false
	)
	return btn

func _make_enemy_btn(enemy_id: String, defeated: Dictionary) -> Button:
	var enemy: Dictionary = TacticalBattle.EnemyData.get(enemy_id, {})
	var times_defeated: int = int(defeated.get(enemy_id, 0))
	var btn := Button.new()
	btn.text = "%s  [%s]  LV %d" % [
		str(enemy.get("name", enemy_id)),
		str(enemy.get("element", "?")).to_upper(),
		int(enemy.get("level", 1)),
	]
	if times_defeated > 0:
		btn.text += "  v"
	btn.toggle_mode = true
	btn.pressed.connect(func():
		_selected_enemy = enemy_id
		_refresh_fight_button()
		for sibling in enemy_scroll.get_children():
			if sibling != btn and sibling is Button:
				sibling.button_pressed = false
	)
	return btn

func _refresh_fight_button() -> void:
	fight_button.visible = _selected_dragon != "" and _selected_enemy != ""

func _on_fight_pressed() -> void:
	if _selected_dragon == "" or _selected_enemy == "":
		return
	var payload := {
		"dragon_id": _selected_dragon,
		"npc_id": _selected_enemy,
		"return_screen": "battleSelect",
		"is_singularity": false,
	}
	navigate.emit("battle", payload)
