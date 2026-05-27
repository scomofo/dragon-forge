extends GutTest

const EconomyLedgerScript = preload("res://src/economy/economy_ledger.gd")
const SaveDataScript = preload("res://src/save/save_data.gd")
const SaveServiceScript = preload("res://src/save/save_service.gd")

const ECONOMY_LEDGER_PATH: String = "res://src/economy/economy_ledger.gd"
const SETTLEMENT_HARNESS_PATH: String = "res://tests/integration/economy/test_scrap_reward_addition_boundary.gd"
const TEST_SAVE_PATH: String = "user://gut_scrap_reward_addition_slot.tres"
const TEST_TEMP_PATH: String = "user://gut_scrap_reward_addition_slot.tmp.tres"
const TEST_BACKUP_PATH: String = "user://gut_scrap_reward_addition_slot.bak.tres"


func before_each() -> void:
	_remove_save_files()


func after_each() -> void:
	_remove_save_files()


func test_authored_reward_addition_commits_and_preserves_exact_balance_above_display_cap() -> void:
	var services: Dictionary = _make_initialized_services(90)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save

	var reward_tx: SaveTransaction = save_service.begin_transaction(&"reward_addition")
	var reward_result: EconomyResult = _add_scraps(ledger, reward_tx, 15, &"combat_node_001")
	if reward_result == null:
		return
	var reward_commit: SaveCommitResult = save_service.commit_transaction(reward_tx)
	var rewarded_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(reward_result.success, reward_result.error_message)
	assert_eq(reward_result.reason, &"ok")
	assert_eq(reward_result.source_id, &"combat_node_001")
	assert_eq(reward_result.amount, 15)
	assert_eq(reward_result.balance_before, 90)
	assert_eq(reward_result.balance_after, 105)
	assert_true(reward_commit.success, reward_commit.error_message)
	assert_eq(rewarded_save.player_scraps, 105)

	var high_services: Dictionary = _make_initialized_services(995)
	var high_ledger: EconomyLedger = high_services.ledger
	var high_save_service: SaveService = high_services.save
	var high_tx: SaveTransaction = high_save_service.begin_transaction(&"reward_above_display_cap")
	var high_result: EconomyResult = _add_scraps(high_ledger, high_tx, 15, &"combat_node_999")
	if high_result == null:
		return
	var high_commit: SaveCommitResult = high_save_service.commit_transaction(high_tx)
	var high_save: SaveData = _load_save(TEST_SAVE_PATH)

	assert_true(high_result.success, high_result.error_message)
	assert_eq(high_result.balance_before, 995)
	assert_eq(high_result.balance_after, 1010)
	assert_true(high_commit.success, high_commit.error_message)
	assert_eq(high_save.player_scraps, 1010)


func test_invalid_reward_amounts_and_transactions_do_not_mutate_scraps() -> void:
	var services: Dictionary = _make_initialized_services(50)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save

	var negative_tx: SaveTransaction = save_service.begin_transaction(&"negative_reward")
	var negative_result: EconomyResult = _add_scraps(ledger, negative_tx, -1, &"invalid_reward")
	if negative_result == null:
		return
	assert_false(negative_result.success)
	assert_eq(negative_result.reason, &"invalid_amount")
	assert_eq(negative_result.balance_before, 50)
	assert_eq(negative_result.balance_after, 50)
	assert_eq(negative_tx.staged_save.player_scraps, 50)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 50)

	var zero_tx: SaveTransaction = save_service.begin_transaction(&"zero_reward")
	var zero_result: EconomyResult = _add_scraps(ledger, zero_tx, 0, &"no_reward")
	if zero_result == null:
		return
	assert_true(zero_result.success, zero_result.error_message)
	assert_eq(zero_result.reason, &"ok")
	assert_eq(zero_result.balance_before, 50)
	assert_eq(zero_result.balance_after, 50)
	assert_eq(zero_tx.staged_save.player_scraps, 50)

	var null_result: EconomyResult = _add_scraps(ledger, null, 10, &"invalid_tx")
	if null_result == null:
		return
	assert_false(null_result.success)
	assert_eq(null_result.reason, &"invalid_transaction")
	assert_eq(null_result.source_id, &"invalid_tx")
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 50)

	var inactive_tx: SaveTransaction = save_service.begin_transaction(&"inactive_reward")
	inactive_tx.active = false
	var inactive_result: EconomyResult = _add_scraps(ledger, inactive_tx, 10, &"inactive_tx")
	if inactive_result == null:
		return
	assert_false(inactive_result.success)
	assert_eq(inactive_result.reason, &"invalid_transaction")
	assert_eq(inactive_tx.staged_save.player_scraps, 50)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 50)

	var missing_staged_tx: SaveTransaction = SaveTransaction.new()
	missing_staged_tx.active = true
	var missing_staged_result: EconomyResult = _add_scraps(ledger, missing_staged_tx, 10, &"missing_staged")
	if missing_staged_result == null:
		return
	assert_false(missing_staged_result.success)
	assert_eq(missing_staged_result.reason, &"invalid_transaction")
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 50)


func test_defeat_settlement_and_mismatched_battle_echo_do_not_deduct_or_add_scraps() -> void:
	var services: Dictionary = _make_initialized_services(1005)
	var ledger: EconomyLedger = services.ledger
	var save_service: SaveService = services.save

	var defeat_tx: SaveTransaction = save_service.begin_transaction(&"defeat_reward")
	var defeat_applied: bool = _settle_authored_reward(ledger, defeat_tx, false, 25, 25, &"defeat_node")
	assert_false(defeat_applied)
	assert_eq(defeat_tx.staged_save.player_scraps, 1005)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 1005)

	var mismatch_tx: SaveTransaction = save_service.begin_transaction(&"mismatched_battle_echo")
	var mismatch_applied: bool = _settle_authored_reward(ledger, mismatch_tx, true, 25, 999, &"combat_node_002")
	assert_false(mismatch_applied)
	assert_eq(mismatch_tx.staged_save.player_scraps, 1005)
	assert_eq(_load_save(TEST_SAVE_PATH).player_scraps, 1005)

	var authored_tx: SaveTransaction = save_service.begin_transaction(&"authored_reward_echo")
	var authored_applied: bool = _settle_authored_reward(ledger, authored_tx, true, 25, 25, &"combat_node_002")
	assert_true(authored_applied)
	assert_eq(authored_tx.staged_save.player_scraps, 1030)


func test_oq_sh01_bonus_tuning_remains_provisional_and_out_of_scope() -> void:
	var forbidden_terms: Array[String] = [
		"BOSS" + "_SCRAP_BONUS",
		"HAZARD" + "_SCRAP_BONUS",
		"economy" + "-content-lock",
	]
	var source_paths: Array[String] = [ECONOMY_LEDGER_PATH, SETTLEMENT_HARNESS_PATH]

	for source_path in source_paths:
		var source: String = FileAccess.get_file_as_string(source_path)
		assert_false(source.is_empty(), "%s should be readable." % source_path)
		for term in forbidden_terms:
			assert_false(source.contains(term), "%s must not finalize %s." % [source_path, term])

	var content_lock_path: String = "res://docs/balance/" + "economy" + "-content-lock.md"
	assert_false(FileAccess.file_exists(content_lock_path), "Story must not create the Economy content lock artifact.")


func _add_scraps(ledger: EconomyLedger, tx: SaveTransaction, amount: int, source_id: StringName) -> EconomyResult:
	assert_true(ledger.has_method("add_scraps"), "EconomyLedger.add_scraps() should exist for reward settlement.")
	if not ledger.has_method("add_scraps"):
		return null
	return ledger.add_scraps(tx, amount, source_id)


func _settle_authored_reward(
	ledger: EconomyLedger,
	tx: SaveTransaction,
	victory: bool,
	authored_reward: int,
	battle_echo_reward: int,
	source_id: StringName
) -> bool:
	if not victory or authored_reward != battle_echo_reward:
		return false
	var result: EconomyResult = _add_scraps(ledger, tx, authored_reward, source_id)
	return result != null and result.success


func _make_initialized_services(scraps: int) -> Dictionary:
	var save_service: SaveService = SaveServiceScript.new()
	save_service.configure(TEST_SAVE_PATH, 0)
	var initialize_result: SaveCommitResult = save_service.initialize_slot(_make_save_data(scraps))
	assert_true(initialize_result.success, initialize_result.error_message)
	return {
		"save": save_service,
		"ledger": EconomyLedgerScript.new(),
	}


func _make_save_data(scraps: int) -> SaveData:
	var save_data: SaveData = SaveDataScript.new()
	save_data.player_scraps = scraps
	return save_data


func _load_save(path: String) -> SaveData:
	if not ResourceLoader.exists(path):
		return null
	var loaded: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	if loaded is SaveData:
		return loaded
	return null


func _remove_save_files() -> void:
	for path in [TEST_SAVE_PATH, TEST_TEMP_PATH, TEST_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
