extends "res://tests/test_case.gd"

const ENHANCEMENT_SCENE: PackedScene = preload("res://features/outgame/espers/EsperEnhancementUI.tscn")
const BOARD_SCENE: PackedScene = preload("res://features/outgame/espers/SummonBoardUI.tscn")
const DETAIL_SCENE: PackedScene = preload("res://features/outgame/espers/EsperDetailUI.tscn")


func test_esper_enhancement_ui_item_and_stat_display() -> void:
	var ui: Control = ENHANCEMENT_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(ui)

	# Verify item name and icon in feeder header
	var act_item_name: Label = ui.get_node("summon_mix_act_item_bg/summon_mix_act_item_name")
	assert_eq(act_item_name.text, "ผลึกเวทมนตร์ (Magicite)", "Feed item name must be localized Magicite")

	var act_item_icon: TextureRect = ui.get_node("summon_mix_act_item_bg/summon_mix_act_item_icon")
	assert_not_null(act_item_icon.texture, "Feed item icon must have a texture")
	assert_true(act_item_icon.texture.resource_path.ends_with("item_10700.png"), "Feed item icon should be magicite")

	# Verify slot contents inside summon_mix_item
	var mix_item: Control = ui.get_node("summon_mix_item")
	var item_icon: Sprite2D = mix_item.get_node_or_null("ItemIcon") as Sprite2D
	assert_not_null(item_icon, "summon_mix_item must have an ItemIcon Sprite2D")
	assert_not_null(item_icon.texture, "ItemIcon must have a texture")

	var exp_badge: Label = mix_item.get_node_or_null("ExpBadge") as Label
	assert_not_null(exp_badge, "summon_mix_item must have an ExpBadge label")
	assert_eq(exp_badge.text, "+1,000 EXP", "ExpBadge must display +1,000 EXP")

	# Initialize with Siren (beastId 1)
	ui.init_scene({"summon_id": "1", "summon_name": "Siren"})

	var hp_label: Label = ui.get_node("summon_mix_status_bg/summon_mix_status_hp/hp_label")
	var atk_label: Label = ui.get_node("summon_mix_status_bg/summon_mix_status_atk/atk_label")
	assert_true(hp_label.text.to_int() > 0, "HP stat should be calculated and > 0 for Siren")
	assert_true(atk_label.text.to_int() > 0, "ATK stat should be calculated and > 0 for Siren")

	ui.get_parent().remove_child(ui)
	ui.queue_free()


func test_summon_board_ui_textures_colors_and_formatting() -> void:
	var board = BOARD_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(board)

	# Verify textures for node types
	var bg_atk_unlearned = board._get_node_bg_texture(12, false)
	var bg_atk_learned = board._get_node_bg_texture(12, true)
	var bg_start = board._get_node_bg_texture(0, false)
	assert_not_null(bg_atk_unlearned, "Attack background texture must exist")
	assert_not_null(bg_atk_learned, "Attack learned background texture must exist")
	assert_not_null(bg_start, "Start background texture must exist")
	assert_true(bg_atk_learned != bg_atk_unlearned, "Learned texture should differ from unlearned")

	# Verify high contrast text colors
	var color_learned: Color = board._get_node_color("learned")
	var color_learnable: Color = board._get_node_color("learnable")
	var color_unreachable: Color = board._get_node_color("unreachable")

	# Colors should have high brightness / contrast
	assert_true(color_learned.v > 0.8, "Learned color brightness must be high")
	assert_true(color_learnable.b > 0.8, "Learnable color should be vibrant cyan/blue")
	assert_true(color_unreachable.v > 0.8, "Unreachable color should be soft readable white")

	# Verify text formatting
	var node_stat: Dictionary = {"pieceType": 12, "pieceParam": 35, "costSp": 5}
	var text_learnable: String = board._format_reward(node_stat, "learnable")
	assert_true("ATK +35" in text_learnable, "Should show stat name")
	assert_true("5 SP" in text_learnable, "Should show SP cost when learnable")

	var text_learned: String = board._format_reward(node_stat, "learned")
	assert_true("ATK +35" in text_learned, "Should show stat name")
	assert_true("[ปลดแล้ว]" in text_learned, "Should show [ปลดแล้ว] when learned")

	var node_start: Dictionary = {"pieceType": 0, "pieceParam": 0, "costSp": 0}
	var text_start: String = board._format_reward(node_start, "start")
	assert_eq(text_start, "START", "START node should show START")

	board.get_parent().remove_child(board)
	board.queue_free()


func test_esper_detail_ui_modals_resist_magic_special() -> void:
	var detail = DETAIL_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(detail)

	detail.init_scene({"summon_id": "1", "summon_name": "Siren"})

	# Test 1: Resist button
	detail._on_elem_pressed()
	assert_true(detail.detail_modal.visible, "Modal should be visible after pressing Resist")
	assert_true("ความต้านทาน" in detail.modal_title.text, "Modal title should be Resistances")
	assert_true("ความต้านทานธาตุ" in detail.modal_content.text, "Content should have elemental resistances")
	assert_true("ไฟ (Fire)" in detail.modal_content.text, "Content should list Fire")
	assert_true("น้ำ (Water)" in detail.modal_content.text, "Content should list Water")
	assert_true("ความต้านทานสถานะ" in detail.modal_content.text, "Content should have status resistances")

	detail._close_modal()
	assert_false(detail.detail_modal.visible, "Modal should be hidden after close")

	# Test 2: Magic button
	detail._on_magic_pressed()
	assert_true(detail.detail_modal.visible, "Modal should be visible after pressing Magic")
	assert_true("เวทมนตร์" in detail.modal_title.text, "Modal title should be Magic")

	# Test 3: Special button
	detail._on_ability_pressed()
	assert_true(detail.detail_modal.visible, "Modal should be visible after pressing Special")
	assert_true("ความสามารถพิเศษ" in detail.modal_title.text, "Modal title should be Special Abilities")
	assert_true("Lunatic Voice" in detail.modal_content.text, "Content should include Siren's evocation Lunatic Voice")

	detail.get_parent().remove_child(detail)
	detail.queue_free()

