extends PanelContainer

signal navigate(target: String)

var _entries: Array = []

func setup(entries: Array) -> void:
	_entries = entries
	_rebuild()

func _rebuild() -> void:
	var hbox := $HBoxContainer
	for child in hbox.get_children():
		child.queue_free()
	for entry in _entries:
		var btn := Button.new()
		btn.text = str(entry.get("label", ""))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var target := str(entry.get("target", ""))
		btn.pressed.connect(func(): navigate.emit(target))
		hbox.add_child(btn)
