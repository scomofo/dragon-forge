extends RefCounted
class_name FlightTuningData

const HIGH_BANK_DEGREES := 25.0
const MAX_BANK_DEGREES := 30.0
const MAX_PITCH_DEGREES := 45.0

static func air_density_for_altitude(altitude: float, skybox_leak: float = 0.0, thread_intensity: float = 0.0) -> float:
	var altitude_density := 1.0 - (maxf(0.0, altitude) / 2000.0)
	var leak_loss := clampf(skybox_leak, 0.0, 1.0) * 0.48
	var thread_loss := clampf(thread_intensity, 0.0, 1.0) * 0.32
	return clampf(altitude_density - leak_loss - thread_loss, 0.08, 1.0)

static func traction_force(velocity: Vector3, grip_factor: float, air_density: float, wing_surface_area: float = 1.0) -> Vector3:
	return velocity * clampf(grip_factor, 0.0, 2.0) * clampf(air_density, 0.0, 1.0) * clampf(wing_surface_area, 0.25, 2.5)

static func lift_coefficient(air_density: float, is_stalling: bool) -> float:
	if is_stalling:
		return 0.1
	return lerpf(0.22, 0.72, clampf(air_density, 0.0, 1.0))

static func is_high_bank(roll_radians: float) -> bool:
	return absf(rad_to_deg(roll_radians)) > HIGH_BANK_DEGREES

static func drift_vector(right_vector: Vector3, roll_radians: float, air_density: float, speed: float) -> Vector3:
	if not is_high_bank(roll_radians):
		return Vector3.ZERO
	var density_loss := 1.0 - clampf(air_density, 0.0, 1.0)
	var bank_pressure := clampf((absf(rad_to_deg(roll_radians)) - HIGH_BANK_DEGREES) / 35.0, 0.0, 1.0)
	return right_vector * signf(roll_radians) * density_loss * bank_pressure * speed * 0.42

static func stall_state(air_density: float, velocity: Vector3, thread_intensity: float = 0.0) -> bool:
	return air_density <= 0.18 or (thread_intensity >= 0.8 and velocity.length() < 18.0)

static func midi_density_boost(player_frequency: float, wind_frequency: float) -> float:
	var delta := absf(player_frequency - wind_frequency)
	if delta <= 3.0:
		return 0.22
	if delta <= 8.0:
		return 0.1
	return 0.0

static func packet_velocity_glitch(speed: float, max_speed: float) -> float:
	if max_speed <= 0.0:
		return 0.0
	return smoothstep(0.72, 1.0, clampf(speed / max_speed, 0.0, 1.0))
