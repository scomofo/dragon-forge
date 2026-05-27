class_name BattleSetupPayload
extends RefCounted

## Typed read-only setup data used to create a runtime BattleSession.

var battle_id: StringName = &""
var complete_on_resolution: bool = false
var victory: bool = false
var raw_xp_awarded: int = 0
var scraps_earned: int = 0
var player_hp_remaining: int = 0
var player_level_start: int = 1
var enemy_level: int = 1
var player_dragon_id: StringName = &""
var boss_id: StringName = &""
var final_phase_id: StringName = &""
