extends RefCounted
class_name SfxData

const UI_SFX := {
	"torque_seek": {
		"world_layer": "ratchet_tick",
		"system_layer": "sine_sweep_220_440hz",
		"combined_effect": "needle_tracks_pressure",
		"priority": 2,
	},
	"torque_green": {
		"world_layer": "bolt_turn_click",
		"system_layer": "clean_buffer_ping",
		"combined_effect": "safe_zone_confirmed",
		"priority": 3,
	},
	"torque_slip": {
		"world_layer": "wrench_slip_sparks",
		"system_layer": "bitcrushed_error_buzz",
		"combined_effect": "red_zone_warning",
		"priority": 4,
	},
	"binary_flip": {
		"world_layer": "floor_plate_clack",
		"system_layer": "square_beep_weighted_bit",
		"combined_effect": "bit_toggled",
		"priority": 2,
	},
	"binary_match": {
		"world_layer": "heavy_latch_open",
		"system_layer": "ascending_cache_chord",
		"combined_effect": "door_logic_open",
		"priority": 4,
	},
	"mirror_admin_purge": {
		"world_layer": "whiteout_pressure_wash",
		"system_layer": "parity_scan_alarm",
		"combined_effect": "sector_purge_threat",
		"priority": 5,
	},
}

static func get_ui_sfx_profile(event_id: String) -> Dictionary:
	var profile: Dictionary = UI_SFX.get(event_id, {})
	var result := profile.duplicate(true)
	if not result.is_empty():
		result["id"] = event_id
		result["dual_tone"] = true
	return result

static func get_torque_meter_sfx(state: Dictionary) -> Dictionary:
	if bool(state.get("sparks", false)) or str(state.get("zone_label", "")) == "RED SLIP":
		return get_ui_sfx_profile("torque_slip")
	if bool(state.get("bolt_turning", false)) or bool(state.get("in_green_zone", false)):
		return get_ui_sfx_profile("torque_green")
	return get_ui_sfx_profile("torque_seek")

static func get_binary_display_sfx(display: Dictionary, tile_toggled: bool = false) -> Dictionary:
	if bool(display.get("matched", false)):
		return get_ui_sfx_profile("binary_match")
	if tile_toggled:
		return get_ui_sfx_profile("binary_flip")
	return {}

static func get_anomaly_sfx(anomaly_id: String, pressure: Dictionary) -> Dictionary:
	if anomaly_id == "mirror_admin_sentinel" and bool(pressure.get("active", false)):
		return get_ui_sfx_profile("mirror_admin_purge")
	return {}
