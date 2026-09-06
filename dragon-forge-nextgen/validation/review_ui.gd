extends RefCounted
## Tools-only UI; all materials and styles are local to each review scene.
static func panel(parent: Node, at: Vector2, width: float = 292.0) -> VBoxContainer:
	var box = PanelContainer.new()
	box.position = at
	box.custom_minimum_size.x = width
	var style = StyleBoxFlat.new()
	style.bg_color = Color("101d29")
	style.border_color = Color("44606c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	box.add_theme_stylebox_override("panel", style)
	parent.add_child(box)
	var rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 7)
	box.add_child(rows)
	return rows

static func text(parent: Node, words: String, size: int = 14) -> Label:
	var label = Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("e0e9ec"))
	parent.add_child(label)
	return label

static func button(parent: Node, words: String, action: Callable) -> Button:
	var node = Button.new()
	node.text = words
	node.custom_minimum_size.y = 29
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.pressed.connect(action)
	parent.add_child(node)
	return node

static func picker(parent: Node, items: Array, action: Callable) -> OptionButton:
	var node = OptionButton.new()
	node.fit_to_longest_item = false
	node.custom_minimum_size.y = 28
	for item in items:
		node.add_item(str(item))
	node.item_selected.connect(action)
	parent.add_child(node)
	return node

static func toggle(parent: Node, words: String, value: bool, action: Callable) -> CheckButton:
	var node = CheckButton.new()
	node.text = words
	node.button_pressed = value
	node.toggled.connect(action)
	parent.add_child(node)
	return node

static func row(parent: Node) -> HBoxContainer:
	var node = HBoxContainer.new()
	node.add_theme_constant_override("separation", 5)
	parent.add_child(node)
	return node
