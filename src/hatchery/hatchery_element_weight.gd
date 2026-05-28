class_name HatcheryElementWeight
extends Resource

## Authored element probability row for the standard Hatchery pull table.

@export var element_id: StringName
@export var rarity_id: StringName
@export_range(0, 10000, 1) var weight_basis_points: int = 0
