extends Control

signal navigate(target: String, payload: Variant)

const SaveHelper = preload("res://scripts/sim/save_helper.gd")
const DragonData = preload("res://scripts/sim/dragon_data.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
	{"label": "STATS",    "target": "stats"},
]

@onready var stats_text: RichTextLabel = $VBoxContainer/StatsText
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	_refresh()

func _refresh() -> void:
	var lines: PackedStringArray = []

	lines.append("[color=#c0c8ff][b]COMBAT[/b][/color]")
	lines.append("Battles Won: %d" % SaveHelper.count_battles_won(_save))
	lines.append("Singularity Bosses Defeated: %d" % SaveHelper.count_singularity_defeated(_save))
	lines.append("")

	lines.append("[color=#c0c8ff][b]COLLECTION[/b][/color]")
	var owned: Array = _save.get("hatchery_state", {}).get("owned_dragons", [])
	lines.append("Dragons Owned: %d" % owned.size())

	var max_lvl := 1
	for lvl in _save.get("dragon_levels", {}).values():
		max_lvl = maxi(max_lvl, int(lvl))
	lines.append("Highest Level: %d" % max_lvl)
	lines.append("Highest Stage: %d" % DragonData.get_stage_for_level(max_lvl))
	lines.append("")

	lines.append("[color=#c0c8ff][b]RESOURCES[/b][/color]")
	lines.append("Data Scraps: %d" % int(_save.get("data_scraps", 0)))
	lines.append("Key Items: %d" % _save.get("key_items", []).size())
	lines.append("")

	var flags: Array = _save.get("mission_flags", [])
	if flags.size() > 0:
		lines.append("[color=#c0c8ff][b]FLAGS[/b][/color]")
		for flag in flags:
			lines.append("• %s" % str(flag))

	stats_text.clear()
	stats_text.append_text("\n".join(lines))
