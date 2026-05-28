class_name HatcheryPityRules
extends Resource

## Authored pity thresholds for Hatchery pull resolution.

const RARE_PITY_THRESHOLD: int = 10
const ELEMENT_SOFT_PITY_ONSET: int = 20
const ELEMENT_SOFT_PITY_GUARANTEED: int = 40
const RARE_ELEMENT_ID: StringName = &"Shadow"
const DEFAULT_TIE_BREAK_PRIORITY: Array[StringName] = [&"Fire", &"Ice", &"Shadow", &"Stone", &"Storm", &"Venom"]

@export var rare_element_id: StringName = RARE_ELEMENT_ID
@export var rare_pity_threshold: int = RARE_PITY_THRESHOLD
@export var element_soft_pity_onset: int = ELEMENT_SOFT_PITY_ONSET
@export var element_soft_pity_guaranteed: int = ELEMENT_SOFT_PITY_GUARANTEED
@export var tie_break_priority: Array[StringName] = DEFAULT_TIE_BREAK_PRIORITY.duplicate()


func configure_mvp_defaults() -> void:
	rare_element_id = RARE_ELEMENT_ID
	rare_pity_threshold = RARE_PITY_THRESHOLD
	element_soft_pity_onset = ELEMENT_SOFT_PITY_ONSET
	element_soft_pity_guaranteed = ELEMENT_SOFT_PITY_GUARANTEED
	tie_break_priority = DEFAULT_TIE_BREAK_PRIORITY.duplicate()
