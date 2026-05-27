class_name BattleDurableDelta
extends RefCounted

## Runtime settlement request; callers commit it through Save / Persistence.

var player_dragon_id: StringName = &""
var player_hp_remaining: int = 0
var player_status_id: StringName = &""
var consumed_item_flags: Array[StringName] = []
var raw_xp_awarded: int = 0
var scraps_earned: int = 0
var active_resonance_eligible: bool = false
var defeated_boss_id: StringName = &""
var phase_checkpoint: BattlePhaseCheckpointDelta = null
var battle_completed: bool = false
var victory: bool = false
