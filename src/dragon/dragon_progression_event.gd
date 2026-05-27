class_name DragonProgressionEvent
extends RefCounted

## Pending Dragon Progression event payload.
## Callers publish these only after SaveTransaction commit succeeds.

var event_id: StringName = &""
var dragon_id: StringName = &""
var element: StringName = &""
var from_stage: int = 0
var to_stage: int = 0
var old_level: int = 0
var new_level: int = 0
