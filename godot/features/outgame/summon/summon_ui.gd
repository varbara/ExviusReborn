extends Control

# === Audio Paths ===
const BGM_CRYSTAL: String = "res://assets/audio/bgm/bg_Crystal.ogg"
const SFX_CRYSTAL_APPEAR: String = "res://assets/audio/sfx/se_ev_crystal_appeare.wav"
const SFX_CRYSTAL_CHANGE: String = "res://assets/audio/sfx/se_menu_change_crystal_1.wav"
const SFX_CRYSTAL_SHATTER: String = "res://assets/audio/sfx/se_ev_crystal_disappeare.wav"
const SFX_UNIT_GET_NORMAL: String = "res://assets/audio/sfx/se_battle_get_crystal_1.wav"
const SFX_UNIT_GET_RARE: String = "res://assets/audio/sfx/se_battle_get_crystal_2.wav"

# === Effekseer Crystal Paths ===
const EFK_CRYSTAL_BLUE: String = "res://assets/battle_effect/map_crystal_blue_001.efkefc"
const EFK_CRYSTAL_YELLOW: String = "res://assets/battle_effect/map_crystal_yellow_001.efkefc"
const EFK_CRYSTAL_RAINBOW: String = "res://assets/battle_effect/map_crystal_rainbow_001.efkefc"
const EFK_CRYSTAL_FIRE: String = "res://assets/battle_effect/map_crystal_fire_001.efkefc"
const EFK_CHANGE_BLUE_RAINBOW: String = "res://assets/battle_effect/map_crystal_blue_001_change_rainbow.efkefc"
const EFK_CHANGE_YELLOW_RAINBOW: String = "res://assets/battle_effect/map_crystal_yellow_001_change_rainbow.efkefc"
const EFK_CRYSTAL_EXPLODE: String = "res://assets/battle_effect/GLElenaCrystalExplode.efkefc"
const EFK_FLASH_IMPACT: String = "res://assets/battle_effect/atk_impact_001_white_flashcut.efkefc"

# === UI Textures ===
const TEX_COSMOS_BG: Texture2D = preload("res://assets/ui/common/gacha_cosmos_bg.png")
const TEX_GACHA_BG_TOP: Texture2D = preload("res://assets/ui/gacha/gacha_bg_top.tres")
const TEX_GACHA_BG_BOTTOM: Texture2D = preload("res://assets/ui/gacha/gacha_bg_bottom.tres")
const TEX_BOTTOMLINE: Texture2D = preload("res://assets/ui/common/bottomline.tres")
const TEX_HEADER_CHARA: Texture2D = preload("res://assets/ui/unit/unit_namebg_chara.tres")

const TEX_TAB_BTN_OFF: Texture2D = preload("res://assets/ui/create/cre_btn4_2.tres")
const TEX_TAB_BTN_ON: Texture2D = preload("res://assets/ui/create/cre_btn4_1.tres")

const TEX_SELECT_UNIT_BG: Texture2D = preload("res://assets/ui/gacha/gacha_select_unitbg.tres")
const TEX_ARROW_L: Texture2D = preload("res://assets/ui/gacha/gacha_arrow_gold_l.tres")
const TEX_ARROW_R: Texture2D = preload("res://assets/ui/gacha/gacha_arrow_gold_r.tres")
const TEX_BTN_RATIO_OFF: Texture2D = preload("res://assets/ui/gacha/gacha_btn_ratio_normal.tres")
const TEX_BTN_RATIO_ON: Texture2D = preload("res://assets/ui/gacha/gacha_btn_ratio_on.tres")
const TEX_MOG_BALLOON: Texture2D = preload("res://assets/ui/gacha/gacha_mogballoon_m.tres")
const TEX_MOG_PANEL: Texture2D = preload("res://assets/ui/gacha/gacha_panel_mogu.tres")

const TEX_BTN_LARGE_1: Texture2D = preload("res://assets/ui/common/button_large1.tres")
const TEX_BTN_LARGE_2: Texture2D = preload("res://assets/ui/common/button_large2.tres")
const TEX_BTN_LARGE_OFF: Texture2D = preload("res://assets/ui/common/button_large_off.tres")
const TEX_LOCK_RIBBON: Texture2D = preload("res://assets/ui/gacha/gacha_special_banner_lock_ribbon.tres")
const TEX_BTN_MINI_LONG_1: Texture2D = preload("res://assets/ui/common/button_mini_long1.tres")
const TEX_BTN_MINI_LONG_2: Texture2D = preload("res://assets/ui/common/button_mini_long2.tres")
const TEX_LABEL_SKIP: Texture2D = preload("res://assets/ui/common/minibutton_label_skip.tres")

const TEX_MOVIE_BOTTOM: Texture2D = preload("res://assets/ui/gacha/gacha_movieframe_bottom.tres")
const TEX_NUMBER_BG: Texture2D = preload("res://assets/ui/gacha/gacha_enabled_number_bg.tres")
const TEX_UNITNAME_BG: Texture2D = preload("res://assets/ui/gacha/gacha_unitname_bg.tres")
const TEX_QUOTE_BG: Texture2D = preload("res://assets/ui/gacha/gacha_textbg.tres")

const TEX_STAR: Texture2D = preload("res://assets/ui/unit/unit_raritystar.tres")
const TEX_STAR_NV: Texture2D = preload("res://assets/ui/unit/unit_raritystar_nv.tres")
const TEX_BADGE_NV: Texture2D = preload("res://assets/ui/gacha/gacha_label_raritynv.tres")
const TEX_BADGE_NEW: Texture2D = preload("res://assets/ui/common/common_label_new.tres")

# Summon Costs (Lapis)
const LAPIS_COST_SINGLE: int = 100
const LAPIS_COST_MULTI: int = 1000

enum RevealState {
	IDLE,
	CRYSTAL_DROPPING,
	CRYSTAL_WAITING_TAP,
	CRYSTAL_UPGRADING,
	CRYSTAL_SHATTERING,
	UNIT_PRESENTED
}

@onready var banner_view: Control = $BannerView
@onready var reveal_overlay: Control = $RevealOverlay
@onready var results_overlay: Control = $ResultsOverlay
@onready var pool_info_popup: Control = $PoolInfoPopup

# State
var _all_banners: Array = []
var _filtered_banners: Array = []
var _current_category: String = "all"
var _current_banner_idx: int = 0
var _last_summon_amount: int = 11
var _previous_bgm_path: String = ""
var _is_tutorial_mode: bool = false

# Banner View UI Nodes
var _tabs_container: HBoxContainer = null
var _tab_buttons: Dictionary = {}
var _ratio_btn: TextureButton = null
var _banner_title_label: Label = null
var _banner_counter_label: Label = null
var _banner_subtitle_label: Label = null
var _featured_units_container: Control = null
var _lock_overlay_container: Control = null
var _lock_req_label: Label = null
var _dots_container: HBoxContainer = null
var _pity_panel: PanelContainer = null
var _pity_label: Label = null
var _pity_progress_bar: ProgressBar = null
var _btn_pity_select: Button = null
var _mog_desc_label: Label = null
var _btn_prev_banner: TextureButton = null
var _btn_next_banner: TextureButton = null
var _btn_summon_single: TextureButton = null
var _btn_summon_multi: TextureButton = null

# Pity Unit Selection Popup Nodes
var _pity_select_popup: Control = null
var _pity_select_title: Label = null
var _pity_select_subtitle: Label = null
var _pity_select_list_vbox: VBoxContainer = null

# Insufficient Currency Popup Nodes
var _insufficient_lapis_popup: Control = null
var _insufficient_currency_popup: Control = null
var _insufficient_currency_title: Label = null
var _insufficient_currency_text: Label = null
var _insufficient_lapis_text: Label = null

# Reveal View UI Nodes & State
var _reveal_state: RevealState = RevealState.IDLE
var _summoned_units: Array = []
var _reveal_index: int = 0
var _reveal_counter_label: Label = null
var _reveal_crystal_stage: Node2D = null
var _reveal_active_emitter: Node2D = null
var _reveal_unit_holder: Control = null
var _reveal_prompt_label: Label = null
var _reveal_flash_rect: ColorRect = null
var _reveal_aura_rect: ColorRect = null
var _reveal_true_tier: int = 0
var _reveal_display_tier: int = 0
var _reveal_tween: Tween = null
var _prompt_tween: Tween = null
var _crystal_loop_timer: float = 0.0

# Results View UI Nodes
var _results_header_label: Label = null
var _results_subtitle_label: Label = null
var _results_rows_vbox: VBoxContainer = null
var _results_summon_again_label: Label = null
var _results_again_btn: TextureButton = null
var _results_ok_btn: TextureButton = null
var _results_pity_claim_btn: Button = null

# Pool Info Nodes
var _pool_info_title: Label = null
var _pool_info_text: RichTextLabel = null


func init_scene(params: Dictionary = {}) -> void:
	# STRICT ONE-TIME ONLY: If tutorial summon is already completed, tutorial mode is permanently disabled!
	if UnitService != null and bool(UnitService.get("is_tutorial_summon_done")):
		_is_tutorial_mode = false
	elif bool(params.get("is_tutorial", false)):
		_is_tutorial_mode = true
	else:
		_is_tutorial_mode = false

	if is_inside_tree() and _banner_title_label != null:
		_refresh_banner_display()


func _ready() -> void:
	if UnitService != null and bool(UnitService.get("is_tutorial_summon_done")):
		_is_tutorial_mode = false
	elif UnitService != null and not bool(UnitService.call("is_summon_system_unlocked")):
		_is_tutorial_mode = false
	else:
		_is_tutorial_mode = (UnitService != null and not bool(UnitService.get("is_tutorial_summon_done")))

	_all_banners = UnitService.get_summon_banners()
	_build_banner_view()
	_build_reveal_overlay()
	_build_results_overlay()
	_build_pool_info_popup()
	_build_pity_select_popup()
	_build_insufficient_lapis_popup()
	_select_category("all")


func _process(delta: float) -> void:
	if _reveal_state in [RevealState.CRYSTAL_DROPPING, RevealState.CRYSTAL_WAITING_TAP]:
		if is_instance_valid(_reveal_active_emitter):
			_crystal_loop_timer += delta
			var playing: bool = true
			if _reveal_active_emitter.has_method("is_playing"):
				playing = bool(_reveal_active_emitter.call("is_playing"))
			if not playing or _crystal_loop_timer >= 0.90:
				_crystal_loop_timer = 0.0
				if _reveal_active_emitter.has_method("play"):
					_reveal_active_emitter.call("play")


func _exit_tree() -> void:
	_restore_overlays_and_bgm()


# ==============================================================================
# 1. BANNER SELECTION VIEW
# ==============================================================================

func _build_banner_view() -> void:
	for child in banner_view.get_children():
		child.queue_free()

	# Top decorative frame
	var top_bg := TextureRect.new()
	top_bg.texture = TEX_GACHA_BG_TOP
	top_bg.position = Vector2(0, 0)
	top_bg.size = Vector2(640, 260)
	top_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	top_bg.modulate = Color(1, 1, 1, 0.45)
	top_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_view.add_child(top_bg)

	# Category Tabs Row (All / NV / Rare / Standard) using clean blank FFBE tab buttons
	var tabs_hbox := HBoxContainer.new()
	_tabs_container = tabs_hbox
	tabs_hbox.position = Vector2(10, 6)
	tabs_hbox.size = Vector2(620, 54)
	tabs_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs_hbox.add_theme_constant_override("separation", 6)
	banner_view.add_child(tabs_hbox)

	var tab_defs: Array[Dictionary] = [
		{"id": "all", "label": "All Rooms"},
		{"id": "nv", "label": "NV Summon"},
		{"id": "rare", "label": "Rare Summon"},
		{"id": "standard", "label": "Standard"},
	]

	for tdef in tab_defs:
		var tbtn := TextureButton.new()
		tbtn.custom_minimum_size = Vector2(148, 50)
		tbtn.ignore_texture_size = true
		tbtn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		tbtn.texture_normal = TEX_TAB_BTN_OFF
		tbtn.texture_pressed = TEX_TAB_BTN_ON
		var cat_id: String = str(tdef["id"])
		tbtn.pressed.connect(func() -> void: _select_category(cat_id))

		var tlbl := Label.new()
		tlbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tlbl.text = str(tdef["label"])
		tlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tlbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tlbl.add_theme_font_size_override("font_size", 15)
		tlbl.add_theme_color_override("font_color", Color(1.0, 0.96, 0.82))
		tlbl.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.12, 0.95))
		tlbl.add_theme_constant_override("outline_size", 5)
		tbtn.add_child(tlbl)

		tabs_hbox.add_child(tbtn)
		_tab_buttons[cat_id] = {"btn": tbtn, "lbl": tlbl}

	# Ornate Divider Line
	var top_line := TextureRect.new()
	top_line.texture = TEX_BOTTOMLINE
	top_line.position = Vector2(0, 56)
	top_line.size = Vector2(640, 16)
	top_line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_view.add_child(top_line)

	# Clean Ornate Banner Title Bar
	var title_bar := PanelContainer.new()
	title_bar.position = Vector2(12, 70)
	title_bar.size = Vector2(616, 66)
	var title_style := StyleBoxFlat.new()
	title_style.bg_color = Color(0.06, 0.10, 0.24, 0.92)
	title_style.border_color = Color(0.92, 0.76, 0.32, 1.0)
	title_style.set_border_width_all(2)
	title_style.set_corner_radius_all(8)
	title_bar.add_theme_stylebox_override("panel", title_style)
	banner_view.add_child(title_bar)

	var title_inner := Control.new()
	title_bar.add_child(title_inner)

	_banner_title_label = Label.new()
	_banner_title_label.position = Vector2(18, 4)
	_banner_title_label.size = Vector2(510, 32)
	_banner_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_title_label.add_theme_font_size_override("font_size", 22)
	_banner_title_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
	_banner_title_label.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.01, 1.0))
	_banner_title_label.add_theme_constant_override("outline_size", 6)
	title_inner.add_child(_banner_title_label)

	_banner_counter_label = Label.new()
	_banner_counter_label.position = Vector2(20, 36)
	_banner_counter_label.size = Vector2(500, 22)
	_banner_counter_label.add_theme_font_size_override("font_size", 13)
	_banner_counter_label.add_theme_color_override("font_color", Color(0.75, 0.92, 1.0))
	_banner_counter_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_banner_counter_label.add_theme_constant_override("outline_size", 4)
	title_inner.add_child(_banner_counter_label)

	# Rates / Pool Info Button on Title Bar
	var ratio_btn := TextureButton.new()
	_ratio_btn = ratio_btn
	ratio_btn.texture_normal = TEX_BTN_RATIO_OFF
	ratio_btn.texture_pressed = TEX_BTN_RATIO_ON
	ratio_btn.ignore_texture_size = true
	ratio_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ratio_btn.position = Vector2(538, -4)
	ratio_btn.size = Vector2(68, 68)
	ratio_btn.pressed.connect(_on_open_pool_info)
	title_inner.add_child(ratio_btn)

	# Main Banner Showcase Frame (clean ornate cosmic showcase without ticket watermark)
	var showcase_frame := PanelContainer.new()
	showcase_frame.position = Vector2(12, 138)
	showcase_frame.size = Vector2(616, 294)
	var show_style := StyleBoxFlat.new()
	show_style.bg_color = Color(0.05, 0.07, 0.18, 0.86)
	show_style.border_color = Color(0.88, 0.72, 0.30, 0.95)
	show_style.set_border_width_all(3)
	show_style.set_corner_radius_all(10)
	showcase_frame.add_theme_stylebox_override("panel", show_style)
	banner_view.add_child(showcase_frame)

	var showcase_inner := Control.new()
	showcase_frame.add_child(showcase_inner)

	# Cosmic shimmer top inside showcase
	var inner_glow := TextureRect.new()
	inner_glow.texture = TEX_GACHA_BG_TOP
	inner_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inner_glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	inner_glow.modulate = Color(1.0, 0.95, 1.0, 0.35)
	inner_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	showcase_inner.add_child(inner_glow)

	# Subtitle ribbon inside showcase
	var subtitle_bg := ColorRect.new()
	subtitle_bg.color = Color(0.10, 0.14, 0.34, 0.90)
	subtitle_bg.position = Vector2(16, 8)
	subtitle_bg.size = Vector2(578, 28)
	showcase_inner.add_child(subtitle_bg)

	_banner_subtitle_label = Label.new()
	_banner_subtitle_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_subtitle_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner_subtitle_label.add_theme_font_size_override("font_size", 15)
	_banner_subtitle_label.add_theme_color_override("font_color", Color(1.0, 0.90, 0.42))
	_banner_subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_banner_subtitle_label.add_theme_constant_override("outline_size", 4)
	subtitle_bg.add_child(_banner_subtitle_label)

	# Container for Featured Units on Pedestals
	_featured_units_container = Control.new()
	_featured_units_container.position = Vector2(42, 38)
	_featured_units_container.size = Vector2(526, 244)
	_featured_units_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	showcase_inner.add_child(_featured_units_container)

	# Lock Overlay Ribbon (shown when Colosseum requirement not yet met)
	_lock_overlay_container = Control.new()
	_lock_overlay_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_lock_overlay_container.visible = false
	_lock_overlay_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	showcase_inner.add_child(_lock_overlay_container)

	var lock_dim := ColorRect.new()
	lock_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lock_dim.color = Color(0.02, 0.02, 0.06, 0.62)
	lock_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay_container.add_child(lock_dim)

	var lock_ribbon := TextureRect.new()
	lock_ribbon.texture = TEX_LOCK_RIBBON
	lock_ribbon.position = Vector2(10, 82)
	lock_ribbon.size = Vector2(590, 124)
	lock_ribbon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_ribbon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lock_overlay_container.add_child(lock_ribbon)

	_lock_req_label = Label.new()
	_lock_req_label.position = Vector2(54, 180)
	_lock_req_label.size = Vector2(502, 74)
	_lock_req_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lock_req_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lock_req_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lock_req_label.add_theme_font_size_override("font_size", 16)
	_lock_req_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.45))
	_lock_req_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.98))
	_lock_req_label.add_theme_constant_override("outline_size", 6)
	_lock_overlay_container.add_child(_lock_req_label)

	# Left & Right Gold Arrows
	_btn_prev_banner = TextureButton.new()
	_btn_prev_banner.texture_normal = TEX_ARROW_L
	_btn_prev_banner.position = Vector2(2, 108)
	_btn_prev_banner.size = Vector2(48, 80)
	_btn_prev_banner.pressed.connect(func() -> void: _cycle_banner(-1))
	showcase_inner.add_child(_btn_prev_banner)

	_btn_next_banner = TextureButton.new()
	_btn_next_banner.texture_normal = TEX_ARROW_R
	_btn_next_banner.position = Vector2(560, 108)
	_btn_next_banner.size = Vector2(48, 80)
	_btn_next_banner.pressed.connect(func() -> void: _cycle_banner(1))
	showcase_inner.add_child(_btn_next_banner)

	# Page Dots Indicator
	_dots_container = HBoxContainer.new()
	_dots_container.position = Vector2(120, 435)
	_dots_container.size = Vector2(400, 10)
	_dots_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_container.add_theme_constant_override("separation", 10)
	banner_view.add_child(_dots_container)

	# Pity / Step-Up Unit Guarantee Bar + Select Button
	_pity_panel = PanelContainer.new()
	_pity_panel.position = Vector2(14, 448)
	_pity_panel.size = Vector2(612, 54)
	var pity_style := StyleBoxFlat.new()
	pity_style.bg_color = Color(0.08, 0.12, 0.28, 0.94)
	pity_style.border_color = Color(0.86, 0.70, 0.28, 0.95)
	pity_style.set_border_width_all(2)
	pity_style.set_corner_radius_all(8)
	pity_style.content_margin_left = 12
	pity_style.content_margin_right = 10
	pity_style.content_margin_top = 5
	pity_style.content_margin_bottom = 5
	_pity_panel.add_theme_stylebox_override("panel", pity_style)
	banner_view.add_child(_pity_panel)

	var pity_hbox := HBoxContainer.new()
	pity_hbox.add_theme_constant_override("separation", 12)
	_pity_panel.add_child(pity_hbox)

	var pity_left_vbox := VBoxContainer.new()
	pity_left_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pity_left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	pity_left_vbox.add_theme_constant_override("separation", 3)
	pity_hbox.add_child(pity_left_vbox)

	_pity_label = Label.new()
	_pity_label.text = "🎁 การันตีเลือกตัวละคร 4★: 0 / 10 ครั้ง"
	_pity_label.add_theme_font_size_override("font_size", 14)
	_pity_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.50))
	_pity_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_pity_label.add_theme_constant_override("outline_size", 4)
	pity_left_vbox.add_child(_pity_label)

	_pity_progress_bar = ProgressBar.new()
	_pity_progress_bar.custom_minimum_size = Vector2(0, 14)
	_pity_progress_bar.max_value = 10
	_pity_progress_bar.value = 0
	_pity_progress_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.04, 0.05, 0.12, 0.95)
	bar_bg.border_color = Color(0.35, 0.45, 0.68, 0.8)
	bar_bg.set_border_width_all(1)
	bar_bg.set_corner_radius_all(4)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.95, 0.76, 0.20, 1.0)
	bar_fill.set_corner_radius_all(4)
	_pity_progress_bar.add_theme_stylebox_override("background", bar_bg)
	_pity_progress_bar.add_theme_stylebox_override("fill", bar_fill)
	pity_left_vbox.add_child(_pity_progress_bar)

	_btn_pity_select = Button.new()
	_btn_pity_select.custom_minimum_size = Vector2(204, 40)
	_btn_pity_select.text = "★ เลือกตัวการันตี (0/10)"
	_btn_pity_select.add_theme_font_size_override("font_size", 14)
	_btn_pity_select.pressed.connect(_on_open_pity_select_modal)
	pity_hbox.add_child(_btn_pity_select)

	# Summon Buttons Row (1x Summon & 10+1 Summon)
	var summon_btns_hbox := HBoxContainer.new()
	summon_btns_hbox.position = Vector2(14, 507)
	summon_btns_hbox.size = Vector2(612, 98)
	summon_btns_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	summon_btns_hbox.add_theme_constant_override("separation", 16)
	banner_view.add_child(summon_btns_hbox)

	_btn_summon_single = _create_summon_action_button(
		"Summon 1x",
		"%d Lapis • 1 Unit (+1 Pity)" % LAPIS_COST_SINGLE,
		Color(0.85, 0.95, 1.0)
	)
	_btn_summon_single.pressed.connect(func() -> void: _perform_banner_summon(1))
	summon_btns_hbox.add_child(_btn_summon_single)

	_btn_summon_multi = _create_summon_action_button(
		"Summon 10+1",
		"%s Lapis • 11 Units (+10 Pity)" % _format_number(LAPIS_COST_MULTI),
		Color(1.0, 0.92, 0.45)
	)
	_btn_summon_multi.pressed.connect(func() -> void: _perform_banner_summon(11))
	summon_btns_hbox.add_child(_btn_summon_multi)

	# King Mog Description Area at Bottom
	var mog_balloon := TextureRect.new()
	mog_balloon.texture = TEX_MOG_BALLOON
	mog_balloon.position = Vector2(12, 610)
	mog_balloon.size = Vector2(478, 90)
	mog_balloon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner_view.add_child(mog_balloon)

	_mog_desc_label = Label.new()
	_mog_desc_label.position = Vector2(24, 10)
	_mog_desc_label.size = Vector2(420, 68)
	_mog_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mog_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_mog_desc_label.add_theme_font_size_override("font_size", 14)
	_mog_desc_label.add_theme_color_override("font_color", Color(0.18, 0.10, 0.04))
	mog_balloon.add_child(_mog_desc_label)

	var mog_sprite := TextureRect.new()
	mog_sprite.texture = TEX_MOG_PANEL
	mog_sprite.position = Vector2(486, 568)
	mog_sprite.size = Vector2(142, 148)
	mog_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mog_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner_view.add_child(mog_sprite)


func _create_summon_action_button(main_text: String, sub_text: String, main_color: Color) -> TextureButton:
	var btn := TextureButton.new()
	btn.custom_minimum_size = Vector2(296, 100)
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.texture_normal = TEX_BTN_LARGE_1
	btn.texture_pressed = TEX_BTN_LARGE_2

	var vbox := VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	var lbl_main := Label.new()
	lbl_main.text = main_text
	lbl_main.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_main.add_theme_font_size_override("font_size", 22)
	lbl_main.add_theme_color_override("font_color", main_color)
	lbl_main.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.15, 1.0))
	lbl_main.add_theme_constant_override("outline_size", 6)
	vbox.add_child(lbl_main)

	var lbl_sub := Label.new()
	lbl_sub.text = sub_text
	lbl_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_sub.add_theme_font_size_override("font_size", 13)
	lbl_sub.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	lbl_sub.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	lbl_sub.add_theme_constant_override("outline_size", 4)
	vbox.add_child(lbl_sub)

	return btn


func _select_category(cat_id: String) -> void:
	_current_category = cat_id
	_all_banners = UnitService.get_summon_banners()
	if cat_id == "all":
		_filtered_banners = _all_banners.duplicate()
	else:
		_filtered_banners = _all_banners.filter(func(b: Variant) -> bool:
			return b is Dictionary and str(b.get("category", "rare")) == cat_id
		)
	if _filtered_banners.is_empty():
		_filtered_banners = _all_banners.duplicate()

	_current_banner_idx = 0
	for k in _tab_buttons.keys():
		var info: Dictionary = _tab_buttons[k]
		var btn: TextureButton = info["btn"]
		var lbl: Label = info["lbl"]
		var active: bool = (k == cat_id)
		btn.texture_normal = TEX_TAB_BTN_ON if active else TEX_TAB_BTN_OFF
		lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.45) if active else Color(0.82, 0.86, 0.94))

	_refresh_banner_display()


func _cycle_banner(delta: int) -> void:
	if _filtered_banners.size() <= 1:
		return
	_current_banner_idx = posmod(_current_banner_idx + delta, _filtered_banners.size())
	_refresh_banner_display()


func _format_number(n: int) -> String:
	var s: String = str(n)
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = s[i] + result
		count += 1
	return result


func _get_summon_currency(banner: Dictionary) -> String:
	if _is_tutorial_mode:
		return "lapis"
	if UnitService != null and UnitService.has_method("get_banner_currency"):
		return UnitService.get_banner_currency(banner)
	return str(banner.get("cost_currency", "lapis")).to_lower()


func _get_currency_name(currency: String) -> String:
	if currency == "gil":
		return "Gil"
	return "Lapis"


func _get_summon_cost(banner: Dictionary, amount: int) -> int:
	if _is_tutorial_mode:
		return 0
	if UnitService != null and UnitService.has_method("get_banner_cost"):
		return int(UnitService.get_banner_cost(banner, amount))
	var curr: String = _get_summon_currency(banner)
	var default_single: int = 200 if curr == "gil" else LAPIS_COST_SINGLE
	var default_multi: int = 2000 if curr == "gil" else LAPIS_COST_MULTI
	if amount == 1:
		return int(banner.get("cost_single", default_single))
	return int(banner.get("cost_multi", default_multi))


func _get_current_banner() -> Dictionary:
	if _filtered_banners.is_empty():
		return {}
	_current_banner_idx = clampi(_current_banner_idx, 0, _filtered_banners.size() - 1)
	return _filtered_banners[_current_banner_idx]


func _refresh_banner_display() -> void:
	if _is_tutorial_mode:
		_refresh_tutorial_banner_display()
		return

	if _tabs_container != null:
		_tabs_container.visible = true
	if _ratio_btn != null:
		_ratio_btn.visible = true
	if _dots_container != null:
		_dots_container.visible = true
	if _btn_summon_multi != null:
		_btn_summon_multi.visible = true

	var banner: Dictionary = _get_current_banner()
	if banner.is_empty():
		return

	var unlock_status: Dictionary = UnitService.get_banner_unlock_status(banner)
	var is_unlocked: bool = bool(unlock_status.get("unlocked", true))
	var req_label: String = str(unlock_status.get("required_label", "Unlocked from Start"))
	var cur_label: String = str(unlock_status.get("current_label", "BGN Rank D"))

	_banner_title_label.text = str(banner.get("title", "Rare Summon"))
	var pool_ids: Array = banner.get("unit_pool", []) if banner.get("unit_pool") is Array else []
	var pool_desc: String = "Custom Room (%d Units)" % pool_ids.size() if not pool_ids.is_empty() else "Full %s Pool" % str(banner.get("pool_type", "all")).to_upper()
	var req_tag: String = "Unlocked" if is_unlocked else "Req: Colosseum %s" % req_label
	_banner_counter_label.text = "Room %d / %d  •  %s  •  %s" % [_current_banner_idx + 1, _filtered_banners.size(), pool_desc, req_tag]
	_banner_subtitle_label.text = str(banner.get("subtitle", "Featured Units Rate Up!"))
	_mog_desc_label.text = str(banner.get("description", "Summon powerful allies to join your party, kupo!"))

	_btn_prev_banner.visible = _filtered_banners.size() > 1
	_btn_next_banner.visible = _filtered_banners.size() > 1

	# Update Lock Overlay & Summon Buttons
	if _lock_overlay_container != null:
		_lock_overlay_container.visible = not is_unlocked
		if not is_unlocked and _lock_req_label != null:
			_lock_req_label.text = "Reach Colosseum [%s] to Unlock!\n(Current Colosseum: %s)" % [req_label, cur_label]

	# Update Pity / Step-Up Guarantee Panel
	var pity_info: Dictionary = UnitService.get_banner_pity_info(banner)
	var pity_enabled: bool = bool(pity_info.get("enabled", false))

	var single_cost: int = _get_summon_cost(banner, 1)
	var multi_cost: int = _get_summon_cost(banner, 11)
	var curr_name: String = _get_currency_name(_get_summon_currency(banner))
	var single_sub: String = ""
	var multi_sub: String = ""
	if pity_enabled:
		single_sub = "%s %s • 1 Unit (+1 Pity)" % [_format_number(single_cost), curr_name]
		multi_sub = "%s %s • 11 Units (+10 Pity)" % [_format_number(multi_cost), curr_name]
	else:
		single_sub = "%s %s • 1 Unit" % [_format_number(single_cost), curr_name]
		multi_sub = "%s %s • 11 Units" % [_format_number(multi_cost), curr_name]

	_update_summon_button_lock_state(_btn_summon_single, is_unlocked, single_sub, "Locked (%s)" % req_label)
	_update_summon_button_lock_state(_btn_summon_multi, is_unlocked, multi_sub, "Locked (%s)" % req_label)

	if _pity_panel != null:
		_pity_panel.visible = pity_enabled
		if pity_enabled:
			var cur_pity: int = int(pity_info.get("current", 0))
			var req_pity: int = maxi(1, int(pity_info.get("required", 100)))
			var pity_r: int = int(pity_info.get("pity_rarity", 4))
			var can_claim: bool = bool(pity_info.get("can_claim", false))
			var r_str: String = "NV" if pity_r >= 7 else "%d★" % pity_r
			if _pity_label != null:
				if can_claim:
					_pity_label.text = "🎁 การันตีครบแล้ว! (%d / %d) — กดเลือกตัวละคร %s ได้เลย!" % [cur_pity, req_pity, r_str]
					_pity_label.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
				else:
					var multi_left: int = ceili(float(maxi(0, req_pity - cur_pity)) / 10.0)
					_pity_label.text = "🎁 การันตีเลือกตัว %s: %d / %d (กด 10+1 อีก %d รอบ)" % [r_str, cur_pity, req_pity, multi_left]
					_pity_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.50))
			if _pity_progress_bar != null:
				_pity_progress_bar.max_value = req_pity
				_pity_progress_bar.value = mini(cur_pity, req_pity)
			if _btn_pity_select != null:
				_btn_pity_select.disabled = not is_unlocked
				if can_claim:
					_btn_pity_select.text = "🎁 เลือกตัวละคร %s ฟรี!" % r_str
					_btn_pity_select.modulate = Color(1.0, 0.95, 0.55)
				else:
					_btn_pity_select.text = "★ ดู/เลือกตัว %s (%d/%d)" % [r_str, cur_pity, req_pity]
					_btn_pity_select.modulate = Color(0.90, 0.94, 1.0)

	# Page dots
	for child in _dots_container.get_children():
		child.queue_free()
	for i in range(_filtered_banners.size()):
		var dot := ColorRect.new()
		var is_cur: bool = (i == _current_banner_idx)
		dot.custom_minimum_size = Vector2(20 if is_cur else 10, 8)
		dot.color = Color(1.0, 0.85, 0.25, 1.0) if is_cur else Color(0.45, 0.5, 0.65, 0.7)
		_dots_container.add_child(dot)

	# Featured units on pedestals
	for child in _featured_units_container.get_children():
		child.queue_free()

	var featured_ids: Array = banner.get("featured_units", []) if banner.get("featured_units") is Array else []
	if featured_ids.is_empty() and not pool_ids.is_empty():
		featured_ids = pool_ids.slice(0, 3)

	var count: int = mini(featured_ids.size(), 3)
	var area_w: float = _featured_units_container.size.x
	for idx in range(count):
		var uid: int = int(featured_ids[idx])
		var udata: Dictionary = GameDatabase.get_unit(uid)
		if udata.is_empty():
			continue
		var slot_x: float = (area_w / float(count)) * (float(idx) + 0.5) - 76.0
		var slot_y: float = 16.0 if (count == 3 and idx == 1) else 28.0
		var card: Control = _create_unit_pedestal_card(udata, "small", true, false, true)
		card.position = Vector2(slot_x, slot_y)
		_featured_units_container.add_child(card)



func _refresh_tutorial_banner_display() -> void:
	if _tabs_container != null:
		_tabs_container.visible = false
	if _ratio_btn != null:
		_ratio_btn.visible = false
	if _btn_prev_banner != null:
		_btn_prev_banner.visible = false
	if _btn_next_banner != null:
		_btn_next_banner.visible = false
	if _dots_container != null:
		_dots_container.visible = false
	if _pity_panel != null:
		_pity_panel.visible = false
	if _lock_overlay_container != null:
		_lock_overlay_container.visible = false

	if _banner_title_label != null:
		_banner_title_label.text = "First Vision Summon (อัญเชิญวิชั่นครั้งแรก)"
	if _banner_counter_label != null:
		_banner_counter_label.text = "บทเรียนการอัญเชิญ • สุ่มฟรี 1 ครั้งแรก!"
	if _banner_subtitle_label != null:
		_banner_subtitle_label.text = "ลาสเวลล์: 'เอาล่ะ เรน... ลองอัญเชิญวิชั่นดูสิ!'"
	if _mog_desc_label != null:
		_mog_desc_label.text = "นี่คือการอัญเชิญวิชั่นครั้งแรกของคุณตามคำแนะนำของลาสเวลล์! อัญเชิญฟรี 1 ครั้งแรกเพื่อรับเพื่อนร่วมทางคนแรก คูโปะ!"

	# Show starter featured heroes on pedestals (WoL 201000104, Cecil 204000103, Locke 206000203)
	if _featured_units_container != null:
		for child in _featured_units_container.get_children():
			child.queue_free()

		var starter_featured: Array[int] = [201000104, 204000103, 206000203]
		var count: int = starter_featured.size()
		var area_w: float = _featured_units_container.size.x
		for idx in range(count):
			var uid: int = starter_featured[idx]
			var udata: Dictionary = GameDatabase.get_unit(uid)
			if udata.is_empty():
				continue
			var slot_x: float = (area_w / float(count)) * (float(idx) + 0.5) - 76.0
			var slot_y: float = 16.0 if idx == 1 else 28.0
			var card: Control = _create_unit_pedestal_card(udata, "small", true, false, true)
			card.position = Vector2(slot_x, slot_y)
			_featured_units_container.add_child(card)

	# Buttons: Hide multi, show single Free 1x
	if _btn_summon_multi != null:
		_btn_summon_multi.visible = false
	if _btn_summon_single != null:
		_btn_summon_single.visible = true
		_update_summon_button_lock_state(_btn_summon_single, true, "FREE • รับเพื่อนร่วมทางคนแรก!", "")


func _update_summon_button_lock_state(btn: TextureButton, is_unlocked: bool, unlocked_sub: String, locked_sub: String) -> void:
	if btn == null:
		return
	btn.disabled = not is_unlocked
	btn.texture_normal = TEX_BTN_LARGE_1 if is_unlocked else TEX_BTN_LARGE_OFF
	btn.texture_disabled = TEX_BTN_LARGE_OFF
	var vbox: Node = btn.get_child(0) if btn.get_child_count() > 0 else null
	if vbox != null and vbox.get_child_count() >= 2:
		var lbl_main: Label = vbox.get_child(0) as Label
		var lbl_sub: Label = vbox.get_child(1) as Label
		if lbl_main != null:
			lbl_main.modulate = Color(1, 1, 1, 1) if is_unlocked else Color(0.65, 0.65, 0.72, 0.9)
		if lbl_sub != null:
			lbl_sub.text = unlocked_sub if is_unlocked else locked_sub
			lbl_sub.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0) if is_unlocked else Color(1.0, 0.65, 0.55))


# ==============================================================================
# 2. SHARED PEDESTAL & UNIT ILLUSTRATION BUILDER
# ==============================================================================

func _get_pedestal_texture(rarity: int, is_nv: int, size_mode: String) -> Texture2D:
	var r_key: String = "rarenv" if (is_nv != 0 or rarity >= 7) else "rare%d" % clampi(rarity, 1, 7)
	var path: String = "res://assets/ui/unit/unit_charastand_%s_%s.tres" % [r_key, size_mode]
	if ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D
	var fallback: String = "res://assets/ui/unit/unit_charastand_%s.tres" % size_mode
	return ResourceLoader.load(fallback) as Texture2D


func _create_unit_pedestal_card(unit_data: Dictionary, size_mode: String, show_nameplate: bool, show_new_badge: bool, show_stars: bool = true) -> Control:
	var is_large: bool = (size_mode == "large")
	var card_size: Vector2 = Vector2(260, 280) if is_large else Vector2(152, 200)
	var root := Control.new()
	root.custom_minimum_size = card_size
	root.size = card_size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rarity: int = int(unit_data.get("current_rarity", unit_data.get("rare", 3)))
	var is_nv: int = int(unit_data.get("isNv", 0))
	var unit_id: int = int(unit_data.get("unitId", unit_data.get("unit_id", 0)))

	var ped_size: Vector2 = Vector2(240, 120) if is_large else Vector2(142, 82)
	var ped_pos: Vector2 = Vector2((card_size.x - ped_size.x) * 0.5, card_size.y - ped_size.y - (18.0 if not show_nameplate else 52.0))
	var pedestal := TextureRect.new()
	pedestal.texture = _get_pedestal_texture(rarity, is_nv, size_mode)
	pedestal.position = ped_pos
	pedestal.size = ped_size
	pedestal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pedestal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pedestal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(pedestal)

	# Unit illustration sprite positioned onto pedestal
	var ills_path: String = "res://assets/unit_illustrations/unit_ills_%d.png" % unit_id
	if ResourceLoader.exists(ills_path):
		var tex: Texture2D = ResourceLoader.load(ills_path) as Texture2D
		if tex != null:
			var sprite := TextureRect.new()
			sprite.texture = tex
			sprite.size = tex.get_size()
			sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var offset_str: String = str(unit_data.get("spriteOffset", "0:0:100"))
			var parts: PackedStringArray = offset_str.split(":")
			var x_off: float = float(parts[0]) if parts.size() > 0 and parts[0].is_valid_float() else 0.0
			var y_off: float = float(parts[1]) if parts.size() > 1 and parts[1].is_valid_float() else 0.0
			var raw_scale: float = (float(parts[2]) / 100.0) if parts.size() > 2 and parts[2].is_valid_float() else 1.0

			var spr_scale: float = clampf(raw_scale * (1.35 if is_large else 0.90), 0.72, 1.85)
			sprite.scale = Vector2(spr_scale, spr_scale)

			var ped_anchor := Vector2(ped_size.x * 0.5, ped_size.y * 0.62)
			var spr_bottom_center := Vector2(sprite.size.x * 0.5 - x_off, sprite.size.y - y_off) * spr_scale
			sprite.position = ped_anchor - spr_bottom_center
			pedestal.add_child(sprite)

	# Rarity stars & NV badge row at the bottom rim of the pedestal
	if show_stars:
		var stars_hbox := HBoxContainer.new()
		stars_hbox.position = Vector2(0, ped_pos.y + ped_size.y - 10)
		stars_hbox.size = Vector2(card_size.x, 20)
		stars_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		stars_hbox.add_theme_constant_override("separation", 1)
		stars_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(stars_hbox)

		if is_nv != 0 or rarity >= 7:
			var nv_badge := TextureRect.new()
			nv_badge.texture = TEX_BADGE_NV
			nv_badge.custom_minimum_size = Vector2(68, 18)
			nv_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			nv_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stars_hbox.add_child(nv_badge)
		else:
			var star_cnt: int = clampi(rarity, 1, 7)
			for _s in range(star_cnt):
				var st := TextureRect.new()
				st.texture = TEX_STAR
				st.custom_minimum_size = Vector2(15, 15)
				st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				stars_hbox.add_child(st)

	# Unit Nameplate
	if show_nameplate:
		var name_bg := ColorRect.new()
		name_bg.color = Color(0.03, 0.05, 0.14, 0.88)
		name_bg.position = Vector2(4, card_size.y - 24)
		name_bg.size = Vector2(card_size.x - 8, 22)
		name_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(name_bg)

		var name_lbl := Label.new()
		name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		name_lbl.text = str(unit_data.get("unitName", "Unknown"))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.clip_text = true
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.97, 0.85))
		name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
		name_lbl.add_theme_constant_override("outline_size", 4)
		name_bg.add_child(name_lbl)

	# NEW! Badge
	if show_new_badge and bool(unit_data.get("is_new", false)):
		var new_rect := TextureRect.new()
		new_rect.texture = TEX_BADGE_NEW
		new_rect.position = Vector2(4, 14)
		new_rect.size = Vector2(54, 20)
		new_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		root.add_child(new_rect)

	return root


# ==============================================================================
# 3. SUMMON EXECUTION & INTERACTIVE CRYSTAL REVEAL SEQUENCE
# ==============================================================================

func _perform_banner_summon(amount: int) -> void:
	if _is_tutorial_mode:
		if UnitService != null and bool(UnitService.get("is_tutorial_summon_done")):
			_is_tutorial_mode = false
			_refresh_banner_display()
			return
		_last_summon_amount = 1
		var result: Dictionary = UnitService.perform_tutorial_summon()
		_summoned_units = result.get("summoned", [])
		if _summoned_units.is_empty():
			return
		_start_crystal_reveal_sequence()
		return

	var banner: Dictionary = _get_current_banner()
	if banner.is_empty():
		return

	var unlock_status: Dictionary = UnitService.get_banner_unlock_status(banner)
	if not bool(unlock_status.get("unlocked", true)):
		return

	# Currency check (Lapis or Gil)
	var cost: int = _get_summon_cost(banner, amount)
	var curr: String = _get_summon_currency(banner)

	if curr == "gil":
		var current_gil: int = int(PlayerProfile.gil) if PlayerProfile != null else 0
		if current_gil < cost:
			_show_insufficient_currency_dialog("gil", cost, current_gil)
			return
		if PlayerProfile != null and cost > 0:
			PlayerProfile.deduct_gil(cost)
	else:
		var current_lapis: int = int(PlayerProfile.lapis) if PlayerProfile != null else 0
		if current_lapis < cost:
			_show_insufficient_currency_dialog("lapis", cost, current_lapis)
			return
		if PlayerProfile != null and cost > 0:
			PlayerProfile.deduct_lapis(cost)

	_last_summon_amount = amount
	var result: Dictionary = UnitService.summon_from_banner(banner, amount)
	if result.has("error"):
		push_warning("Summon error: %s" % str(result.get("error")))
		if PlayerProfile != null and cost > 0:
			if curr == "gil":
				PlayerProfile.add_gil(cost)
			else:
				PlayerProfile.add_lapis(cost)
		return

	_summoned_units = result.get("summoned", [])
	if _summoned_units.is_empty():
		if PlayerProfile != null and cost > 0:
			if curr == "gil":
				PlayerProfile.add_gil(cost)
			else:
				PlayerProfile.add_lapis(cost)
		return

	_start_crystal_reveal_sequence()


func _build_reveal_overlay() -> void:
	for child in reveal_overlay.get_children():
		child.queue_free()

	# Fullscreen Cosmic Background
	var bg := TextureRect.new()
	bg.texture = TEX_COSMOS_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	reveal_overlay.add_child(bg)

	# Subtle Rarity Aura Backdrop
	_reveal_aura_rect = ColorRect.new()
	_reveal_aura_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_aura_rect.color = Color(0.1, 0.3, 0.8, 0.0)
	_reveal_aura_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(_reveal_aura_rect)

	# Clean Top & Bottom Decorative Bars
	var top_bar := ColorRect.new()
	top_bar.color = Color(0.02, 0.04, 0.12, 0.82)
	top_bar.position = Vector2(0, 0)
	top_bar.size = Vector2(640, 74)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(top_bar)

	var top_line := TextureRect.new()
	top_line.texture = TEX_BOTTOMLINE
	top_line.position = Vector2(0, 68)
	top_line.size = Vector2(640, 14)
	top_line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(top_line)

	var bot_bar := TextureRect.new()
	bot_bar.texture = TEX_MOVIE_BOTTOM
	bot_bar.position = Vector2(0, 894)
	bot_bar.size = Vector2(640, 66)
	bot_bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bot_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(bot_bar)

	# Stage for 3D Effekseer Crystal Emitters
	_reveal_crystal_stage = Node2D.new()
	_reveal_crystal_stage.position = Vector2(0, 0)
	reveal_overlay.add_child(_reveal_crystal_stage)

	# Holder for Revealed Unit Presentation (Pedestal, Nameplate, Quote Box)
	_reveal_unit_holder = Control.new()
	_reveal_unit_holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_unit_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(_reveal_unit_holder)

	# Tap Prompt Label
	_reveal_prompt_label = Label.new()
	_reveal_prompt_label.position = Vector2(0, 848)
	_reveal_prompt_label.size = Vector2(640, 38)
	_reveal_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reveal_prompt_label.add_theme_font_size_override("font_size", 20)
	_reveal_prompt_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
	_reveal_prompt_label.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.15, 1.0))
	_reveal_prompt_label.add_theme_constant_override("outline_size", 6)
	_reveal_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(_reveal_prompt_label)

	# Fullscreen Tap Catcher Button (below Skip Button)
	var tap_catcher := Button.new()
	tap_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tap_catcher.flat = true
	tap_catcher.focus_mode = Control.FOCUS_NONE
	tap_catcher.modulate = Color(1, 1, 1, 0)
	tap_catcher.pressed.connect(_on_reveal_screen_tapped)
	reveal_overlay.add_child(tap_catcher)

	# Top-Left Pull Counter Badge
	var counter_bg := TextureRect.new()
	counter_bg.texture = TEX_NUMBER_BG
	counter_bg.position = Vector2(16, 18)
	counter_bg.size = Vector2(210, 36)
	counter_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	counter_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(counter_bg)

	_reveal_counter_label = Label.new()
	_reveal_counter_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reveal_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_reveal_counter_label.add_theme_font_size_override("font_size", 16)
	_reveal_counter_label.add_theme_color_override("font_color", Color(0.9, 0.96, 1.0))
	_reveal_counter_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_reveal_counter_label.add_theme_constant_override("outline_size", 4)
	counter_bg.add_child(_reveal_counter_label)

	# Top-Right SKIP Button
	var skip_btn := TextureButton.new()
	skip_btn.texture_normal = TEX_BTN_MINI_LONG_1
	skip_btn.texture_pressed = TEX_BTN_MINI_LONG_2
	skip_btn.ignore_texture_size = true
	skip_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	skip_btn.position = Vector2(476, 8)
	skip_btn.size = Vector2(148, 56)
	skip_btn.pressed.connect(_on_skip_reveal_pressed)
	reveal_overlay.add_child(skip_btn)

	var skip_icon := TextureRect.new()
	skip_icon.texture = TEX_LABEL_SKIP
	skip_icon.position = Vector2(28, 16)
	skip_icon.size = Vector2(92, 24)
	skip_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	skip_btn.add_child(skip_icon)

	# White Screen Flash Overlay (Topmost inside RevealOverlay)
	_reveal_flash_rect = ColorRect.new()
	_reveal_flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_flash_rect.color = Color(1, 1, 1, 0)
	_reveal_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reveal_overlay.add_child(_reveal_flash_rect)


func _start_crystal_reveal_sequence() -> void:
	_hide_persistent_bars()
	if get_node_or_null("/root/AudioService") != null:
		if _previous_bgm_path == "":
			_previous_bgm_path = AudioService.current_music_path()
		AudioService.play_music(BGM_CRYSTAL)

	results_overlay.hide()
	reveal_overlay.show()
	_reveal_index = 0
	_present_crystal_at_index(_reveal_index)


func _get_crystal_tier_for_unit(unit_data: Dictionary) -> int:
	var rarity: int = int(unit_data.get("current_rarity", unit_data.get("rare", 3)))
	var is_nv: int = int(unit_data.get("isNv", 0))
	if is_nv != 0 or rarity >= 7:
		return 3 # Red NV Crystal
	elif rarity >= 5:
		return 2 # Rainbow Crystal
	elif rarity == 4:
		return 1 # Gold Crystal
	return 0 # Blue Crystal


func _get_crystal_effect_path(tier: int) -> String:
	match tier:
		3: return EFK_CRYSTAL_FIRE
		2: return EFK_CRYSTAL_RAINBOW
		1: return EFK_CRYSTAL_YELLOW
		_: return EFK_CRYSTAL_BLUE


func _get_tier_aura_color(tier: int) -> Color:
	match tier:
		3: return Color(1.0, 0.15, 0.25, 0.22)
		2: return Color(0.95, 0.45, 1.0, 0.20)
		1: return Color(1.0, 0.82, 0.20, 0.16)
		_: return Color(0.20, 0.55, 1.0, 0.14)


func _clear_crystal_stage() -> void:
	for child in _reveal_crystal_stage.get_children():
		child.queue_free()
	_reveal_active_emitter = null


func _spawn_effekseer_emitter(efk_path: String, pos: Vector2, sc: Vector2 = Vector2(3.2, 3.2), loop_effect: bool = false) -> Node2D:
	if not ClassDB.class_exists("EffekseerEmitter2D") or not ResourceLoader.exists(efk_path):
		return null
	var emitter: Node2D = ClassDB.instantiate("EffekseerEmitter2D") as Node2D
	emitter.set("effect", ResourceLoader.load(efk_path))
	emitter.position = pos
	emitter.scale = sc
	emitter.set("autoplay", true)
	_reveal_crystal_stage.add_child(emitter)
	if loop_effect and emitter.has_signal("finished"):
		emitter.connect("finished", func() -> void:
			if is_instance_valid(emitter) and _reveal_state in [RevealState.CRYSTAL_DROPPING, RevealState.CRYSTAL_WAITING_TAP]:
				if emitter.has_method("play"):
					emitter.call("play")
		)
	if emitter.has_method("play"):
		emitter.call("play")
	return emitter


func _present_crystal_at_index(idx: int) -> void:
	if idx >= _summoned_units.size():
		_show_summon_results_screen()
		return

	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()

	_clear_crystal_stage()
	for child in _reveal_unit_holder.get_children():
		child.queue_free()

	var unit_data: Dictionary = _summoned_units[idx]
	_reveal_counter_label.text = "CRYSTAL  %d / %d" % [idx + 1, _summoned_units.size()]

	_reveal_true_tier = _get_crystal_tier_for_unit(unit_data)
	# 28% chance for 4★/5★/NV crystal to start one tier lower and upgrade on tap!
	if _reveal_true_tier >= 1 and randf() < 0.28:
		_reveal_display_tier = _reveal_true_tier - 1
	else:
		_reveal_display_tier = _reveal_true_tier

	_reveal_aura_rect.color = _get_tier_aura_color(_reveal_display_tier)
	_reveal_flash_rect.color = Color(1, 1, 1, 0)

	# Play crystal appear sound
	if get_node_or_null("/root/AudioService") != null:
		AudioService.play_sfx(SFX_CRYSTAL_APPEAR)

	# Spawn descending 3D crystal
	_reveal_state = RevealState.CRYSTAL_DROPPING
	_crystal_loop_timer = 0.0
	_set_prompt_text("✦  A CRYSTAL DESCENDS...  ✦")

	var efk_path: String = _get_crystal_effect_path(_reveal_display_tier)
	_reveal_active_emitter = _spawn_effekseer_emitter(efk_path, Vector2(320, -80), Vector2(3.2, 3.2), true)

	_reveal_tween = create_tween()
	if _reveal_active_emitter != null:
		_reveal_tween.tween_property(_reveal_active_emitter, "position", Vector2(320, 420), 0.48).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_reveal_tween.tween_interval(0.25)

	_reveal_tween.tween_callback(func() -> void:
		_reveal_state = RevealState.CRYSTAL_WAITING_TAP
		_set_prompt_text("✦  TAP SCREEN TO SHATTER CRYSTAL  ✦")
	)


func _on_reveal_screen_tapped() -> void:
	match _reveal_state:
		RevealState.CRYSTAL_DROPPING:
			if _reveal_tween and _reveal_tween.is_valid():
				_reveal_tween.kill()
			if _reveal_active_emitter != null:
				_reveal_active_emitter.position = Vector2(320, 420)
			_reveal_state = RevealState.CRYSTAL_WAITING_TAP
			_shatter_or_upgrade_current_crystal()

		RevealState.CRYSTAL_WAITING_TAP:
			_shatter_or_upgrade_current_crystal()

		RevealState.CRYSTAL_UPGRADING, RevealState.CRYSTAL_SHATTERING:
			if _reveal_tween and _reveal_tween.is_valid():
				_reveal_tween.kill()
			_present_unit_for_current_crystal()

		RevealState.UNIT_PRESENTED:
			_reveal_index += 1
			if _reveal_index >= _summoned_units.size():
				_show_summon_results_screen()
			else:
				_present_crystal_at_index(_reveal_index)


func _shatter_or_upgrade_current_crystal() -> void:
	if _reveal_display_tier < _reveal_true_tier:
		# Fake-out Crystal Upgrade Animation!
		_reveal_state = RevealState.CRYSTAL_UPGRADING
		_set_prompt_text("✦  THE CRYSTAL IS RESONATING...!  ✦")
		if get_node_or_null("/root/AudioService") != null:
			AudioService.play_sfx(SFX_CRYSTAL_CHANGE)

		var change_efk: String = EFK_CHANGE_BLUE_RAINBOW if _reveal_display_tier == 0 else EFK_CHANGE_YELLOW_RAINBOW
		_spawn_effekseer_emitter(change_efk, Vector2(320, 420), Vector2(3.2, 3.2))

		_reveal_display_tier = _reveal_true_tier
		_reveal_tween = create_tween()
		_reveal_tween.tween_property(_reveal_flash_rect, "color", Color(1.0, 0.95, 0.65, 0.85), 0.18)
		_reveal_tween.tween_callback(func() -> void:
			_clear_crystal_stage()
			_reveal_aura_rect.color = _get_tier_aura_color(_reveal_true_tier)
			_reveal_active_emitter = _spawn_effekseer_emitter(_get_crystal_effect_path(_reveal_true_tier), Vector2(320, 420), Vector2(3.4, 3.4))
		)
		_reveal_tween.tween_property(_reveal_flash_rect, "color", Color(1.0, 1.0, 1.0, 0.0), 0.25)
		_reveal_tween.tween_interval(0.35)
		_reveal_tween.tween_callback(func() -> void:
			_execute_crystal_shatter()
		)
	else:
		_execute_crystal_shatter()


func _execute_crystal_shatter() -> void:
	_reveal_state = RevealState.CRYSTAL_SHATTERING
	_set_prompt_text("")

	if get_node_or_null("/root/AudioService") != null:
		AudioService.play_sfx(SFX_CRYSTAL_SHATTER)

	_spawn_effekseer_emitter(EFK_CRYSTAL_EXPLODE, Vector2(320, 420), Vector2(6.0, 6.0))
	_spawn_effekseer_emitter(EFK_FLASH_IMPACT, Vector2(320, 420), Vector2(8.0, 8.0))

	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()

	_reveal_tween = create_tween()
	_reveal_tween.tween_property(_reveal_flash_rect, "color", Color(1.0, 1.0, 1.0, 1.0), 0.22)
	_reveal_tween.tween_callback(func() -> void:
		_present_unit_for_current_crystal()
	)
	_reveal_tween.tween_property(_reveal_flash_rect, "color", Color(1.0, 1.0, 1.0, 0.0), 0.30)


func _present_unit_for_current_crystal() -> void:
	_reveal_state = RevealState.UNIT_PRESENTED
	_clear_crystal_stage()
	_reveal_flash_rect.color = Color(1, 1, 1, 0)

	for child in _reveal_unit_holder.get_children():
		child.queue_free()

	if _reveal_index >= _summoned_units.size():
		_show_summon_results_screen()
		return

	var unit_data: Dictionary = _summoned_units[_reveal_index]
	var rarity: int = int(unit_data.get("current_rarity", unit_data.get("rare", 3)))
	var is_nv: int = int(unit_data.get("isNv", 0))
	var unit_id: int = int(unit_data.get("unitId", unit_data.get("unit_id", 0)))
	var job_id: int = int(unit_data.get("jobId", 0))

	if get_node_or_null("/root/AudioService") != null:
		var get_sfx: String = SFX_UNIT_GET_RARE if (is_nv != 0 or rarity >= 5) else SFX_UNIT_GET_NORMAL
		AudioService.play_sfx(get_sfx)

	_reveal_aura_rect.color = _get_tier_aura_color(_get_crystal_tier_for_unit(unit_data))

	# 1. Large Pedestal + Unit Illustration (without duplicate stars on pedestal)
	var large_card: Control = _create_unit_pedestal_card(unit_data, "large", false, false, false)
	large_card.position = Vector2(190, 200)
	large_card.pivot_offset = large_card.size * 0.5
	large_card.scale = Vector2(1.25, 1.25)
	_reveal_unit_holder.add_child(large_card)

	var pop_tw: Tween = create_tween()
	pop_tw.tween_property(large_card, "scale", Vector2(1.0, 1.0), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# 2. Unit Nameplate (gacha_unitname_bg.tres: 330 x 102)
	var nameplate := TextureRect.new()
	nameplate.texture = TEX_UNITNAME_BG
	nameplate.position = Vector2(130, 534)
	nameplate.size = Vector2(380, 112)
	nameplate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	nameplate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_unit_holder.add_child(nameplate)

	# Job Name
	var job_name: String = GameDatabase.get_job_name(job_id) if job_id > 0 else "Vision Ally"
	if job_name == "":
		job_name = "Vision Ally"
	var job_lbl := Label.new()
	job_lbl.position = Vector2(16, 10)
	job_lbl.size = Vector2(348, 24)
	job_lbl.text = job_name
	job_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	job_lbl.add_theme_font_size_override("font_size", 15)
	job_lbl.add_theme_color_override("font_color", Color(0.72, 0.92, 1.0))
	job_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	job_lbl.add_theme_constant_override("outline_size", 4)
	nameplate.add_child(job_lbl)

	# Unit Name
	var uname_lbl := Label.new()
	uname_lbl.position = Vector2(12, 34)
	uname_lbl.size = Vector2(356, 36)
	uname_lbl.text = str(unit_data.get("unitName", "Unknown"))
	uname_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	uname_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	uname_lbl.add_theme_font_size_override("font_size", 23)
	uname_lbl.add_theme_color_override("font_color", Color(1.0, 0.97, 0.82))
	uname_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.02, 1.0))
	uname_lbl.add_theme_constant_override("outline_size", 6)
	nameplate.add_child(uname_lbl)

	# Rarity Stars row inside Nameplate
	var stars_row := HBoxContainer.new()
	stars_row.position = Vector2(12, 74)
	stars_row.size = Vector2(356, 28)
	stars_row.alignment = BoxContainer.ALIGNMENT_CENTER
	stars_row.add_theme_constant_override("separation", 3)
	nameplate.add_child(stars_row)

	if is_nv != 0 or rarity >= 7:
		var nv_b := TextureRect.new()
		nv_b.texture = TEX_BADGE_NV
		nv_b.custom_minimum_size = Vector2(96, 24)
		stars_row.add_child(nv_b)
	else:
		for _s in range(clampi(rarity, 1, 7)):
			var st := TextureRect.new()
			st.texture = TEX_STAR
			st.custom_minimum_size = Vector2(22, 22)
			st.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			st.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			stars_row.add_child(st)

	# NEW! Badge on Nameplate if first time obtaining unit
	if bool(unit_data.get("is_new", false)):
		var new_badge := TextureRect.new()
		new_badge.texture = TEX_BADGE_NEW
		new_badge.position = Vector2(304, -10)
		new_badge.size = Vector2(74, 28)
		new_badge.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		new_badge.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		nameplate.add_child(new_badge)

	# 3. Summon Dialogue Quote Box (gacha_textbg.tres: 640 x 144)
	var quote_box := TextureRect.new()
	quote_box.texture = TEX_QUOTE_BG
	quote_box.position = Vector2(0, 676)
	quote_box.size = Vector2(640, 150)
	quote_box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	quote_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_unit_holder.add_child(quote_box)

	var quote_text: String = GameDatabase.get_unit_summon_text(unit_id)
	if quote_text.strip_edges() == "":
		quote_text = "\"My strength is yours to command. Let us carve a new future together!\""

	var quote_lbl := Label.new()
	quote_lbl.position = Vector2(36, 18)
	quote_lbl.size = Vector2(568, 114)
	quote_lbl.text = quote_text
	quote_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quote_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quote_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	quote_lbl.add_theme_font_size_override("font_size", 17)
	quote_lbl.add_theme_color_override("font_color", Color(0.96, 0.96, 1.0))
	quote_lbl.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.08, 0.95))
	quote_lbl.add_theme_constant_override("outline_size", 5)
	quote_box.add_child(quote_lbl)

	if _reveal_index + 1 < _summoned_units.size():
		_set_prompt_text("✦  TAP FOR NEXT CRYSTAL (%d / %d)  ▶" % [_reveal_index + 2, _summoned_units.size()])
	else:
		_set_prompt_text("✦  TAP TO VIEW SUMMON RESULTS  ▶")


func _set_prompt_text(txt: String) -> void:
	if _reveal_prompt_label == null:
		return
	_reveal_prompt_label.text = txt
	if _prompt_tween and _prompt_tween.is_valid():
		_prompt_tween.kill()
	_reveal_prompt_label.modulate = Color(1, 1, 1, 1)
	if txt != "":
		_prompt_tween = create_tween().set_loops()
		_prompt_tween.tween_property(_reveal_prompt_label, "modulate:a", 0.35, 0.55)
		_prompt_tween.tween_property(_reveal_prompt_label, "modulate:a", 1.0, 0.55)


func _on_skip_reveal_pressed() -> void:
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_clear_crystal_stage()
	_show_summon_results_screen()


# ==============================================================================
# 4. SUMMON RESULTS SUMMARY SCREEN (10+1 GRID)
# ==============================================================================

func _build_results_overlay() -> void:
	for child in results_overlay.get_children():
		child.queue_free()

	# Cosmic Background
	var bg := TextureRect.new()
	bg.texture = TEX_COSMOS_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	results_overlay.add_child(bg)

	# Top Decorative Header (Clean ornate header without baked-in text)
	var top_decor := TextureRect.new()
	top_decor.texture = TEX_GACHA_BG_TOP
	top_decor.position = Vector2(0, 0)
	top_decor.size = Vector2(640, 180)
	top_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	top_decor.modulate = Color(1, 1, 1, 0.55)
	results_overlay.add_child(top_decor)

	var title_plate := PanelContainer.new()
	title_plate.position = Vector2(12, 12)
	title_plate.size = Vector2(616, 66)
	var res_title_style := StyleBoxFlat.new()
	res_title_style.bg_color = Color(0.06, 0.10, 0.24, 0.94)
	res_title_style.border_color = Color(0.92, 0.76, 0.32, 1.0)
	res_title_style.set_border_width_all(2)
	res_title_style.set_corner_radius_all(8)
	title_plate.add_theme_stylebox_override("panel", res_title_style)
	results_overlay.add_child(title_plate)

	var title_inner := Control.new()
	title_plate.add_child(title_inner)

	var header_lbl := Label.new()
	_results_header_label = header_lbl
	header_lbl.position = Vector2(0, 4)
	header_lbl.size = Vector2(612, 32)
	header_lbl.text = "UNITS OBTAINED"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_lbl.add_theme_font_size_override("font_size", 23)
	header_lbl.add_theme_color_override("font_color", Color(1.0, 0.94, 0.55))
	header_lbl.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.01, 1.0))
	header_lbl.add_theme_constant_override("outline_size", 6)
	title_inner.add_child(header_lbl)

	_results_subtitle_label = Label.new()
	_results_subtitle_label.position = Vector2(0, 36)
	_results_subtitle_label.size = Vector2(612, 22)
	_results_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_results_subtitle_label.add_theme_font_size_override("font_size", 14)
	_results_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.94, 1.0))
	_results_subtitle_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_results_subtitle_label.add_theme_constant_override("outline_size", 4)
	title_inner.add_child(_results_subtitle_label)

	# Scrollable / Centered Rows Container for 10+1 Pedestals
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(6, 84)
	scroll.size = Vector2(628, 736)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	results_overlay.add_child(scroll)

	_results_rows_vbox = VBoxContainer.new()
	_results_rows_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_results_rows_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_results_rows_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_results_rows_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(_results_rows_vbox)

	# Bottom Decorative Bar + Buttons
	var bot_decor := TextureRect.new()
	bot_decor.texture = TEX_GACHA_BG_BOTTOM
	bot_decor.position = Vector2(0, 824)
	bot_decor.size = Vector2(640, 136)
	bot_decor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	results_overlay.add_child(bot_decor)

	var btns_hbox := HBoxContainer.new()
	btns_hbox.position = Vector2(14, 838)
	btns_hbox.size = Vector2(612, 100)
	btns_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btns_hbox.add_theme_constant_override("separation", 16)
	results_overlay.add_child(btns_hbox)

	var btn_again := _create_summon_action_button(
		"Summon Again",
		"FREE Summon",
		Color(1.0, 0.94, 0.50)
	)
	_results_again_btn = btn_again
	btn_again.pressed.connect(func() -> void: _perform_banner_summon(_last_summon_amount))
	btns_hbox.add_child(btn_again)
	_results_summon_again_label = btn_again.get_child(0).get_child(1) as Label

	var btn_ok := _create_summon_action_button(
		"OK / Back",
		"Return to Summon Rooms",
		Color(0.88, 0.96, 1.0)
	)
	_results_ok_btn = btn_ok
	btn_ok.pressed.connect(_on_close_results_pressed)
	btns_hbox.add_child(btn_ok)


func _show_summon_results_screen() -> void:
	_reveal_state = RevealState.IDLE
	reveal_overlay.hide()
	results_overlay.show()
	_refresh_banner_display()

	if get_node_or_null("/root/AudioService") != null:
		AudioService.play_sfx(SFX_UNIT_GET_RARE)

	for child in _results_rows_vbox.get_children():
		child.queue_free()

	if _is_tutorial_mode:
		if _results_header_label != null:
			_results_header_label.text = "FIRST ALLY JOINED!"
		if _results_subtitle_label != null:
			_results_subtitle_label.text = "ยินดีด้วย! คุณปลดล็อกระบบอัญเชิญ (Summon) และได้รับวิชั่นแรกมาร่วมทีมแล้ว!"
		if _results_again_btn != null:
			_results_again_btn.visible = false
		if _results_ok_btn != null:
			var ok_vbox: Node = _results_ok_btn.get_child(0) if _results_ok_btn.get_child_count() > 0 else null
			if ok_vbox != null and ok_vbox.get_child_count() >= 2:
				var l0: Label = ok_vbox.get_child(0) as Label
				var l1: Label = ok_vbox.get_child(1) as Label
				if l0 != null: l0.text = "OK"
				if l1 != null: l1.text = "เข้าสู่หน้าตู้สุ่มปกติ"

		if not _summoned_units.is_empty():
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			_results_rows_vbox.add_child(row)
			var single_card: Control = _create_unit_pedestal_card(_summoned_units[0], "large", true, true, true)
			row.add_child(single_card)
		return

	if _results_header_label != null:
		_results_header_label.text = "UNITS OBTAINED"
	if _results_again_btn != null:
		_results_again_btn.visible = true
	if _results_ok_btn != null:
		var ok_vbox: Node = _results_ok_btn.get_child(0) if _results_ok_btn.get_child_count() > 0 else null
		if ok_vbox != null and ok_vbox.get_child_count() >= 2:
			var l0: Label = ok_vbox.get_child(0) as Label
			var l1: Label = ok_vbox.get_child(1) as Label
			if l0 != null: l0.text = "OK / Back"
			if l1 != null: l1.text = "Return to Summon Rooms"

	# Count rarity breakdown
	var nv_cnt: int = 0
	var r5_cnt: int = 0
	var r4_cnt: int = 0
	var r3_cnt: int = 0
	var r12_cnt: int = 0
	for u in _summoned_units:
		var r: int = int(u.get("current_rarity", u.get("rare", 3)))
		var nv: int = int(u.get("isNv", 0))
		if nv != 0 or r >= 7:
			nv_cnt += 1
		elif r >= 5:
			r5_cnt += 1
		elif r == 4:
			r4_cnt += 1
		elif r == 3:
			r3_cnt += 1
		else:
			r12_cnt += 1

	var banner: Dictionary = _get_current_banner()
	var b_title: String = str(banner.get("title", "Summon"))
	_results_subtitle_label.text = "%s  •  NV:%d | 5★:%d | 4★:%d | 3★:%d | 1-2★:%d" % [b_title, nv_cnt, r5_cnt, r4_cnt, r3_cnt, r12_cnt]
	if _results_summon_again_label != null:
		var again_cost: int = _get_summon_cost(banner, _last_summon_amount)
		var curr_name: String = _get_currency_name(_get_summon_currency(banner))
		if _last_summon_amount == 1:
			_results_summon_again_label.text = "%s %s • Pull 1x Again" % [_format_number(again_cost), curr_name]
		else:
			_results_summon_again_label.text = "%s %s • Pull 10+1 Again" % [_format_number(again_cost), curr_name]

	# Show a prominent Claim Guaranteed Unit button on Results screen if Pity is ready!
	var pity_info: Dictionary = UnitService.get_banner_pity_info(banner)
	if bool(pity_info.get("can_claim", false)):
		var pity_r: int = int(pity_info.get("pity_rarity", 4))
		var r_str: String = "NV" if pity_r >= 7 else "%d★" % pity_r
		var claim_row := HBoxContainer.new()
		claim_row.alignment = BoxContainer.ALIGNMENT_CENTER
		_results_rows_vbox.add_child(claim_row)
		var claim_btn := Button.new()
		claim_btn.custom_minimum_size = Vector2(540, 42)
		claim_btn.text = "🎁 การันตีครบ %d/%d ครั้งแล้ว! คลิกเพื่อเลือกตัวละคร %s ฟรี 1 ตัว!" % [
			int(pity_info.get("current", 10)),
			int(pity_info.get("required", 10)),
			r_str
		]
		claim_btn.add_theme_font_size_override("font_size", 16)
		claim_btn.modulate = Color(1.0, 0.95, 0.50)
		claim_btn.pressed.connect(func() -> void:
			_on_close_results_pressed()
			_on_open_pity_select_modal()
		)
		claim_row.add_child(claim_btn)

	# Single pull vs Multi pull layout
	if _summoned_units.size() == 1:
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		_results_rows_vbox.add_child(row)
		var single_card: Control = _create_unit_pedestal_card(_summoned_units[0], "large", true, true, true)
		row.add_child(single_card)
		return

	# Arrange 11 (or N) units in neat rows of up to 4 per row (e.g. 4 + 4 + 3 for 11 units)
	var per_row: int = 4
	var current_row: HBoxContainer = null
	for i in range(_summoned_units.size()):
		if i % per_row == 0:
			current_row = HBoxContainer.new()
			current_row.alignment = BoxContainer.ALIGNMENT_CENTER
			current_row.add_theme_constant_override("separation", 4)
			_results_rows_vbox.add_child(current_row)

		var u_card: Control = _create_unit_pedestal_card(_summoned_units[i], "small", true, true, true)
		u_card.custom_minimum_size = Vector2(152, 200)
		current_row.add_child(u_card)


func _on_close_results_pressed() -> void:
	var was_tutorial: bool = _is_tutorial_mode
	if _is_tutorial_mode:
		_is_tutorial_mode = false
		UnitService.complete_tutorial_summon()

	results_overlay.hide()
	reveal_overlay.hide()
	if was_tutorial:
		_select_category("all")
	else:
		_refresh_banner_display()
	_restore_overlays_and_bgm()


func _hide_persistent_bars() -> void:
	var ui_mgr: Node = get_node_or_null("/root/UIManager")
	if ui_mgr != null:
		if ui_mgr.get("top_header") != null:
			ui_mgr.top_header.hide()
		if ui_mgr.get("bottom_nav") != null:
			ui_mgr.bottom_nav.hide()


func _restore_overlays_and_bgm() -> void:
	var ui_mgr: Node = get_node_or_null("/root/UIManager")
	if ui_mgr != null and ui_mgr.has_method("_update_overlays"):
		ui_mgr.call("_update_overlays")
	elif get_node_or_null("/root/AudioService") != null and _previous_bgm_path != "":
		AudioService.play_music(_previous_bgm_path)
	_previous_bgm_path = ""


# ==============================================================================
# 5. DROP RATES & ROOM UNIT POOL POPUP
# ==============================================================================

func _build_pool_info_popup() -> void:
	for child in pool_info_popup.get_children():
		child.queue_free()

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.78)
	pool_info_popup.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.position = Vector2(36, 130)
	panel.size = Vector2(568, 700)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.09, 0.20, 0.97)
	style.border_color = Color(0.85, 0.72, 0.32, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	panel.add_theme_stylebox_override("panel", style)
	pool_info_popup.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	_pool_info_title = Label.new()
	_pool_info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pool_info_title.add_theme_font_size_override("font_size", 22)
	_pool_info_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	vbox.add_child(_pool_info_title)

	_pool_info_text = RichTextLabel.new()
	_pool_info_text.bbcode_enabled = true
	_pool_info_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pool_info_text.add_theme_font_size_override("normal_font_size", 16)
	vbox.add_child(_pool_info_text)

	var close_btn := TextureButton.new()
	close_btn.custom_minimum_size = Vector2(200, 64)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.texture_normal = TEX_BTN_MINI_LONG_1
	close_btn.texture_pressed = TEX_BTN_MINI_LONG_2
	close_btn.pressed.connect(func() -> void: pool_info_popup.hide())
	vbox.add_child(close_btn)

	var close_lbl := Label.new()
	close_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_lbl.text = "CLOSE"
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_lbl.add_theme_font_size_override("font_size", 18)
	close_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	close_lbl.add_theme_constant_override("outline_size", 5)
	close_btn.add_child(close_lbl)


func _on_open_pool_info() -> void:
	var banner: Dictionary = _get_current_banner()
	if banner.is_empty():
		return

	_pool_info_title.text = "%s — Drop Rates & Pool" % str(banner.get("title", "Summon"))
	var unlock_status: Dictionary = UnitService.get_banner_unlock_status(banner)
	var pity_info: Dictionary = UnitService.get_banner_pity_info(banner)
	var rates: Dictionary = banner.get("rates", {}) if banner.get("rates") is Dictionary else {}
	var lines: PackedStringArray = []
	lines.append("[color=#ffd866][b]■ Colosseum Unlock Condition[/b][/color]")
	if bool(unlock_status.get("unlocked", true)):
		lines.append("  • [color=#88ff88]Status: UNLOCKED[/color] (Required: %s)" % str(unlock_status.get("required_label", "Unlocked from Start")))
	else:
		lines.append("  • [color=#ff6666]Status: LOCKED[/color] — Requires Colosseum [b]%s[/b] (Current: %s)" % [
			str(unlock_status.get("required_label", "")),
			str(unlock_status.get("current_label", ""))
		])
	lines.append("")
	if bool(pity_info.get("enabled", false)):
		var pr: int = int(pity_info.get("pity_rarity", 4))
		var pr_str: String = "NV" if pr >= 7 else "%d★" % pr
		lines.append("[color=#ffd866][b]■ Step-Up Pity Guarantee (การันตีเลือกตัวละคร)[/b][/color]")
		lines.append("  • สุ่มครบทุกๆ [b]%d ครั้ง[/b] เลือกตัวละครระดับ [color=#ffe066][b]%s[/b][/color] ได้ 1 ตัวฟรี! (สะสมปัจจุบัน: %d/%d)" % [
			int(pity_info.get("required", 10)),
			pr_str,
			int(pity_info.get("current", 0)),
			int(pity_info.get("required", 10))
		])
		lines.append("")
	lines.append("[color=#ffd866][b]■ Rarity Drop Rates[/b][/color]")
	lines.append("  • [color=#ff6677]Neo Vision / 7★ (Red Crystal):[/color] %d%%" % int(rates.get("7", 0)))
	lines.append("  • [color=#ee88ff]5★ Base (Rainbow Crystal):[/color] %d%%" % int(rates.get("5", 0)))
	lines.append("  • [color=#ffe066]4★ Base (Gold Crystal):[/color] %d%%" % int(rates.get("4", 5)))
	lines.append("  • [color=#66bbff]3★ Base (Blue Crystal):[/color] %d%%" % int(rates.get("3", 15)))
	lines.append("  • [color=#aaccff]1★-2★ Base (Standard Adventurers):[/color] %d%%" % int(rates.get("1_2", rates.get("2", 80))))
	lines.append("  • [color=#88ff88]Featured Unit Rate-Up Chance:[/color] %d%%" % int(rates.get("featured_boost", 35)))
	lines.append("")

	var featured_ids: Array = banner.get("featured_units", []) if banner.get("featured_units") is Array else []
	if not featured_ids.is_empty():
		lines.append("[color=#ffd866][b]■ Featured Rate-Up Units (%d)[/b][/color]" % featured_ids.size())
		for fid in featured_ids:
			var u: Dictionary = GameDatabase.get_unit(int(fid))
			if not u.is_empty():
				var r_str: String = "NV" if int(u.get("isNv", 0)) != 0 else "%d★" % int(u.get("rare", 5))
				lines.append("  ★ [b]%s[/b] (%s) [color=#8899aa][ID: %d][/color]" % [str(u.get("unitName", "")), r_str, int(fid)])
		lines.append("")

	var custom_pool: Array = banner.get("unit_pool", []) if banner.get("unit_pool") is Array else []
	if not custom_pool.is_empty():
		lines.append("[color=#ffd866][b]■ Custom Room Unit Pool (%d Units)[/b][/color]" % custom_pool.size())
		for pid in custom_pool:
			var pu: Dictionary = GameDatabase.get_unit(int(pid))
			if not pu.is_empty():
				var pr_str: String = "NV" if int(pu.get("isNv", 0)) != 0 else "%d★" % int(pu.get("rare", 3))
				lines.append("  • %s (%s) [color=#8899aa][ID: %d][/color]" % [str(pu.get("unitName", "")), pr_str, int(pid)])
	else:
		lines.append("[color=#ffd866][b]■ Room Pool Mode[/b][/color]")
		lines.append("  • Includes all summonable [b]%s[/b] units in database (including 1★-2★ Standard Adventurers)." % str(banner.get("pool_type", "all")).to_upper())

	_pool_info_text.text = "\n".join(lines)
	pool_info_popup.show()


# ==============================================================================
# 6. PITY / STEP-UP GUARANTEED UNIT SELECTION POPUP
# ==============================================================================

func _build_pity_select_popup() -> void:
	if _pity_select_popup != null and is_instance_valid(_pity_select_popup):
		_pity_select_popup.queue_free()

	_pity_select_popup = Control.new()
	_pity_select_popup.name = "PitySelectPopup"
	_pity_select_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pity_select_popup.visible = false
	add_child(_pity_select_popup)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.82)
	_pity_select_popup.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.position = Vector2(24, 100)
	panel.size = Vector2(592, 760)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.19, 0.98)
	style.border_color = Color(0.95, 0.78, 0.28, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	_pity_select_popup.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	_pity_select_title = Label.new()
	_pity_select_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pity_select_title.add_theme_font_size_override("font_size", 20)
	_pity_select_title.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45))
	_pity_select_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_pity_select_title.add_theme_constant_override("outline_size", 5)
	vbox.add_child(_pity_select_title)

	_pity_select_subtitle = Label.new()
	_pity_select_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_pity_select_subtitle.add_theme_font_size_override("font_size", 14)
	_pity_select_subtitle.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0))
	vbox.add_child(_pity_select_subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	_pity_select_list_vbox = VBoxContainer.new()
	_pity_select_list_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pity_select_list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(_pity_select_list_vbox)

	var close_btn := TextureButton.new()
	close_btn.custom_minimum_size = Vector2(200, 58)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.texture_normal = TEX_BTN_MINI_LONG_1
	close_btn.texture_pressed = TEX_BTN_MINI_LONG_2
	close_btn.pressed.connect(func() -> void: _pity_select_popup.hide())
	vbox.add_child(close_btn)

	var close_lbl := Label.new()
	close_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_lbl.text = "CLOSE"
	close_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	close_lbl.add_theme_font_size_override("font_size", 17)
	close_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	close_lbl.add_theme_constant_override("outline_size", 5)
	close_btn.add_child(close_lbl)


func _on_open_pity_select_modal() -> void:
	var banner: Dictionary = _get_current_banner()
	if banner.is_empty():
		return

	var pity_info: Dictionary = UnitService.get_banner_pity_info(banner)
	var cur_pity: int = int(pity_info.get("current", 0))
	var req_pity: int = maxi(1, int(pity_info.get("required", 10)))
	var pity_r: int = int(pity_info.get("pity_rarity", 4))
	var can_claim: bool = bool(pity_info.get("can_claim", false))
	var r_str: String = "NV" if pity_r >= 7 else "%d★" % pity_r

	_pity_select_title.text = "🎁 เลือกตัวละครการันตี %s (%s)" % [r_str, str(banner.get("title", ""))]
	if can_claim:
		_pity_select_subtitle.text = "แต้มสะสมครบแล้ว (%d / %d)! กดปุ่ม [เลือกตัวนี้] เพื่อรับตัวละครที่ต้องการได้ทันที!" % [cur_pity, req_pity]
		_pity_select_subtitle.add_theme_color_override("font_color", Color(0.55, 1.0, 0.55))
	else:
		_pity_select_subtitle.text = "สะสมการสุ่มครบ %d ครั้งเพื่อเลือกตัวละครฟรี 1 ตัว (ปัจจุบัน: %d / %d ครั้ง)" % [req_pity, cur_pity, req_pity]
		_pity_select_subtitle.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))

	for child in _pity_select_list_vbox.get_children():
		child.queue_free()

	var selectable_units: Array = UnitService.get_banner_selectable_units(banner)
	var owned_set: Dictionary = UnitService._get_owned_unit_id_set()

	for u in selectable_units:
		var uid: int = int(u.get("unitId", 0))
		var uname: String = str(u.get("unitName", "Unknown"))
		var urare: int = int(u.get("minRare", pity_r))
		var is_nv: bool = int(u.get("isNv", 0)) != 0 or urare >= 7
		var is_feat: bool = bool(u.get("is_featured", false))
		var is_owned: bool = owned_set.has(uid)

		var row_panel := PanelContainer.new()
		var r_style := StyleBoxFlat.new()
		r_style.bg_color = Color(0.14, 0.18, 0.38, 0.95) if is_feat else Color(0.08, 0.11, 0.25, 0.92)
		r_style.border_color = Color(1.0, 0.82, 0.25, 0.95) if is_feat else Color(0.28, 0.38, 0.62, 0.85)
		r_style.set_border_width_all(2 if is_feat else 1)
		r_style.set_corner_radius_all(8)
		r_style.content_margin_left = 10
		r_style.content_margin_right = 10
		r_style.content_margin_top = 6
		r_style.content_margin_bottom = 6
		row_panel.add_theme_stylebox_override("panel", r_style)
		_pity_select_list_vbox.add_child(row_panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		row_panel.add_child(hbox)

		# Unit Icon
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(56, 56)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var icon_path: String = "res://assets/unit_icons/unit_icon_%d.png" % uid
		if ResourceLoader.exists(icon_path):
			icon_rect.texture = load(icon_path)
		hbox.add_child(icon_rect)

		# Name + Rarity + Badges
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_child(info_vbox)

		var name_lbl := Label.new()
		var feat_prefix: String = "★ [FEATURED] " if is_feat else ""
		var own_suffix: String = "  (มีแล้ว)" if is_owned else "  [NEW!]"
		name_lbl.text = "%s%s (%s)%s" % [feat_prefix, uname, "NV" if is_nv else "%d★" % urare, own_suffix]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45) if is_feat else Color(0.95, 0.97, 1.0))
		info_vbox.add_child(name_lbl)

		var id_lbl := Label.new()
		var quote_preview: String = GameDatabase.get_unit_summon_text(uid).replace("\n", " ")
		if quote_preview.length() > 48:
			quote_preview = quote_preview.substr(0, 48) + "..."
		id_lbl.text = "ID: %d  •  \"%s\"" % [uid, quote_preview] if quote_preview != "" else "ID: %d" % uid
		id_lbl.add_theme_font_size_override("font_size", 12)
		id_lbl.add_theme_color_override("font_color", Color(0.68, 0.78, 0.92))
		info_vbox.add_child(id_lbl)

		# Select Button
		var pick_btn := Button.new()
		pick_btn.custom_minimum_size = Vector2(124, 42)
		pick_btn.disabled = not can_claim
		pick_btn.text = "🎁 เลือกตัวนี้" if can_claim else "ยังไม่ครบ (%d/%d)" % [cur_pity, req_pity]
		pick_btn.add_theme_font_size_override("font_size", 14)
		if can_claim:
			pick_btn.modulate = Color(0.65, 1.0, 0.65)
		var captured_uid: int = uid
		pick_btn.pressed.connect(func() -> void: _on_claim_pity_unit(captured_uid))
		hbox.add_child(pick_btn)

	_pity_select_popup.show()


func _on_claim_pity_unit(chosen_unit_id: int) -> void:
	var banner: Dictionary = _get_current_banner()
	if banner.is_empty():
		return

	var res: Dictionary = UnitService.claim_banner_pity_unit(banner, chosen_unit_id)
	if res.has("error"):
		return

	var summoned: Array = res.get("summoned", [])
	if summoned.is_empty():
		return

	_pity_select_popup.hide()
	_refresh_banner_display()

	_summoned_units = summoned
	_reveal_index = 0
	_start_crystal_reveal_sequence()


# ==============================================================================
# 7. INSUFFICIENT CURRENCY POPUP
# ==============================================================================

func _build_insufficient_lapis_popup() -> void:
	if _insufficient_currency_popup != null and is_instance_valid(_insufficient_currency_popup):
		_insufficient_currency_popup.queue_free()

	_insufficient_currency_popup = Control.new()
	_insufficient_currency_popup.name = "InsufficientCurrencyPopup"
	_insufficient_currency_popup.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_insufficient_currency_popup.visible = false
	_insufficient_currency_popup.z_index = 150
	add_child(_insufficient_currency_popup)
	_insufficient_lapis_popup = _insufficient_currency_popup

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0, 0, 0, 0.82)
	_insufficient_currency_popup.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.position = Vector2(40, 310)
	panel.size = Vector2(560, 280)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.18, 0.96)
	style.border_color = Color(0.90, 0.35, 0.25, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	panel.add_theme_stylebox_override("panel", style)
	_insufficient_currency_popup.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = "💎 เพชร (Lapis) ไม่เพียงพอ! 💎"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	title_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title_lbl.add_theme_constant_override("outline_size", 5)
	vbox.add_child(title_lbl)
	_insufficient_currency_title = title_lbl

	var text_lbl := Label.new()
	text_lbl.text = ""
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.add_theme_font_size_override("font_size", 16)
	text_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	vbox.add_child(text_lbl)
	_insufficient_currency_text = text_lbl
	_insufficient_lapis_text = text_lbl

	var ok_btn := TextureButton.new()
	ok_btn.texture_normal = TEX_BTN_LARGE_1
	ok_btn.texture_pressed = TEX_BTN_LARGE_2
	ok_btn.custom_minimum_size = Vector2(240, 52)
	ok_btn.ignore_texture_size = true
	ok_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ok_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_btn.pressed.connect(func() -> void: _insufficient_currency_popup.hide())
	vbox.add_child(ok_btn)

	var btn_lbl := Label.new()
	btn_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn_lbl.text = "ตกลง (OK)"
	btn_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn_lbl.add_theme_font_size_override("font_size", 18)
	btn_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
	ok_btn.add_child(btn_lbl)


func _show_insufficient_currency_dialog(currency: String, cost: int, current_balance: int) -> void:
	if _insufficient_currency_popup == null or not is_instance_valid(_insufficient_currency_popup):
		_build_insufficient_lapis_popup()

	var is_gil: bool = (currency == "gil")
	var curr_name: String = "Gil" if is_gil else "Lapis"
	var missing: int = maxi(0, cost - current_balance)

	if _insufficient_currency_title != null:
		if is_gil:
			_insufficient_currency_title.text = "🪙 เงินกิล (Gil) ไม่เพียงพอ! 🪙"
			_insufficient_currency_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
		else:
			_insufficient_currency_title.text = "💎 เพชร (Lapis) ไม่เพียงพอ! 💎"
			_insufficient_currency_title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))

	if _insufficient_currency_text != null:
		var advice: String = "กรุณาสะสม Gil เพิ่มเติมจากการลงด่านหรือขายไอเทม คูโปะ!" if is_gil else "กรุณาสะสม Lapis เพิ่มเติมจากการผ่านด่านหรือภารกิจ คูโปะ!"
		_insufficient_currency_text.text = "ต้องการ: %s %s\nคุณมีเพียง: %s %s (ขาดอีก %s %s)\n\n%s" % [
			_format_number(cost),
			curr_name,
			_format_number(current_balance),
			curr_name,
			_format_number(missing),
			curr_name,
			advice
		]
	_insufficient_currency_popup.show()


func _show_insufficient_lapis_dialog(cost: int, current_lapis: int) -> void:
	_show_insufficient_currency_dialog("lapis", cost, current_lapis)
