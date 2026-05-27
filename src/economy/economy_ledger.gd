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
	var result: EconomyResult = check_affordability(save_data, amount)
	return result.success and result.affordable


## Validates Scrap affordability without mutating the supplied save data.
func check_affordability(save_data: SaveData, amount: int, source_id: StringName = &"") -> EconomyResult:
	var balance: int = get_scraps(save_data)
	var result: EconomyResult = _make_result(amount, balance, source_id)
	if save_data == null:
		return _fail_result(result, &"invalid_save_data", "EconomyLedger requires SaveData.")
	if amount < 0:
		return _fail_result(result, &"invalid_amount", "Scrap amount must be >= 0.")

	result.success = true
	result.reason = &"ok" if balance >= amount else &"insufficient_scraps"
	result.affordable = balance >= amount
	return result


## Stages a Scrap spend inside an active SaveTransaction.
func spend_scraps(tx: SaveTransaction, amount: int, sink_id: StringName) -> EconomyResult:
	var save_data: SaveData = tx.staged_save if _is_valid_transaction(tx) else null
	var balance: int = get_scraps(save_data)
	var result: EconomyResult = _make_result(amount, balance, sink_id)
	result.sink_id = sink_id
	if not _is_valid_transaction(tx):
		return _fail_result(result, &"invalid_transaction", "spend_scraps requires an active SaveTransaction.")
	if amount < 0:
		return _fail_result(result, &"invalid_amount", "Scrap amount must be >= 0.")
	if amount > balance:
		return _fail_result(result, &"insufficient_scraps", "Not enough Scraps.")

	save_data.player_scraps = balance - amount
	result.success = true
	result.reason = &"ok"
	result.affordable = true
	result.balance_after = save_data.player_scraps
	return result


## Stages a Scrap reward addition inside an active SaveTransaction.
func add_scraps(tx: SaveTransaction, amount: int, source_id: StringName) -> EconomyResult:
	var save_data: SaveData = tx.staged_save if _is_valid_transaction(tx) else null
	var balance: int = get_scraps(save_data)
	var result: EconomyResult = _make_result(amount, balance, source_id)
	if not _is_valid_transaction(tx):
		return _fail_result(result, &"invalid_transaction", "add_scraps requires an active SaveTransaction.")
	if amount < 0:
		return _fail_result(result, &"invalid_amount", "Scrap amount must be >= 0.")

	save_data.player_scraps = balance + amount
	result.success = true
	result.reason = &"ok"
	result.balance_after = save_data.player_scraps
	return result


func _make_result(amount: int, balance: int, source_id: StringName) -> EconomyResult:
	var result: EconomyResult = EconomyResultResource.new()
	result.amount = amount
	result.balance_before = balance
	result.balance_after = balance
	result.source_id = source_id
	return result


func _is_valid_transaction(tx: SaveTransaction) -> bool:
	return tx != null and tx.active and tx.staged_save != null


func _fail_result(result: EconomyResult, reason: StringName, error_message: String) -> EconomyResult:
	result.success = false
	result.reason = reason
	result.error_message = error_message
	result.affordable = false
	return result
