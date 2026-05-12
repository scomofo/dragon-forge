extends Control

signal navigate(target: String, payload: Variant)

const LoreCanon = preload("res://scripts/sim/lore_canon.gd")

const FELIX_FIRST_CONTACT := [
	"Professor Felix: \"You're awake. Finally.\"",
	"Felix: \"The rendered world is fragmenting. Mirror Admin is pushing a Great Reset.\"",
	"Felix: \"Your dragons — the guardian protocols — are dormant. We need them back online.\"",
	"Felix: \"Ready when you are, Skye.\"",
]
const BOOT_DELAY := 0.45
const FELIX_DELAY := 0.6

@onready var boot_terminal: RichTextLabel = $VBoxContainer/BootTerminal
@onready var felix_label: Label = $VBoxContainer/FelixLabel
@onready var start_button: Button = $VBoxContainer/StartButton

var _boot_lines: Array = LoreCanon.OPENING_BOOT_LINES
var _boot_index: int = 0
var _felix_index: int = 0

func _ready() -> void:
	boot_terminal.text = ""
	felix_label.visible = false
	start_button.visible = false
	start_button.pressed.connect(_on_start_pressed)
	_show_next_boot_line()

func _show_next_boot_line() -> void:
	if _boot_index >= _boot_lines.size():
		await get_tree().create_timer(0.6).timeout
		_show_felix_lines()
		return
	boot_terminal.append_text(_boot_lines[_boot_index] + "\n")
	_boot_index += 1
	await get_tree().create_timer(BOOT_DELAY).timeout
	_show_next_boot_line()

func _show_felix_lines() -> void:
	felix_label.visible = true
	if _felix_index >= FELIX_FIRST_CONTACT.size():
		start_button.visible = true
		return
	felix_label.text = FELIX_FIRST_CONTACT[_felix_index]
	_felix_index += 1
	await get_tree().create_timer(FELIX_DELAY).timeout
	_show_felix_lines()

func _on_start_pressed() -> void:
	navigate.emit("hatchery", null)

func setup(_save: Dictionary) -> void:
	pass
