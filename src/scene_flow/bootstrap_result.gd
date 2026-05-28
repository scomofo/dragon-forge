class_name BootstrapResult
extends RefCounted

## Named result for BootstrapRoot startup.

var success: bool = false
var reason: StringName = &""
var message: String = ""
var boot_log: Array[StringName] = []
var source_result: RefCounted = null


func configure(
		is_success: bool,
		result_reason: StringName,
		result_message: String,
		steps: Array[StringName],
		nested_result: RefCounted = null
) -> BootstrapResult:
	success = is_success
	reason = result_reason
	message = result_message
	boot_log = steps.duplicate()
	source_result = nested_result
	return self
