class_name BattleAnimationLookupResult
extends RefCounted

## Typed result for runtime battle animation manifest lookups.

var success: bool = false
var reason: StringName = &""
var error_message: String = ""
var manifest_id: StringName = &""
var battle_id: StringName = &""
var actor_set_id: StringName = &""
var source_actor_set_id: StringName = &""
var move_id: StringName = &""
var animation_action_id: StringName = &""
var action_class: StringName = &""
var slot_id: StringName = &""
var binding: BattleActionAnimationBinding = null
var action_clip: BattleAnimationClip = null
var vfx_clip: BattleAnimationClip = null
var receive_clip: BattleAnimationClip = null
var base_clip: BattleAnimationClip = null
