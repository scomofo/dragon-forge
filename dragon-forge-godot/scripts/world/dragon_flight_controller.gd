extends CharacterBody3D
class_name DragonFlightController

const FlightTuningData := preload("res://scripts/sim/flight_tuning_data.gd")

@export var max_speed := 50.0
@export var pitch_speed := 1.5
@export var roll_speed := 2.0
@export var grip_factor := 0.85
@export var wing_surface_area := 1.0
@export var gravity := 9.8
@export var skybox_leak := 0.0
@export var thread_intensity := 0.0
@export var wind_frequency := 440.0
@export var dragon_roar_frequency := 440.0

var is_drifting := false
var is_stalling := false
var air_density := 1.0
var integrity := 1.0

func _physics_process(delta: float) -> void:
	handle_flight_input(delta)
	_apply_aero_traction(delta)
	move_and_slide()

func handle_flight_input(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	rotation.z = lerp_angle(rotation.z, -input_dir.x * deg_to_rad(FlightTuningData.MAX_BANK_DEGREES), delta * roll_speed)
	rotation.x = lerp_angle(rotation.x, input_dir.y * deg_to_rad(FlightTuningData.MAX_PITCH_DEGREES), delta * pitch_speed)
	is_drifting = FlightTuningData.is_high_bank(rotation.z)

func _apply_aero_traction(delta: float) -> void:
	air_density = FlightTuningData.air_density_for_altitude(global_position.y, skybox_leak, thread_intensity)
	air_density = clampf(air_density + FlightTuningData.midi_density_boost(dragon_roar_frequency, wind_frequency), 0.08, 1.0)
	is_stalling = FlightTuningData.stall_state(air_density, velocity, thread_intensity)

	var forward_dir := -global_transform.basis.z
	var target_velocity := forward_dir * max_speed * air_density
	velocity = velocity.lerp(target_velocity, delta * 2.0)

	var current_speed := velocity.length()
	var lift := current_speed * FlightTuningData.lift_coefficient(air_density, is_stalling) * air_density
	velocity.y += (lift - gravity) * delta

	if is_drifting:
		velocity += FlightTuningData.drift_vector(global_transform.basis.x, rotation.z, air_density, current_speed) * delta

	if thread_intensity > 0.0:
		integrity = clampf(integrity - thread_intensity * delta * 0.02, 0.0, 1.0)

func packet_burst(strength: float = 1.0) -> void:
	var forward_dir := -global_transform.basis.z
	velocity += forward_dir * max_speed * clampf(strength, 0.2, 2.0)

func hover_lock() -> void:
	velocity = Vector3.ZERO

func flight_hud_data() -> Dictionary:
	return {
		"air_density": air_density,
		"integrity": integrity,
		"is_drifting": is_drifting,
		"is_stalling": is_stalling,
		"bandwidth": clampf(velocity.length() / max_speed, 0.0, 1.0),
		"velocity_glitch": FlightTuningData.packet_velocity_glitch(velocity.length(), max_speed),
	}
