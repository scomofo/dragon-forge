class_name EconomyResult
extends RefCounted

## Named result for EconomyLedger read, affordability, and mutation helpers.
## ECO-001 only uses read/affordability fields; spend/add stories extend usage.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var source_id: StringName = &""
var amount: int = 0
var balance_before: int = 0
var balance_after: int = 0
var affordable: bool = false

