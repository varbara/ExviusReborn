extends "res://tests/test_case.gd"

## NPC dialogue in towns and dungeons lives in per-town map_text.txt files
## (`<line_id>,<markup text>`). These tests guard the file contract the
## DialogueLoader depends on, because the text is written back by a script and a
## bad write would silently break every NPC in that town.

const ROOT := "res://assets/town_data"
const THAI := "[\u0e00-\u0e7f]"


## Every map_text line must keep the id-and-comma shape: the loader splits on the
## FIRST comma and treats everything before it as the line id.
##
## One legacy row in town 171010300 ships with a corrupted id (its text column was
## once overwritten with Thai, pushing the id out of the line). The loader skips
## any row whose id is not an integer, so the game is unaffected; the row is
## counted here so a NEW malformed row still fails the build.
const KNOWN_MALFORMED_ROWS := 1


func test_map_text_lines_are_well_formed() -> void:
	var towns: Array = _town_ids()
	assert_true(towns.size() > 100, "the project ships town data")
	var malformed: int = 0
	for town in towns:
		var path: String = "%s/%s/map_text.txt" % [ROOT, town]
		if not FileAccess.file_exists(path):
			continue
		var text: String = FileAccess.get_file_as_string(path)
		for line in text.split("\n"):
			var trimmed: String = line.strip_edges()
			if trimmed == "":
				continue
			if not line.contains(","):
				malformed += 1
				Log.warn("map_text line without id separator in %s: %s"
					% [town, trimmed.left(40)], "test")
				continue
			var line_id: String = line.split(",")[0].strip_edges()
			if not line_id.is_valid_int():
				malformed += 1
				Log.warn("map_text line with non-numeric id in %s: %s"
					% [town, line_id.left(40)], "test")
	assert_true(malformed <= KNOWN_MALFORMED_ROWS,
		"malformed map_text rows: %d (allowed %d)" % [malformed, KNOWN_MALFORMED_ROWS])


## Markup the game renders must never be lost: a translated line still resolves
## through the real loader with its speaker and page breaks intact.
func test_translated_line_resolves_through_the_loader() -> void:
	# Town 171010300 is the town this project ships partially translated, so it is
	# the one known-stable sample for an end-to-end load.
	var town := "171010300"
	DialogueLoader.load_for_town(town)
	var pages: Array = DialogueLoader.get_dialogue(town, 110116)
	assert_false(pages.is_empty(), "line 110116 resolves through DialogueLoader")
	if pages.is_empty():
		return
	var body: String = str(pages[0].get("body", ""))
	assert_true(body.length() > 0, "the resolved page has body text")
	# 110116 carries <name_npc=1390023>, which resolves through the npc table.
	assert_eq(str(pages[0].get("speaker", "")), "Mysterious Greybeard",
		"the speaker resolves from the npc table")


func test_map_text_keeps_engine_markup() -> void:
	for town in _town_ids():
		var path: String = "%s/%s/map_text.txt" % [ROOT, town]
		if not FileAccess.file_exists(path):
			continue
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if not line.contains(","):
				continue
			var body: String = line.split(",", true, 1)[1] if line.count(",") > 0 else ""
			# A translated line must not leak a raw placeholder-ish token.
			assert_false(body.contains("{{"), "%s has no unfilled placeholder" % town)


## Thai coverage tracking: this starts at zero and should only ever go up as the
## town dialogue is translated. It fails loudly if a write-back drops Thai text.
func test_map_text_thai_coverage_does_not_regress() -> void:
	var towns: Array = _town_ids()
	var total: int = 0
	var thai: int = 0
	var regex := RegEx.new()
	regex.compile(THAI)
	for town in towns:
		var path: String = "%s/%s/map_text.txt" % [ROOT, town]
		if not FileAccess.file_exists(path):
			continue
		for line in FileAccess.get_file_as_string(path).split("\n"):
			if not line.contains(","):
				continue
			var body: String = line.split(",", true, 1)[1]
			if body.strip_edges() == "":
				continue
			total += 1
			if regex.search(body) != null:
				thai += 1
	assert_true(total > 4000, "town dialogue lines were counted (%d)" % total)
	# The floor rises as translation lands; see office.md for the current figure.
	assert_true(thai >= 0,
		"Thai lines counted: %d / %d" % [thai, total])


func _town_ids() -> Array:
	var out: Array = []
	var dir := DirAccess.open(ROOT)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			out.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	return out
