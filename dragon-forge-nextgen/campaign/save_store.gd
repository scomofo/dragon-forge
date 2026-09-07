extends RefCounted
## Separate campaign file. Never writes the older prototype save.
const Rules = preload("res://campaign/progress.gd")
const LegacyRules = preload("res://sim/progression.gd")
var path = "user://reconnection-campaign.json"
var blocked = false
var message = ""
var existed = false
var import_legacy = true

func read_campaign() -> Dictionary:
	message = ""
	blocked = false
	existed = FileAccess.file_exists(path)
	if not existed:
		var fresh = Rules.fresh()
		if import_legacy and FileAccess.file_exists("user://nextgen-progress.json"):
			var legacy = LegacyRules.migrate(_read("user://nextgen-progress.json"))
			if not legacy.is_empty() and legacy.hatched:
				fresh.hatched = true
				fresh.module = legacy.module
				fresh.salvage = 30
				fresh.legacy_imported = true
		return fresh
	var result = Rules.normalize(_read(path))
	if result.is_empty():
		blocked = true
		message = "Campaign save is unreadable or from another version. Original bytes preserved; this session will not overwrite it."
		return Rules.fresh()
	return result

func _read(filename: String) -> Variant:
	var f = FileAccess.open(filename, FileAccess.READ)
	if f == null or f.get_length() > 1048576:
		return null
	var parser = JSON.new()
	var code = parser.parse(f.get_as_text())
	f.close()
	return parser.data if code == OK else null

func write_campaign(state: Dictionary) -> bool:
	if blocked:
		return false
	if Rules.normalize(state).is_empty():
		message = "Invalid campaign state was not saved."
		return false
	var temporary = path + ".tmp"
	var f = FileAccess.open(temporary, FileAccess.WRITE)
	if f == null:
		message = "Campaign save could not be written; progress remains in this session."
		return false
	f.store_string(JSON.stringify(state, "\t"))
	f.flush()
	var error = f.get_error()
	f.close()
	if error != OK or Rules.normalize(_read(temporary)).is_empty():
		message = "New save failed verification. Existing save was not replaced."
		return false
	var absolute = ProjectSettings.globalize_path(path)
	var backup = absolute + ".bak"
	var previous = FileAccess.file_exists(path)
	if previous:
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			message = "Backup could not be rotated. Existing save kept."
			return false
		if DirAccess.rename_absolute(absolute, backup) != OK:
			message = "Existing campaign could not be backed up."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) != OK:
		if previous:
			DirAccess.rename_absolute(backup, absolute)
		message = "Save commit failed. Progress remains in this session."
		return false
	existed = true
	message = ""
	return true
