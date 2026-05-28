class_name ContentRegistryValidationResult
extends RefCounted

## Validation report for authored content startup checks.

var ok: bool = true
var duplicate_required_ids: Array[StringName] = []
var duplicate_optional_ids: Array[StringName] = []
var missing_required_ids: Array[StringName] = []
var empty_required_entries: int = 0
var load_errors: PackedStringArray = []
var actionable_errors: PackedStringArray = []
var warnings: PackedStringArray = []


func fail() -> void:
	ok = false


func add_duplicate_required_id(content_id: StringName, content_type: StringName) -> void:
	if not duplicate_required_ids.has(content_id):
		duplicate_required_ids.append(content_id)
	actionable_errors.append(
		"Duplicate required content ID '%s' for type '%s'; rename one authored definition or mark one optional." %
		[content_id, content_type]
	)
	fail()


func add_duplicate_optional_id(content_id: StringName, content_type: StringName) -> void:
	if not duplicate_optional_ids.has(content_id):
		duplicate_optional_ids.append(content_id)
	warnings.append(
		"Duplicate optional content ID '%s' for type '%s'; first definition will be used." %
		[content_id, content_type]
	)


func add_missing_required_id(content_id: StringName, content_type: StringName) -> void:
	if not missing_required_ids.has(content_id):
		missing_required_ids.append(content_id)
	actionable_errors.append(
		"Missing required content ID '%s' for type '%s'; add an authored definition or remove it from the required ID list." %
		[content_id, content_type]
	)
	fail()


func add_empty_required_entry(content_type: StringName) -> void:
	empty_required_entries += 1
	actionable_errors.append(
		"Required content list for type '%s' contains an empty ID; replace it with a stable StringName." %
		content_type
	)
	fail()


func add_load_error(path: String) -> void:
	load_errors.append(path)
	actionable_errors.append("Failed to load authored content Resource at '%s'." % path)
	fail()


func add_missing_id_property(resource: Resource, content_type: StringName) -> void:
	actionable_errors.append(
		"Authored content Resource '%s' for type '%s' has no stable ID property." %
		[resource.resource_path, content_type]
	)
	fail()
