class_name BattleStatusIconHelper
extends RefCounted

## Helper to resolve BattleStatus models into AtlasTextures from FFBE icon sheets,
## and format floating text callouts with colors.

const BAD_ICONS_PATH: String = "res://assets/ui/battle/state_icon_bad.png"
const UP_ICONS_PATH: String = "res://assets/ui/battle/state_icon_up.png"
const DOWN_ICONS_PATH: String = "res://assets/ui/battle/state_icon_down.png"

const AILMENT_CELLS: Dictionary = {
	"POISON": Vector2i(0, 0),
	"BLIND": Vector2i(1, 0),
	"SLEEP": Vector2i(2, 0),
	"SILENCE": Vector2i(3, 0),
	"PARALYSIS": Vector2i(4, 0),
	"PARALYZE": Vector2i(4, 0),
	"CONFUSION": Vector2i(5, 0),
	"CONFUSE": Vector2i(5, 0),
	"DISEASE": Vector2i(6, 0),
	"PETRIFY": Vector2i(7, 0),
	"KO": Vector2i(0, 1),
	"ZOMBIE": Vector2i(1, 1),
	"STOP": Vector2i(2, 1),
	"CHARM": Vector2i(3, 1),
	"BERSERK": Vector2i(4, 1),
}

const STAT_COLS: Dictionary = {
	"ATK": 0,
	"DEF": 1,
	"MAG": 2,
	"SPR": 3,
}

const CALLOUT_AILMENT_COLORS: Dictionary = {
	"POISON": Color(0.85, 0.45, 1.0),
	"BLIND": Color(0.7, 0.7, 0.8),
	"SLEEP": Color(0.4, 0.7, 1.0),
	"SILENCE": Color(0.8, 0.6, 0.9),
	"PARALYSIS": Color(1.0, 0.9, 0.2),
	"PARALYZE": Color(1.0, 0.9, 0.2),
	"CONFUSION": Color(1.0, 0.65, 0.2),
	"CONFUSE": Color(1.0, 0.65, 0.2),
	"DISEASE": Color(0.6, 0.85, 0.3),
	"PETRIFY": Color(0.7, 0.7, 0.7),
	"STOP": Color(0.4, 0.9, 1.0),
	"CHARM": Color(1.0, 0.5, 0.75),
	"BERSERK": Color(1.0, 0.3, 0.3),
	"ZOMBIE": Color(0.5, 0.8, 0.5),
}

static var _textures: Dictionary = {}


static func get_status_texture(status: BattleStatus) -> Texture2D:
	if status == null:
		return null
	var key_str: String = status.key.to_upper()
	var cache_key: String = "%s:%s:%d" % [status.kind, key_str, 1 if status.value >= 0 else -1]
	if _textures.has(cache_key):
		return _textures[cache_key]

	var sheet_path: String = ""
	var cell: Vector2i = Vector2i(-1, -1)

	match status.kind:
		BattleStatus.AILMENT:
			sheet_path = BAD_ICONS_PATH
			cell = AILMENT_CELLS.get(key_str, Vector2i(-1, -1))
		BattleStatus.STAT:
			var col: int = STAT_COLS.get(key_str, -1)
			if col >= 0:
				if status.value >= 0:
					sheet_path = UP_ICONS_PATH
					cell = Vector2i(col, 0)
				else:
					sheet_path = DOWN_ICONS_PATH
					cell = Vector2i(col, 0)
		BattleStatus.MITIGATION, BattleStatus.SHIELD:
			sheet_path = UP_ICONS_PATH
			cell = Vector2i(5, 0)
		BattleStatus.REGEN:
			sheet_path = UP_ICONS_PATH
			cell = Vector2i(6, 0)
		BattleStatus.MP_REGEN:
			sheet_path = UP_ICONS_PATH
			cell = Vector2i(7, 0)

	if sheet_path != "" and cell.x >= 0 and cell.y >= 0:
		var tex := AtlasTexture.new()
		tex.atlas = load(sheet_path) as Texture2D
		tex.region = Rect2(cell.x * 36, cell.y * 34, 36, 34)
		_textures[cache_key] = tex
		return tex

	return null


## Returns a callout Dictionary { "text": String, "color": Color } for a status event, or empty if none.
static func get_callout(kind: StringName, key: String, value: int) -> Dictionary:
	var upper_key: String = key.to_upper()
	match kind:
		BattleStatus.AILMENT:
			var txt: String = upper_key
			var col: Color = CALLOUT_AILMENT_COLORS.get(upper_key, Color.WHITE)
			return {"text": txt, "color": col}
		BattleStatus.SHIELD:
			return {"text": "BARRIER", "color": Color(1.0, 0.85, 0.2)}
		BattleStatus.STAT:
			var stat_name: String = upper_key
			if value > 0:
				return {"text": "%s UP" % stat_name, "color": Color(0.3, 1.0, 0.4)}
			elif value < 0:
				return {"text": "%s DOWN" % stat_name, "color": Color(1.0, 0.4, 0.3)}
		BattleStatus.MITIGATION:
			return {"text": "MITIGATE", "color": Color(0.3, 0.9, 1.0)}
		BattleStatus.AUTO_REVIVE:
			return {"text": "RERAISE", "color": Color(1.0, 0.9, 0.3)}
		BattleStatus.REGEN:
			return {"text": "REGEN", "color": Color(0.5, 1.0, 0.6)}
		BattleStatus.MP_REGEN:
			return {"text": "REFRESH", "color": Color(0.7, 0.7, 1.0)}
	return {}

