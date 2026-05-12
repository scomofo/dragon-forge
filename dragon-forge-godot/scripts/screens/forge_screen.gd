extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
	{"label": "SHOP",     "target": "shop"},
]

@onready var scraps_label: Label = $VBoxContainer/ScrapsLabel
@onready var recipe_list: VBoxContainer = $VBoxContainer/ScrollContainer/RecipeList
@onready var status_label: Label = $VBoxContainer/StatusLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _recipes: Array = []

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	status_label.text = ""
	_load_recipes()
	_refresh()

func _load_recipes() -> void:
	var file := FileAccess.open("res://data/shop_items.json", FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_recipes = parsed.get("forge_recipes", [])

func _refresh() -> void:
	scraps_label.text = "DATA SCRAPS: %d" % int(_save.get("data_scraps", 0))
	_rebuild_list()

func _rebuild_list() -> void:
	for c in recipe_list.get_children(): c.queue_free()

	for recipe in _recipes:
		var cost: int = int(recipe.get("scraps_cost", 0))
		var can_afford: bool = int(_save.get("data_scraps", 0)) >= cost

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl := Label.new()
		name_lbl.text = "%s  %s" % [str(recipe.get("icon", "")), str(recipe.get("name", ""))]
		name_lbl.add_theme_font_size_override("font_size", 15)
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = str(recipe.get("description", ""))
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(desc_lbl)

		var cores_lbl := Label.new()
		cores_lbl.text = "Cores required: %s" % _cores_to_string(recipe.get("cores", {}))
		cores_lbl.add_theme_font_size_override("font_size", 10)
		cores_lbl.add_theme_color_override("font_color", Color("#a0a0a0"))
		info.add_child(cores_lbl)

		row.add_child(info)

		var btn := Button.new()
		btn.text = ("CRAFT\n%d scraps" % cost) if cost > 0 else "CRAFT\nFree"
		btn.custom_minimum_size = Vector2(80, 0)
		btn.disabled = not can_afford
		var recipe_copy := recipe.duplicate()
		btn.pressed.connect(func(): _on_craft(recipe_copy))
		row.add_child(btn)

		recipe_list.add_child(row)
		recipe_list.add_child(HSeparator.new())

func _cores_to_string(cores: Dictionary) -> String:
	if cores.has("same"):
		return "%d of same element" % int(cores["same"])
	if cores.has("different"):
		return "%d different elements" % int(cores["different"])
	if cores.has("any"):
		return "%d any" % int(cores["any"])
	if cores.has("allSix"):
		return "all 6 elements"
	return "none"

func _on_craft(recipe: Dictionary) -> void:
	var cost: int = int(recipe.get("scraps_cost", 0))
	if int(_save.get("data_scraps", 0)) < cost:
		return

	_save["data_scraps"] = int(_save["data_scraps"]) - cost

	var effect: String = str(recipe.get("effect", ""))
	var xp: int = int(recipe.get("xp_amount", 0))
	match effect:
		"grantXpElement", "grantXp":
			if xp > 0:
				_save = DragonProgression.award_dragon_xp(_save, xp)
		"stabilityBoost":
			if not _save.has("mission_flags"):
				_save["mission_flags"] = []
			var flags: Array = _save["mission_flags"]
			if not flags.has("stability_boost_active"):
				flags.append("stability_boost_active")
		"exoticPull":
			if not _save.has("mission_flags"):
				_save["mission_flags"] = []
			var flags: Array = _save["mission_flags"]
			if not flags.has("exotic_pull_ready"):
				flags.append("exotic_pull_ready")

	status_label.text = "Crafted: %s" % str(recipe.get("name", ""))
	_write_save()
	_refresh()

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
