extends CanvasLayer
class_name TransitionController

signal hard_reset_window_opened
signal hard_reset_completed
signal hard_reset_jammed
signal dither_transition_completed

const CRT_SHADER := preload("res://assets/shaders/crt_power_off.gdshader")
const DITHER_SHADER := preload("res://assets/shaders/dither_transition.gdshader")

var crt_rect: ColorRect
var dither_rect: ColorRect
var crt_material: ShaderMaterial
var dither_material: ShaderMaterial
var hard_reset_jammed := false

func _ready() -> void:
	layer = 40
	crt_material = ShaderMaterial.new()
	crt_material.shader = CRT_SHADER
	crt_rect = ColorRect.new()
	crt_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	crt_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crt_rect.material = crt_material
	crt_rect.color = Color.WHITE
	crt_rect.visible = false
	add_child(crt_rect)

	dither_material = ShaderMaterial.new()
	dither_material.shader = DITHER_SHADER
	dither_rect = ColorRect.new()
	dither_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	dither_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dither_rect.material = dither_material
	dither_rect.color = Color.WHITE
	dither_rect.visible = false
	add_child(dither_rect)

func trigger_hard_reset(duration: float = 2.0) -> void:
	hard_reset_jammed = false
	crt_rect.visible = true
	crt_material.set_shader_parameter("collapse_factor", 0.0)
	hard_reset_window_opened.emit()
	var tween := create_tween()
	tween.tween_property(crt_material, "shader_parameter/collapse_factor", 1.0, duration)
	await get_tree().create_timer(maxf(0.05, duration - 0.2)).timeout
	if hard_reset_jammed:
		return
	await tween.finished
	hard_reset_completed.emit()

func jam_hard_reset() -> void:
	hard_reset_jammed = true
	hard_reset_jammed.emit()
	var tween := create_tween()
	tween.tween_property(crt_material, "shader_parameter/collapse_factor", 0.0, 0.28)
	await tween.finished
	crt_rect.visible = false

func play_dither_transition(duration: float = 0.85, packet_loss: float = 0.0) -> void:
	dither_rect.visible = true
	dither_material.set_shader_parameter("transition_level", 0.0)
	dither_material.set_shader_parameter("packet_loss_flicker", packet_loss)
	var tween := create_tween()
	tween.tween_property(dither_material, "shader_parameter/transition_level", 1.0, duration)
	await tween.finished
	dither_transition_completed.emit()
	dither_rect.visible = false
	dither_material.set_shader_parameter("packet_loss_flicker", 0.0)

func set_packet_loss_flicker(amount: float) -> void:
	dither_rect.visible = amount > 0.01
	dither_material.set_shader_parameter("transition_level", clampf(amount * 0.35, 0.0, 1.0))
	dither_material.set_shader_parameter("packet_loss_flicker", clampf(amount, 0.0, 1.0))
