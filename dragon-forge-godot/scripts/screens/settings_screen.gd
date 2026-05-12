extends Control

signal navigate(target: String, payload: Variant)

const NAV_ENTRIES := [
	{"label": "HATCHERY", "target": "hatchery"},
	{"label": "BATTLE",   "target": "battleSelect"},
	{"label": "FUSION",   "target": "fusion"},
]

@onready var music_toggle: CheckButton = $VBoxContainer/SettingsBox/MusicRow/MusicToggle
@onready var sfx_toggle: CheckButton = $VBoxContainer/SettingsBox/SfxRow/SfxToggle
@onready var wipe_button: Button = $VBoxContainer/SettingsBox/WipeButton
@onready var confirm_row: HBoxContainer = $VBoxContainer/SettingsBox/ConfirmRow
@onready var nav_bar: Control = $VBoxContainer/NavBar

var _save: Dictionary = {}

func setup(save: Dictionary) -> void:
	_save = save.duplicate(true)

func _ready() -> void:
	nav_bar.navigate.connect(func(t): navigate.emit(t, null))
	nav_bar.setup(NAV_ENTRIES)
	confirm_row.visible = false

	music_toggle.button_pressed = bool(_save.get("settings_music", true))
	sfx_toggle.button_pressed = bool(_save.get("settings_sfx", true))

	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	wipe_button.pressed.connect(_on_wipe_pressed)

	var confirm_yes: Button = confirm_row.get_node_or_null("ConfirmYes")
	var confirm_no: Button = confirm_row.get_node_or_null("ConfirmNo")
	if confirm_yes != null:
		confirm_yes.pressed.connect(_on_wipe_confirmed)
	if confirm_no != null:
		confirm_no.pressed.connect(func(): confirm_row.visible = false)

func _on_music_toggled(pressed: bool) -> void:
	_save["settings_music"] = pressed
	_write_save()

func _on_sfx_toggled(pressed: bool) -> void:
	_save["settings_sfx"] = pressed
	_write_save()

func _on_wipe_pressed() -> void:
	confirm_row.visible = true

func _on_wipe_confirmed() -> void:
	var path := "user://dragon_forge_save.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	navigate.emit("title", null)

func _write_save() -> void:
	var main := get_tree().get_root().get_node_or_null("Main")
	if main != null and main.has_method("save_to_disk"):
		main.save_to_disk(_save)
