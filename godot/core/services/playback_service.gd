extends Node

## PlaybackService — Manages Book of Recollection / Story Replay master data
## and player unlock progression checks.

signal playback_data_loaded

var seasons: Array = []
var chapters: Array = []
var maps: Array = []
var events: Array = []

# Quick lookups
var _chapters_by_season: Dictionary = {}
var _maps_by_chapter: Dictionary = {}
var _events_by_map: Dictionary = {}

var is_loaded: bool = false


func _ready() -> void:
	load_data()


func load_data() -> void:
	seasons = _load_json_array("res://assets/static_data/playback/seasons.json")
	chapters = _load_json_array("res://assets/static_data/playback/chapters.json")
	maps = _load_json_array("res://assets/static_data/playback/maps.json")
	events = _load_json_array("res://assets/static_data/playback/events.json")

	_chapters_by_season.clear()
	for c in chapters:
		var sid: int = int(c.get("season_id", 0))
		if not _chapters_by_season.has(sid):
			_chapters_by_season[sid] = []
		_chapters_by_season[sid].append(c)

	_maps_by_chapter.clear()
	for m in maps:
		var cid: int = int(m.get("chapter_id", 0))
		if not _maps_by_chapter.has(cid):
			_maps_by_chapter[cid] = []
		_maps_by_chapter[cid].append(m)

	_events_by_map.clear()
	for e in events:
		var mid: int = int(e.get("map_id", 0))
		if not _events_by_map.has(mid):
			_events_by_map[mid] = []
		_events_by_map[mid].append(e)

	is_loaded = true
	playback_data_loaded.emit()


func _load_json_array(path: String) -> Array:
	var result: Array = []
	if not FileAccess.file_exists(path):
		return result

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return result

	var text: String = file.get_as_text()
	var json: JSON = JSON.new()
	if json.parse(text) == OK and json.data is Array:
		for item in json.data:
			if item is Dictionary:
				result.append(item)
	return result


# === Queries ===

func get_seasons() -> Array:
	return seasons


func get_chapters(season_id: int = 10) -> Array:
	return _chapters_by_season.get(season_id, [])


func get_maps(chapter_id: int) -> Array:
	return _maps_by_chapter.get(chapter_id, [])


func get_events(map_id: int) -> Array:
	return _events_by_map.get(map_id, [])


# === Progress Gating ===

## Checks whether a chapter is unlocked for the current player save.
func is_chapter_unlocked(chapter: Dictionary) -> bool:
	var sw: String = str(chapter.get("switch_info", "0")).strip_edges()
	if sw == "" or sw == "0":
		return true
	if SwitchService:
		return SwitchService.is_unlocked(sw)
	return false


## Checks whether an episode/map is unlocked.
func is_map_unlocked(map_data: Dictionary) -> bool:
	var mid: int = int(map_data.get("map_id", 0))
	# Falling Star (Prologue / Opening) is available by default
	if mid == 100100:
		return true

	var sw: String = str(map_data.get("switch_info", "0")).strip_edges()
	if sw == "" or sw == "0":
		return true
	if SwitchService:
		return SwitchService.is_unlocked(sw)
	return false


## Checks whether a scene/event is unlocked.
func is_event_unlocked(event_data: Dictionary) -> bool:
	var eid: int = int(event_data.get("event_id", 0))
	# Opening is available by default
	if eid == 10010002:
		return true

	var sw: String = str(event_data.get("switch_info", "0")).strip_edges()
	if sw != "" and sw != "0":
		if SwitchService and SwitchService.is_unlocked(sw):
			return true
		return false

	var mission_id: String = str(event_data.get("mission_id", ""))
	if mission_id != "" and MissionService:
		if MissionService.cleared_missions.has(mission_id):
			return true

	# Default fallback to map unlock status
	var mid: int = int(event_data.get("map_id", 0))
	for m in maps:
		if int(m.get("map_id", 0)) == mid:
			return is_map_unlocked(m)

	return true


## Filters an array of maps to only include those unlocked by player progress.
func filter_unlocked_maps(map_list: Array) -> Array:
	var result: Array = []
	for m in map_list:
		if is_map_unlocked(m):
			result.append(m)
	return result


## Filters an array of events to only include those unlocked by player progress.
func filter_unlocked_events(event_list: Array) -> Array:
	var result: Array = []
	for e in event_list:
		if is_event_unlocked(e):
			result.append(e)
	return result
