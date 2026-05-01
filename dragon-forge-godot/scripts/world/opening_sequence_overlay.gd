extends Control

signal completed(profile: Dictionary)

const DragonProgression := preload("res://scripts/sim/dragon_progression.gd")
const SfxData := preload("res://scripts/sim/sfx_data.gd")
const StoryData := preload("res://scripts/sim/story_data.gd")

var profile := {}
var sequence_profile := {}
var pages: Array[Dictionary] = []
var page_index := 0
var current_audio_profile := {}
var panel: PanelContainer
var title_label: Label
var speaker_label: Label
var body_label: Label
var prompt_label: Label
var progress_bar: ProgressBar

func _ready() -> void:
	_build_ui()
	visible = false

func should_show_for_profile(next_profile: Dictionary) -> bool:
	return not DragonProgression.has_mission_flag(next_profile, "opening_sequence_seen")

func is_sequence_active() -> bool:
	return visible and not pages.is_empty()

func get_sequence_profile_for_test() -> Dictionary:
	return StoryData.opening_sequence_profile()

func get_audio_profile_for_test(tone: String) -> Dictionary:
	return SfxData.get_opening_sequence_audio_profile(tone)

func get_current_audio_profile_for_test() -> Dictionary:
	return current_audio_profile.duplicate(true)

func start(next_profile: Dictionary) -> void:
	profile = next_profile.duplicate(true)
	sequence_profile = StoryData.opening_sequence_profile()
	pages = _build_pages(sequence_profile)
	page_index = 0
	visible = true
	_render_page()

func advance() -> bool:
	if not is_sequence_active():
		return false
	if page_index < pages.size() - 1:
		page_index += 1
		_render_page()
		return true
	visible = false
	var next_profile := DragonProgression.set_mission_flag(profile, "opening_sequence_seen")
	completed.emit(next_profile)
	return true

func _unhandled_input(event: InputEvent) -> void:
	if not is_sequence_active() or not event.is_pressed():
		return
	if event.is_action_pressed("confirm") or event.is_action_pressed("cancel"):
		advance()
		accept_event()

func _build_pages(source: Dictionary) -> Array[Dictionary]:
	var next_pages: Array[Dictionary] = []
	for line in source.get("boot_lines", []):
		next_pages.append({
			"speaker": "ASTRAEUS",
			"body": str(line),
			"tone": "system",
		})
	next_pages.append({
		"speaker": "SYSTEM WARNING",
		"body": str(source.get("stakes", "")),
		"tone": "warning",
	})
	for line in source.get("felix_lines", []):
		next_pages.append({
			"speaker": "FELIX",
			"body": str(line),
			"tone": "mentor",
		})
	next_pages.append({
		"speaker": "SKYE",
		"body": str(source.get("first_objective", "")),
		"tone": "objective",
	})
	return next_pages

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90

	var veil := ColorRect.new()
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0.015, 0.02, 0.026, 0.94)
	add_child(veil)

	panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 360)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -360
	panel.offset_top = -190
	panel.offset_right = 360
	panel.offset_bottom = 190
	add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(title_label)

	speaker_label = Label.new()
	speaker_label.add_theme_font_size_override("font_size", 16)
	speaker_label.add_theme_color_override("font_color", Color("#8fe6ff"))
	box.add_child(speaker_label)

	body_label = Label.new()
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.add_theme_font_size_override("font_size", 22)
	box.add_child(body_label)

	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.min_value = 0
	progress_bar.max_value = 1
	progress_bar.custom_minimum_size = Vector2(0, 10)
	box.add_child(progress_bar)

	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", 14)
	prompt_label.add_theme_color_override("font_color", Color("#ffd166"))
	box.add_child(prompt_label)

func _render_page() -> void:
	if pages.is_empty():
		return
	var page: Dictionary = pages[page_index]
	current_audio_profile = SfxData.get_opening_sequence_audio_profile(str(page.get("tone", "system")))
	_play_audio_cue(str(page.get("tone", "system")))
	title_label.text = "%s\n%s" % [
		str(sequence_profile.get("title", "ASTRAEUS EMERGENCY WAKE")),
		str(sequence_profile.get("subtitle", "Operator signal recovered")),
	]
	speaker_label.text = str(page.get("speaker", "SYSTEM"))
	if page.get("tone", "system") == "warning":
		speaker_label.add_theme_color_override("font_color", Color("#ff594d"))
	elif page.get("tone", "system") == "objective":
		speaker_label.add_theme_color_override("font_color", Color("#ffd166"))
	elif page.get("tone", "system") == "mentor":
		speaker_label.add_theme_color_override("font_color", Color("#70ff8f"))
	else:
		speaker_label.add_theme_color_override("font_color", Color("#8fe6ff"))
	body_label.text = str(page.get("body", ""))
	progress_bar.max_value = maxi(1, pages.size())
	progress_bar.value = page_index + 1
	prompt_label.text = "SPACE/ENTER advances  %02d/%02d" % [page_index + 1, pages.size()]

func _play_audio_cue(tone: String) -> void:
	var director := get_node_or_null("/root/AudioDirector")
	if director != null and director.has_method("play_opening_sequence_cue"):
		current_audio_profile = director.call("play_opening_sequence_cue", tone)
