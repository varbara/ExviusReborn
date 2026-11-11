extends "res://tests/test_case.gd"

## The world map folds several data sources into one canvas, and the places it
## draws sometimes exist twice. These tests lock the two rules that keep the map
## readable: a duplicate town never stacks on its dungeon, and a party-scoped AI
## trigger resolves instead of being skipped.

const MapUiScript = preload("res://features/outgame/map/map_ui.gd")


## Port City Lodin (area 111) and Militant Town of Moraque (area 1171) exist in
## both `town` and `dungeon` with the same name and the same coordinates, so both
## loops drew an icon and a label in the identical spot.
func test_town_duplicating_a_dungeon_is_not_drawn_again() -> void:
	var dungeons: Array = [{"name": "Port City Lodin", "position": "177:1074"}]
	var lodin: Dictionary = {"townName": "Port City Lodin", "position": "177:1074"}
	assert_true(MapUiScript._has_dungeon_marker(dungeons, lodin),
		"a town matching a dungeon's name and position is a duplicate")


## A town at a different spot, or with a different name, keeps its own marker.
func test_ordinary_town_is_not_treated_as_a_duplicate() -> void:
	var dungeons: Array = [{"name": "Port City Lodin", "position": "177:1074"}]
	var mitra: Dictionary = {"townName": "Town of Mitra", "position": "1364:1130"}
	assert_false(MapUiScript._has_dungeon_marker(dungeons, mitra),
		"a town elsewhere on the map is drawn normally")
	var same_name_elsewhere: Dictionary = {
		"townName": "Port City Lodin", "position": "1:2",
	}
	assert_false(MapUiScript._has_dungeon_marker(dungeons, same_name_elsewhere),
		"a matching name at a different position is not a duplicate")


## The town a dungeon stands on is still reachable through that dungeon, which is
## the only marker drawn for the place.
func test_covering_town_is_reachable_through_its_dungeon() -> void:
	var dungeons: Array = [{"name": "Port City Lodin", "position": "177:1074"}]
	var towns: Array = [
		{"townId": "1103", "townName": "Port City Lodin", "position": "177:1074"},
		{"townId": "1101", "townName": "Town of Mitra", "position": "1364:1130"},
	]
	var covered: Dictionary = MapUiScript._covering_town(towns, dungeons[0])
	assert_eq(str(covered.get("townId", "")), "1103",
		"the town at the dungeon's spot is the one the marker opens")
	var mitra: Dictionary = {"townName": "Town of Mitra", "position": "1364:1130"}
	assert_true(MapUiScript._covering_town(towns, mitra).is_empty(),
		"a dungeon elsewhere covers no town")


## Every town the map hides behind a dungeon must be enterable, because the data
## opens its progression switch from inside the town only. Port City Lodin's
## story (story_sub 110) opens 10013003, which unlocks Lanzelt; Militant Town of
## Moraque's (story_sub 1607) opens 10314002. Nothing else in the database sets
## either, so hiding the town without an entry would strand the player.
func test_hidden_towns_hold_the_switch_that_unlocks_the_next_land() -> void:
	var checked: int = 0
	for area_id in ["111", "1171"]:
		var towns: Array = GameDatabase.get_towns(area_id)
		var dungeons: Array = GameDatabase.get_dungeons(area_id)
		for town in towns:
			if not MapUiScript._has_dungeon_marker(dungeons, town):
				continue
			checked += 1
			var town_id: String = str(town.get("townId", ""))
			# The map's own pairing, built from the unlocked rows the view holds.
			var pairing: Dictionary = MapUiScript._covering_town_map(dungeons, towns)
			var paired_town_ids: Array = pairing.values()
			assert_true(paired_town_ids.has(town_id),
				"town %s is paired with the dungeon drawn in its place: %s" % [town_id, str(pairing)])
			var chapters: Array = GameDatabase.get_story_sub(town_id)
			assert_false(chapters.is_empty(),
				"town %s has story chapters, which only entering the town can play" % town_id)
			var opens: bool = false
			for chapter in chapters:
				var open_switch: Variant = chapter.get("openSwitch", null)
				if open_switch != null and str(open_switch) not in ["", "0", "<null>"]:
					opens = true
			assert_true(opens, "town %s's chapter opens the switch for the next land" % town_id)
	assert_eq(checked, 2, "both duplicated places are covered")


## The real data has to actually contain the cases the rule is written for.
func test_known_duplicate_places_exist_in_the_database() -> void:
	for area_id in ["111", "1171"]:
		var towns: Array = GameDatabase.get_towns(area_id)
		var dungeons: Array = GameDatabase.get_dungeons(area_id)
		if towns.is_empty() or dungeons.is_empty():
			continue
		var duplicates: int = 0
		for town in towns:
			if MapUiScript._has_dungeon_marker(dungeons, town):
				duplicates += 1
		assert_eq(duplicates, 1, "area %s has exactly one town duplicated by a dungeon" % area_id)


## A party-scoped trigger used to return null from _resolve_subject, which skipped
## the whole rule. `alive` over the party must now answer.
func test_party_scope_alive_trigger_resolves() -> void:
	var party: Array = [{"current_hp": 500}, {"current_hp": 0}]
	var ctx: Dictionary = {"self": {}, "party": party}
	var trigger: Dictionary = {"scope": 4, "subject": "all", "type": "alive", "param": "1"}
	var subject: Variant = MonsterAIRuntime._resolve_subject(trigger, ctx)
	assert_not_null(subject, "a party-scoped subject resolves")
	var rule: Dictionary = {"order": 1, "verb": "skill", "probability": 100.0}
	var state := MonsterAIState.new()
	state.begin_turn()
	var condition: Dictionary = {"type": "alive", "params": PackedStringArray(["1"])}
	assert_true(MonsterAIRuntime._condition_holds(condition, subject, rule, state, ctx),
		"one surviving member keeps the party alive")


## A wiped party reports itself as not alive, so `alive:0` fires and `alive:1` does not.
func test_party_scope_alive_trigger_after_a_wipe() -> void:
	var wiped: Array = [{"current_hp": 0}, {"current_hp": 0}]
	var ctx: Dictionary = {"self": {}, "party": wiped}
	var trigger: Dictionary = {"scope": 4, "subject": "all", "type": "alive", "param": "1"}
	var subject: Variant = MonsterAIRuntime._resolve_subject(trigger, ctx)
	var rule: Dictionary = {"order": 1, "verb": "skill", "probability": 100.0}
	var state := MonsterAIState.new()
	state.begin_turn()
	var alive_false: Dictionary = {"type": "alive", "params": PackedStringArray(["0"])}
	var alive_true: Dictionary = {"type": "alive", "params": PackedStringArray(["1"])}
	assert_true(MonsterAIRuntime._condition_holds(alive_false, subject, rule, state, ctx),
		"alive:0 matches a wiped party")
	assert_false(MonsterAIRuntime._condition_holds(alive_true, subject, rule, state, ctx),
		"alive:1 does not match a wiped party")


## Monster parts still have no model, and that must keep reporting honestly instead
## of silently reading as a dead subject.
func test_monster_part_scope_is_still_reported_as_unsupported() -> void:
	var trigger: Dictionary = {"scope": 8, "subject": "1", "type": "alive", "param": "1"}
	var subject: Variant = MonsterAIRuntime._resolve_subject(trigger, {"self": {}, "party": []})
	assert_null(subject, "a monster-part subject is still unsupported")
