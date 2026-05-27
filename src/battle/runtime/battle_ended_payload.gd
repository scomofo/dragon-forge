class_name BattleEndedPayload
extends RefCounted

## Typed battle completion payload emitted before durable settlement.

var victory: bool = false
var raw_xp_awarded: int = 0
var scraps_earned: int = 0
var player_hp_remaining: int = 0
var player_level_start: int = 1
var enemy_level: int = 1
var battle_id: StringName = &""
var boss_id: StringName = &""
var final_phase_id: StringName = &""
