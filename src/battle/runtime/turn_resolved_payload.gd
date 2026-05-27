class_name TurnResolvedPayload
extends RefCounted

## Typed turn payload shell for later turn-resolution stories.

var turn_count: int = 0
var player_hp: int = 0
var enemy_hp: int = 0
var player_action_id: StringName = &""
var enemy_action_id: StringName = &""
var presentation_events: Array[PresentationEventPayload] = []
