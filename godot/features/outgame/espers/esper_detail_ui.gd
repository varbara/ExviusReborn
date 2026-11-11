extends Control

@onready var back_button: TextureButton = $UnitNamebgChara2/BackButton
@onready var board_button: TextureButton = $btn_board
@onready var powerup_button: TextureButton = $btn_powerup
@onready var reset_button: TextureButton = $btn_reset
@onready var title_label: Label = $UnitNamebgChara2/Title
@onready var summon_image: TextureRect = $SummonImage
@onready var level_label: Label = $lv_label
@onready var hp_label: Label = $status_frame/label_hp
@onready var mp_label: Label = $status_frame/label_mp
@onready var atk_label: Label = $status_frame/label_atk
@onready var def_label: Label = $status_frame/label_def
@onready var mag_label: Label = $status_frame/label_int
@onready var mind_label: Label = $status_frame/label_mind
@onready var cp_label: Label = $label_cp
@onready var skill_name: Label = $skill_name_label
@onready var skill_desc: Label = $skill_desc_label
@onready var btn_elem: TextureButton = $btn_elem
@onready var btn_magic: TextureButton = $btn_magic
@onready var btn_ability: TextureButton = $btn_ability

@onready var detail_modal: Control = $detail_modal
@onready var dimmer: ColorRect = $detail_modal/dimmer
@onready var modal_title: Label = $detail_modal/modal_panel/vbox/header/modal_title
@onready var btn_close_modal: Button = $detail_modal/modal_panel/vbox/header/btn_close_modal
@onready var modal_content: RichTextLabel = $detail_modal/modal_panel/vbox/scroll/modal_content

var _summon_id: String = ""
var _summon_name: String = ""

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	board_button.pressed.connect(_on_board_pressed)
	powerup_button.pressed.connect(_on_powerup_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	btn_elem.pressed.connect(_on_elem_pressed)
	btn_magic.pressed.connect(_on_magic_pressed)
	btn_ability.pressed.connect(_on_ability_pressed)
	btn_close_modal.pressed.connect(_close_modal)
	dimmer.gui_input.connect(_on_dimmer_gui_input)

	var updated_callable: Callable = Callable(self, "_on_espers_updated")
	if not EsperService.espers_updated.is_connected(updated_callable):
		EsperService.espers_updated.connect(updated_callable)

func _exit_tree() -> void:
	var updated_callable: Callable = Callable(self, "_on_espers_updated")
	if EsperService.espers_updated.is_connected(updated_callable):
		EsperService.espers_updated.disconnect(updated_callable)

func init_scene(params: Dictionary) -> void:
	_summon_id = str(params.get("summon_id", "")).strip_edges()
	_summon_name = str(params.get("summon_name", "")).strip_edges()
	if is_node_ready():
		_refresh_ui()

func _refresh_ui() -> void:
	var display_name: String = _summon_name
	if display_name == "" and _summon_id != "":
		display_name = "Summon %s" % _summon_id
	if display_name == "":
		display_name = "Esper"

	title_label.text = display_name

	var progression: Dictionary = EsperService.get_esper_progression(_summon_id)
	var rank: int = maxi(1, int(progression.get("rank", 1)))
	var level: int = maxi(1, int(progression.get("level", 1)))
	var current_sp: int = maxi(0, int(progression.get("current_sp", 0)))
	skill_name.text = ""
	skill_desc.text = ""
	level_label.text = "Lv. %d (R%d)" % [level, rank]
	cp_label.text = str(current_sp)

	var summon_data: Dictionary = GameDatabase.get_esper(int(_summon_id), rank)
	summon_image.texture = _get_summon_image_texture(summon_data)
	skill_name.text = summon_data.get("skillName")
	skill_desc.text = summon_data.get("description")

	var stats: Dictionary = StatCalculator._extract_esper_stats_for_level_and_rank(summon_data, level)
	var board_stat_bonus: Dictionary = EsperService.get_esper_board_stat_bonuses(_summon_id)
	for stat_key in ["HP", "MP", "ATK", "DEF", "MAG", "SPR"]:
		stats[stat_key] = int(stats.get(stat_key, 0)) + int(board_stat_bonus.get(stat_key, 0))
	hp_label.text = str(stats.get("HP", 0))
	mp_label.text = str(stats.get("MP", 0))
	atk_label.text = str(stats.get("ATK", 0))
	def_label.text = str(stats.get("DEF", 0))
	mag_label.text = str(stats.get("MAG", 0))
	mind_label.text = str(stats.get("SPR", 0))

func _resolve_rank_max_level(entry: Dictionary) -> int:
	var cp_pattern_value: Variant = entry.get("cp_pattern", [])
	if cp_pattern_value is Array:
		var cp_pattern: Array = cp_pattern_value
		if not cp_pattern.is_empty():
			return maxi(1, cp_pattern.size())
	return 1

func _interpolate_stat_value(value: Variant, level: int, rank_max_level: int) -> int:
	if value is Array:
		var values: Array = value
		if values.is_empty():
			return 0
		if values.size() == 1:
			return int(values[0])

		var min_value: float = float(values[0])
		var max_value: float = float(values[1])
		var clamped_max_level: int = maxi(1, rank_max_level)
		var clamped_level: int = clampi(level, 1, clamped_max_level)
		if clamped_max_level <= 1:
			return int(round(min_value))

		var interpolated: float = min_value + float(clamped_level - 1) * (max_value - min_value) / float(clamped_max_level - 1)
		return int(round(interpolated))

	return int(value)

func _get_summon_image_texture(summon_data: Dictionary) -> Texture2D:
	if summon_data.is_empty():
		return null

	var image_filename: String = str(summon_data.get("beastImage", "")).strip_edges()
	if image_filename == "":
		return null

	var image_path: String = "res://assets/esper/" + image_filename
	if not ResourceLoader.exists(image_path):
		return null

	return ResourceLoader.load(image_path) as Texture2D

func _on_espers_updated(_espers: Array) -> void:
	if _summon_id == "":
		return
	_refresh_ui()

func _on_back_pressed() -> void:
	UIManager.pop()

func _on_board_pressed() -> void:
	UIManager.push("summon_board_ui", {
		"summon_id": _summon_id,
		"summon_name": _summon_name
	})

func _on_powerup_pressed() -> void:
	UIManager.push("esper_enhancement_ui", {
		"summon_id": _summon_id,
		"summon_name": _summon_name
	})

func _on_reset_pressed() -> void:
	if _summon_id == "":
		return

	var result: Dictionary = EsperService.reset_esper_board_progression(_summon_id)
	if not bool(result.get("success", false)):
		return

	_refresh_ui()

func _close_modal() -> void:
	detail_modal.visible = false

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_close_modal()

func _on_elem_pressed() -> void:
	if _summon_id == "":
		return

	var progression: Dictionary = EsperService.get_esper_progression(_summon_id)
	var rank: int = maxi(1, int(progression.get("rank", 1)))
	var summon_data: Dictionary = GameDatabase.get_esper(int(_summon_id), rank)

	# 1. Base resistances
	var raw_elem_str: String = str(summon_data.get("elemResistValue", "0,0,0,0,0,0,0,0"))
	var elem_parts: PackedStringArray = raw_elem_str.split(",")
	var elem_vals: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
	for i in range(mini(elem_parts.size(), 8)):
		elem_vals[i] = int(elem_parts[i])

	var raw_ail_str: String = str(summon_data.get("ailmentResistValue", "0,0,0,0,0,0,0,0"))
	var ail_parts: PackedStringArray = raw_ail_str.split(",")
	var ail_vals: Array[int] = [0, 0, 0, 0, 0, 0, 0, 0]
	for i in range(mini(ail_parts.size(), 8)):
		ail_vals[i] = int(ail_parts[i])

	# 2. Board resistance bonuses
	var unlocked_nodes: Array = progression.get("unlocked_board_nodes", [])
	if not unlocked_nodes.is_empty():
		var board_nodes: Array = GameDatabase.get_esper_board(int(_summon_id), rank)
		for node in board_nodes:
			var node_id: String = str(node.get("pieceId", ""))
			if unlocked_nodes.has(node_id):
				var p_type: int = int(node.get("pieceType", 0))
				if p_type >= 100 and p_type <= 107:
					var elem_idx: int = p_type - 100
					if elem_idx >= 0 and elem_idx < 8:
						elem_vals[elem_idx] += int(node.get("pieceParam", 0))

	# 3. Format BBCode
	var elem_names: Array[Dictionary] = [
		{"icon": "🔥", "name": "ไฟ (Fire)"},
		{"icon": "❄️", "name": "น้ำแข็ง (Ice)"},
		{"icon": "⚡", "name": "สายฟ้า (Lightning)"},
		{"icon": "💧", "name": "น้ำ (Water)"},
		{"icon": "🌪️", "name": "ลม (Wind)"},
		{"icon": "⛰️", "name": "ดิน (Earth)"},
		{"icon": "✨", "name": "แสง (Light)"},
		{"icon": "🌑", "name": "ความมืด (Dark)"}
	]
	var ail_names: Array[Dictionary] = [
		{"icon": "☠️", "name": "พิษ (Poison)"},
		{"icon": "👁️", "name": "ตาบอด (Blind)"},
		{"icon": "💤", "name": "หลับ (Sleep)"},
		{"icon": "🔇", "name": "ใบ้ (Silence)"},
		{"icon": "⚡", "name": "อัมพาต (Paralyze)"},
		{"icon": "🌀", "name": "สับสน (Confuse)"},
		{"icon": "☣️", "name": "ติดเชื้อ (Disease)"},
		{"icon": "🗿", "name": "กลายเป็นหิน (Petrify)"}
	]

	var bb: String = "[b][color=#f5c542]═══ ความต้านทานธาตุ (Elemental Resistances) ═══[/color][/b]\n"
	for i in range(8):
		var val: int = elem_vals[i]
		var val_str: String = ""
		if val > 0:
			val_str = "[color=#51cf66]+%d%%[/color]" % val
		elif val < 0:
			val_str = "[color=#ff6b6b]%d%%[/color]" % val
		else:
			val_str = "[color=#ced4da]0%[/color]"
		bb += "%s %-22s: %s\n" % [elem_names[i]["icon"], elem_names[i]["name"], val_str]

	bb += "\n[b][color=#f5c542]═══ ความต้านทานสถานะ (Status Resistances) ═══[/color][/b]\n"
	for i in range(8):
		var val: int = ail_vals[i]
		var val_str: String = ""
		if val > 0:
			val_str = "[color=#51cf66]+%d%%[/color]" % val
		elif val < 0:
			val_str = "[color=#ff6b6b]%d%%[/color]" % val
		else:
			val_str = "[color=#ced4da]0%[/color]"
		bb += "%s %-24s: %s\n" % [ail_names[i]["icon"], ail_names[i]["name"], val_str]

	modal_title.text = "ความต้านทาน (Resistances)"
	modal_content.text = bb
	detail_modal.visible = true

func _on_magic_pressed() -> void:
	if _summon_id == "":
		return

	var progression: Dictionary = EsperService.get_esper_progression(_summon_id)
	var unlocked_skills: Array = progression.get("unlocked_skills", [])
	
	var magic_list: Array[Dictionary] = []
	for skill_id in unlocked_skills:
		var magic_data: Dictionary = GameDatabase.get_magic(str(skill_id))
		if not magic_data.is_empty():
			magic_list.append(magic_data)

	var bb: String = "[b][color=#f5c542]═══ เวทมนตร์ที่เรียนรู้ (Learned Magic) ═══[/color][/b]\n\n"
	if magic_list.is_empty():
		bb += "[color=#adb5bd]ยังไม่มีเวทมนตร์ที่เรียนรู้ในขณะนี้\nคุณสามารถปลดล็อคเวทมนตร์ได้จากเมนู Board (กระดานฝึกฝน)[/color]"
	else:
		for m in magic_list:
			var m_name: String = str(m.get("name", "Unknown Magic"))
			var m_cost: int = int(m.get("cost", 0))
			var m_desc: String = str(m.get("explainShort", "")).strip_edges()
			if m_desc == "":
				m_desc = "-"
			bb += "[b][color=#63e6be]✦ %s[/color][/b]  [color=#a5d8ff](MP: %d)[/color]\n%s\n\n" % [m_name, m_cost, m_desc]

	modal_title.text = "เวทมนตร์ (Magic Spells)"
	modal_content.text = bb
	detail_modal.visible = true

func _on_ability_pressed() -> void:
	if _summon_id == "":
		return

	var progression: Dictionary = EsperService.get_esper_progression(_summon_id)
	var rank: int = maxi(1, int(progression.get("rank", 1)))
	var summon_data: Dictionary = GameDatabase.get_esper(int(_summon_id), rank)

	var bb: String = "[b][color=#f5c542]═══ ท่าอัญเชิญอสูร (Evocation) ═══[/color][/b]\n\n"
	var evocation_name: String = str(summon_data.get("skillName", "")).strip_edges()
	var evocation_desc: String = str(summon_data.get("description", "")).strip_edges()
	if evocation_name != "":
		bb += "[b][color=#ff922b]★ %s[/color][/b]  [color=#ffd43b](Evocation Skill)[/color]\n%s\n\n" % [evocation_name, evocation_desc]
	else:
		bb += "[color=#adb5bd]ไม่มีข้อมูลท่าอัญเชิญ[/color]\n\n"

	bb += "[b][color=#f5c542]═══ ความสามารถพิเศษ (Special Abilities & Passives) ═══[/color][/b]\n\n"
	var unlocked_skills: Array = progression.get("unlocked_skills", [])
	var ability_count: int = 0
	for skill_id in unlocked_skills:
		# Check active ability
		var ability_data: Dictionary = GameDatabase.get_ability(str(skill_id))
		if not ability_data.is_empty():
			ability_count += 1
			var a_name: String = str(ability_data.get("name", "Ability"))
			var a_cost: int = int(ability_data.get("cost", 0))
			var a_desc: String = str(ability_data.get("explainShort", "")).strip_edges()
			if a_desc == "":
				a_desc = "-"
			bb += "[b][color=#4dabf7]◆ %s[/color][/b]  [color=#a5d8ff](Active • MP: %d)[/color]\n%s\n\n" % [a_name, a_cost, a_desc]
			continue

		# Check passive ability
		var passive_data: Dictionary = GameDatabase.get_passive(str(skill_id))
		if not passive_data.is_empty():
			ability_count += 1
			var p_name: String = str(passive_data.get("name", "Passive"))
			var p_desc: String = str(passive_data.get("explainShort", "")).strip_edges()
			if p_desc == "":
				p_desc = "-"
			bb += "[b][color=#b197fc]◆ %s[/color][/b]  [color=#d0bfff](Passive • ติดตัว)[/color]\n%s\n\n" % [p_name, p_desc]

	if ability_count == 0:
		bb += "[color=#adb5bd]ยังไม่มีอบิลิตี้พิเศษที่เรียนรู้ในขณะนี้\nคุณสามารถปลดล็อคความสามารถได้จากเมนู Board (กระดานฝึกฝน)[/color]"

	modal_title.text = "ความสามารถพิเศษ (Special & Abilities)"
	modal_content.text = bb
	detail_modal.visible = true
