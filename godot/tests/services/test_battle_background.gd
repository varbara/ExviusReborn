extends "res://tests/test_case.gd"

## A stage whose own battleBgId is 0 still needs a background. The game's master data
## leaves 10,297 of 22,603 missions at 0 -- Deserted Highroad's stages and all their
## phases included -- which is why the battle screen drew the plain backdrop there.
## GameDatabase.resolve_battle_bg_id falls back to the phase, then to the nearest stage
## of the same land, and these tests keep that chain tied to real rows and real files.

const DESERTED_HIGHROAD: String = "1120101"
const FULAN_SOUTH: String = "1110801"


func _file_exists(file_name: String) -> bool:
	return FileAccess.file_exists("res://assets/battle_bg/" + file_name)


## The reported case: a Lanzelt stage with no background of its own.
func test_a_stage_without_its_own_background_still_resolves_one() -> void:
	var own: Array = GameDatabase.query(
		"SELECT battleBgId FROM mission WHERE missionId = ?", [DESERTED_HIGHROAD])
	assert_false(own.is_empty(), "Deserted Highroad - Northeast exists")
	assert_eq(int(own[0].get("battleBgId", -1)), 0, "its own battleBgId is the 0 the game ships")

	var resolved: String = GameDatabase.resolve_battle_bg_id(DESERTED_HIGHROAD)
	assert_true(resolved != "" and resolved != "0", "a background id is resolved anyway")
	var file_name: String = GameDatabase.get_mission_bg(DESERTED_HIGHROAD)
	assert_true(file_name != "", "the resolved id names a background file")
	assert_true(_file_exists(file_name), "%s is on disk: %s" % [file_name, file_name])

	# It has to come from Lanzelt itself, not from another land's stage that happens
	# to sit at the same place in the story order.
	var from_area: Array = GameDatabase.query(
		"SELECT m.missionId AS missionId FROM mission m JOIN dungeon d ON d.dungeonId = m.dungeonId "
		+ "WHERE d.areaId = 112 AND m.battleBgId = ? LIMIT 1", [int(resolved)])
	assert_false(from_area.is_empty(),
		"background %s is one a Lanzelt stage uses" % resolved)


## A stage that does have its own background keeps it: the fallback never overrides.
func test_a_stage_with_its_own_background_keeps_it() -> void:
	var own: Array = GameDatabase.query(
		"SELECT battleBgId, battleBgId AS bg FROM mission WHERE missionId = ?", [FULAN_SOUTH])
	assert_false(own.is_empty(), "Fulan Pass - South exists")
	var own_bg: int = int(own[0].get("battleBgId", 0))
	assert_true(own_bg != 0, "Fulan Pass ships a background of its own")
	assert_eq(int(GameDatabase.resolve_battle_bg_id(FULAN_SOUTH)), own_bg,
		"the mission's own background wins")


## Whatever is resolved has to be a real row and a real file, not an empty string that
## would put the battle back on a plain backdrop.
func test_every_lanzelt_stage_resolves_a_background_that_exists() -> void:
	var broken: Array = []
	for row in GameDatabase.query(
			"SELECT m.missionId AS missionId FROM mission m JOIN dungeon d ON d.dungeonId = m.dungeonId "
			+ "WHERE d.areaId = 112 ORDER BY m.missionId"):
		var mission_id: String = str(row.get("missionId", ""))
		var file_name: String = GameDatabase.get_mission_bg(mission_id)
		if file_name == "" or not _file_exists(file_name):
			broken.append("%s -> %r" % [mission_id, file_name])
	assert_eq(broken.size(), 0, "every Lanzelt stage resolves to a file on disk: %s" % str(broken))
