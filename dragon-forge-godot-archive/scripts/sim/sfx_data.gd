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
	"opening_boot_tick": {
		"world_layer": "distant_relay_clack",
		"system_layer": "low_square_clock_110hz",
		"combined_effect": "astraeus_wake_sequence",
		"priority": 4,
	},
	"opening_warning_pulse": {
		"world_layer": "sub_bass_pressure_swell",
		"system_layer": "descending_minor_alarm",
		"combined_effect": "great_reset_threat",
		"priority": 5,
	},
	"felix_radio_lock": {
		"world_layer": "workshop_radio_static",
		"system_layer": "carrier_signal_lock",
		"combined_effect": "felix_first_contact",
		"priority": 3,
	},
	"objective_chime": {
		"world_layer": "dragon_heart_thump",
		"system_layer": "ascending_guardian_chime",
		"combined_effect": "skye_objective_confirmed",
		"priority": 4,
	},
}

const MUSIC_PROFILES := {
	"opening_sequence": {
		"id": "opening_sequence",
		"mood": "tense",
		"tempo_bpm": 92,
		"loop": true,
		"lead_voice": "muted_square_alarm",
		"bass_voice": "low_pulse_wave",
		"percussion": "relay_clock_ticks",
		"progression": ["D2", "F2", "C#2", "A1"],
		"intensity": 0.86,
		"ducking": 0.35,
	},
	"world_wandering": {
		"id": "world_wandering",
		"mood": "uneasy_wonder",
		"tempo_bpm": 108,
		"loop": true,
		"lead_voice": "warm_triangle_melody",
		"bass_voice": "soft_square_root_motion",
		"percussion": "light_step_ticks",
		"progression": ["G2", "B2", "A2", "E2"],
		"intensity": 0.42,
		"ducking": 0.12,
	},
	"battle_tension": {
		"id": "battle_tension",
		"mood": "urgent",
		"tempo_bpm": 138,
		"loop": true,
		"lead_voice": "bitcrushed_saw_warning",
		"bass_voice": "square_octave_drive",
		"percussion": "noise_snare_gate",
		"progression": ["E2", "F2", "D2", "C2"],
		"intensity": 0.94,
		"ducking": 0.2,
	},
}

static func get_ui_sfx_profile(event_id: String) -> Dictionary:
	var profile: Dictionary = UI_SFX.get(event_id, {})
	var result := profile.duplicate(true)
	if not result.is_empty():
		result["id"] = event_id
		result["dual_tone"] = true
	return result

static func get_music_profile(context_id: String) -> Dictionary:
	var profile: Dictionary = MUSIC_PROFILES.get(context_id, {})
	var result := profile.duplicate(true)
	if not result.is_empty():
		result["nes_style"] = true
		result["channel_budget"] = {
			"pulse_1": result.get("lead_voice", ""),
			"pulse_2": "counterline_or_alarm",
			"triangle": result.get("bass_voice", ""),
			"noise": result.get("percussion", ""),
		}
	return result

static func get_music_synth_plan(profile: Dictionary) -> Dictionary:
	if profile.is_empty():
		return {}
	var notes: Array = profile.get("progression", [])
	var lead_steps: Array = []
	var bass_steps: Array = []
	for note in notes:
		var note_text := str(note)
		lead_steps.append({
			"note": note_text,
			"frequency": note_to_frequency(note_text),
			"wave": "pulse",
			"duty": 0.25 if profile.get("mood", "") == "urgent" else 0.5,
		})
		bass_steps.append({
			"note": _transpose_octave(note_text, -1),
			"frequency": note_to_frequency(_transpose_octave(note_text, -1)),
			"wave": "triangle",
			"duty": 0.5,
		})
	return {
		"presentation": "procedural_nes_music_plan",
		"music_id": profile.get("id", ""),
		"tempo_bpm": int(profile.get("tempo_bpm", 120)),
		"step_seconds": 60.0 / float(maxi(1, int(profile.get("tempo_bpm", 120)))),
		"loop": bool(profile.get("loop", true)),
		"channels": {
			"pulse_1": lead_steps,
			"pulse_2": _counterline_steps(notes),
			"triangle": bass_steps,
			"noise": [{
				"pattern": profile.get("percussion", "noise_tick"),
				"frequency": 1800.0,
				"wave": "noise",
			}],
		},
		"master_gain": clampf(float(profile.get("intensity", 0.5)) * 0.28, 0.04, 0.32),
	}

static func get_sfx_synth_plan(profile: Dictionary) -> Dictionary:
	if profile.is_empty():
		return {}
	var priority := int(profile.get("priority", 1))
	return {
		"presentation": "procedural_nes_sfx_plan",
		"sfx_id": profile.get("id", ""),
		"duration": 0.08 + float(priority) * 0.035,
		"world_layer": profile.get("world_layer", ""),
		"system_layer": profile.get("system_layer", ""),
		"channels": {
			"pulse_1": [{
				"frequency": 220.0 + float(priority) * 55.0,
				"wave": "pulse",
				"duty": 0.25,
			}],
			"noise": [{
				"frequency": 900.0 + float(priority) * 180.0,
				"wave": "noise",
			}],
		},
		"master_gain": clampf(0.08 + float(priority) * 0.035, 0.08, 0.28),
	}

static func get_opening_sequence_audio_profile(tone: String = "system") -> Dictionary:
	var cue_id := "opening_boot_tick"
	if tone == "warning":
		cue_id = "opening_warning_pulse"
	elif tone == "mentor":
		cue_id = "felix_radio_lock"
	elif tone == "objective":
		cue_id = "objective_chime"
	return {
		"presentation": "nes_audio_scene_cue",
		"music": get_music_profile("opening_sequence"),
		"sfx": get_ui_sfx_profile(cue_id),
		"tone": tone,
	}

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

static func note_to_frequency(note: String) -> float:
	var text := note.strip_edges()
	if text.length() < 2:
		return 440.0
	var names := {
		"C": -9,
		"C#": -8,
		"Db": -8,
		"D": -7,
		"D#": -6,
		"Eb": -6,
		"E": -5,
		"F": -4,
		"F#": -3,
		"Gb": -3,
		"G": -2,
		"G#": -1,
		"Ab": -1,
		"A": 0,
		"A#": 1,
		"Bb": 1,
		"B": 2,
	}
	var note_name := text.substr(0, 2) if text.length() >= 3 and (text[1] == "#" or text[1] == "b") else text.substr(0, 1)
	var octave_text := text.substr(note_name.length())
	var octave := int(octave_text) if octave_text.is_valid_int() else 4
	var semitone: int = int(names.get(note_name, 0)) + (octave - 4) * 12
	return 440.0 * pow(2.0, float(semitone) / 12.0)

static func _counterline_steps(notes: Array) -> Array:
	var steps: Array = []
	for index in notes.size():
		var source := str(notes[index])
		var shifted := _transpose_octave(source, 1 if index % 2 == 0 else 0)
		steps.append({
			"note": shifted,
			"frequency": note_to_frequency(shifted),
			"wave": "pulse",
			"duty": 0.125,
		})
	return steps

static func _transpose_octave(note: String, octaves: int) -> String:
	var text := note.strip_edges()
	if text.length() < 2:
		return note
	var note_name := text.substr(0, 2) if text.length() >= 3 and (text[1] == "#" or text[1] == "b") else text.substr(0, 1)
	var octave_text := text.substr(note_name.length())
	var octave := int(octave_text) if octave_text.is_valid_int() else 4
	return "%s%d" % [note_name, octave + octaves]
