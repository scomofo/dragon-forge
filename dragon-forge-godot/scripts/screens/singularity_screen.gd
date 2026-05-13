extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const DragonData = preload("res://scripts/sim/dragon_data.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY",    "target": "hatchery"},
	{"label": "BATTLE",      "target": "battleSelect"},
	{"label": "SINGULARITY", "target": "singularity"},
	{"label": "CAMPAIGN",    "target": "campaignMap"},
]

@onready var dragon_list: VBoxContainer = $VBoxContainer/ContentRow/DragonPick/ScrollContainer/DragonList
@onready var boss_list: VBoxContainer = $VBoxContainer/ContentRow/BossList/ScrollContainer/Bosses
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var challenge_button: Button = $VBoxContainer/ChallengeButton
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _bosses: Array = []
var _final_boss: Dictionary = {}
var _selected_dragon: String = ""
var _selected_boss_id: String = ""

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_refresh()

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	challenge_button.visible = false
	challenge_button.pressed.connect(_on_challenge_pressed)
	_load_boss_data()

func _load_boss_data() -> void:
	var file := FileAccess.open("res://data/singularity_bosses.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_bosses = parsed.get("bosses", [])
		_final_boss = parsed.get("final_boss", {})

func _refresh() -> void:
	_rebuild_dragon_list()
	_rebuild_boss_list()

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

func _rebuild_boss_list() -> void:
	for c in boss_list.get_children(): c.queue_free()

	var flags: Array = _save.get("mission_flags", [])

	for boss in _bosses:
		var boss_id: String = str(boss.get("id", ""))
		var defeated: bool = flags.has("singularity_%s_defeated" % boss_id)
		var req_id: String = str(boss.get("unlock_requires", ""))
		var available: bool = req_id == "" or req_id == "null" or flags.has("singularity_%s_defeated" % req_id)

		var row := HBoxContainer.new()

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = str(boss.get("name", boss_id))
		name_lbl.add_theme_font_size_override("font_size", 14)
		if defeated:
			name_lbl.add_theme_color_override("font_color", Color("#70ff8f"))
		elif not available:
			name_lbl.add_theme_color_override("font_color", Color("#444455"))
		info.add_child(name_lbl)

		var quote_lbl := Label.new()
		quote_lbl.text = str(boss.get("felix_quote", ""))
		quote_lbl.add_theme_font_size_override("font_size", 10)
		quote_lbl.add_theme_color_override("font_color", Color("#8090a0"))
		quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(quote_lbl)

		row.add_child(info)

		var stats: Dictionary = boss.get("stats", {})
		var stats_lbl := Label.new()
		stats_lbl.text = "LV%d\nHP:%d" % [int(boss.get("level", 1)), int(stats.get("hp", 0))]
		stats_lbl.add_theme_font_size_override("font_size", 10)
		row.add_child(stats_lbl)

		if available and not defeated:
			var sel_btn := Button.new()
			sel_btn.text = "SELECT"
			sel_btn.toggle_mode = true
			var bid := boss_id
			sel_btn.pressed.connect(func():
				_selected_boss_id = bid
				_deselect_siblings(boss_list, sel_btn)
				_update_challenge_button()
			)
			row.add_child(sel_btn)

		boss_list.add_child(row)
		boss_list.add_child(HSeparator.new())

	if not _final_boss.is_empty():
		var fb_id: String = str(_final_boss.get("id", "the_singularity"))
		var defeated: bool = flags.has("singularity_defeated")
		var req_id: String = str(_final_boss.get("unlock_requires", ""))
		var available: bool = req_id == "" or req_id == "null" or flags.has("singularity_%s_defeated" % req_id)

		var row := HBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.text = "★ %s" % str(_final_boss.get("name", fb_id))
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if defeated:
			name_lbl.add_theme_color_override("font_color", Color("#70ff8f"))
		elif not available:
			name_lbl.add_theme_color_override("font_color", Color("#444455"))
		row.add_child(name_lbl)

		if available and not defeated:
			var sel_btn := Button.new()
			sel_btn.text = "SELECT"
			sel_btn.toggle_mode = true
			sel_btn.pressed.connect(func():
				_selected_boss_id = fb_id
				_deselect_siblings(boss_list, sel_btn)
				_update_challenge_button()
			)
			row.add_child(sel_btn)

		boss_list.add_child(row)

func _deselect_siblings(parent: Control, except: Button) -> void:
	for c in parent.get_children():
		if c is Button and c != except:
			c.button_pressed = false

func _update_challenge_button() -> void:
	challenge_button.visible = _selected_dragon != "" and _selected_boss_id != ""

func _on_challenge_pressed() -> void:
	if _selected_dragon == "" or _selected_boss_id == "":
		return
	navigate.emit("battle", {
		"dragon_id": _selected_dragon,
		"npc_id": _selected_boss_id,
		"return_screen": "singularity",
		"is_singularity": true,
	})
