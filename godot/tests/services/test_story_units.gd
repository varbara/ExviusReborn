extends "res://tests/test_case.gd"

## The main story hands Fina over once Lechios Hills is cleared. Nothing in the
## datamine says so -- `unit.joinParty` is 1 for almost every unit, and no switch
## type means "unit acquired" -- so StoryUnits records the join point and
## StoryUnitService applies it. These tests tie the join to the real data, keep it
## from duplicating, and check the level survives a reload.

const STORY_UNITS = preload("res://core/story/story_units.gd")

const FINA_UNIT_ID: String = "100000302"
const LECHIOS_CLEAR_SWITCH: String = "10024400"


func _snapshot_state() -> Dictionary:
	return {
		"switches": SwitchService.opened_switches.duplicate(true),
		"units": UnitService.owned_units_ids.duplicate(true),
	}


func _restore_state(state: Dictionary) -> void:
	SwitchService.opened_switches = state["switches"]
	UnitService.owned_units_ids = state["units"]
	StoryUnitService.take_granted()


func _owned_finas() -> Array:
	return UnitService.owned_units_ids.filter(
		func(unit): return unit is Dictionary and str(unit.get("unit_id", "")) == FINA_UNIT_ID)


func _drop_fina_and_clear_switch() -> void:
	SwitchService.opened_switches.erase(LECHIOS_CLEAR_SWITCH)
	UnitService.owned_units_ids = UnitService.owned_units_ids.filter(
		func(unit): return not (unit is Dictionary and str(unit.get("unit_id", "")) == FINA_UNIT_ID))


## The join hangs on the switch Lechios Hills' last stage opens; hanging it on any
## other switch would bring her in somewhere the story never reaches.
func test_the_join_switch_is_what_lechios_hills_last_stage_opens() -> void:
	var rows: Array = GameDatabase.query(
		"SELECT openSwitch FROM mission WHERE missionId = ?", ["1120704"])
	assert_false(rows.is_empty(), "Lechios Hills - Bandit's Hideout exists")
	if rows.is_empty():
		return
	assert_eq(str(rows[0].get("openSwitch", "")), LECHIOS_CLEAR_SWITCH,
		"the join switch is what that stage opens")


## Every join in the table has to point at a unit that exists and a switch something
## actually opens: a typo would join nobody, and nothing would report it.
func test_every_recorded_join_points_at_real_data() -> void:
	assert_true(STORY_UNITS.GRANTS.size() >= 5, "the table holds the joins found so far")
	for entry in STORY_UNITS.GRANTS:
		var unit_id: String = str(entry.get("unit_id", ""))
		var switch_id: String = str(entry.get("switch", ""))
		var unit: Dictionary = GameDatabase.get_unit(int(unit_id))
		assert_eq(str(unit.get("unitName", "")), str(entry.get("name", "")),
			"unit %s is the %s the join names" % [unit_id, str(entry.get("name", "?"))])
		assert_true(int(entry.get("level", 0)) >= 1,
			"%s joins at a real level" % str(entry.get("name", unit_id)))
		var from_missions: Array = GameDatabase.query(
			"SELECT missionId FROM mission WHERE openSwitch LIKE ?", ["%" + switch_id + "%"])
		var from_stories: Array = GameDatabase.query(
			"SELECT storySubId FROM story_sub WHERE openSwitch LIKE ?", ["%" + switch_id + "%"])
		assert_true(not from_missions.is_empty() or not from_stories.is_empty(),
			"switch %s is opened by a stage or a town story, so the join can fire" % switch_id)


## More than one join works through the same funnel: Lid arrives on her own switch.
func test_a_second_story_unit_joins_on_its_own_switch() -> void:
	var before: Dictionary = _snapshot_state()
	SwitchService.opened_switches.erase("10057500")
	UnitService.owned_units_ids = UnitService.owned_units_ids.filter(
		func(unit): return not (unit is Dictionary and str(unit.get("unit_id", "")) == "100000503"))
	SwitchService.unlock_switches("10057500", "test")
	var lids: Array = UnitService.owned_units_ids.filter(
		func(unit): return unit is Dictionary and str(unit.get("unit_id", "")) == "100000503")
	assert_eq(lids.size(), 1, "clearing Galebreak hands Lid over")
	_restore_state(before)


## The unit id has to be the Fina the wiki describes: her 2-star story entry.
func test_fina_is_a_real_unit_at_her_story_rarity() -> void:
	var unit: Dictionary = GameDatabase.get_unit(int(FINA_UNIT_ID))
	assert_eq(str(unit.get("unitName", "")), "Fina", "unit 100000302 is Fina")
	assert_eq(int(unit.get("rare", 0)), 2, "she joins as her 2-star entry")


## Nothing is handed over while the stage is unplayed.
func test_join_waits_for_the_switch() -> void:
	var before: Dictionary = _snapshot_state()
	_drop_fina_and_clear_switch()
	var granted: Array = StoryUnitService.apply_grants("test")
	assert_eq(granted.size(), 0, "no story unit before Lechios Hills is cleared")
	assert_eq(_owned_finas().size(), 0, "the roster does not gain Fina early")
	_restore_state(before)


## She joins once, at level 20, and a second check adds nothing.
func test_join_adds_fina_once_at_level_twenty() -> void:
	var before: Dictionary = _snapshot_state()
	_drop_fina_and_clear_switch()
	SwitchService.opened_switches.append(LECHIOS_CLEAR_SWITCH)

	var granted: Array = StoryUnitService.apply_grants("test")
	assert_eq(granted.size(), 1, "Fina joins when Lechios Hills is cleared")
	if not granted.is_empty():
		assert_eq(str(granted[0].get("unit_id", "")), FINA_UNIT_ID, "the granted unit is Fina")
		assert_eq(int(granted[0].get("level", 0)), 20, "she joins at level 20")

	assert_eq(_owned_finas().size(), 1, "the roster holds exactly one story Fina")

	var stored: Array = _owned_finas()
	if not stored.is_empty():
		assert_eq(int(stored[0].get("current_rarity", 0)), 2, "she is stored at 2 stars")
		var gear: Dictionary = stored[0].get("equipment", {})
		assert_eq(gear.size(), 0, "a story unit is handed over wearing nothing")

	assert_eq(StoryUnitService.take_granted().size(), 1,
		"the join is reported once, for the results screen")
	assert_eq(StoryUnitService.apply_grants("test").size(), 0, "the join does not repeat")
	assert_eq(StoryUnitService.take_granted().size(), 0,
		"a repeated check reports nothing")
	_restore_state(before)


## The join hangs off the switch funnel itself, so clearing the stage is enough:
## no screen has to remember to hand her over.
func test_clearing_the_stage_grants_her_through_the_switch_funnel() -> void:
	var before: Dictionary = _snapshot_state()
	_drop_fina_and_clear_switch()
	SwitchService.unlock_switches(LECHIOS_CLEAR_SWITCH, "test")
	assert_eq(_owned_finas().size(), 1, "the switch funnel hands Fina over")
	_restore_state(before)


## The level is stored as xp, so a save written with her must load at level 20 too.
func test_granted_fina_reloads_at_the_same_level() -> void:
	var before: Dictionary = _snapshot_state()
	_drop_fina_and_clear_switch()
	SwitchService.opened_switches.append(LECHIOS_CLEAR_SWITCH)
	StoryUnitService.apply_grants("test")

	var payload: Dictionary = UnitService.snapshot_payload()
	var reloaded: Array = UnitService._hydrate_owned_units(payload.get("owned_units", []))
	var fina_reloaded: Array = reloaded.filter(
		func(unit): return unit is Dictionary and str(unit.get("unit_id", "")) == FINA_UNIT_ID)
	assert_eq(fina_reloaded.size(), 1, "the save carries Fina")
	if not fina_reloaded.is_empty():
		assert_eq(int(fina_reloaded[0].get("level", 0)), 20, "she reloads at level 20")
	_restore_state(before)
