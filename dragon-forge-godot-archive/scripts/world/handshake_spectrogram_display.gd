extends Control
class_name HandshakeSpectrogramDisplay

const LED_ORDER := ["E4", "G4", "A4", "C4", "D4"]
const NOTE_COLORS := {
	"E4": Color("#FFFF00"),
	"G4": Color("#FF0000"),
	"A4": Color("#C0C0C0"),
	"C4": Color("#00FF00"),
	"D4": Color("#00FFFF"),
}
const NOTE_FREQS := {
	"E4": 329.63,
	"G4": 392.0,
	"A4": 440.0,
	"C4": 261.63,
	"D4": 293.66,
}

var prompt: Array[String] = []
var response: Array[String] = []
var purge_count := 0
var time := 0.0

func set_handshake(next_prompt: Array[String], next_response: Array[String], next_purge_count: int) -> void:
	prompt = next_prompt.duplicate()
	response = next_response.duplicate()
	purge_count = next_purge_count
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(340, 168)

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	draw_rect(rect, Color("#080b0d"))
	draw_rect(rect, Color("#3c474c"), false, 2.0)
	_draw_led_rack(rect)
	_draw_wave_stack(rect)
	_draw_response_slots(rect)
	if purge_count > 0:
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 14)), Color("#b31524", 0.45))

func _draw_led_rack(rect: Rect2) -> void:
	var start := rect.position + Vector2(16, 20)
	for i in LED_ORDER.size():
		var note: String = LED_ORDER[i]
		var lit := i < prompt.size()
		var active := response.size() == i
		var color: Color = NOTE_COLORS[note]
		var alpha := 0.35 + 0.45 * (sin(time * 3.0 + i) + 1.0) * 0.5 if lit else 0.12
		draw_circle(start + Vector2(0, i * 22), 7.0 + (2.0 if active else 0.0), Color(color, alpha))
		draw_string(get_theme_default_font(), start + Vector2(16, i * 22 + 5), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)

func _draw_wave_stack(rect: Rect2) -> void:
	var wave_rect := Rect2(rect.position + Vector2(82, 20), Vector2(rect.size.x - 102, 82))
	for i in prompt.size():
		var note: String = prompt[i]
		var y_offset := wave_rect.position.y + 8 + i * 15
		_draw_wave(wave_rect.position.x, y_offset, wave_rect.size.x, NOTE_FREQS[note], NOTE_COLORS[note], 0.85 if i < response.size() else 0.45)

func _draw_response_slots(rect: Rect2) -> void:
	var y := rect.end.y - 34
	var x0 := rect.position.x + 18
	for i in LED_ORDER.size():
		var note: String = response[i] if i < response.size() else ""
		var color: Color = NOTE_COLORS.get(note, Color("#2c3438"))
		var slot := Rect2(x0 + i * 58, y, 44, 20)
		draw_rect(slot, Color(color, 0.65 if note != "" else 0.22))
		draw_rect(slot, Color("#e8f2ef", 0.5), false, 1.0)
		if note != "":
			draw_string(get_theme_default_font(), slot.position + Vector2(9, 15), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#050505"))

func _draw_wave(x: float, y: float, width: float, frequency: float, color: Color, alpha: float) -> void:
	var points := PackedVector2Array()
	var cycles := frequency / 180.0
	for i in 64:
		var t := float(i) / 63.0
		points.append(Vector2(x + t * width, y + sin(t * TAU * cycles + time * 1.7) * 5.0))
	draw_polyline(points, Color(color, alpha), 1.8)
