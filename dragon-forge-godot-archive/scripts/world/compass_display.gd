extends Control
class_name CompassDisplay

var player_position := Vector2i.ZERO
var husk_position := Vector2i(27, 8)
var waypoint := Vector2i(-1, -1)
var stability := 1.0
var packet_velocity := 0.0
var pulse := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(340, 92)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_navigation(next_player_position: Vector2i, next_husk_position: Vector2i, next_waypoint: Vector2i, next_stability: float, next_packet_velocity: float) -> void:
	player_position = next_player_position
	husk_position = next_husk_position
	waypoint = next_waypoint
	stability = clampf(next_stability, 0.0, 1.0)
	packet_velocity = clampf(next_packet_velocity, 0.0, 1.0)
	queue_redraw()

func _process(delta: float) -> void:
	pulse = fmod(pulse + delta * (1.6 + packet_velocity * 4.0), TAU)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(46, size.y * 0.5)
	var radius := 31.0
	var alpha := 0.28 + stability * 0.62
	draw_circle(center, radius + 3.0, Color("#071521", 0.86))
	draw_arc(center, radius, 0.0, TAU, 56, Color("#00ffff", alpha), 2.0)
	draw_arc(center, radius + 6.0, pulse, pulse + PI * 0.38, 16, Color("#fff05a", 0.35 + packet_velocity * 0.45), 3.0)
	_draw_vector(center, radius, husk_position, Color("#00ffff", 0.9), 3.0)
	if waypoint.x >= 0:
		_draw_vector(center, radius * 0.76, waypoint, Color("#fff05a", 0.95), 2.0)

	var font := get_theme_default_font()
	draw_string(font, Vector2(94, 30), "HUSK VECTOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#dfffff"))
	draw_string(font, Vector2(94, 50), "Stability %.0f%% | Packet Velocity %.0f%%" % [stability * 100.0, packet_velocity * 100.0], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#f4ead2"))
	var waypoint_text := "No waypoint" if waypoint.x < 0 else "Waypoint %d,%d" % [waypoint.x, waypoint.y]
	draw_string(font, Vector2(94, 70), waypoint_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("#fff05a" if waypoint.x >= 0 else "#8a8170"))

func _draw_vector(center: Vector2, radius: float, target: Vector2i, color: Color, width: float) -> void:
	var delta := Vector2(target - player_position)
	if delta.length() < 0.01:
		draw_circle(center, 5.0, color)
		return
	var direction := delta.normalized()
	var end := center + direction * radius
	draw_line(center, end, color, width)
	var side := Vector2(-direction.y, direction.x)
	var arrow := PackedVector2Array([
		end + direction * 7.0,
		end - direction * 5.0 + side * 5.0,
		end - direction * 5.0 - side * 5.0,
	])
	draw_polygon(arrow, PackedColorArray([color, color, color]))
