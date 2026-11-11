extends "res://tests/test_case.gd"

## Tests the battle Trust Mastery gain system (authentic FFBE: 10% chance per mission clear for +0.1% trust).

const TEST_UNIT_ID: String = "100000102" # Rain 2*
const CECIL_UNIT_ID: String = "204000103" # Cecil 3* (TMR: Excalibur 303002000)
const TEST_INSTANCE_ID: String = "test_trust_unit_001"
var _original_units: Array = []


func before_each() -> void:
	if not SkillResolver.opcode_schemas_ready:
		SkillResolver.load_schemas()
	_original_units = UnitService.owned_units_ids.duplicate(true)


func after_each() -> void:
	UnitService.owned_units_ids = _original_units.duplicate(true)


func _create_test_unit(unit_id: String = TEST_UNIT_ID, trust_val: float = 0.0, job_id: int = 1) -> Dictionary:
	return {
		"instance_id": TEST_INSTANCE_ID,
		"unit_id": unit_id,
		"level": 10,
		"xp": 1000,
		"current_rarity": 3,
		"trust_value": trust_val,
		"trust_reward_claimed": false,
		"jobId": job_id,
		"equipment": {}
	}


func test_award_battle_trust_increases_trust_by_tenth_percent() -> void:
	var unit: Dictionary = _create_test_unit(TEST_UNIT_ID, 0.0)
	UnitService.owned_units_ids = [unit]

	# Force 100% chance for test determinism
	var result: Dictionary = UnitService.award_battle_trust([TEST_INSTANCE_ID], 1.0, 0.1)
	assert_true(bool(result.get("success", false)))
	var awarded: Array = result.get("awarded", [])
	assert_eq(awarded.size(), 1)
	assert_eq(awarded[0]["instance_id"], TEST_INSTANCE_ID)
	assert_eq(float(awarded[0]["trust_before"]), 0.0)
	assert_eq(float(awarded[0]["trust_after"]), 0.1)
	assert_eq(float(unit["trust_value"]), 0.1)


func test_award_battle_trust_skips_material_units() -> void:
	var material_unit: Dictionary = _create_test_unit(TEST_UNIT_ID, 0.0, UnitService.TRUST_MATERIAL_JOB_ID)
	UnitService.owned_units_ids = [material_unit]

	var result: Dictionary = UnitService.award_battle_trust([TEST_INSTANCE_ID], 1.0, 0.1)
	assert_true(bool(result.get("success", false)))
	assert_eq(result.get("awarded", []).size(), 0)
	assert_eq(float(material_unit["trust_value"]), 0.0)


func test_award_battle_trust_skips_units_at_100_percent() -> void:
	var max_unit: Dictionary = _create_test_unit(TEST_UNIT_ID, 100.0)
	UnitService.owned_units_ids = [max_unit]

	var result: Dictionary = UnitService.award_battle_trust([TEST_INSTANCE_ID], 1.0, 0.1)
	assert_true(bool(result.get("success", false)))
	assert_eq(result.get("awarded", []).size(), 0)
	assert_eq(float(max_unit["trust_value"]), 100.0)


func test_award_battle_trust_grants_tmr_when_reaching_100_percent() -> void:
	var cecil: Dictionary = _create_test_unit(CECIL_UNIT_ID, 99.9)
	UnitService.owned_units_ids = [cecil]

	var result: Dictionary = UnitService.award_battle_trust([TEST_INSTANCE_ID], 1.0, 0.1)
	assert_true(bool(result.get("success", false)))
	var awarded: Array = result.get("awarded", [])
	assert_eq(awarded.size(), 1)
	assert_eq(float(awarded[0]["trust_after"]), 100.0)
	assert_eq(float(cecil["trust_value"]), 100.0)
	assert_true(bool(cecil["trust_reward_claimed"]))
	var tmr_info: Dictionary = awarded[0].get("tmr_granted", {})
	assert_true(not tmr_info.is_empty(), "TMR reward granted at 100%")
	assert_eq(tmr_info["template_id"], "303002000", "Cecil granted Excalibur")
