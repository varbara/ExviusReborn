extends Control

signal dungeon_requested(mission_id: String)

@onready var dimmer: ColorRect = $dimmer
@onready var panel: PanelContainer = $panel
@onready var item_icon: TextureRect = $panel/vbox/header/item_icon
@onready var item_name_label: Label = $panel/vbox/header/vbox_title/item_name
@onready var item_qty_label: Label = $panel/vbox/header/vbox_title/item_qty
@onready var btn_close: Button = $panel/vbox/header/btn_close
@onready var modal_content: RichTextLabel = $panel/vbox/scroll/content
@onready var btn_map: Button = $panel/vbox/footer/btn_map
@onready var btn_ok: Button = $panel/vbox/footer/btn_ok

var _item_id: int = 0
## mission_id -> true for every dungeon row rendered as a clickable link.
var _mission_links: Dictionary = {}

func _ready() -> void:
	z_index = 100
	_ensure_fullscreen()
	if btn_close != null:
		btn_close.pressed.connect(close)
	if btn_ok != null:
		btn_ok.pressed.connect(close)
	if btn_map != null:
		btn_map.pressed.connect(_on_map_pressed)
	if dimmer != null:
		dimmer.gui_input.connect(_on_dimmer_gui_input)
	if modal_content != null:
		modal_content.meta_clicked.connect(_on_meta_clicked)

func _ensure_fullscreen() -> void:
	position = Vector2.ZERO
	custom_minimum_size = Vector2(640, 960)
	size = Vector2(640, 960)
	if get_viewport() != null:
		var vp_rect: Rect2 = get_viewport().get_visible_rect()
		if vp_rect.size.x > 0 and vp_rect.size.y > 0:
			size = vp_rect.size
	if dimmer != null:
		dimmer.position = Vector2.ZERO
		dimmer.size = size
	if panel != null:
		var panel_w: float = 520.0
		var panel_h: float = 540.0
		panel.custom_minimum_size = Vector2(panel_w, panel_h)
		panel.size = Vector2(panel_w, panel_h)
		panel.position = Vector2((size.x - panel_w) / 2.0, (size.y - panel_h) / 2.0)

func open(item_id: int, required_count: int = 0) -> void:
	_item_id = item_id
	_ensure_fullscreen()
	visible = true
	move_to_front()

	var item_data: Dictionary = GameDatabase.get_item(item_id)
	var item_name: String = str(item_data.get("name", "Item #%d" % item_id))
	var icon_name: String = str(item_data.get("iconFile", "")).strip_edges()

	# Set icon
	if item_icon != null:
		if icon_name != "":
			var tex_path: String = "res://assets/items/" + icon_name
			if ResourceLoader.exists(tex_path):
				item_icon.texture = ResourceLoader.load(tex_path) as Texture2D
			else:
				item_icon.texture = null
		else:
			item_icon.texture = null

	# Set title
	if item_name_label != null:
		item_name_label.text = item_name

	# Set quantity on hand / required
	var stackables: Dictionary = InventoryService.owned_items.get("stackables", {})
	var owned_count: int = int(stackables.get(str(item_id), 0))
	if item_qty_label != null:
		if required_count > 0:
			item_qty_label.text = "ครอบครอง: %d  /  ต้องการ: %d" % [owned_count, required_count]
			if owned_count < required_count:
				item_qty_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
			else:
				item_qty_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.5))
		else:
			item_qty_label.text = "ครอบครอง: %d" % owned_count
			item_qty_label.remove_theme_color_override("font_color")

	# Fetch drop locations
	var drop_info: Dictionary = GameDatabase.get_item_drop_locations(item_id)
	var dungeons: Array = drop_info.get("dungeons", [])
	var shops: Array = drop_info.get("shops", [])

	# Format content BBCode
	var bb: String = ""

	# Section 1: Drop Dungeons
	bb += "[b][color=#f5c542]═══ แผนที่ / ดันเจี้ยนที่ดรอป (Drop Locations) ═══[/color][/b]\n"
	_mission_links.clear()
	if dungeons.is_empty():
		bb += "[color=#adb5bd]ไม่มีข้อมูลการดรอปในดันเจี้ยนทั่วไป (อาจเป็นไอเทมเฉพาะกิจกรรมหรือภารกิจ)[/color]\n\n"
	else:
		# Group missions by dungeon, keeping each mission's id so cleared ones can
		# be shown as a link back to the stage.
		var grouped: Dictionary = {}
		for row in dungeons:
			var d_name: String = str(row.get("dungeon_name", ""))
			var m_name: String = str(row.get("mission_name", ""))
			var l_name: String = str(row.get("land_name", ""))
			var m_id: String = str(row.get("mission_id", "")).strip_edges()
			if not grouped.has(d_name):
				grouped[d_name] = {"land": l_name, "missions": []}
			var mission_ids_seen: Array = grouped[d_name]["mission_ids"] if grouped[d_name].has("mission_ids") else []
			if not grouped[d_name].has("mission_ids"):
				grouped[d_name]["mission_ids"] = mission_ids_seen
			if not mission_ids_seen.has(m_id):
				grouped[d_name]["missions"].append({"name": m_name, "id": m_id})
				mission_ids_seen.append(m_id)

		for d_name in grouped.keys():
			var entry: Dictionary = grouped[d_name]
			var l_name: String = entry.get("land", "")
			var land_badge: String = "  [color=#a5d8ff](%s)[/color]" % l_name if l_name != "" else ""
			bb += "📍 [b][color=#63e6be]%s[/color][/b]%s\n" % [d_name, land_badge]
			var missions: Array = entry.get("missions", [])
			for m in missions:
				var m_name: String = str((m as Dictionary).get("name", ""))
				var m_id: String = str((m as Dictionary).get("id", ""))
				if m_id != "" and MissionService.is_mission_cleared(m_id):
					# Cleared stage: make the name a link that opens the dungeon.
					_mission_links[m_id] = true
					bb += "    [color=#e9ecef]• [url=mission:%s]%s[/url][/color] [color=#63e6be]▸ ไปที่ด่าน[/color]\n" % [m_id, m_name]
				else:
					bb += "    [color=#e9ecef]• %s[/color]\n" % m_name
		bb += "\n"

	# Section 2: Shops
	bb += "[b][color=#f5c542]═══ ร้านค้าที่มีจำหน่าย (Shops & Towns) ═══[/color][/b]\n"
	if shops.is_empty():
		bb += "[color=#adb5bd]ไม่มีจำหน่ายในร้านค้า (ต้องฟาร์มจากมอนสเตอร์เท่านั้น)[/color]\n\n"
	else:
		for s in shops:
			var shop_name: String = str(s.get("shop_name", "Material Store"))
			var town_name: String = str(s.get("town_name", "Town"))
			var land_name: String = str(s.get("land_name", ""))
			var land_str: String = " - %s" % land_name if land_name != "" else ""
			bb += "🏪 [b][color=#ffd43b]%s[/color][/b] [color=#ced4da](%s%s)[/color]\n" % [town_name, shop_name, land_str]
		bb += "\n"

	# Section 3: Description
	var explain: String = str(item_data.get("explainShort", "")).strip_edges()
	if explain != "":
		bb += "[b][color=#f5c542]═══ คำอธิบายไอเทม (Description) ═══[/color][/b]\n"
		bb += "[color=#ced4da]%s[/color]\n" % explain

	if modal_content != null:
		modal_content.text = bb

func close() -> void:
	visible = false

func _on_dimmer_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			close()

func _on_map_pressed() -> void:
	close()
	UIManager.push("map_ui")


## A `[url=mission:<id>]` link was clicked: ask the owner to open that stage.
func _on_meta_clicked(meta: Variant) -> void:
	var raw: String = str(meta).strip_edges()
	if not raw.begins_with("mission:"):
		return
	var mission_id: String = raw.trim_prefix("mission:").strip_edges()
	if mission_id == "" or not _mission_links.has(mission_id):
		return
	close()
	dungeon_requested.emit(mission_id)

