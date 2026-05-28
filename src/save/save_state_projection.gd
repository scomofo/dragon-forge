class_name SaveStateProjection
extends RefCounted

## Read-only snapshot of save state intended for runtime systems at load time.
## It exposes derived state without handing feature systems a mutable SaveData Resource.

const MAP_EXPLORE: StringName = &"MAP_EXPLORE"
const MAP_FREE_ROAM: StringName = &"MAP_FREE_ROAM"

var _ending_id: StringName = &""
var _map_state: StringName = MAP_EXPLORE
var _warnings: PackedStringArray = []


func configure_from_save_data(save_data: SaveData, known_ending_ids: Array[StringName] = []) -> void:
	_ending_id = &""
	_map_state = MAP_EXPLORE
	_warnings.clear()

	if save_data == null:
		_warnings.append("Save projection requested without loaded SaveData.")
		return

	_ending_id = save_data.ending_id
	_map_state = MAP_FREE_ROAM if _ending_id != &"" else MAP_EXPLORE
	if _ending_id != &"" and not known_ending_ids.is_empty() and not known_ending_ids.has(_ending_id):
		_warnings.append("Unknown ending_id '%s' loaded; projecting MAP_FREE_ROAM from non-empty ending_id." % _ending_id)


func get_ending_id() -> StringName:
	return _ending_id


func get_map_state() -> StringName:
	return _map_state


func is_post_game() -> bool:
	return _ending_id != &""


func get_warnings() -> PackedStringArray:
	return _warnings.duplicate()
