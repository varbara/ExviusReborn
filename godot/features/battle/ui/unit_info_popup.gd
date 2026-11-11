class_name UnitInfoPopup
extends Control

## The info / Libra analysis window: a combatant's name, level, race/tribe, HP, MP,
## live stats (with buffs and breaks), elemental resistances, status ailment
## resistances, and active statuses with the turns they have left.

const RACE_NAMES: Dictionary = {
	1: "Beast (สัตว์อสูร)",
	2: "Avian (นก)",
	3: "Aquatic (สัตว์น้ำ)",
	4: "Demon (ปิศาจ)",
	5: "Human (มนุษย์)",
	6: "Machina (เครื่องจักร)",
	7: "Dragon (มังกร)",
	8: "Spirit (ภูต)",
	9: "Insect (แมลง)",
	10: "Stone (หิน)",
	11: "Plantoid (พืช)",
	12: "Reaper (อันเดด)",
}

const ELEMENT_LABELS: Array = [
	["FIRE", "ไฟ (Fire)"],
	["ICE", "น้ำแข็ง (Ice)"],
	["LIGHTNING", "สายฟ้า (Lightning)"],
	["WATER", "น้ำ (Water)"],
	["WIND", "ลม (Wind)"],
	["EARTH", "ดิน (Earth)"],
	["LIGHT", "แสง (Light)"],
	["DARK", "มืด (Dark)"],
]

const AILMENT_LABELS: Array = [
	["POISON", "พิษ (Poison)"],
	["BLIND", "ตาบอด (Blind)"],
	["SLEEP", "หลับ (Sleep)"],
	["SILENCE", "ใบ้ (Silence)"],
	["PARALYSIS", "อัมพาต (Paralysis)"],
	["CONFUSION", "สับสน (Confusion)"],
	["DISEASE", "โรค (Disease)"],
	["PETRIFY", "หิน (Petrify)"],
]

@onready var info_text: RichTextLabel = %InfoText
@onready var close_button: Button = %CloseButton

## Id of the combatant shown, so the battle screen can refresh it; -1 when none.
var shown_id: int = -1


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)


func _on_close_pressed() -> void:
	shown_id = -1
	hide()


static func _format_resist(val: int) -> String:
	if val > 0:
		return "[color=#66ff66]+%d%%[/color]" % val
	elif val < 0:
		return "[color=#ff6666]%d%%[/color]" % val
	return "%d%%" % val


func setup_from_combatant(fighter: Combatant) -> void:
	if fighter == null:
		shown_id = -1
		info_text.text = "[color=red]Invalid Unit Data[/color]"
		return
	shown_id = fighter.id

	var race_list: PackedStringArray = []
	for r_id in fighter.races:
		race_list.append(str(RACE_NAMES.get(int(r_id), "Race #%d" % int(r_id))))
	var race_str: String = ", ".join(race_list) if not race_list.is_empty() else "-"

	var lines: PackedStringArray = [
		"[b][u]%s[/u][/b]  (Lv. %d)" % [fighter.name, fighter.level],
		"เผ่าพันธุ์ (Race): %s" % race_str,
		"HP: %d / %d" % [fighter.hp, fighter.max_hp],
		"MP: %d / %d" % [fighter.mp, fighter.max_mp],
		"",
		"[b]ค่าสถานะ (Stats)[/b]",
		"ATK: %d  |  DEF: %d" % [fighter.stat("ATK"), fighter.stat("DEF")],
		"MAG: %d  |  SPR: %d" % [fighter.stat("MAG"), fighter.stat("SPR")],
		"",
		"[b]ความต้านทานธาตุ (Elemental Resistances)[/b]",
	]

	for i in range(0, ELEMENT_LABELS.size(), 2):
		var e1: Array = ELEMENT_LABELS[i]
		var e2: Array = ELEMENT_LABELS[i + 1]
		var v1: int = fighter.element_resistance(str(e1[0]))
		var v2: int = fighter.element_resistance(str(e2[0]))
		lines.append("%s: %s   |   %s: %s" % [e1[1], _format_resist(v1), e2[1], _format_resist(v2)])

	lines.append("")
	lines.append("[b]ความต้านทานสถานะผิดปกติ (Status Resistances)[/b]")
	for i in range(0, AILMENT_LABELS.size(), 2):
		var a1: Array = AILMENT_LABELS[i]
		var a2: Array = AILMENT_LABELS[i + 1]
		var r1: int = fighter.ailment_resistance(str(a1[0]))
		var r2: int = fighter.ailment_resistance(str(a2[0]))
		lines.append("%s: %s   |   %s: %s" % [a1[1], _format_resist(r1), a2[1], _format_resist(r2)])

	lines.append("")
	lines.append("[b]ผลสถานะปัจจุบัน (Active Effects)[/b]")
	if fighter.statuses.is_empty():
		lines.append("ไม่มี (None)")
	for status in fighter.statuses:
		lines.append(status.describe())
	info_text.text = "\n".join(lines)
