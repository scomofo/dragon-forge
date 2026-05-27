extends GutTest

const ECONOMY_LEDGER_PATH: String = "res://src/economy/economy_ledger.gd"
const ECONOMY_RESULT_PATH: String = "res://src/economy/economy_result.gd"
const SAVE_DATA_PATH: String = "res://src/save/save_data.gd"


func test_get_scraps_returns_exact_saved_balance_above_display_cap() -> void:
	var ledger: RefCounted = _make_ledger()
	var save_data: Resource = _make_save_data(1000)
	if ledger == null or save_data == null:
		return

	assert_eq(ledger.get_scraps(save_data), 1000)


func test_can_afford_handles_zero_exact_and_above_price_without_mutation() -> void:
	var ledger: RefCounted = _make_ledger()
	if ledger == null:
		return

	var zero_balance: Resource = _make_save_data(0)
	var exact_balance: Resource = _make_save_data(50)
	var above_balance: Resource = _make_save_data(65)

	assert_false(ledger.can_afford(zero_balance, 35))
	assert_true(ledger.can_afford(exact_balance, 50))
	assert_true(ledger.can_afford(above_balance, 50))
	assert_eq(zero_balance.player_scraps, 0)
	assert_eq(exact_balance.player_scraps, 50)
	assert_eq(above_balance.player_scraps, 65)


func test_can_afford_rejects_every_positive_catalog_price_at_zero_balance() -> void:
	var ledger: RefCounted = _make_ledger()
	var save_data: Resource = _make_save_data(0)
	if ledger == null or save_data == null:
		return

	for item_price in [35, 45, 50, 175, 200, 225]:
		assert_false(ledger.can_afford(save_data, item_price), "zero scraps should not afford %d" % item_price)
	assert_eq(save_data.player_scraps, 0)


func test_affordability_result_accepts_zero_price_without_mutation() -> void:
	var ledger: RefCounted = _make_ledger()
	var save_data: Resource = _make_save_data(0)
	if ledger == null or save_data == null:
		return

	var result: RefCounted = ledger.check_affordability(save_data, 0, &"unit_test")

	assert_true(result.success, result.error_message)
	assert_true(result.affordable)
	assert_eq(result.reason, &"ok")
	assert_eq(result.amount, 0)
	assert_eq(result.balance_before, 0)
	assert_eq(result.balance_after, 0)
	assert_eq(save_data.player_scraps, 0)


func test_negative_amount_returns_named_failure_without_mutation() -> void:
	var ledger: RefCounted = _make_ledger()
	var save_data: Resource = _make_save_data(10)
	if ledger == null or save_data == null:
		return

	var result: RefCounted = ledger.check_affordability(save_data, -1, &"unit_test")

	assert_true(result.get_script().resource_path.ends_with("economy_result.gd"))
	assert_false(result.success)
	assert_false(result.affordable)
	assert_eq(result.reason, &"invalid_amount")
	assert_eq(result.amount, -1)
	assert_eq(result.balance_before, 10)
	assert_eq(result.balance_after, 10)
	assert_eq(save_data.player_scraps, 10)


func test_null_save_data_returns_named_failure() -> void:
	var ledger: RefCounted = _make_ledger()
	if ledger == null:
		return

	var result: RefCounted = ledger.check_affordability(null, 10, &"unit_test")

	assert_false(result.success)
	assert_false(result.affordable)
	assert_eq(result.reason, &"invalid_save_data")
	assert_eq(result.amount, 10)


func _make_ledger() -> RefCounted:
	assert_true(ResourceLoader.exists(ECONOMY_LEDGER_PATH), "EconomyLedger script should exist.")
	assert_true(ResourceLoader.exists(ECONOMY_RESULT_PATH), "EconomyResult script should exist.")
	if not ResourceLoader.exists(ECONOMY_LEDGER_PATH) or not ResourceLoader.exists(ECONOMY_RESULT_PATH):
		return null
	var script: GDScript = load(ECONOMY_LEDGER_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func _make_save_data(player_scraps: int) -> Resource:
	assert_true(ResourceLoader.exists(SAVE_DATA_PATH), "SaveData script should exist.")
	if not ResourceLoader.exists(SAVE_DATA_PATH):
		return null
	var script: GDScript = load(SAVE_DATA_PATH)
	assert_not_null(script)
	if script == null:
		return null
	var save_data: Resource = script.new()
	save_data.player_scraps = player_scraps
	return save_data
