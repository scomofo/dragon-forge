class_name ContentRegistry
extends Node

## Foundation service that validates stable authored-content IDs at startup.
## Runtime callers receive duplicated Resource definitions so shared `.tres` data stays immutable.

const ContentRegistryValidationResultResource = preload("res://src/content/content_registry_validation_result.gd")

const ID_PROPERTY_CANDIDATES: Array[StringName] = [
	&"content_id",
	&"screen_id",
	&"battle_id",
	&"move_id",
	&"manifest_id",
	&"id",
]

var _definitions_by_key: Dictionary[String, Resource] = {}


func clear() -> void:
	_definitions_by_key.clear()


func register_definitions(
		definitions: Array,
		required_ids: Array = [],
		content_type: StringName = &"generic"
) -> RefCounted:
	var result: RefCounted = ContentRegistryValidationResultResource.new()
	var required_lookup: Dictionary[StringName, bool] = _required_lookup(required_ids, content_type, result)
	var candidate_definitions: Dictionary[String, Resource] = {}
	var required_keys: Dictionary[String, bool] = {}

	for definition in definitions:
		if definition == null:
			result.add_load_error("<null resource>")
			continue
		var resource: Resource = definition
		var stable_id: StringName = _extract_stable_id(resource)
		var definition_type: StringName = _extract_content_type(resource, content_type)
		if stable_id == &"":
			result.add_missing_id_property(resource, definition_type)
			continue

		var key: String = _definition_key(definition_type, stable_id)
		var is_required: bool = required_lookup.get(stable_id, false) or _extract_required(resource)
		if candidate_definitions.has(key):
			if is_required or required_keys.get(key, false):
				result.add_duplicate_required_id(stable_id, definition_type)
			else:
				result.add_duplicate_optional_id(stable_id, definition_type)
			continue

		candidate_definitions[key] = resource
		required_keys[key] = is_required

	for required_id in required_ids:
		var required_string_name := StringName(required_id)
		if required_string_name == &"":
			continue
		var required_key: String = _definition_key(content_type, required_string_name)
		if not candidate_definitions.has(required_key):
			result.add_missing_required_id(required_string_name, content_type)

	if result.ok:
		_definitions_by_key = candidate_definitions
	return result


func load_resource_paths(
		resource_paths: Array,
		required_ids: Array = [],
		content_type: StringName = &"generic"
) -> RefCounted:
	var result: RefCounted = ContentRegistryValidationResultResource.new()
	var definitions: Array[Resource] = []
	for path in resource_paths:
		var resource: Resource = ResourceLoader.load(path)
		if resource == null:
			result.add_load_error(path)
			continue
		definitions.append(resource)
	if not result.ok:
		return result
	return register_definitions(definitions, required_ids, content_type)


func has_definition(content_id: StringName, content_type: StringName = &"") -> bool:
	return _find_key(content_id, content_type) != ""


func get_definition(content_id: StringName, content_type: StringName = &"") -> Resource:
	var key: String = _find_key(content_id, content_type)
	if key == "":
		return null
	return _definitions_by_key[key].duplicate(true)


func get_registered_ids(content_type: StringName = &"") -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in _definitions_by_key.keys():
		var parts: PackedStringArray = key.split(":", false, 1)
		if parts.size() != 2:
			continue
		if content_type != &"" and StringName(parts[0]) != content_type:
			continue
		ids.append(StringName(parts[1]))
	return ids


func _required_lookup(
		required_ids: Array,
		content_type: StringName,
		result: RefCounted
) -> Dictionary[StringName, bool]:
	var lookup: Dictionary[StringName, bool] = {}
	for required_id in required_ids:
		var required_string_name := StringName(required_id)
		if required_string_name == &"":
			result.add_empty_required_entry(content_type)
			continue
		lookup[required_string_name] = true
	return lookup


func _extract_stable_id(resource: Resource) -> StringName:
	for property_name in ID_PROPERTY_CANDIDATES:
		if not _has_property(resource, property_name):
			continue
		var value = resource.get(property_name)
		if value is StringName:
			return value
		if value is String:
			return StringName(value)
	return &""


func _extract_content_type(resource: Resource, fallback_type: StringName) -> StringName:
	if fallback_type != &"":
		return fallback_type
	if _has_property(resource, &"content_type"):
		var value = resource.get(&"content_type")
		if value is StringName and value != &"":
			return value
		if value is String and value != "":
			return StringName(value)
	return &"generic"


func _extract_required(resource: Resource) -> bool:
	if not _has_property(resource, &"required"):
		return false
	return bool(resource.get(&"required"))


func _has_property(resource: Resource, property_name: StringName) -> bool:
	for property in resource.get_property_list():
		if property.name == property_name:
			return true
	return false


func _find_key(content_id: StringName, content_type: StringName) -> String:
	if content_type != &"":
		var exact_key: String = _definition_key(content_type, content_id)
		if _definitions_by_key.has(exact_key):
			return exact_key
		return ""

	var suffix := ":%s" % content_id
	for key in _definitions_by_key.keys():
		if key.ends_with(suffix):
			return key
	return ""


func _definition_key(content_type: StringName, content_id: StringName) -> String:
	return "%s:%s" % [content_type, content_id]
