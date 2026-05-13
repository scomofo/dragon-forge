extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const SaveHelper = preload("res://scripts/sim/save_helper.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
	{"label": "SHOP",     "target": "shop"},
]

@onready var scraps_label: Label = $VBoxContainer/ScrapsLabel
@onready var item_list: VBoxContainer = $VBoxContainer/ScrollContainer/ItemList
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _shop_items: Array = []

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_refresh()

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	status_label.text = ""
	_load_shop_data()

func _load_shop_data() -> void:
	var file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_shop_items = parsed.get("buy_items", [])

func _refresh() -> void:
	scraps_label.text = "DATA SCRAPS: %d" % int(_save.get("data_scraps", 0))
	_rebuild_list()

func _rebuild_list() -> void:
	for c in item_list.get_children(): c.queue_free()

	for item in _shop_items:
		var item_id: String = str(item.get("id", ""))
		var cost: int = int(item.get("cost", 0))
		var can_afford: bool = int(_save.get("data_scraps", 0)) >= cost

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = "%s  %s" % [str(item.get("icon", "")), str(item.get("name", item_id))]
		name_lbl.add_theme_font_size_override("font_size", 15)
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(item.get("description", ""))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc_lbl)

		row.add_child(info)

		var btn := Button.new()
		btn.text = "BUY\n%d" % cost
		btn.custom_minimum_size = Vector2(64, 0)
		btn.disabled = not can_afford
		var item_copy: Dictionary = item.duplicate()
		btn.pressed.connect(func(): _on_buy(item_copy))
		row.add_child(btn)

		item_list.add_child(row)
		item_list.add_child(HSeparator.new())

func _on_buy(item: Dictionary) -> void:
	var cost: int = int(item.get("cost", 0))
	if int(_save.get("data_scraps", 0)) < cost:
		return

	_save["data_scraps"] = int(_save["data_scraps"]) - cost

	var effect: String = str(item.get("effect", ""))
	var item_id: String = str(item.get("id", ""))
	match effect:
		"xpBoost":
			SaveHelper.add_inventory_item(_save, "xp_boost_charges", 3)
		"shinyUpgrade":
			SaveHelper.add_inventory_item(_save, "shiny_charm", 1)
		"pityReset":
			if not _save.has("hatchery_state"):
				_save["hatchery_state"] = {}
			_save["hatchery_state"]["pity_counter"] = 0
		"reroll":
			SaveHelper.add_inventory_item(_save, "element_reroll", 1)
		"grantXp":
			var xp_amount: int = int(item.get("xp_amount", 50))
			_save = DragonProgression.award_dragon_xp(_save, xp_amount)
		_:
			SaveHelper.add_inventory_item(_save, item_id, 1)

	status_label.text = "Purchased: %s" % str(item.get("name", item_id))
	_write_save()
	_refresh()

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
