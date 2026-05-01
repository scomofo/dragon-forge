extends Node
class_name AudioDirectorService

const SfxData := preload("res://scripts/sim/sfx_data.gd")

var current_music: Dictionary = {}
var last_sfx: Dictionary = {}
var last_scene_cue: Dictionary = {}
var cue_history: Array[Dictionary] = []

func play_music_context(context_id: String) -> Dictionary:
	var music := SfxData.get_music_profile(context_id)
	if music.is_empty():
		return {}
	current_music = music.duplicate(true)
	current_music["context_id"] = context_id
	current_music["runtime_ready"] = true
	_record_cue({
		"kind": "music",
		"id": context_id,
		"profile": current_music.duplicate(true),
	})
	return current_music.duplicate(true)

func play_music_profile(profile: Dictionary) -> Dictionary:
	if profile.is_empty():
		return {}
	current_music = profile.duplicate(true)
	current_music["runtime_ready"] = true
	_record_cue({
		"kind": "music",
		"id": str(current_music.get("id", "")),
		"profile": current_music.duplicate(true),
	})
	return current_music.duplicate(true)

func play_sfx_profile(profile: Dictionary) -> Dictionary:
	if profile.is_empty():
		return {}
	last_sfx = profile.duplicate(true)
	last_sfx["runtime_ready"] = true
	_record_cue({
		"kind": "sfx",
		"id": str(last_sfx.get("id", "")),
		"profile": last_sfx.duplicate(true),
	})
	return last_sfx.duplicate(true)

func play_opening_sequence_cue(tone: String) -> Dictionary:
	var cue := SfxData.get_opening_sequence_audio_profile(tone)
	last_scene_cue = cue.duplicate(true)
	play_music_profile(cue.get("music", {}))
	play_sfx_profile(cue.get("sfx", {}))
	_record_cue({
		"kind": "scene_cue",
		"id": "opening_sequence_%s" % tone,
		"profile": cue.duplicate(true),
	})
	return cue.duplicate(true)

func stop_music(reason: String = "") -> void:
	current_music = {
		"id": "",
		"stopped": true,
		"reason": reason,
	}
	_record_cue({
		"kind": "music_stop",
		"id": reason,
		"profile": current_music.duplicate(true),
	})

func get_audio_state_for_test() -> Dictionary:
	return {
		"current_music": current_music.duplicate(true),
		"last_sfx": last_sfx.duplicate(true),
		"last_scene_cue": last_scene_cue.duplicate(true),
		"cue_count": cue_history.size(),
		"playback_mode": "profile_router_until_stream_assets_land",
	}

func _record_cue(cue: Dictionary) -> void:
	cue_history.append(cue)
	if cue_history.size() > 24:
		cue_history.pop_front()
