class_name SaveCommitResult
extends RefCounted

## Named result returned by SaveService commit and initialization operations.
## Callers inspect this object instead of anonymous Dictionary contracts.

var success: bool = false
var reason: StringName = &""
var slot_id: int = -1
var changed_fields: Array[StringName] = []
var post_commit_events: Array[RefCounted] = []
var error_message: String = ""
var error_code: int = OK
var failure_point: StringName = &""
