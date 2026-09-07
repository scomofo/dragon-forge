extends RefCounted
## Separate namespace, checked writes, backup, and no overwrite of unreadable data.
const Progress = preload("res://sim/progression.gd")
var path = "user://nextgen-progress.json"
var blocked = false
var message = ""

func read_progress() -> Dictionary:
	blocked = false
	message = ""
	if not FileAccess.file_exists(path):
		return Progress.fresh()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		blocked = true
		message = "Save could not be read. This session will not overwrite it."
		return Progress.fresh()
	var parser = JSON.new()
	var parse_error = parser.parse(file.get_as_text())
	file.close()
	var parsed = parser.data if parse_error == OK else null
	if not Progress.validate(parsed):
		blocked = true
		message = "Save is unreadable or from another version. Preserved on disk; session-only progress."
		return Progress.fresh()
	# JSON numbers are floats; normalize both integer fields before use.
	parsed.version = 1
	parsed.clears = int(parsed.clears)
	return parsed

func write_progress(state: Dictionary) -> bool:
	if blocked or not Progress.validate(state):
		return false
	var temporary = path + ".tmp"
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		message = "Save failed. Progress is still available in this session."
		return false
	file.store_string(JSON.stringify(state))
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK:
		message = "Save write failed. Existing save was not replaced."
		return false
	var absolute = ProjectSettings.globalize_path(path)
	var backup = absolute + ".bak"
	var had_previous = FileAccess.file_exists(path)
	if had_previous:
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			message = "Could not rotate backup; existing save kept."
			return false
		if DirAccess.rename_absolute(absolute, backup) != OK:
			message = "Could not back up save; existing save kept."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) != OK:
		if had_previous:
			DirAccess.rename_absolute(backup, absolute)
		message = "Save could not be committed. Progress remains in this session."
		return false
	message = ""
	return true
