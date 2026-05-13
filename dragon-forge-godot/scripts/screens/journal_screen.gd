extends Control

signal navigate(target: String, payload: Variant)

const DragonData = preload("res://scripts/sim/dragon_data.gd")
const SaveHelper = preload("res://scripts/sim/save_helper.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
	{"label": "JOURNAL",  "target": "journal"},
]

@onready var milestone_list: VBoxContainer = $VBoxContainer/ScrollContainer/MilestoneList
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _milestones: Array = []

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_refresh()

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	status_label.text = ""
	_load_milestones()

func _load_milestones() -> void:
	var file := FileAccess.open("res://data/journal_milestones.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_ARRAY:
		_milestones = parsed

func _refresh() -> void:
	_rebuild_list()

func _rebuild_list() -> void:
	for c in milestone_list.get_children(): c.queue_free()

	for milestone in _milestones:
		var m_id: String = str(milestone.get("id", ""))
		var claimed: bool = SaveHelper.is_milestone_claimed(_save, m_id)
		var unlocked: bool = _check_condition(milestone.get("condition", {}))
		var reward: int = int(milestone.get("reward", 0))

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var title_lbl := Label.new()
		title_lbl.text = str(milestone.get("title", m_id))
		title_lbl.add_theme_font_size_override("font_size", 15)
		if claimed:
			title_lbl.add_theme_color_override("font_color", Color("#70ff8f"))
		elif not unlocked:
			title_lbl.add_theme_color_override("font_color", Color("#555566"))
		info.add_child(title_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(milestone.get("description", ""))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc_lbl)

		row.add_child(info)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(72, 0)
		if claimed:
			btn.text = "DONE"
			btn.disabled = true
		elif unlocked:
			btn.text = "CLAIM\n+%d" % reward
			var mid_copy: Dictionary = milestone.duplicate()
			btn.pressed.connect(func(): _on_claim(mid_copy))
		else:
			btn.text = "LOCKED"
			btn.disabled = true
		row.add_child(btn)

		milestone_list.add_child(row)
		milestone_list.add_child(HSeparator.new())

func _check_condition(condition: Dictionary) -> bool:
	var type: String = str(condition.get("type", ""))
	var value: int = int(condition.get("value", 0))
	match type:
		"battles_won":
			return SaveHelper.count_battles_won(_save) >= value
		"max_stage":
			var max_lvl := 1
			for lvl in _save.get("dragon_levels", {}).values():
				max_lvl = maxi(max_lvl, int(lvl))
			return DragonData.get_stage_for_level(max_lvl) >= value
		"eggs_hatched":
			return _save.get("hatchery_state", {}).get("owned_dragons", []).size() >= value
		"singularity_defeated":
			return SaveHelper.count_singularity_defeated(_save) >= value
	return false

func _on_claim(milestone: Dictionary) -> void:
	var m_id: String = str(milestone.get("id", ""))
	var reward: int = int(milestone.get("reward", 0))
	SaveHelper.claim_milestone(_save, m_id)
	_save["data_scraps"] = int(_save.get("data_scraps", 0)) + reward
	status_label.text = "Claimed: %s  +%d scraps" % [str(milestone.get("title", m_id)), reward]
	_write_save()
	_refresh()

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
