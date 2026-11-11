extends Node

## Hands over the units the main story gives the player; StoryUnits holds the join
## points. SwitchService stays a plain switch ledger and UnitService a plain roster:
## this listens to the one funnel every unlock goes through -- a mission clear, a
## town's story, an event scene -- and applies the joins it has reached.

const StoryUnits = preload("res://core/story/story_units.gd")

signal story_unit_granted(unit: Dictionary)

## Grants made since the last take_granted(), for the screen that reports rewards.
var _recently_granted: Array = []

func _ready() -> void:
	SwitchService.switches_unlocked.connect(_on_switches_unlocked)

func _on_switches_unlocked() -> void:
	apply_grants("story_switch")

## Grants every story unit whose switch is already open and that the roster does not
## hold yet. Idempotent, so it also backfills a save written before that join
## existed. Returns what this call actually added.
func apply_grants(source_event: String = "story_unit") -> Array:
	var granted: Array = []
	for entry in StoryUnits.GRANTS:
		if not SwitchService.is_unlocked(str(entry.get("switch", ""))):
			continue
		var result: Dictionary = UnitService.grant_story_unit(
			str(entry.get("unit_id", "")),
			int(entry.get("level", 1)),
			source_event
		)
		if not bool(result.get("success", false)):
			continue
		granted.append(result)
		_recently_granted.append(result)
		story_unit_granted.emit(result)
	return granted

## Empties the "granted just now" list and returns it.
func take_granted() -> Array:
	var granted: Array = _recently_granted.duplicate(true)
	_recently_granted.clear()
	return granted
