extends "res://tests/test_case.gd"

const ITEM_DROP_POPUP_SCENE: PackedScene = preload("res://features/outgame/units/components/ItemDropPopup.tscn")
const UNIT_AWAKENING_SCENE: PackedScene = preload("res://features/outgame/units/UnitAwakening.tscn")


func test_game_database_get_item_drop_locations() -> void:
	# Beast Meat: 290010000
	var drop_info: Dictionary = GameDatabase.get_item_drop_locations(290010000)
	var dungeons: Array = drop_info.get("dungeons", [])
	var shops: Array = drop_info.get("shops", [])

	assert_true(not dungeons.is_empty(), "Beast Meat should drop in at least one dungeon")
	var found_earth_shrine: bool = false
	for d in dungeons:
		if str(d.get("dungeon_name", "")) == "Earth Shrine":
			found_earth_shrine = true
			break
	assert_true(found_earth_shrine, "Beast Meat should drop in Earth Shrine")

	assert_true(not shops.is_empty(), "Beast Meat should be sold in at least one town store")
	var found_grandshelt_shop: bool = false
	for s in shops:
		if "Grandshelt" in str(s.get("town_name", "")):
			found_grandshelt_shop = true
			break
	assert_true(found_grandshelt_shop, "Beast Meat should be sold in Royal Capital Grandshelt")

	# Litrock: 290020000
	var litrock_info: Dictionary = GameDatabase.get_item_drop_locations(290020000)
	var litrock_dungeons: Array = litrock_info.get("dungeons", [])
	assert_true(not litrock_dungeons.is_empty(), "Litrock should have drop dungeons")
	var found_siren_or_fulan: bool = false
	for d in litrock_dungeons:
		var dname: String = str(d.get("dungeon_name", ""))
		if "Siren" in dname or "Fulan" in dname or "Castle" in dname:
			found_siren_or_fulan = true
			break
	assert_true(found_siren_or_fulan, "Litrock should drop in Siren's Tower, Fulan Pass, or Grandshelt Castle")


func test_item_drop_popup_instantiation_and_content() -> void:
	var popup = ITEM_DROP_POPUP_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(popup)

	popup.open(290010000, 8)
	assert_true(popup.visible, "Popup should be visible when opened")
	assert_eq(popup.size, Vector2(640, 960), "Popup size should fill the 640x960 viewport")
	assert_true(popup.panel.position.x >= 0.0, "Panel should not be offscreen to the left")
	assert_true(popup.panel.position.y >= 0.0, "Panel should not be offscreen to the top")
	assert_almost_eq(popup.panel.position.x, 60.0, 5.0, "Panel should be centered horizontally at x=60")
	assert_almost_eq(popup.panel.position.y, 210.0, 5.0, "Panel should be centered vertically at y=210")
	assert_eq(popup.item_name_label.text, "Beast Meat", "Item name should be Beast Meat")
	assert_true("ต้องการ: 8" in popup.item_qty_label.text, "Qty label should show required count 8")
	assert_true("Drop Locations" in popup.modal_content.text, "Content should contain drop locations header")
	assert_true("Earth Shrine" in popup.modal_content.text, "Content should list Earth Shrine")
	assert_true("Shops & Towns" in popup.modal_content.text, "Content should contain shops header")

	popup.close()
	assert_false(popup.visible, "Popup should be hidden after close()")

	popup.get_parent().remove_child(popup)
	popup.queue_free()


func test_unit_awakening_search_button_wired() -> void:
	if not SkillResolver.opcode_schemas_ready:
		SkillResolver.load_schemas()

	var awakening_screen = UNIT_AWAKENING_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(awakening_screen)

	var rain_unit: Dictionary = GameDatabase.get_unit(100000102).duplicate()
	rain_unit.merge({
		"instance_id": "test_rain_1",
		"unit_id": "100000102",
		"level": 30,
		"current_rarity": 2,
		"equipment": {},
	}, true)

	awakening_screen.init_scene({
		"base_unit": rain_unit,
		"base_unit_instance_id": "test_rain_1"
	})
	awakening_screen._populate_awakening_requirements()

	var slot1: Control = awakening_screen.material_nodes[0]
	assert_true(slot1.visible, "Slot 1 should be visible for Rain's awakening")

	var search_on: TextureButton = slot1.get_node_or_null("unit_classup_item_search_on") as TextureButton
	assert_not_null(search_on, "Search button should exist in slot 1")
	assert_true(search_on.visible, "Search button should be visible when material is present")

	# Simulate pressing the search button
	search_on.emit_signal("pressed")
	assert_not_null(awakening_screen._drop_popup, "Drop popup instance should exist")
	assert_true(awakening_screen._drop_popup.visible, "Drop popup should be visible after pressing search button")
	assert_true(awakening_screen._drop_popup.panel.position.x >= 0.0, "Popup panel in UnitAwakening must be on screen")
	assert_true(awakening_screen._drop_popup.panel.position.y >= 0.0, "Popup panel in UnitAwakening must be on screen")
	assert_almost_eq(awakening_screen._drop_popup.panel.position.x, 60.0, 5.0, "Popup panel in UnitAwakening centered at x=60")

	awakening_screen._drop_popup.close()
	assert_false(awakening_screen._drop_popup.visible, "Drop popup should close cleanly")

	awakening_screen.get_parent().remove_child(awakening_screen)
	awakening_screen.queue_free()


## Drop rows must carry the mission id, otherwise a cleared stage can't be opened
## from the popup.
func test_drop_rows_carry_the_mission_id() -> void:
	var drop_info: Dictionary = GameDatabase.get_item_drop_locations(290010000)
	var dungeons: Array = drop_info.get("dungeons", [])
	assert_true(not dungeons.is_empty(), "Beast Meat has drop dungeons")
	for row in dungeons:
		assert_true(str(row.get("mission_id", "")).strip_edges() != "",
			"every drop row carries a mission_id")


## A mission resolves to the world/land/area/dungeon the map needs to open it,
## and an unknown id resolves to nothing.
func test_mission_resolves_to_a_map_target() -> void:
	var target: Dictionary = MissionService.get_mission_map_target("1110101")
	assert_true(bool(target.get("ok", false)), "Earth Shrine - Entrance resolves")
	assert_eq(str(target.get("world_id", "")), "1", "world 1")
	assert_eq(str(target.get("dungeon_id", "")), "11101", "Earth Shrine dungeon")
	assert_true(str(target.get("dungeon_name", "")) != "", "the dungeon name resolves")
	assert_false(bool(MissionService.get_mission_map_target("999999999").get("ok", true)),
		"an unknown mission resolves to nothing")


## A cleared stage shows up as a clickable link in the drop popup and emits the
## mission id; an uncleared one does not.
func test_cleared_stage_becomes_a_link_in_the_drop_popup() -> void:
	var saved: Dictionary = MissionService.cleared_missions.duplicate(true)
	MissionService.cleared_missions = {"1110101": {"cleared": true, "objectives": [true]}}

	var popup = ITEM_DROP_POPUP_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(popup)
	popup.open(290010000)
	assert_true("[url=mission:1110101]" in popup.modal_content.text,
		"the cleared stage is a link")

	var received: Array = []
	popup.dungeon_requested.connect(func(mission_id: String) -> void: received.append(mission_id))
	popup._on_meta_clicked("mission:1110101")
	assert_eq(received, ["1110101"], "clicking the link emits the mission id")
	popup._on_meta_clicked("mission:999999999")
	assert_eq(received.size(), 1, "an unknown mission is ignored")

	popup.get_parent().remove_child(popup)
	popup.queue_free()
	MissionService.cleared_missions = saved
