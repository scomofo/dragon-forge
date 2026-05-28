class_name HatcheryRarityWeight
extends Resource

## Authored rarity probability row for the standard Hatchery pull table.

@export var rarity_id: StringName
@export_range(0, 10000, 1) var weight_basis_points: int = 0
@export var xp_multiplier: int = 1
