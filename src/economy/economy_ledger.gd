class_name EconomyLedger
extends RefCounted

const EconomyResultResource = preload("res://src/economy/economy_result.gd")


## Returns the exact durable Scrap balance from a save snapshot or staged save.
func get_scraps(save_data: SaveData) -> int:
	if save_data == null:
		return 0
	return save_data.player_scraps


## Returns whether the save snapshot or staged save can afford the amount.
func can_afford(save_data: SaveData, amount: int) -> bool:
	var result: RefCounted = check_affordability(save_data, amount)
	return result.success and result.affordable


## Validates Scrap affordability without mutating the supplied save data.
func check_affordability(save_data: SaveData, amount: int, source_id: StringName = &"") -> RefCounted:
	var balance: int = get_scraps(save_data)
	var result: RefCounted = _make_result(amount, balance, source_id)
	if save_data == null:
		return _fail_result(result, &"invalid_save_data", "EconomyLedger requires SaveData.")
	if amount < 0:
		return _fail_result(result, &"invalid_amount", "Scrap amount must be >= 0.")

	result.success = true
	result.reason = &"ok" if balance >= amount else &"insufficient_scraps"
	result.affordable = balance >= amount
	return result


func _make_result(amount: int, balance: int, source_id: StringName) -> RefCounted:
	var result: RefCounted = EconomyResultResource.new()
	result.amount = amount
	result.balance_before = balance
	result.balance_after = balance
	result.source_id = source_id
	return result


func _fail_result(result: RefCounted, reason: StringName, error_message: String) -> RefCounted:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	result.affordable = false
	return result
