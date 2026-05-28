class_name ContentDefinition
extends Resource

## Minimal typed authored-content record for stable implementation-facing IDs.

@export var content_id: StringName
@export var content_type: StringName = &"generic"
@export var source_path: String = ""
@export var required: bool = true
