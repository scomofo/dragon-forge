class_name BattleActorAnimationSet
extends Resource

@export var actor_id: StringName
@export var actor_kind: StringName
@export var element: StringName
@export var stage_id: StringName
@export var variant_id: StringName
@export var facing: StringName = &"right"
@export var frame_slot_size: Vector2i
@export var anchor: Vector2
@export var idle_clip_id: StringName
@export var telegraph_clip_id: StringName
@export var hurt_clip_id: StringName
@export var defend_start_clip_id: StringName
@export var defend_hit_clip_id: StringName
@export var ko_clip_id: StringName
@export var victory_settle_clip_id: StringName
@export var action_bindings: Array[BattleActionAnimationBinding] = []


func required_base_clip_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for clip_id in required_base_clip_slots().values():
		if clip_id != &"":
			ids.append(clip_id)
	return ids


func required_base_clip_slots() -> Dictionary:
	return {
		&"idle": idle_clip_id,
		&"telegraph": telegraph_clip_id,
		&"hurt": hurt_clip_id,
		&"defend_start": defend_start_clip_id,
		&"defend_hit": defend_hit_clip_id,
		&"ko": ko_clip_id,
	}


func find_binding_for_move(move_id: StringName, animation_action_id: StringName) -> BattleActionAnimationBinding:
	for binding in action_bindings:
		if binding == null:
			continue
		if binding.move_id == move_id:
			return binding
	for binding in action_bindings:
		if binding == null:
			continue
		if animation_action_id != &"" and binding.animation_action_id == animation_action_id:
			return binding
	return null
