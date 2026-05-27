class_name BattleRecoilResult
extends RefCounted

## Named result for one RECOIL status tick pass.

var player_dot_damage: int = 0
var enemy_dot_damage: int = 0
var player_ko: bool = false
var enemy_ko: bool = false
var resolution_required: bool = false
var tick_order: Array[StringName] = []
