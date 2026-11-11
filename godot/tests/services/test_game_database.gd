extends "res://tests/test_case.gd"

## Town maps are keyed by resource_map, not by their display icons. Event towns
## can reuse another town's icon, and Farplane has no map_icon_* filename at all.


func test_town_folder_comes_from_the_map_resource() -> void:
	assert_eq(GameDatabase.get_town("2100").get("mapFolderId"), "121010100", "Dirando Shore")
	assert_eq(GameDatabase.get_town("9001").get("mapFolderId"), "211020100", "Farplane")


func test_town_scene_prefers_the_map_resource_over_the_display_icon() -> void:
	var town_map: Node = preload("res://features/town/town_map.gd").new()
	# Dirando Shore reuses another town's icon, while Farplane has no usable map icon.
	assert_eq(town_map._resolve_town_folder_id("2100"), "121010100", "Dirando Shore")
	assert_eq(town_map._resolve_town_folder_id("9001"), "211020100", "Farplane")
	town_map.free()


## Battle dialogue must expose paramTh, otherwise the Thai translation can never
## reach MissionTimeline (it reads paramTh and falls back to paramEn).
func test_battle_script_rows_carry_the_thai_column() -> void:
	var rows: Array = GameDatabase.get_battle_script("14022601")
	assert_true(not rows.is_empty(), "battleScript 14022601 has rows")
	var row: Dictionary = rows[0]
	assert_true(row.has("paramTh"), "the query selects paramTh")
	assert_true(row.has("paramEn"), "the query still selects paramEn")
	assert_true(row.has("cond"), "the query still selects cond")


## A translated world-1 script parses to Thai lines, speaker name included.
func test_a_translated_battle_script_parses_as_thai() -> void:
	var segments: Array = MissionTimeline.parse_battle_script("14022601")
	assert_true(not segments.is_empty(), "the script parses")
	var lines: Array = (segments[0] as Dictionary).get("lines", [])
	assert_true(not lines.is_empty(), "the segment carries lines")
	var first: Dictionary = lines[0]
	assert_eq(str(first.get("speaker", "")), "เรน", "the speaker name is Thai")
	var thai_re := RegEx.new()
	thai_re.compile("[\\x{0E00}-\\x{0E7F}]")
	assert_true(thai_re.search(str(first.get("text", ""))) != null, "the line text is Thai")
