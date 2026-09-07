extends CanvasLayer
const Combat = preload("res://sim/combat.gd")
const Quality = preload("res://presentation/quality.gd")
var world
var objective: Label
var toast_label: Label
var stats: Label
var health: ProgressBar
var heat: ProgressBar
var health_text: Label
var heat_text: Label
var abilities: Array = []
var menu: Control
var resume_button: Button
var quality_select: OptionButton
var reduced_check: CheckBox
var confirmation: ConfirmationDialog
var toast_remaining = 0.0
var root: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Theme.new()
	root.theme.default_font_size = 17
	add_child(root)
	var top = HBoxContainer.new()
	root.add_child(top)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 24
	top.offset_right = -24
	top.offset_top = 20
	top.add_theme_constant_override("separation", 16)
	var brand = _panel(top)
	brand.custom_minimum_size.x = 320
	var column = VBoxContainer.new()
	brand.add_child(column)
	_label(column, "DRAGON FORGE", 27, Color("ffd4a1"))
	_label(column, "NEXTGEN  /  OUTER GRID", 15, Color("73d6da"))
	stats = _label(column, "", 14, Color("a4b7c4"))
	var objective_panel = _panel(top)
	objective_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var objective_column = VBoxContainer.new()
	objective_panel.add_child(objective_column)
	_label(objective_column, "CURRENT OBJECTIVE", 13, Color("73d6da"))
	objective = _label(objective_column, "", 18)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var pause_button = _button(top, "MENU\nEsc / Start")
	pause_button.custom_minimum_size.x = 120
	pause_button.pressed.connect(func(): set_pause(true))
	toast_label = Label.new()
	root.add_child(toast_label)
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	toast_label.offset_top = 134
	toast_label.offset_left = 200
	toast_label.offset_right = -200
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_color_override("font_color", Color("ffdea8"))
	toast_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	toast_label.add_theme_constant_override("shadow_offset_x", 2)
	toast_label.add_theme_constant_override("shadow_offset_y", 2)
	var bottom = PanelContainer.new()
	root.add_child(bottom)
	_style(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 24
	bottom.offset_right = -24
	bottom.offset_top = -158
	bottom.offset_bottom = -20
	var bottom_column = VBoxContainer.new()
	bottom.add_child(bottom_column)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bottom_column.add_child(row)
	var vitals = VBoxContainer.new()
	vitals.custom_minimum_size.x = 260
	row.add_child(vitals)
	health_text = _label(vitals, "MAGMA", 16, Color("ffd4a1"))
	health = _bar(vitals, Color("82dcbb"), 120)
	heat_text = _label(vitals, "CORE HEAT", 14, Color("b5c4cf"))
	heat = _bar(vitals, Color("ff8750"), 100)
	for i in range(Combat.ORDER.size()):
		var id: String = Combat.ORDER[i]
		var button = _button(row, "")
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(175, 86)
		button.pressed.connect(func(): world.dragon.try_ability(id))
		abilities.append(button)
	_label(bottom_column, "MOVE  WASD / left stick    AIM  Mouse / right stick    DODGE  Space / A    GUARD  Shift / LT    INTERACT  E / B", 15, Color("b5c4cf"))
	_build_menu()

func _panel(parent: Node) -> PanelContainer:
	var panel = PanelContainer.new()
	parent.add_child(panel)
	_style(panel)
	return panel

func _style(panel: PanelContainer) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.05, 0.075, 0.94)
	style.border_color = Color("35515f")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

func _label(parent: Node, text: String, size: int = 17, color: Color = Color.WHITE) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func _button(parent: Node, text: String) -> Button:
	var node = Button.new()
	node.text = text
	parent.add_child(node)
	return node

func _bar(parent: Node, color: Color, maximum: float) -> ProgressBar:
	var node = ProgressBar.new()
	node.max_value = maximum
	node.show_percentage = false
	node.custom_minimum_size.y = 9
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	node.add_theme_stylebox_override("fill", fill)
	parent.add_child(node)
	return node

func _build_menu() -> void:
	menu = Control.new()
	root.add_child(menu)
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	shade.color = Color(0.0, 0.015, 0.03, 0.88)
	menu.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center = CenterContainer.new()
	menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel = _panel(center)
	panel.custom_minimum_size.x = 610
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	_label(column, "FORGE PAUSED", 30, Color("ffd4a1"))
	_label(column, "Simulation, cooldowns and enemy tells are paused.", 17)
	_label(column, "Graphics quality (renderer does not change at runtime)", 16, Color("a4b7c4"))
	quality_select = OptionButton.new()
	for title in Quality.NAMES:
		quality_select.add_item(title)
	quality_select.select(world.quality_index)
	quality_select.item_selected.connect(func(index): world.set_quality(index))
	column.add_child(quality_select)
	reduced_check = CheckBox.new()
	reduced_check.text = "Reduced motion / calmer effects"
	reduced_check.toggled.connect(func(enabled): world.set_reduced_motion(enabled))
	column.add_child(reduced_check)
	_label(column, "1 / X  Claw   2 / Y  Breath   3 / LB  Wall   4 / RB  Burst", 16)
	_label(column, "Avoid the marked impact. Attack while SHIELD OPEN.\nTwo breath hits overload a conduit and break nearby shields.", 16, Color("73d6da"))
	resume_button = _button(column, "Resume")
	resume_button.pressed.connect(func(): set_pause(false))
	_button(column, "Retry encounter - keep completed milestones").pressed.connect(_retry_pressed)
	_button(column, "Start a new expedition...").pressed.connect(func(): confirmation.popup_centered())
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Reset prototype progress?"
	confirmation.dialog_text = "Resets only this nextgen prototype's milestones.\nYour original Dragon Forge saves are not touched."
	confirmation.confirmed.connect(_reset_confirmed)
	add_child(confirmation)
	menu.visible = false

func _process(delta: float) -> void:
	if world == null or not is_instance_valid(world.dragon):
		return
	var state: Dictionary = world.dragon.state
	health.value = state.hp
	heat.value = state.heat
	health_text.text = "MAGMA  %d / %d" % [int(state.hp), int(state.max_hp)]
	heat_text.text = "CORE HEAT  %d / 100" % int(state.heat)
	objective.text = world.objective_text()
	stats.text = "%s | %d FPS | %d draws" % [world.quality_info.get("renderer", ""), int(Performance.get_monitor(Performance.TIME_FPS)), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
	if world.store.message != "":
		stats.text += "\nSAVE WARNING - session only"
	for i in range(abilities.size()):
		var id: String = Combat.ORDER[i]
		var cooldown: float = state.cooldowns.get(id, 0.0)
		var status = "%.1fs" % cooldown if cooldown > 0.0 else ("TOO HOT" if state.heat + Combat.ABILITIES[id].heat > 100.0 else "READY")
		abilities[i].text = "[%d] %s\n%s" % [i + 1, Combat.ABILITIES[id].name, status]
		abilities[i].disabled = not world.dragon.active or Combat.rejection(state, id) != "" or menu.visible
	if not menu.visible:
		toast_remaining = maxf(0.0, toast_remaining - delta)
	toast_label.visible = toast_remaining > 0.0

func toast(text: String) -> void:
	toast_label.text = text
	toast_remaining = 4.0

func set_pause(value: bool) -> void:
	menu.visible = value
	get_tree().paused = value
	if value:
		resume_button.grab_focus()
	else:
		world.dragon.input_grace = 0.2
		get_viewport().gui_release_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ng_menu") and not event.is_echo():
		if confirmation.visible:
			confirmation.hide()
		else:
			set_pause(not menu.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ng_retry") and world.dragon.state.hp <= 0.0 and not menu.visible:
		world.retry()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(menu) and not world.test_mode:
		set_pause.call_deferred(true)

func _retry_pressed() -> void:
	world.retry()
	set_pause(false)

func _reset_confirmed() -> void:
	world.new_expedition()
	set_pause(false)
