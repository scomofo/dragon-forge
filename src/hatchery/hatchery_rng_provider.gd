class_name HatcheryRngProvider
extends RefCounted

## Deterministic RNG seam for Hatchery tests and transaction-scoped production rolls.

const BASIS_POINTS_TOTAL: int = 10000

var seed_value: int = 0
var uses_scripted_rolls: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _scripted_rolls: Array[float] = []
var _scripted_index: int = 0


func configure_seed(value: int) -> void:
	seed_value = value
	uses_scripted_rolls = false
	_scripted_rolls.clear()
	_scripted_index = 0
	_rng.seed = value


func configure_scripted_rolls(rolls: Array) -> void:
	uses_scripted_rolls = true
	_scripted_rolls.clear()
	for roll in rolls:
		_scripted_rolls.append(clampf(float(roll), 0.0, 0.999999))
	_scripted_index = 0


func next_float() -> float:
	if uses_scripted_rolls and _scripted_index < _scripted_rolls.size():
		var scripted_roll: float = _scripted_rolls[_scripted_index]
		_scripted_index += 1
		return scripted_roll
	return _rng.randf()


func next_basis_point() -> int:
	return clampi(int(floor(next_float() * float(BASIS_POINTS_TOTAL))), 0, BASIS_POINTS_TOTAL - 1)
