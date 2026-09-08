extends CanvasLayer
## Presentation reads simulation; all decisions go through the world's checked actions.
const Combat = preload("res://sim/combat.gd")
const Quality = preload("res://presentation/quality.gd")
const Modules = preload("res://sim/forge_modules.gd")
const GOLD = Color("f4c47c")
const TEAL = Color("76e0ca")
const MUTED = Color("b0bdc9")
const PAPER = Color("f4f1e8")
var world
var root: Control
var objective: Label
var objective_detail: Label
var objective_panel: PanelContainer
var route_text: Label
var step_label: Label
var steps: Array = []
var toast_label: Label
var toast_remaining = 0.0
var stats: Label
var health: ProgressBar
var heat: ProgressBar
var health_text: Label
var heat_text: Label
var module_text: Label
var defensive_text: Label
var abilities: Array = []
var menu: Control
var overlay: Control
var overlay_column: VBoxContainer
var overlay_kind = ""
var resume_button: Button
var quality_select: OptionButton
var reduced_check: CheckBox
var confirmation: ConfirmationDialog
var enemy_panel: PanelContainer
var enemy_readout: Label
var enemy_name: Label
var enemy_health: ProgressBar
var enemy_timer: ProgressBar
var prompt: Button
var top_row: HBoxContainer
var feedback_title: Label
var feedback_detail: Label
var feedback_remaining = 0.0
var debug_visible = false
var dead_presented = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = Theme.new()
	root.theme.default_font_size = 16
	add_child(root)
	top_row = HBoxContainer.new()
	root.add_child(top_row)
	_place(top_row, Control.PRESET_TOP_WIDE, 24, 18, -24, 56)
	top_row.add_theme_constant_override("separation", 18)
	_label(top_row, "DRAGON  /  FORGE", 23, GOLD)
	var brand = _label(top_row, "OUTER GRID   /   RECONNECTION", 13, MUTED)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	brand.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var pause_button = _button(top_row, "Pause   [Esc]")
	pause_button.pressed.connect(func(): set_pause(true))
	objective_panel = _panel(root)
	_place(objective_panel, Control.PRESET_TOP_LEFT, 24, 78, 304, 78)
	var column = _column(objective_panel, 8)
	step_label = _label(column, "RECONNECTION  /  01", 12, TEAL)
	objective = _label(column, "", 21, PAPER)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_detail = _label(column, "", 15, MUTED)
	objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var route = HBoxContainer.new()
	column.add_child(route)
	route.add_theme_constant_override("separation", 5)
	for i in range(6):
		var pip = ColorRect.new()
		pip.custom_minimum_size = Vector2(34, 3)
		pip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		route.add_child(pip)
		steps.append(pip)
	route_text = _label(column, "", 13, GOLD)
	route_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_build_enemy()
	feedback_title = _label(root, "", 25, TEAL)
	_place(feedback_title, Control.PRESET_TOP_WIDE, 320, 186, -180, 220)
	feedback_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shadow(feedback_title)
	feedback_detail = _label(root, "", 14, PAPER)
	_place(feedback_detail, Control.PRESET_TOP_WIDE, 320, 218, -180, 245)
	feedback_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shadow(feedback_detail)
	toast_label = _label(root, "", 16, GOLD)
	_place(toast_label, Control.PRESET_BOTTOM_WIDE, 320, -241, -40, -205)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_shadow(toast_label)
	prompt = _button(root, "")
	_place(prompt, Control.PRESET_CENTER_BOTTOM, -180, -182, 180, -140)
	prompt.pressed.connect(func(): world.interact())
	prompt.focus_mode = Control.FOCUS_NONE
	_build_vitals()
	_build_abilities()
	var controls = _label(root, "WASD  Move     Mouse  Aim     Space  Dodge     Shift  Guard     E  Interact", 13, MUTED)
	_place(controls, Control.PRESET_BOTTOM_WIDE, 28, -30, -28, -8)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats = _label(root, "", 13, MUTED)
	_place(stats, Control.PRESET_TOP_RIGHT, -335, 62, -24, 82)
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_build_menu()
	overlay = _shade()
	var center = CenterContainer.new()
	overlay.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var modal_panel = _panel(center)
	modal_panel.custom_minimum_size.x = 1050
	overlay_column = _column(modal_panel, 16)
	overlay.visible = false

func _build_enemy() -> void:
	enemy_panel = _panel(root)
	_place(enemy_panel, Control.PRESET_TOP_WIDE, 326, 78, -238, 78)
	var col = _column(enemy_panel, 6)
	enemy_name = _label(col, "", 17, PAPER)
	enemy_health = _bar(col, GOLD, 100, 7)
	enemy_readout = _label(col, "", 14, TEAL)
	enemy_timer = _bar(col, TEAL, 1.0, 3)
	enemy_panel.visible = false

func _build_vitals() -> void:
	var panel = _panel(root)
	_place(panel, Control.PRESET_BOTTOM_LEFT, 24, -129, 304, -39)
	var col = _column(panel, 3)
	health_text = _label(col, "MAGMA", 16, PAPER)
	health = _bar(col, TEAL, 120, 6)
	heat_text = _label(col, "", 12, GOLD)
	heat = _bar(col, Color("e99156"), 100, 4)
	module_text = _label(col, "", 12, MUTED)
	defensive_text = _label(root, "", 13, PAPER)
	_place(defensive_text, Control.PRESET_BOTTOM_LEFT, 28, -155, 304, -133)

func _build_abilities() -> void:
	var row = HBoxContainer.new()
	root.add_child(row)
	_place(row, Control.PRESET_BOTTOM_WIDE, 320, -129, -24, -39)
	row.add_theme_constant_override("separation", 10)
	for i in range(Combat.ORDER.size()):
		var id: String = Combat.ORDER[i]
		var button = _button(row, "")
		button.custom_minimum_size = Vector2(184, 90)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func(): world.dragon.try_ability(id))
		var content = VBoxContainer.new()
		button.add_child(content)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_place(content, Control.PRESET_FULL_RECT, 14, 9, -14, -9)
		content.add_theme_constant_override("separation", 4)
		var label = _label(content, str(i + 1) + "   " + Combat.ABILITIES[id].name, 16, PAPER)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var status = _label(content, "", 13, TEAL)
		var charge = _bar(content, GOLD, 1.0, 3)
		charge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cost = _label(content, "", 12, MUTED)
		abilities.append({"button": button, "status": status, "charge": charge, "cost": cost})

func _process(delta: float) -> void:
	if world == null or not is_instance_valid(world.dragon):
		return
	var state: Dictionary = world.dragon.state
	var info: Dictionary = world.guidance()
	objective.text = info.title
	objective_detail.text = info.detail
	step_label.text = "RECONNECTION  /  %02d" % (int(info.index) + 1)
	for i in range(steps.size()):
		steps[i].color = GOLD if i == info.index else (TEAL if i < info.index else Color("34434d"))
	var distance = Vector2(info.target.x - world.dragon.position.x, info.target.z - world.dragon.position.z).length()
	route_text.text = "%s   /   %dm" % [info.marker, int(distance)] if info.marker != "" else "%d / 3 RELAYS CLEARED" % int(world.progress.clears)
	if not world.progress.gate_open and world.progress.hatched:
		route_text.text = "RELAY CHARGE   %d / 60" % int(world.conduits[0].sim.heat)
		if world.conduits[0].sim.heat > 0.0:
			objective_detail.text = "Good. Let Breath recharge, then hit the relay again before it cools."
	health.max_value = state.max_hp
	health.value = state.hp
	heat.value = state.heat
	health_text.text = "MAGMA                         %d / %d" % [int(state.hp), int(state.max_hp)]
	heat_text.text = "CORE HEAT    %d / 100" % int(state.heat)
	module_text.text = Modules.profile(world.progress.module).name.to_upper() + (" / TESTED" if world.progress.trial_cleared else "")
	defensive_text.text = "GUARD ACTIVE" if state.guard else ("DODGE  %.1fs" % state.dodge_cd if state.dodge_cd > 0.0 else ("DODGE LOCKED  /  COOL CORE" if state.heat > 90.0 else "SPACE  Dodge ready     SHIFT  Guard"))
	if not world.dragon.active:
		health_text.text = "MAGMA  /  DORMANT"
		heat_text.text = "AWAITING A SPARK"
		module_text.text = "AWAKEN AT THE HATCHERY"
		defensive_text.text = ""
	_update_enemy()
	stats.visible = debug_visible or world.store.message != "" or world.preferences.message != ""
	stats.text = "%s  /  %d FPS  /  %d draws" % [world.quality_info.get("renderer", ""), int(Performance.get_monitor(Performance.TIME_FPS)), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))]
	if world.store.message != "":
		stats.text = "SAVE WARNING  /  Session only"
	elif world.preferences.message != "":
		stats.text = "SETTINGS WARNING  /  Session only"
	for i in range(abilities.size()):
		var id: String = Combat.ORDER[i]
		var card: Dictionary = abilities[i]
		var cooldown: float = state.cooldowns.get(id, 0.0)
		var hot = state.heat + Combat.heat_cost(state, id) > 100.0
		card.status.text = "COOLING  %.1fs" % cooldown if cooldown > 0.0 else ("TOO HOT" if hot else "READY")
		card.status.modulate = GOLD if hot or cooldown > 0.0 else TEAL
		if not world.dragon.active:
			card.status.text = "AWAITING HATCH"
			card.status.modulate = MUTED
		if state.action == id:
			card.status.text = Combat.action_phase(state)
		card.charge.value = 1.0 - cooldown / float(Combat.ABILITIES[id].cooldown)
		card.cost.text = "%d damage  /  %d heat" % [int(Combat.technique_damage(state, id)), int(round(Combat.heat_cost(state, id)))]
		# Let near-ready clicks use the same bounded buffer as keyboard input.
		card.button.disabled = not world.dragon.active or state.hp <= 0.0 or menu.visible or overlay.visible
	var context: String = world.interaction()
	prompt.text = "[ E / B ]   " + context
	prompt.visible = context != "" and not menu.visible and not overlay.visible
	if not get_tree().paused:
		toast_remaining = maxf(0.0, toast_remaining - delta)
		feedback_remaining = maxf(0.0, feedback_remaining - delta)
	toast_label.visible = toast_remaining > 0.0 and not menu.visible and not overlay.visible
	feedback_title.visible = feedback_remaining > 0.0 and not menu.visible and not overlay.visible
	feedback_detail.visible = feedback_title.visible
	if state.hp > 0.0:
		dead_presented = false

func _update_enemy() -> void:
	enemy_panel.visible = is_instance_valid(world.enemy)
	if not enemy_panel.visible:
		return
	var foe = world.enemy
	enemy_name.text = ("PACKET WARDEN" if foe.boss else "FIREWALL SENTINEL") + "     %d / %d" % [int(foe.hp), int(foe.max_hp)]
	enemy_health.max_value = foe.max_hp
	enemy_health.value = foe.hp
	var caption = "SHIELD CLOSED   /   Draw out its attack"
	var color = MUTED
	var fraction = 1.0
	if foe.brain.mode == "tell":
		caption = "IMPACT  %.1fs   /   DODGE OR GUARD" % foe.brain.timer
		color = GOLD
		fraction = foe.brain.timer / foe.brain.locked_duration
	elif foe.brain.vulnerable():
		caption = "SHIELD OPEN  %.1fs   /   COUNTER NOW" % foe.brain.timer
		color = TEAL
		fraction = foe.brain.timer / 2.4
	if foe.brain.enraged:
		caption = "OVERCLOCK  /  " + caption
	enemy_readout.text = caption
	enemy_readout.modulate = color
	enemy_timer.value = clampf(fraction, 0.0, 1.0)

func toast(text: String) -> void:
	toast_label.text = text
	toast_remaining = 4.5

func feedback(title: String, detail: String, color: Color = TEAL) -> void:
	feedback_title.text = title
	feedback_title.modulate = color
	feedback_detail.text = detail
	feedback_remaining = 1.3

func _build_menu() -> void:
	menu = _shade()
	var center = CenterContainer.new()
	menu.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel = _panel(center)
	panel.custom_minimum_size.x = 640
	var column = _column(panel, 12)
	_label(column, "TAKE A BREATH", 30, GOLD)
	_label(column, "The world waits. No attacks or cooldowns advance here.", 16, MUTED)
	_label(column, "GRAPHICS", 12, TEAL)
	quality_select = OptionButton.new()
	for title in Quality.NAMES:
		quality_select.add_item(title)
	quality_select.select(world.quality_index)
	quality_select.item_selected.connect(func(index): world.set_quality(index))
	column.add_child(quality_select)
	reduced_check = CheckBox.new()
	reduced_check.text = "Reduced motion / calmer effects"
	reduced_check.set_pressed_no_signal(world.reduced_motion)
	reduced_check.toggled.connect(func(enabled): world.set_reduced_motion(enabled))
	column.add_child(reduced_check)
	_label(column, "Quality and motion persist separately. Renderer changes require relaunch.", 14, MUTED)
	_label(column, "1 / X  Claw     2 / Y  Breath     3 / LB  Wall     4 / RB  Burst", 15, PAPER)
	_label(column, "Space / A  Dodge     Shift / LT  Guard     E / B  Interact", 15, PAPER)
	resume_button = _button(column, "Resume")
	resume_button.pressed.connect(func(): set_pause(false))
	_button(column, "Retry checkpoint  /  keep earned progress").pressed.connect(func(): world.retry())
	_button(column, "Return to the Forge").pressed.connect(func(): world.return_to_forge())
	_button(column, "Diagnostics  /  F3").pressed.connect(func(): debug_visible = not debug_visible)
	_button(column, "Reset prototype progress...").pressed.connect(func(): confirmation.popup_centered())
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Reset this prototype?"
	confirmation.dialog_text = "This clears this prototype's milestones, core choice and trial badge.\nOriginal Dragon Forge saves are untouched."
	confirmation.confirmed.connect(func(): world.new_expedition())
	add_child(confirmation)
	menu.visible = false

func show_modules() -> void:
	if not world.can_configure():
		return
	_open_overlay("modules")
	_label(overlay_column, "THE FORGE NEEDS A HEART", 30, GOLD)
	_label(overlay_column, "One recovered core. Three ways to shape your guardian.", 18, PAPER)
	_label(overlay_column, "Choose a module. You can change it here for free between field tests.", 15, MUTED)
	var row = HBoxContainer.new()
	overlay_column.add_child(row)
	row.add_theme_constant_override("separation", 14)
	var first: Button
	for id in Modules.ORDER:
		var data: Dictionary = Modules.DATA[id]
		var card = _panel(row)
		card.custom_minimum_size.x = 322
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var col = _column(card, 14)
		_label(col, data.tag, 12, data.color)
		_label(col, data.name, 23, PAPER)
		var body = _label(col, data.detail, 16, MUTED)
		body.custom_minimum_size = Vector2(276, 90)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label(col, data.stats, 15, data.color)
		var choice = _button(col, "Equipped" if world.progress.module == id else "Install " + data.name)
		choice.disabled = world.progress.module == id
		choice.pressed.connect(func(): world.choose_module(id))
		if first == null and not choice.disabled:
			first = choice
	var buttons = HBoxContainer.new()
	overlay_column.add_child(buttons)
	buttons.add_theme_constant_override("separation", 14)
	var test = _button(buttons, "Field test  /  face the Warden")
	test.disabled = world.progress.module == ""
	test.pressed.connect(func(): world.start_trial())
	_button(buttons, "Back to the Forge").pressed.connect(close_overlay)
	_label(overlay_column, "Field tests keep your progress. They award a completion badge, not extra cores.", 14, MUTED)
	if first != null:
		first.grab_focus()

func show_defeat() -> void:
	if not is_instance_valid(world.dragon) or world.dragon.state.hp > 0.0 or dead_presented:
		return
	dead_presented = true
	_open_overlay("defeat")
	_label(overlay_column, "REGROUP. NOT RESTART.", 32, GOLD)
	_label(overlay_column, "Your cleared relays and installed module are safe.", 19, PAPER)
	_label(overlay_column, "Bait the marked circle. Dodge out or hold guard. Attack during SHIELD OPEN.\nSave some heat for your dodge: it locks above 90 heat.", 18, MUTED)
	var retry_button = _button(overlay_column, "Retry checkpoint  [R]")
	retry_button.pressed.connect(func(): world.retry())
	_button(overlay_column, "Return to the Forge").pressed.connect(func(): world.return_to_forge())
	retry_button.grab_focus()

func show_trial_result() -> void:
	if world.trial_active or not world.progress.trial_cleared:
		return
	_open_overlay("result")
	_label(overlay_column, "FIELD TEST COMPLETE", 32, TEAL)
	_label(overlay_column, Modules.profile(world.progress.module).name + "  /  Warden defeated", 23, PAPER)
	_label(overlay_column, "Try a different build at the Forge.\nNo extra core was awarded; your original expedition remains complete.", 18, MUTED)
	_label(overlay_column, "FIELD-TEST BADGE EARNED" if world.store.message == "" else "SESSION ONLY  /  " + world.store.message, 14, MUTED)
	var back = _button(overlay_column, "Return to the Forge")
	back.pressed.connect(func(): world.return_to_forge())
	back.grab_focus()

func _open_overlay(kind: String) -> void:
	for child in overlay_column.get_children():
		overlay_column.remove_child(child)
		child.queue_free()
	overlay_kind = kind
	menu.visible = false
	overlay.visible = true
	world.dragon.buffered_id = ""
	world.dragon.buffer_time = 0.0
	get_tree().paused = true
	_focus_first_overlay_control.call_deferred()

func _focus_first_overlay_control() -> void:
	# Dynamic roster/recipe cards need one layout pass before follow-focus can
	# calculate the target rectangle inside their ScrollContainer.
	await get_tree().process_frame
	if not overlay.visible:
		return
	var first = _first_focusable(overlay_column)
	if first != null:
		first.grab_focus()
		var ancestor = first.get_parent()
		while ancestor != null and ancestor != overlay_column:
			if ancestor is ScrollContainer:
				ancestor.ensure_control_visible(first)
				break
			ancestor = ancestor.get_parent()

func _first_focusable(parent: Node) -> Control:
	for child in parent.get_children():
		var interactive = child is BaseButton or child is Range or child is LineEdit or child is TextEdit or child is ItemList or child is Tree
		if interactive and child.focus_mode != Control.FOCUS_NONE and child.is_visible_in_tree() and not (child is BaseButton and child.disabled):
			return child
		var nested = _first_focusable(child)
		if nested != null:
			return nested
	return null

func close_overlay() -> void:
	overlay.visible = false
	overlay_kind = ""
	menu.visible = false
	world.dragon.buffered_id = ""
	world.dragon.buffer_time = 0.0
	world.dragon.input_grace = 0.22
	get_tree().paused = false
	get_viewport().gui_release_focus()

func set_pause(value: bool) -> void:
	if value and overlay.visible:
		return
	if not value:
		close_overlay()
		return
	menu.visible = true
	world.dragon.buffered_id = ""
	world.dragon.buffer_time = 0.0
	quality_select.select(world.quality_index)
	reduced_check.set_pressed_no_signal(world.reduced_motion)
	get_tree().paused = true
	resume_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		debug_visible = not debug_visible
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ng_menu") and not event.is_echo():
		if confirmation.visible:
			confirmation.hide()
		elif overlay.visible:
			close_overlay()
		else:
			set_pause(not menu.visible)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ng_retry") and not event.is_echo() and world.dragon.state.hp <= 0.0:
		world.retry()
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(menu) and not world.test_mode:
		set_pause.call_deferred(true)

func _shade() -> Control:
	var node = Control.new()
	root.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = ColorRect.new()
	node.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.024, 0.035, 0.92)
	return node

func _panel(parent: Node) -> PanelContainer:
	var node = PanelContainer.new()
	parent.add_child(node)
	node.add_theme_stylebox_override("panel", _style(Color("0e1b26"), Color("374955")))
	return node

func _style(background: Color, border: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _column(parent: Node, gap: int) -> VBoxContainer:
	var node = VBoxContainer.new()
	parent.add_child(node)
	node.add_theme_constant_override("separation", gap)
	return node

func _label(parent: Node, text: String, size: int = 16, color: Color = PAPER) -> Label:
	var node = Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

func _button(parent: Node, text: String) -> Button:
	var node = Button.new()
	node.text = text
	node.custom_minimum_size.y = 38
	node.add_theme_stylebox_override("normal", _style(Color("132631"), Color("49616b")))
	node.add_theme_stylebox_override("hover", _style(Color("203541"), GOLD))
	node.add_theme_stylebox_override("pressed", _style(Color("2a4048"), TEAL))
	var focus = _style(Color(0, 0, 0, 0), GOLD)
	focus.set_border_width_all(2)
	node.add_theme_stylebox_override("focus", focus)
	node.add_theme_stylebox_override("disabled", _style(Color("10202a"), Color("2d404b")))
	node.add_theme_color_override("font_color", PAPER)
	node.add_theme_color_override("font_disabled_color", MUTED)
	parent.add_child(node)
	return node

func _bar(parent: Node, color: Color, maximum: float, thickness: float) -> ProgressBar:
	var node = ProgressBar.new()
	node.max_value = maximum
	node.step = 0.001
	node.show_percentage = false
	node.custom_minimum_size.y = thickness
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	node.add_theme_stylebox_override("fill", fill)
	var back = StyleBoxFlat.new()
	back.bg_color = Color("2b3c45")
	node.add_theme_stylebox_override("background", back)
	parent.add_child(node)
	return node

func _place(node: Control, preset: int, left: float, top: float, right: float, bottom: float) -> void:
	node.set_anchors_and_offsets_preset(preset)
	node.offset_left = left
	node.offset_top = top
	node.offset_right = right
	node.offset_bottom = bottom

func _shadow(label: Label) -> void:
	label.add_theme_color_override("font_shadow_color", Color("07141e"))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
