extends Control

@onready var sprite_rect: TextureRect = $SpriteRect
@onready var fallback_label: Label = $FallbackLabel

const ELEMENT_COLORS := {
	"fire": Color("#ff6b35"),
	"ice": Color("#58dbff"),
	"storm": Color("#c3a6ff"),
	"stone": Color("#a0956a"),
	"venom": Color("#70ff8f"),
	"shadow": Color("#b084ff"),
}

var _manifest: Dictionary = {}

func _ready() -> void:
	_load_manifest()

func set_dragon(dragon_id: String, stage: int = 1) -> void:
	var path: String = _resolve_path(dragon_id, stage)
	if path != "" and ResourceLoader.exists(path):
		sprite_rect.texture = load(path)
		sprite_rect.visible = true
		fallback_label.visible = false
	else:
		sprite_rect.visible = false
		fallback_label.text = dragon_id.substr(0, 1).to_upper()
		fallback_label.add_theme_color_override("font_color",
			ELEMENT_COLORS.get(dragon_id, Color.WHITE))
		fallback_label.visible = true

func _load_manifest() -> void:
	const MANIFEST_PATH := "res://data/sprite_manifest.json"
	if not ResourceLoader.exists(MANIFEST_PATH):
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		_manifest = parsed

func _resolve_path(dragon_id: String, stage: int) -> String:
	var key := "%s_stage%d" % [dragon_id, stage]
	if _manifest.has(key):
		return str(_manifest[key])
	var fallback := "%s_stage1" % dragon_id
	if _manifest.has(fallback):
		return str(_manifest[fallback])
	return ""
