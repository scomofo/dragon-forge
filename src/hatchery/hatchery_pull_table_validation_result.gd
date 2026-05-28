class_name HatcheryPullTableValidationResult
extends RefCounted

## Named validation report for HatcheryPullTable content-lock checks.

var ok: bool = true
var reason: StringName = &"ok"
var error_message: String = ""
var failed_fields: PackedStringArray = []
var missing_element_ids: Array[StringName] = []
var duplicate_element_ids: Array[StringName] = []
var forbidden_element_ids: Array[StringName] = []
var missing_rarity_ids: Array[StringName] = []
var duplicate_rarity_ids: Array[StringName] = []
var actionable_errors: PackedStringArray = []
var warnings: PackedStringArray = []


func fail() -> void:
	ok = false
	if reason == &"ok":
		reason = &"invalid_pull_table"


func add_field_error(field_name: String, message: String) -> void:
	if not failed_fields.has(field_name):
		failed_fields.append(field_name)
	actionable_errors.append(message)
	error_message = message
	fail()


func add_missing_element_id(element_id: StringName) -> void:
	if not missing_element_ids.has(element_id):
		missing_element_ids.append(element_id)
	add_field_error("element_weights", "Missing required Hatchery element '%s'." % element_id)


func add_duplicate_element_id(element_id: StringName) -> void:
	if not duplicate_element_ids.has(element_id):
		duplicate_element_ids.append(element_id)
	add_field_error("element_weights", "Duplicate Hatchery element '%s' in pull table." % element_id)


func add_forbidden_element_id(element_id: StringName) -> void:
	if not forbidden_element_ids.has(element_id):
		forbidden_element_ids.append(element_id)
	add_field_error("element_weights", "Forbidden Hatchery element '%s' cannot appear in the standard pool." % element_id)


func add_missing_rarity_id(rarity_id: StringName) -> void:
	if not missing_rarity_ids.has(rarity_id):
		missing_rarity_ids.append(rarity_id)
	add_field_error("rarity_weights", "Missing required Hatchery rarity '%s'." % rarity_id)


func add_duplicate_rarity_id(rarity_id: StringName) -> void:
	if not duplicate_rarity_ids.has(rarity_id):
		duplicate_rarity_ids.append(rarity_id)
	add_field_error("rarity_weights", "Duplicate Hatchery rarity '%s' in pull table." % rarity_id)
