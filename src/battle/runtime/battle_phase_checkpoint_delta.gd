class_name BattlePhaseCheckpointDelta
extends RefCounted

## Typed Mirror Admin phase checkpoint settlement data.

var boss_id: StringName = &""
var phase_id: StringName = &""
var boss_hp: int = 0
var player_hp: int = 0
var turn_count: int = 0
var statuses_cleared: bool = false
var defend_cooldowns_cleared: bool = false
