class_name RecollectionScreen
extends Control

## RecollectionScreen — Book of Recollection / Story Replay System
## Flow:
##   View 1: Chapter Select (Season 1 chapters with authentic 640x240 plates)
##   View 2: Episode Select (Episodes / Maps under selected chapter)
##   View 3: Scene Select (Scenes with Opening/Battle Yes/No matching FFBE)
## All gated by story progression (cleared missions / switches).

enum ViewMode {
	CHAPTERS,
	EPISODES,
	SCENES
}

var current_view: ViewMode = ViewMode.CHAPTERS
var current_season_id: int = 10
var current_chapter: Dictionary = {}
var current_map: Dictionary = {}
var pending_event: Dictionary = {}

@onready var back_button: TextureButton = %BackButton
@onready var title_label: Label = %Title

@onready var scroll_container: ScrollContainer = %ScrollContainer
@onready var chapter_list: VBoxContainer = %ChapterList
@onready var episode_list: VBoxContainer = %EpisodeList
@onready var scene_list: VBoxContainer = %SceneList
@onready var empty_notice: Label = %EmptyNotice

@onready var action_dialog: Control = %ActionDialog
@onready var action_title: Label = %ActionTitle
@onready var btn_play_cutscene: Button = %BtnPlayCutscene
@onready var btn_start_battle: Button = %BtnStartBattle
@onready var btn_cancel_action: Button = %BtnCancelAction


func _ready() -> void:
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

	if btn_play_cutscene:
		btn_play_cutscene.pressed.connect(_on_dialog_play_cutscene)
	if btn_start_battle:
		btn_start_battle.pressed.connect(_on_dialog_start_battle)
	if btn_cancel_action:
		btn_cancel_action.pressed.connect(_on_dialog_cancel)

	# Click outside action dialog to cancel
	if action_dialog:
		action_dialog.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed:
				action_dialog.visible = false
		)

	# Ensure touch/mouse drag scrolling helper is attached
	if scroll_container and not scroll_container.has_node("_TouchDragScroll"):
		var helper: Node = Node.new()
		helper.name = "_TouchDragScroll"
		helper.set_script(preload("res://features/shared/touch_drag_scroll.gd"))
		scroll_container.add_child(helper, false, Node.INTERNAL_MODE_BACK)

	if action_dialog:
		action_dialog.visible = false
	show_chapter_view(current_season_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		get_viewport().set_input_as_handled()


func _on_back_pressed() -> void:
	if action_dialog and action_dialog.visible:
		action_dialog.visible = false
		return

	match current_view:
		ViewMode.SCENES:
			show_episode_view(current_chapter)
		ViewMode.EPISODES:
			show_chapter_view(current_season_id)
		ViewMode.CHAPTERS:
			if UIManager and UIManager.get("_menu_stack") != null and UIManager._menu_stack.size() > 1:
				UIManager.pop()
			else:
				UIManager.set_root("game_ui")


# === View 1: Chapter Select ===

func show_chapter_view(season_id: int) -> void:
	current_view = ViewMode.CHAPTERS
	current_season_id = season_id

	if title_label:
		title_label.text = "Book of Recollection"

	chapter_list.visible = true
	episode_list.visible = false
	scene_list.visible = false
	empty_notice.visible = false

	for child in chapter_list.get_children():
		child.queue_free()

	var chapters: Array = PlaybackService.get_chapters(season_id) if PlaybackService else []
	var shown_count: int = 0

	for ch in chapters:
		# Check unlock progress: only show unlocked chapters
		var unlocked: bool = PlaybackService.is_chapter_unlocked(ch) if PlaybackService else true
		if not unlocked:
			continue

		shown_count += 1
		var btn: TextureButton = TextureButton.new()
		btn.custom_minimum_size = Vector2(640, 240)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.mouse_filter = Control.MOUSE_FILTER_PASS

		var plate_path: String = ch.get("plate_texture", "")
		if ResourceLoader.exists(plate_path):
			btn.texture_normal = load(plate_path)

		var captured_ch: Dictionary = ch
		btn.pressed.connect(func() -> void: _on_chapter_selected(captured_ch))
		chapter_list.add_child(btn)

	if shown_count == 0:
		empty_notice.text = "ไม่มีบทที่ปลดล็อคในขณะนี้\n(กรุณาเล่นเนื้อเรื่องเพื่อปลดล็อค)"
		empty_notice.visible = true

	scroll_container.scroll_vertical = 0


func _on_chapter_selected(chapter: Dictionary) -> void:
	show_episode_view(chapter)


func _on_season_prev() -> void:
	pass


func _on_season_next() -> void:
	pass


# === View 2: Episode Select ===

func show_episode_view(chapter: Dictionary) -> void:
	current_view = ViewMode.EPISODES
	current_chapter = chapter

	if title_label:
		title_label.text = str(chapter.get("name", "Episodes"))

	chapter_list.visible = false
	episode_list.visible = true
	scene_list.visible = false
	empty_notice.visible = false

	for child in episode_list.get_children():
		child.queue_free()

	var cid: int = int(chapter.get("chapter_id", 0))
	var all_maps: Array = PlaybackService.get_maps(cid) if PlaybackService else []
	var unlocked_maps: Array = PlaybackService.filter_unlocked_maps(all_maps) if PlaybackService else all_maps

	if unlocked_maps.is_empty():
		empty_notice.text = "ยังไม่มีตอนที่ปลดล็อคในบทนี้\n(กรุณาผ่านด่านเนื้อเรื่องก่อน)"
		empty_notice.visible = true
	else:
		for m in unlocked_maps:
			var item: Control = _create_episode_item(m)
			episode_list.add_child(item)

	scroll_container.scroll_vertical = 0


func _create_episode_item(map_data: Dictionary) -> Control:
	var btn: TextureButton = TextureButton.new()
	btn.custom_minimum_size = Vector2(624, 112)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.mouse_filter = Control.MOUSE_FILTER_PASS

	if ResourceLoader.exists("res://assets/ui/memory/memory_plate_dungeon2.tres"):
		btn.texture_normal = load("res://assets/ui/memory/memory_plate_dungeon2.tres")

	var lbl: Label = Label.new()
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.text = str(map_data.get("name", ""))
	lbl.position = Vector2(0, 0)
	lbl.size = Vector2(624, 112)
	if ResourceLoader.exists("res://assets/ui/font/tahomabd.ttf"):
		lbl.add_theme_font_override("font", load("res://assets/ui/font/tahomabd.ttf"))
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(lbl)

	var captured_m: Dictionary = map_data
	btn.pressed.connect(func() -> void: _on_episode_selected(captured_m))
	return btn


func _on_episode_selected(map_data: Dictionary) -> void:
	show_scene_view(map_data)


# === View 3: Scene Select (Matches Attachment 6) ===

func show_scene_view(map_data: Dictionary) -> void:
	current_view = ViewMode.SCENES
	current_map = map_data

	if title_label:
		title_label.text = str(map_data.get("name", "Scenes"))

	chapter_list.visible = false
	episode_list.visible = false
	scene_list.visible = true
	empty_notice.visible = false

	for child in scene_list.get_children():
		child.queue_free()

	var mid: int = int(map_data.get("map_id", 0))
	var all_events: Array = PlaybackService.get_events(mid) if PlaybackService else []
	var unlocked_events: Array = PlaybackService.filter_unlocked_events(all_events) if PlaybackService else all_events

	if unlocked_events.is_empty():
		empty_notice.text = "ยังไม่มีฉากที่ปลดล็อค\n(กรุณาผ่านด่านเนื้อเรื่องก่อน)"
		empty_notice.visible = true
	else:
		for ev in unlocked_events:
			var item: Control = _create_scene_item(ev)
			scene_list.add_child(item)

	scroll_container.scroll_vertical = 0


func _create_scene_item(event_data: Dictionary) -> Control:
	var btn: TextureButton = TextureButton.new()
	btn.custom_minimum_size = Vector2(640, 168)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn.mouse_filter = Control.MOUSE_FILTER_PASS

	if ResourceLoader.exists("res://assets/ui/memory/memory_plate_scenario.tres"):
		btn.texture_normal = load("res://assets/ui/memory/memory_plate_scenario.tres")
	if ResourceLoader.exists("res://assets/ui/memory/memory_plate_scenario2.tres"):
		btn.texture_pressed = load("res://assets/ui/memory/memory_plate_scenario2.tres")

	# Scene Title (e.g. "Opening")
	var title_lbl: Label = Label.new()
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_lbl.text = str(event_data.get("name", ""))
	title_lbl.position = Vector2(105, 66)
	title_lbl.size = Vector2(360, 36)
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.add_theme_color_override("font_color", Color.WHITE)
	title_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title_lbl.add_theme_constant_override("shadow_offset_x", 1)
	title_lbl.add_theme_constant_override("shadow_offset_y", 2)
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(title_lbl)

	# Right-side Battle Indicator: Battle Yes / Battle No
	var has_battle: bool = bool(event_data.get("has_battle", false))
	var battle_box: HBoxContainer = HBoxContainer.new()
	battle_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	battle_box.position = Vector2(490, 72)
	battle_box.size = Vector2(120, 24)
	battle_box.alignment = BoxContainer.ALIGNMENT_END

	var battle_label_tex: TextureRect = TextureRect.new()
	battle_label_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/ui/memory/memory_plate_battle.tres"):
		battle_label_tex.texture = load("res://assets/ui/memory/memory_plate_battle.tres")
		battle_label_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	battle_box.add_child(battle_label_tex)

	var yes_no_tex: TextureRect = TextureRect.new()
	yes_no_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var yn_path: String = "res://assets/ui/memory/memory_plate_battle_y.tres" if has_battle else "res://assets/ui/memory/memory_plate_battle_n.tres"
	if ResourceLoader.exists(yn_path):
		yes_no_tex.texture = load(yn_path)
		yes_no_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	battle_box.add_child(yes_no_tex)

	btn.add_child(battle_box)

	var captured_ev: Dictionary = event_data
	btn.pressed.connect(func() -> void: _on_scene_selected(captured_ev))
	return btn


func _get_story_event_ids(event_data: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	var phase_info: String = str(event_data.get("phase_info", "")).strip_edges()
	if phase_info != "":
		# Format: "1:1001000, 4:1001001" or "0:1001006"
		for part in phase_info.split(","):
			var p: String = part.strip_edges()
			if p == "":
				continue
			var pair: PackedStringArray = p.split(":")
			if pair.size() >= 2:
				var sid: String = pair[1].strip_edges()
				if sid != "" and not ids.has(sid):
					ids.append(sid)
			elif p.is_valid_int():
				if not ids.has(p):
					ids.append(p)
	return ids


func _on_scene_selected(event_data: Dictionary) -> void:
	pending_event = event_data
	_start_scene_flow(event_data)


func _start_scene_flow(event_data: Dictionary) -> void:
	var mission_id: String = str(event_data.get("mission_id", ""))
	if mission_id == "6000101" or mission_id == "":
		mission_id = "1110100"

	var has_battle: bool = bool(event_data.get("has_battle", false))
	var has_real_battle: bool = has_battle and not GameDatabase.get_mission_phases(mission_id).is_empty()

	if not has_real_battle:
		# Pure story cutscene(s)
		_play_cutscene(event_data)
		return

	# This is a combat scene (or a scene containing both story and battle).
	# Check whether there are story events in phase_info.
	var phase_info: String = str(event_data.get("phase_info", "")).strip_edges()
	var pre_story_ids: Array[String] = []
	var battle_cutscene_ids: Array[String] = []
	var post_story_ids: Array[String] = []

	var mission_cuts: Array = GameDatabase.get_mission_cutscenes(mission_id)
	var mp_story_ids: Array = []
	for c in mission_cuts:
		mp_story_ids.append(str(c.get("story_event_id", "")))

	if phase_info != "":
		for part in phase_info.split(","):
			var p: String = part.strip_edges()
			if p == "":
				continue
			var pair: PackedStringArray = p.split(":")
			var pnum: int = 1
			var sid: String = ""
			if pair.size() >= 2:
				pnum = int(pair[0])
				sid = pair[1].strip_edges()
			elif p.is_valid_int():
				sid = p

			if sid != "":
				if mp_story_ids.has(sid):
					if not battle_cutscene_ids.has(sid):
						battle_cutscene_ids.append(sid)
				else:
					if pnum <= 1:
						if not pre_story_ids.has(sid):
							pre_story_ids.append(sid)
					else:
						if not post_story_ids.has(sid):
							post_story_ids.append(sid)

	# 1. Play any external pre-battle cutscenes (e.g. Opening intro 1001000)
	if not pre_story_ids.is_empty():
		var pre_scenes: Array = []
		for sid in pre_story_ids:
			var sc: Dictionary = StoryFlow.story_event_scene(sid)
			if not sc.is_empty() and str(sc.get("bin_id", "")) != "":
				sc["is_recollection"] = true
				pre_scenes.append(sc)
		if not pre_scenes.is_empty():
			await StoryFlow.play_scenes(pre_scenes)

	# 2. Start the battle with is_recollection flag and allowed cutscene filter
	_start_battle_with_params(mission_id, battle_cutscene_ids, post_story_ids)


func _start_battle_with_params(mission_id: String, allowed_cutscene_ids: Array[String] = [], post_story_ids: Array[String] = []) -> void:
	if MissionService:
		MissionService.request_start_mission(mission_id)

	var battle_params: Dictionary = {
		"mission_id": mission_id,
		"is_recollection": true,
		"allowed_cutscene_ids": allowed_cutscene_ids,
	}

	if not post_story_ids.is_empty():
		battle_params["on_finished"] = func() -> void:
			var post_scenes: Array = []
			for sid in post_story_ids:
				var sc: Dictionary = StoryFlow.story_event_scene(sid)
				if not sc.is_empty() and str(sc.get("bin_id", "")) != "":
					sc["is_recollection"] = true
					post_scenes.append(sc)
			if not post_scenes.is_empty():
				StoryFlow.play_scenes(post_scenes)

	UIManager.push("combat_ui", battle_params)


# === Actions: Play Cutscene / Start Battle ===

func _on_dialog_play_cutscene() -> void:
	action_dialog.visible = false
	if not pending_event.is_empty():
		_play_cutscene(pending_event)


func _on_dialog_start_battle() -> void:
	action_dialog.visible = false
	if not pending_event.is_empty():
		_start_battle(pending_event)


func _on_dialog_cancel() -> void:
	action_dialog.visible = false


func _play_cutscene(event_data: Dictionary) -> void:
	var se_ids: Array[String] = _get_story_event_ids(event_data)
	var scenes: Array = []

	for sid in se_ids:
		var scene: Dictionary = StoryFlow.story_event_scene(sid)
		if not scene.is_empty() and str(scene.get("bin_id", "")) != "":
			scene["is_recollection"] = true
			scenes.append(scene)

	# Fallback if no story_event found in DB: check if cutscene_info names a bin
	if scenes.is_empty():
		var cs_info: String = str(event_data.get("cutscene_info", ""))
		var layer: int = 0
		var bin_id: String = ""
		if cs_info != "":
			var parts: PackedStringArray = cs_info.split(",")
			var first: String = parts[0].strip_edges()
			var ep: PackedStringArray = first.split(":")
			if ep.size() > 1:
				layer = int(ep[0])
				bin_id = ep[1].strip_edges()
			else:
				bin_id = ep[0].strip_edges()
		if bin_id != "":
			scenes.append({
				"bin_id": bin_id,
				"layer": layer,
				"switches": SwitchService.as_event_switches() if SwitchService else {},
				"name": str(event_data.get("name", "Story Replay")),
				"is_recollection": true
			})

	if scenes.is_empty():
		push_warning("RecollectionScreen: no playable scenes for: %s" % str(event_data))
		return

	await StoryFlow.play_scenes(scenes)


func _start_battle(event_data: Dictionary) -> void:
	var mission_id: String = str(event_data.get("mission_id", ""))
	# Map opening / prologue mission
	if mission_id == "6000101" or mission_id == "":
		mission_id = "1110100"
	_start_battle_with_params(mission_id)
