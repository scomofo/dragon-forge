extends Control
class_name RelayRouteDisplay

var progress_km := 0
var stamina := 100.0
var charge := 0.0
var pedal := 0.5
var has_tread := false

func set_route(next_progress_km: int, next_stamina: float, next_charge: float, next_pedal: float, next_has_tread: bool) -> void:
	progress_km = next_progress_km
	stamina = next_stamina
	charge = next_charge
	pedal = next_pedal
	has_tread = next_has_tread
	queue_redraw()

func _ready() -> void:
	custom_minimum_size = Vector2(320, 92)

func _draw() -> void:
	var rect := Rect2(Vector2(6, 8), size - Vector2(12, 18))
	draw_rect(rect, Color("#d7d2bf"))
	draw_line(Vector2(rect.position.x, rect.end.y - 18), Vector2(rect.end.x, rect.end.y - 18), Color("#787365"), 2.0)

	for i in 8:
		var x := rect.position.x + i * rect.size.x / 7.0
		draw_line(Vector2(x, rect.end.y - 18), Vector2(x + 18, rect.position.y + 18), Color("#b0aa98", 1.0), 1.0)

	var dragon_x := lerpf(rect.position.x + 12, rect.end.x - 26, clampf(progress_km / 50.0, 0.0, 1.0))
	var dragon_y := rect.end.y - 28 - sin(progress_km * 0.4) * 8.0
	draw_circle(Vector2(dragon_x, dragon_y), 11, Color("#b94d3e"))
	draw_polygon(PackedVector2Array([
		Vector2(dragon_x - 9, dragon_y),
		Vector2(dragon_x - 35, dragon_y + 8),
		Vector2(dragon_x - 10, dragon_y + 9),
	]), PackedColorArray([Color("#6f423c"), Color("#6f423c"), Color("#6f423c")]))

	var band_color := Color("#5f8f6d") if pedal > 0.4 and pedal < 0.6 else Color("#a85a4a")
	var tread_color := Color("#2e5740") if has_tread else Color("#7a6b4f")
	draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x * stamina / 100.0, 6), band_color)
	draw_rect(Rect2(rect.position.x, rect.position.y + 9, rect.size.x * charge / 100.0, 5), Color("#5c7aa8"))
	draw_circle(Vector2(rect.end.x - 14, rect.position.y + 16), 6, tread_color)
