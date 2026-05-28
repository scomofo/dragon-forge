class_name DragonRecord
extends Resource

## Typed durable dragon identity and progression record stored inside SaveData.
## Stage is intentionally derived from level by Dragon Progression and is not persisted.

@export var dragon_id: StringName = &""
@export var element: StringName = &""
@export var base_hp: int = 0
@export var base_atk: int = 0
@export var base_def: int = 0
@export var base_spd: int = 0
@export var level: int = 1
@export var xp: int = 0
@export var shiny: bool = false
@export var battle_charges: int = 0
@export var is_elder: bool = false
