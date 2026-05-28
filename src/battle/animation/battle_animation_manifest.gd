class_name BattleAnimationManifest
extends Resource

@export var manifest_id: StringName
@export var schema_version: int = 1
@export var actor_sets: Array[BattleActorAnimationSet] = []
@export var global_clips: Array[BattleAnimationClip] = []
@export var reduced_motion_profile_id: StringName
@export var fallback_policy: StringName = &"content_lock_error"
@export var notes: String = ""


func find_actor_set(actor_set_id: StringName) -> BattleActorAnimationSet:
	for actor_set in actor_sets:
		if actor_set == null:
			continue
		if actor_set.actor_id == actor_set_id:
			return actor_set
	return null


func find_clip(clip_id: StringName) -> BattleAnimationClip:
	for clip in global_clips:
		if clip == null:
			continue
		if clip.clip_id == clip_id:
			return clip
	return null
