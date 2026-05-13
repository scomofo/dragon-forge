extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const DragonData = preload("res://scripts/sim/dragon_data.gd")

const NAV_ENTRIES := [
	{"label": "HATCHERY",  "target": "hatchery"},
	{"label": "BATTLE",    "target": "battleSelect"},
	{"label": "FUSION",    "target": "fusion"},
]
const FUSE_COST := 100

const FUSION_TABLE := {
	"fire+ice": "storm",
	"fire+stone": "fire",
	"fire+storm": "venom",
	"fire+venom": "shadow",
	"fire+shadow": "fire",
	"ice+stone": "ice",
	"ice+storm": "ice",
	"ice+venom": "shadow",
	"ice+shadow": "venom",
	"stone+storm": "stone",
	"stone+venom": "stone",
	"stone+shadow": "stone",
	"storm+venom": "storm",
	"storm+shadow": "shadow",
	"venom+shadow": "venom",
}

const UNSTABLE_PAIRS := ["fire+ice", "stone+storm", "venom+shadow"]

const STABILITY_COLORS := {
	"stable":   Color("#ffd166"),
	"normal":   Color("#ffffff"),
	"unstable": Color("#ff4d4d"),
}

@onready var scraps_label: Label = $VBoxContainer/ScrapsLabel
@onready var list_a: VBoxContainer = $VBoxContainer/PickRow/PickA/ScrollContainer/ListA
@onready var list_b: VBoxContainer = $VBoxContainer/PickRow/PickB/ScrollContainer/ListB
@onready var preview_element: Label = $VBoxContainer/PickRow/Preview/PreviewElement
@onready var preview_stability: Label = $VBoxContainer/PickRow/Preview/PreviewStability
@onready var preview_stats: Label = $VBoxContainer/PickRow/Preview/PreviewStats
@onready var fuse_button: Button = $VBoxContainer/FuseButton
@onready var fusion_overlay: Control = $FusionOverlay
@onready var fusion_label: Label = $FusionOverlay/OverlayVBox/FusionLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}
var _selected_a: String = ""
var _selected_b: String = ""

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_refresh()

func _ready() -> void:
	fuse_button.pressed.connect(_on_fuse_pressed)
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	fusion_overlay.visible = false
	fuse_button.visible = false

func _refresh() -> void:
	scraps_label.text = "DATA SCRAPS: %d" % int(_save.get("data_scraps", 0))
	_rebuild_lists()
	_update_preview()

func _rebuild_lists() -> void:
	for c in list_a.get_children(): c.queue_free()
	for c in list_b.get_children(): c.queue_free()

	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})

	for dragon_id in owned:
		var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
		var level: int = int(levels.get(dragon_id, 1))
		var label_text := "%s LV%d" % [str(dragon_def.get("name", dragon_id)), level]

		var btn_a := Button.new()
		btn_a.text = label_text
		btn_a.toggle_mode = true
		var id_a := dragon_id
		btn_a.pressed.connect(func():
			if _selected_b == id_a:
				_selected_b = ""
			_selected_a = id_a
			_deselect_siblings(list_a, btn_a)
			_deselect_if_same_b()
			_update_preview()
		)
		list_a.add_child(btn_a)

		var btn_b := Button.new()
		btn_b.text = label_text
		btn_b.toggle_mode = true
		var id_b := dragon_id
		btn_b.pressed.connect(func():
			if _selected_a == id_b:
				_selected_a = ""
			_selected_b = id_b
			_deselect_siblings(list_b, btn_b)
			_deselect_if_same_a()
			_update_preview()
		)
		list_b.add_child(btn_b)

func _deselect_siblings(parent: VBoxContainer, except: Button) -> void:
	for c in parent.get_children():
		if c is Button and c != except:
			c.button_pressed = false

func _deselect_if_same_b() -> void:
	if _selected_b == _selected_a and _selected_b != "":
		_selected_b = ""
		for c in list_b.get_children():
			if c is Button: c.button_pressed = false

func _deselect_if_same_a() -> void:
	if _selected_a == _selected_b and _selected_a != "":
		_selected_a = ""
		for c in list_a.get_children():
			if c is Button: c.button_pressed = false

func _update_preview() -> void:
	if _selected_a == "" or _selected_b == "" or _selected_a == _selected_b:
		preview_element.text = "Element: —"
		preview_stability.text = "Stability: —"
		preview_stats.text = ""
		fuse_button.visible = false
		return

	var elem_a: String = str(DragonData.DRAGONS.get(_selected_a, {}).get("element", "fire"))
	var elem_b: String = str(DragonData.DRAGONS.get(_selected_b, {}).get("element", "fire"))
	var result_element := _fuse_elements(elem_a, elem_b)
	var stability := _get_stability(elem_a, elem_b)

	preview_element.text = "Element: %s" % result_element.to_upper()
	preview_stability.text = "Stability: %s" % stability.to_upper()
	preview_stability.add_theme_color_override("font_color", STABILITY_COLORS.get(stability, Color.WHITE))

	var level_a: int = DragonProgression.get_dragon_level(_save, _selected_a)
	var level_b: int = DragonProgression.get_dragon_level(_save, _selected_b)
	var def_a: Dictionary = DragonData.DRAGONS.get(_selected_a, {})
	var def_b: Dictionary = DragonData.DRAGONS.get(_selected_b, {})
	if def_a.is_empty() or def_b.is_empty():
		preview_stats.text = ""
	else:
		var stats_a := DragonData.calculate_stats(def_a.get("base_stats", {}), level_a)
		var stats_b := DragonData.calculate_stats(def_b.get("base_stats", {}), level_b)
		var result_level: int = maxi(1, (level_a + level_b) / 2)
		var penalty: float = 0.85 if stability == "unstable" else 1.0
		var result_hp := floori((stats_a["hp"] + stats_b["hp"]) * 0.6 * penalty)
		var result_atk := floori((stats_a["atk"] + stats_b["atk"]) * 0.6 * penalty)
		var result_def := floori((stats_a["def"] + stats_b["def"]) * 0.6 * penalty)
		var result_spd := floori((stats_a["spd"] + stats_b["spd"]) * 0.6 * penalty)
		preview_stats.text = "HP:%d  ATK:%d  DEF:%d  SPD:%d  LV:%d" % [
			result_hp, result_atk, result_def, result_spd, result_level
		]

	var can_afford: bool = int(_save.get("data_scraps", 0)) >= FUSE_COST
	fuse_button.visible = true
	fuse_button.disabled = not can_afford

func _fuse_elements(a: String, b: String) -> String:
	var key := _pair_key(a, b)
	return FUSION_TABLE.get(key, a)

func _get_stability(a: String, b: String) -> String:
	if a == b:
		return "unstable"
	var key := _pair_key(a, b)
	if UNSTABLE_PAIRS.has(key):
		return "unstable"
	return "stable"

func _pair_key(a: String, b: String) -> String:
	var pair := [a, b]
	pair.sort()
	return "%s+%s" % [pair[0], pair[1]]

func _on_fuse_pressed() -> void:
	if _selected_a == "" or _selected_b == "" or _selected_a == _selected_b:
		return
	if int(_save.get("data_scraps", 0)) < FUSE_COST:
		return

	_save["data_scraps"] = int(_save["data_scraps"]) - FUSE_COST

	var elem_a: String = str(DragonData.DRAGONS.get(_selected_a, {}).get("element", "fire"))
	var elem_b: String = str(DragonData.DRAGONS.get(_selected_b, {}).get("element", "fire"))
	var result_element := _fuse_elements(elem_a, elem_b)
	var stability := _get_stability(elem_a, elem_b)

	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", []).duplicate()
	owned.erase(_selected_a)
	owned.erase(_selected_b)

	var result_id := result_element
	if not DragonData.DRAGONS.has(result_id):
		result_id = DragonData.DRAGONS.keys()[0]
	if not owned.has(result_id):
		owned.append(result_id)

	var level_a: int = DragonProgression.get_dragon_level(_save, _selected_a)
	var level_b: int = DragonProgression.get_dragon_level(_save, _selected_b)
	var result_level: int = maxi(1, (level_a + level_b) / 2)
	if not _save.has("dragon_levels"):
		_save["dragon_levels"] = {}
	_save["dragon_levels"][result_id] = result_level
	if not _save.has("dragon_xp"):
		_save["dragon_xp"] = {}
	_save["dragon_xp"][result_id] = 0

	hatchery_state["owned_dragons"] = owned
	_save["hatchery_state"] = hatchery_state

	_write_save()
	await _play_fusion_animation(_selected_a, _selected_b, result_id, stability)

	_selected_a = ""
	_selected_b = ""
	_refresh()

func _play_fusion_animation(_id_a: String, _id_b: String, result_id: String, stability: String) -> void:
	fusion_overlay.visible = true
	fusion_label.text = "FUSING..."
	var tween := create_tween()
	tween.tween_property(fusion_overlay, "modulate:a", 1.0, 0.0)
	tween.tween_interval(0.5)
	fusion_label.text = "MERGING PROTOCOLS..."
	tween.tween_interval(0.6)
	var def_result: Dictionary = DragonData.DRAGONS.get(result_id, {})
	var result_name: String = str(def_result.get("name", result_id))
	if stability == "unstable":
		fusion_label.text = "FUSION UNSTABLE\n%s EMERGES" % result_name
	else:
		fusion_label.text = "STABLE FUSION\n%s EMERGES" % result_name
	tween.tween_interval(0.8)
	tween.tween_property(fusion_overlay, "modulate:a", 0.0, 0.4)
	await tween.finished
	fusion_overlay.visible = false

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
