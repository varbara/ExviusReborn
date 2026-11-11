class_name BattleMenuModel
extends RefCounted

## What the battle menu draws: the commands it offers with the reason each is greyed, and
## the party as the battle has it. Pure: it reads the battle and writes nothing, so the
## view (BattleMenuScreen) can be checked without a battle and the rules can be checked
## without a screen.

const CMD_GIVE_UP: StringName = &"give_up"
const CMD_REPEAT_INFO: StringName = &"repeat_info"

const LABEL_GIVE_UP: String = "Give Up"
const LABEL_REPEAT_INFO: String = "Repeat Info"

## Not started (or already gone): there is nothing to give up or repeat yet.
const REASON_NO_BATTLE: String = "The battle has not started"
const REASON_OVER: String = "The battle is over"
const REASON_NOT_PLAYER_TURN: String = "Not the party's turn"
const LABEL_NO_PARTY: String = "No party"


## The menu's commands, in the order it draws them.
static func commands(director: BattleDirector, engine: BattleEngine) -> Array[Dictionary]:
	var over: bool = director != null and director.is_finished()
	var no_battle_reason: String = REASON_OVER if over else (REASON_NO_BATTLE if engine == null else "")
	return [
		{"command": CMD_GIVE_UP, "label": LABEL_GIVE_UP, "disabled_reason": no_battle_reason},
		{"command": CMD_REPEAT_INFO, "label": LABEL_REPEAT_INFO, "disabled_reason": no_battle_reason},
	]


## The party, one row per member: { id, name, hp, max_hp, mp, max_mp, lb, max_lb, down }.
## Empty before a battle starts.
static func members(engine: BattleEngine) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if engine == null:
		return rows
	for member in engine.party_members():
		rows.append({
			"id": member.id,
			"name": member.name,
			"hp": member.hp,
			"max_hp": member.max_hp,
			"mp": member.mp,
			"max_mp": member.max_mp,
			"lb": member.lb,
			"max_lb": member.max_lb,
			"down": not member.is_alive(),
		})
	return rows
