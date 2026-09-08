extends RefCounted
## Independent local audio preferences. Never opens or writes a campaign save.
const Catalog = preload("res://campaign/audio/catalog.gd")
var path = "user://reconnection-audio.json"
var blocked = false
var message = ""

func read_values() -> Dictionary:
	blocked = false
	message = ""
	if not FileAccess.file_exists(path): return Catalog.DEFAULTS.duplicate()
	var result = Catalog.normalize(JSON.parse_string(FileAccess.get_file_as_string(path)))
	if result.is_empty():
		blocked = true
		message = "Unreadable or newer audio preferences preserved. Changes are session-only."
		return Catalog.DEFAULTS.duplicate()
	return result

func write_values(values: Dictionary) -> bool:
	if blocked or Catalog.normalize(values).is_empty(): return false
	var temp = path + ".tmp"
	var file = FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		message = "Could not save audio preferences; changes still apply this session."
		return false
	file.store_string(JSON.stringify(values))
	file.close()
	if Catalog.normalize(JSON.parse_string(FileAccess.get_file_as_string(temp))) != values:
		message = "Audio preferences verification failed; previous settings preserved."
		return false
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, path + ".bak") != OK: return false
	if DirAccess.rename_absolute(temp, path) != OK:
		message = "Audio preferences replacement failed; previous settings preserved."
		return false
	message = ""
	return true
