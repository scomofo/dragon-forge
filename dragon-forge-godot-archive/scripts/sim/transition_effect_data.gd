extends RefCounted
class_name TransitionEffectData

static func hard_reset_duration(packet_integrity: float) -> float:
	return lerpf(2.2, 0.9, clampf(1.0 - packet_integrity, 0.0, 1.0))

static func dither_level_for_integrity(sector_integrity: float) -> float:
	return clampf(1.0 - sector_integrity, 0.0, 1.0)

static func packet_loss_flicker(thread_intensity: float, sector_integrity: float) -> float:
	var integrity_loss := 1.0 - clampf(sector_integrity, 0.0, 1.0)
	return clampf(thread_intensity * 0.6 + integrity_loss * 0.5, 0.0, 1.0)

static func render_style_transition(from_style: String, to_style: String) -> Dictionary:
	var is_major := from_style != to_style
	return {
		"from": from_style,
		"to": to_style,
		"duration": 0.85 if is_major else 0.25,
		"uses_dither": is_major,
		"glitch_label": "%s -> %s" % [from_style, to_style],
	}
