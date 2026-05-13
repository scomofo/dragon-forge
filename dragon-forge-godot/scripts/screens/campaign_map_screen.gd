extends Control

signal navigate(target: String, payload: Variant)

const DragonData = preload("res://scripts/sim/dragon_data.gd")
const TacticalBattle = preload("res://scripts/sim/tactical_battle.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY",    "target": "hatchery"},
	{"label": "BATTLE",      "target": "battleSelect"},
	{"label": "SINGULARITY", "target": "singularity"},
	{"label": "CAMPAIGN",    "target": "campaignMap"},
]

const CAMPAIGN_ORDER := [
	"firewall_sentinel",
	"buffer_overflow",
	"bit_wraith",
	"crypto_crab",
	"phishing_siren",
	"glitch_hydra",
	"logic_bomb",
	"recursive_golem",
]

@onready var dragon_list: VBoxContainer = $VBoxContainer/ContentRow/DragonPick/ScrollContainer/DragonList
@onready var zone_list: VBoxContainer = $VBoxContainer/ContentRow/ZoneList/ScrollContainer/Zones
@onready var challenge_button: Button = $VBoxContainer/ChallengeButton
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _selected_dragon: String = ""
var _selected_npc_id: String = ""

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_refresh()

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	challenge_button.visible = false
	challenge_button.pressed.connect(_on_challenge_pressed)

func _refresh() -> void:
	_rebuild_dragon_list()
	_rebuild_zone_list()

func _rebuild_dragon_list() -> void:
	for c in dragon_list.get_children(): c.queue_free()

	var owned: Array = _save.get("hatchery_state", {}).get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})

	for dragon_id in owned:
		var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
		var level: int = int(levels.get(dragon_id, 1))
		var btn := Button.new()
		btn.text = "%s LV%d" % [str(dragon_def.get("name", dragon_id)), level]
		btn.toggle_mode = true
		var did: String = dragon_id
		btn.pressed.connect(func():
			_selected_dragon = did
			_deselect_siblings(dragon_list, btn)
			_update_challenge_button()
		)
		dragon_list.add_child(btn)

func _rebuild_zone_list() -> void:
	for c in zone_list.get_children(): c.queue_free()

	var defeated: Dictionary = _save.get("bestiary_defeated", {})

	for npc_id in CAMPAIGN_ORDER:
		var enemy: Dictionary = TacticalBattle.EnemyData.get(npc_id, {})
		if enemy.is_empty():
			continue

		var is_defeated: bool = int(defeated.get(npc_id, 0)) > 0
		var stats: Dictionary = enemy.get("stats", {})

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(enemy.get("name", npc_id))
		name_lbl.add_theme_font_size_override("font_size", 14)
		if is_defeated:
			name_lbl.add_theme_color_override("font_color", Color("#70ff8f"))
		info.add_child(name_lbl)

		var detail_lbl := Label.new()
		detail_lbl.text = "LV%d  %s  HP:%d  XP:%d" % [
			int(enemy.get("level", 1)),
			str(enemy.get("element", "?")).to_upper(),
			int(stats.get("hp", 0)),
			int(enemy.get("reward_xp", 0)),
		]
		detail_lbl.add_theme_font_size_override("font_size", 10)
		detail_lbl.add_theme_color_override("font_color", Color("#8090a0"))
		info.add_child(detail_lbl)

		row.add_child(info)

		var sel_btn := Button.new()
		sel_btn.text = "AGAIN" if is_defeated else "FIGHT"
		sel_btn.toggle_mode = true
		var nid: String = npc_id
		sel_btn.pressed.connect(func():
			_selected_npc_id = nid
			_deselect_siblings(zone_list, sel_btn)
			_update_challenge_button()
		)
		row.add_child(sel_btn)

		zone_list.add_child(row)
		zone_list.add_child(HSeparator.new())

func _deselect_siblings(parent: Control, except: Button) -> void:
	for c in parent.get_children():
		if c is Button and c != except:
			c.button_pressed = false

func _update_challenge_button() -> void:
	challenge_button.visible = _selected_dragon != "" and _selected_npc_id != ""

func _on_challenge_pressed() -> void:
	if _selected_dragon == "" or _selected_npc_id == "":
		return
	navigate.emit("battle", {
		"dragon_id": _selected_dragon,
		"npc_id": _selected_npc_id,
		"return_screen": "campaignMap",
	})
