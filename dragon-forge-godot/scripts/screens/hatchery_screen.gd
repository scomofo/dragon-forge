extends Control

signal navigate(target: String, payload: Variant)

const DragonProgression = preload("res://scripts/sim/dragon_progression.gd")
const DragonData = preload("res://scripts/sim/dragon_data.gd")
const NavBarScene = preload("res://scenes/components/nav_bar.tscn")
const DragonSpriteScene = preload("res://scenes/components/dragon_sprite.tscn")

const PULL_COST := 50
const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
]

@onready var scraps_label: Label = $VBoxContainer/ScrapsLabel
@onready var dragon_grid: GridContainer = $VBoxContainer/DragonGrid
@onready var pull_button: Button = $VBoxContainer/ButtonRow/PullButton
@onready var singularity_button: Button = $VBoxContainer/ButtonRow/SingularityButton
@onready var egg_overlay: Control = $EggOverlay
@onready var egg_label: Label = $EggOverlay/OverlayVBox/EggLabel
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)
	_refresh()

func _ready() -> void:
	pull_button.pressed.connect(_on_pull_pressed)
	singularity_button.pressed.connect(func(): navigate.emit("singularity", null))
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	egg_overlay.visible = false

func _refresh() -> void:
	var scraps: int = int(_save.get("data_scraps", 0))
	scraps_label.text = "DATA SCRAPS: %d" % scraps
	pull_button.disabled = scraps < PULL_COST
	var sing_defeated: Array = _save.get("singularity_defeated", [])
	singularity_button.visible = sing_defeated.size() >= 1
	_rebuild_dragon_grid()

func _rebuild_dragon_grid() -> void:
	for child in dragon_grid.get_children():
		child.queue_free()
	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", [])
	var levels: Dictionary = _save.get("dragon_levels", {})
	var xp_dict: Dictionary = _save.get("dragon_xp", {})
	for dragon_id in owned:
		var card := _make_dragon_card(dragon_id, levels, xp_dict)
		dragon_grid.add_child(card)

func _make_dragon_card(dragon_id: String, levels: Dictionary, xp_dict: Dictionary) -> Control:
	var card := VBoxContainer.new()
	card.custom_minimum_size = Vector2(100, 120)

	var sprite_inst: Control = DragonSpriteScene.instantiate()
	card.add_child(sprite_inst)
	var level: int = int(levels.get(dragon_id, 1))
	sprite_inst.set_dragon(dragon_id, DragonData.get_stage_for_level(level))
	sprite_inst.custom_minimum_size = Vector2(80, 80)

	var name_label := Label.new()
	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
	name_label.text = str(dragon_def.get("name", dragon_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	card.add_child(name_label)

	var level_label := Label.new()
	level_label.text = "LV %d" % level
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 10)
	card.add_child(level_label)

	var xp: int = int(xp_dict.get(dragon_id, 0))
	var xp_next: int = DragonProgression.xp_to_next_level(level)
	var xp_bar := ProgressBar.new()
	xp_bar.value = float(xp) / float(xp_next) * 100.0
	xp_bar.custom_minimum_size = Vector2(90, 8)
	xp_bar.show_percentage = false
	card.add_child(xp_bar)

	return card

func _on_pull_pressed() -> void:
	var scraps: int = int(_save.get("data_scraps", 0))
	if scraps < PULL_COST:
		return
	_save["data_scraps"] = scraps - PULL_COST

	var hatchery_state: Dictionary = DragonProgression.get_hatchery_state(_save)
	var owned: Array = hatchery_state.get("owned_dragons", []).duplicate()
	var all_ids: Array = DragonData.DRAGONS.keys()
	var candidates: Array = []
	for id in all_ids:
		if not owned.has(id):
			candidates.append(id)

	var new_id: String
	if candidates.is_empty():
		_save["data_scraps"] = int(_save["data_scraps"]) + 25
		_write_save()
		_refresh()
		return
	else:
		candidates.shuffle()
		new_id = candidates[0]

	_save = DragonProgression.open_hatchery_ring(_save)
	var state: Dictionary = _save.get("hatchery_state", {}).duplicate(true)
	if not state.get("owned_dragons", []).has(new_id):
		state["owned_dragons"].append(new_id)
	if not _save.get("dragon_levels", {}).has(new_id):
		_save["dragon_levels"][new_id] = 1
	if not _save.get("dragon_xp", {}).has(new_id):
		_save["dragon_xp"][new_id] = 0
	_save["hatchery_state"] = state

	_write_save()
	await _play_hatch_animation(new_id)
	_refresh()

func _play_hatch_animation(dragon_id: String) -> void:
	egg_overlay.visible = true
	egg_label.text = "HATCHING..."
	var tween := create_tween()
	tween.tween_property(egg_overlay, "modulate:a", 1.0, 0.0)
	tween.tween_interval(0.3)
	for _i in range(6):
		tween.tween_property(egg_overlay, "position:x", 8.0, 0.04)
		tween.tween_property(egg_overlay, "position:x", -8.0, 0.04)
	tween.tween_property(egg_overlay, "position:x", 0.0, 0.04)
	tween.tween_interval(0.3)
	var dragon_def: Dictionary = DragonData.DRAGONS.get(dragon_id, {})
	egg_label.text = "NEW: %s" % str(dragon_def.get("name", dragon_id))
	tween.tween_interval(0.4)
	tween.tween_property(egg_overlay, "modulate:a", 0.0, 0.3)
	await tween.finished
	egg_overlay.visible = false
	egg_overlay.position = Vector2.ZERO

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
