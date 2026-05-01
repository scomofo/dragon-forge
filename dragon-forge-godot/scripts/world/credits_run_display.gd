extends PanelContainer
class_name CreditsRunDisplay

const RestorationData := preload("res://scripts/sim/restoration_data.gd")
const FLIGHT_SEGMENTS := [
	{"threshold": 0.0, "label": "Mainframe Crown", "altitude": "99 km"},
	{"threshold": 0.2, "label": "Legacy Peak", "altitude": "72 km"},
	{"threshold": 0.4, "label": "Logic Core", "altitude": "44 km"},
	{"threshold": 0.6, "label": "Tundra of Silicon", "altitude": "18 km"},
	{"threshold": 0.8, "label": "Southern Partition", "altitude": "3 km"},
	{"threshold": 1.0, "label": "New Landing", "altitude": "0 km"},
]

var _line_count := 0
var _progress := 0.0
var _box: VBoxContainer
var _credits_run: Dictionary = {}
var _presentation: Dictionary = {}
var _lines: Array = []
var _visible_line_count := 0
var _running := false
var _run_duration := 8.0

func _init() -> void:
	custom_minimum_size = Vector2(0, 150)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 5)
	add_child(_box)
	set_process(false)

func set_ending(credits_run: Dictionary, presentation: Dictionary) -> void:
	_credits_run = credits_run.duplicate(true)
	_presentation = presentation.duplicate(true)
	_progress = clampf(float(credits_run.get("rerender_progress", 0.0)), 0.0, 1.0)
	_lines = presentation.get("credits_lines", []).duplicate()
	_line_count = _lines.size()
	_visible_line_count = _line_count
	_running = false
	set_process(false)
	_render()

func start_run(choice: String, presentation: Dictionary) -> void:
	_credits_run = RestorationData.credits_run_state(choice, 0.0)
	_presentation = presentation.duplicate(true)
	_lines = presentation.get("credits_lines", []).duplicate()
	_line_count = _lines.size()
	_visible_line_count = 0
	_progress = 0.0
	_running = true
	set_process(true)
	_render()

func advance_for_test(delta: float) -> void:
	_advance(delta)

func get_visible_line_count() -> int:
	return _visible_line_count

func get_current_segment() -> String:
	return str(_current_segment().get("label", "Mainframe Crown"))

func get_camera_state() -> Dictionary:
	var zoom := lerpf(1.65, 0.85, _progress)
	var transition := "terminal_sky"
	if _progress >= 0.78:
		transition = "pastoral_settle"
	elif _progress >= 0.48:
		transition = "schematic_paintover"
	elif _progress >= 0.22:
		transition = "ascii_to_circuit"
	return {
		"zoom": zoom,
		"transition": transition,
		"shake": maxf(0.0, 0.35 - _progress * 0.35),
		"camera_lead": Vector2(0, lerpf(-80.0, 18.0, _progress)),
	}

func is_complete() -> bool:
	return _progress >= 1.0 and _visible_line_count == _line_count

func _process(delta: float) -> void:
	_advance(delta)

func _advance(delta: float) -> void:
	if not _running:
		return
	_progress = clampf(_progress + maxf(0.0, delta) / _run_duration, 0.0, 1.0)
	_credits_run = RestorationData.credits_run_state(str(_credits_run.get("choice", RestorationData.CHOICE_PATCH)), _progress)
	_visible_line_count = mini(_line_count, int(floor(_progress * float(_line_count))) + (1 if _progress > 0.0 else 0))
	if is_complete():
		_running = false
		set_process(false)
	_render()

func _render() -> void:
	_clear()
	var accent: Color = _presentation.get("accent_color", Color("#ffd56b"))

	var title := Label.new()
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", accent)
	title.text = "Zero-G Credits Run: %s" % _presentation.get("title", "Restoration")
	_box.add_child(title)

	var mode := Label.new()
	mode.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mode.text = "%s | %s | %.0f percent re-rendered" % [
		_credits_run.get("flight_mode", "ZERO_G_ROOT_AUTHORITY"),
		_credits_run.get("visual_shift", "hybrid_high_fidelity_paintover"),
		_progress * 100.0,
	]
	_box.add_child(mode)

	var segment := _current_segment()
	var camera := get_camera_state()
	var descent := Label.new()
	descent.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	descent.text = "Descent: %s | Altitude: %s | Camera %.2fx | %s" % [
		segment.get("label", "Mainframe Crown"),
		segment.get("altitude", "99 km"),
		float(camera.get("zoom", 1.0)),
		camera.get("transition", "terminal_sky"),
	]
	_box.add_child(descent)

	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = _progress
	_box.add_child(bar)

	for line in _lines.slice(0, _visible_line_count):
		var label := Label.new()
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = ">> %s" % str(line)
		_box.add_child(label)

func get_line_count() -> int:
	return _line_count

func get_progress() -> float:
	return _progress

func _current_segment() -> Dictionary:
	if _progress >= 1.0:
		return FLIGHT_SEGMENTS[FLIGHT_SEGMENTS.size() - 1]
	var selected: Dictionary = FLIGHT_SEGMENTS[0]
	for segment in FLIGHT_SEGMENTS:
		if _progress >= float(segment["threshold"]):
			selected = segment
	return selected

func _clear() -> void:
	if _box == null:
		return
	for child in _box.get_children():
		_box.remove_child(child)
		child.free()
