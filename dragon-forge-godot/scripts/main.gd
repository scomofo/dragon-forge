extends Control

const SAVE_PATH := "user://dragon_forge_save.json"
const DEFAULT_SAVE := {
	"dragon_id": "fire",
	"dragon_levels": { "fire": 1 },
	"dragon_xp": { "fire": 0 },
	"dragon_techniques": { "fire": ["magma_breath"] },
	"dragon_loadouts": { "fire": ["magma_breath"] },
	"data_scraps": 320,
	"system_credits": 0,
	"known_techniques": ["magma_breath"],
	"active_techniques": ["magma_breath"],
	"key_items": [],
	"mission_flags": [],
	"captains_log_fragments": [],
	"equipped_anvil_relics": [],
	"hatchery_state": {
		"opened": false,
		"owned_dragons": ["fire"],
		"visit_count": 0,
		"last_ring": "",
		"pity_counter": 0,
	},
	"bestiary_seen": {},
	"bestiary_defeated": {},
	"singularity_defeated": [],
	"inventory": {},
	"stats": {},
	"records": {},
	"journal": { "claimedMilestones": [] },
	"settings_music": true,
	"settings_sfx": true,
}

const SCREENS := {
	"title":        "res://scenes/screens/title_screen.tscn",
	"hatchery":     "res://scenes/screens/hatchery_screen.tscn",
	"battleSelect": "res://scenes/screens/battle_select_screen.tscn",
	"battle":       "res://scenes/screens/battle_screen.tscn",
	"fusion":       "res://scenes/screens/fusion_screen.tscn",
	"shop":         "res://scenes/screens/shop_screen.tscn",
	"forge":        "res://scenes/screens/forge_screen.tscn",
	"journal":      "res://scenes/screens/journal_screen.tscn",
	"stats":        "res://scenes/screens/stats_screen.tscn",
	"settings":     "res://scenes/screens/settings_screen.tscn",
	"singularity":  "res://scenes/screens/singularity_screen.tscn",
	"campaignMap":  "res://scenes/screens/campaign_map_screen.tscn",
}

const SCREEN_MUSIC := {
	"title":        "title",
	"hatchery":     "hatchery",
	"battleSelect": "select",
	"battle":       "battle_tense",
	"fusion":       "hatchery",
	"shop":         "hatchery",
	"forge":        "hatchery",
	"journal":      "hatchery",
	"stats":        "hatchery",
	"settings":     "hatchery",
	"singularity":  "battle_tense",
	"campaignMap":  "select",
}

@onready var fade_overlay: ColorRect = $FadeOverlay

var save: Dictionary = {}
var battle_config: Dictionary = {}
var _current_screen: Control = null
var _current_screen_id: String = ""
var _transitioning: bool = false

func _ready() -> void:
	save = _load_save()
	_switch_screen("title")

func _switch_screen(target: String, payload: Variant = null) -> void:
	if _transitioning:
		return
	if not SCREENS.has(target):
		push_error("Unknown screen target: %s" % target)
		return

	_transitioning = true

	var tween_out := create_tween()
	tween_out.tween_property(fade_overlay, "modulate:a", 1.0, 0.2)
	await tween_out.finished

	if _current_screen != null:
		_current_screen.queue_free()
		_current_screen = null

	_play_music(SCREEN_MUSIC.get(target, ""))
	_play_sfx("nav_switch")

	if target == "battle" and payload is Dictionary:
		battle_config = payload.duplicate(true)

	var packed: PackedScene = load(SCREENS[target])
	var screen: Control = packed.instantiate()
	screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	move_child(fade_overlay, get_child_count() - 1)
	_current_screen = screen
	_current_screen_id = target

	if screen.has_signal("navigate"):
		screen.navigate.connect(_on_screen_navigate)

	if screen.has_method("setup"):
		if target == "battle":
			screen.setup(save, battle_config)
		else:
			screen.setup(save)

	var tween_in := create_tween()
	tween_in.tween_property(fade_overlay, "modulate:a", 0.0, 0.2)
	await tween_in.finished

	_transitioning = false

func _on_screen_navigate(target: String, payload: Variant = null) -> void:
	save = _load_save()
	_switch_screen(target, payload)

func save_to_disk(updated_save: Dictionary) -> void:
	save = updated_save.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot open save file for writing.")
		return
	file.store_string(JSON.stringify(save, "\t"))
	file.close()

func _load_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return DEFAULT_SAVE.duplicate(true)
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_SAVE.duplicate(true)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return DEFAULT_SAVE.duplicate(true)
	var result := DEFAULT_SAVE.duplicate(true)
	for key in parsed:
		result[key] = parsed[key]
	return result

func _play_music(track: String) -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and track != "":
		director.play_music_context(track)

func _play_sfx(sfx_id: String) -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null:
		var sfx_data_class = load("res://scripts/sim/sfx_data.gd")
		if sfx_data_class != null:
			var profile: Dictionary = sfx_data_class.get_sfx_profile(sfx_id)
			if not profile.is_empty():
				director.play_sfx_profile(profile)
