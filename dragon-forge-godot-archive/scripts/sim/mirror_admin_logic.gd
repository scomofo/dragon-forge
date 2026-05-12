extends RefCounted
class_name MirrorAdminLogic

const PHASE_PARITY := "PARITY"
const PHASE_OVERCLOCK := "OVERCLOCK"
const PHASE_KERNEL_PANIC := "KERNEL_PANIC"
const SYSTEM_STABLE := "Stable"
const SYSTEM_THROTTLING := "Throttling"
const SYSTEM_CRITICAL := "Critical"

static func create_state() -> Dictionary:
	return {
		"phase": PHASE_PARITY,
		"system_state": SYSTEM_STABLE,
		"packet_integrity": 1.0,
		"packet_shield": 1.0,
		"core_exposed": false,
		"target_frequency": 440.0,
		"mirrored_element": "neutral",
		"is_stunned": false,
		"stun_timer": 0.0,
		"hard_reset_active": false,
	}

static func update_phase(state: Dictionary) -> Dictionary:
	var next := state.duplicate(true)
	var integrity := float(next.get("packet_integrity", 1.0))
	if integrity <= 0.25:
		next["phase"] = PHASE_KERNEL_PANIC
		next["system_state"] = SYSTEM_CRITICAL
	elif integrity <= 0.62:
		next["phase"] = PHASE_OVERCLOCK
		next["system_state"] = SYSTEM_THROTTLING
	else:
		next["phase"] = PHASE_PARITY
		next["system_state"] = SYSTEM_STABLE
	next["hard_reset_active"] = integrity <= 0.05
	return next

static func mirror_player_state(state: Dictionary, player_state: Dictionary) -> Dictionary:
	var next := update_phase(state)
	next["target_frequency"] = float(player_state.get("current_frequency", next.get("target_frequency", 440.0)))
	next["mirrored_element"] = str(player_state.get("element", "neutral"))
	next["reflect_color"] = player_state.get("element_color", Color("#e7f7ff"))
	if next["phase"] == PHASE_PARITY:
		next["defense_alignment"] = "%s_shielding" % next["mirrored_element"]
	return next

static func predicted_thread_mine_position(player_position: Vector3, player_velocity: Vector3, lead_time: float = 0.5) -> Vector3:
	return player_position + player_velocity * maxf(0.0, lead_time)

static func apply_packet_pressure(state: Dictionary, pressure: float, delta: float) -> Dictionary:
	var next := state.duplicate(true)
	var shield := float(next.get("packet_shield", 1.0))
	var integrity := float(next.get("packet_integrity", 1.0))
	var pressure_amount := clampf(pressure, 0.0, 1.0) * delta
	if shield > 0.0:
		shield = maxf(0.0, shield - pressure_amount)
	else:
		integrity = maxf(0.0, integrity - pressure_amount * 0.45)
	next["packet_shield"] = shield
	next["packet_integrity"] = integrity
	next["core_exposed"] = shield <= 0.0
	return update_phase(next)

static func regenerate_packet_shield(state: Dictionary, delta: float, player_is_pressuring: bool) -> Dictionary:
	var next := state.duplicate(true)
	if player_is_pressuring or bool(next.get("core_exposed", false)):
		return next
	next["packet_shield"] = clampf(float(next.get("packet_shield", 1.0)) + delta * 0.18, 0.0, 1.0)
	return next

static func dissonant_frequency(admin_frequency: float) -> float:
	return admin_frequency * pow(2.0, 6.0 / 12.0)

static func check_dissonant_stun(state: Dictionary, player_frequency: float, tolerance_hz: float = 4.0) -> Dictionary:
	var next := state.duplicate(true)
	var admin_frequency := float(next.get("target_frequency", 440.0))
	var target := dissonant_frequency(admin_frequency)
	if absf(player_frequency - target) <= tolerance_hz:
		next["is_stunned"] = true
		next["stun_timer"] = 3.0
		next["missing_texture_exposed"] = true
		next["core_exposed"] = true
	return next

static func tick_stun(state: Dictionary, delta: float) -> Dictionary:
	var next := state.duplicate(true)
	if not bool(next.get("is_stunned", false)):
		return next
	var remaining := maxf(0.0, float(next.get("stun_timer", 0.0)) - delta)
	next["stun_timer"] = remaining
	if remaining <= 0.0:
		next["is_stunned"] = false
		next["missing_texture_exposed"] = false
	return next

static func jam_hard_reset_with_manual(state: Dictionary, has_manual_override: bool) -> Dictionary:
	var next := state.duplicate(true)
	if bool(next.get("hard_reset_active", false)) and has_manual_override:
		next["hard_reset_active"] = false
		next["phase"] = "READ_ONLY"
		next["system_state"] = "Read-Only"
		next["packet_integrity"] = maxf(float(next.get("packet_integrity", 0.0)), 0.05)
	return next
