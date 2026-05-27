class_name DragonStats
extends RefCounted

## Read-only-by-convention derived dragon stat snapshot.
## Durable records persist level/base fields; stage and computed stats live here.

var dragon_id: StringName = &""
var element: StringName = &""
var level: int = 1
var stage: int = 1
var stage_multiplier: float = 0.5
var hp: int = 0
var atk: int = 0
var def: int = 0
var spd: int = 0
var shiny: bool = false
var is_elder: bool = false
