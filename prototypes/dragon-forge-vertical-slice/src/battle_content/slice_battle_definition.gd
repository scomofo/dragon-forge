extends Resource

@export var battle_id: StringName
@export var move_ids: Array[StringName] = []
@export var enemy_move_ids: Array[StringName] = []
@export var support_actor_ids: Array[StringName] = []
@export var animation_manifest_id: StringName
@export var player_actor_animation_selector: StringName
@export var player_actor_animation_set_id: StringName
@export var enemy_actor_animation_set_id: StringName
@export var support_actor_animation_set_ids: Array[StringName] = []
@export var boss_phase_animation_set_ids: Array[StringName] = []
