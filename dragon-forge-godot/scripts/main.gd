extends Control


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
	"world":        "res://scenes/world/world.tscn",
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
	"world":        "hatchery",
}

@onready var fade_overlay: ColorRect = $FadeOverlay

var save: Dictionary = {}
var battle_config: Dictionary = {}
var _current_screen: Control = null
var _current_screen_id: String = ""
var _transitioning: bool = false

func _ready() -> void:
	save = SaveIO.save
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
	save = SaveIO.save
	_switch_screen(target, payload)


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
