extends Resource

@export var clip_id: StringName
@export var asset_path: String
@export var frame_count: int
@export var frame_duration_ms: int
@export var frame_paths: PackedStringArray = []
@export var loop: bool = false
@export var anchor: Vector2
@export var slot_size: Vector2i
@export var playback_mode: StringName = &"strip"
@export var reduced_motion_clip_id: StringName
@export var preview_sheet_path: String
@export var runtime_capture_paths: PackedStringArray = []
@export var approval_status: StringName = &"prototype"
@export var accessibility_notes: String = ""
