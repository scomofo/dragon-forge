extends RefCounted
## Presentation preferences use their own file, not the progress schema.
var path = "user://nextgen-preferences.json"
var blocked = false
var message = ""

static func defaults() -> Dictionary:
	return {"version": 1, "quality": 1, "reduced_motion": false}

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != 1:
		return false
	var q = value.get("quality")
	return (q is int or q is float) and is_finite(float(q)) and q == floor(q) and q >= 0 and q <= 3 and value.get("reduced_motion") is bool

func read_values() -> Dictionary:
	blocked = false
	message = ""
	if not FileAccess.file_exists(path):
		return defaults()
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		blocked = true
	else:
		var parser = JSON.new()
		var error = parser.parse(file.get_as_text())
		file.close()
		if error == OK and valid(parser.data):
			return {"version": 1, "quality": int(parser.data.quality), "reduced_motion": parser.data.reduced_motion}
		blocked = true
	message = "Preferences could not be read. Existing file preserved; settings apply this session."
	return defaults()

func write_values(value: Dictionary) -> bool:
	if blocked or not valid(value):
		return false
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		message = "Settings could not be saved; applied for this session."
		return false
	file.store_string(JSON.stringify(value))
	file.flush()
	var result = file.get_error()
	file.close()
	if result == OK:
		result = DirAccess.rename_absolute(ProjectSettings.globalize_path(path + ".tmp"), ProjectSettings.globalize_path(path))
	if result != OK:
		message = "Settings could not be committed; applied for this session."
		return false
	message = ""
	return true
