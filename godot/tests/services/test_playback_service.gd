extends "res://tests/test_case.gd"

## Unit tests for PlaybackService and RecollectionScreen

func test_playback_service_loads_data() -> void:
	assert_true(PlaybackService != null, "PlaybackService autoload should exist")
	PlaybackService.load_data()
	assert_true(PlaybackService.is_loaded, "Playback data should be loaded")
	assert_true(PlaybackService.get_seasons().size() >= 1, "Should have at least 1 season")
	assert_true(PlaybackService.get_chapters(10).size() >= 11, "Season 1 should have at least 11 chapters")


func test_chapter_progress_gating() -> void:
	SwitchService.reset()
	var s1_chapters = PlaybackService.get_chapters(10)
	assert_true(s1_chapters.size() >= 2, "Should have multiple chapters")

	var ch1 = s1_chapters[0] # Grandshelt (switch_info: "0")
	var ch2 = s1_chapters[1] # Lanzelt (switch_info: "10016001")

	assert_true(PlaybackService.is_chapter_unlocked(ch1), "Grandshelt (ch1) should be unlocked by default")
	assert_false(PlaybackService.is_chapter_unlocked(ch2), "Lanzelt (ch2) should be locked initially")

	# Unlock switch for Chapter 2
	SwitchService.unlock_switches("10016001", "test")
	assert_true(PlaybackService.is_chapter_unlocked(ch2), "Lanzelt should unlock after clearing Grandshelt switch")

	SwitchService.reset()


func test_map_and_scene_progress_gating() -> void:
	SwitchService.reset()
	var maps = PlaybackService.get_maps(1001)
	assert_true(maps.size() >= 2, "Chapter 1001 should have maps")

	var map_falling_star = maps[0] # Falling Star (100100)
	assert_true(PlaybackService.is_map_unlocked(map_falling_star), "Falling Star should be unlocked by default")

	var events = PlaybackService.get_events(100100)
	assert_true(events.size() >= 1, "Falling Star should have events")
	var event_opening = events[0]
	assert_true(PlaybackService.is_event_unlocked(event_opening), "Opening event should be unlocked by default")

	# Test a locked map in chapter 1001 (e.g. Map 100101 Black-Clad Destroyer: switch 10002200)
	var map_bcd = maps[1]
	assert_false(PlaybackService.is_map_unlocked(map_bcd), "Black-Clad Destroyer should be locked initially")

	SwitchService.unlock_switches("10002200", "test")
	assert_true(PlaybackService.is_map_unlocked(map_bcd), "Black-Clad Destroyer should unlock after switch 10002200")

	SwitchService.reset()


func test_recollection_screen_scene_instantiation() -> void:
	var scene_res = load("res://features/outgame/recollection/RecollectionScreen.tscn")
	assert_true(scene_res != null, "RecollectionScreen.tscn should load cleanly")
	var screen = scene_res.instantiate()
	assert_true(screen != null, "RecollectionScreen should instantiate cleanly")

	# Simulate ready
	screen._ready()
	assert_true(int(screen.current_view) == 0, "Initial view should be CHAPTERS (0)")
	assert_true(screen.back_button != null, "BackButton should exist")
	assert_true(screen.title_label != null, "Title label should exist")
	assert_eq(screen.title_label.text, "Book of Recollection", "Initial title should be Book of Recollection")

	# Select chapter 1001
	var ch1 = PlaybackService.get_chapters(10)[0]
	screen.show_episode_view(ch1)
	assert_true(int(screen.current_view) == 1, "Should transition to EPISODES (1)")
	assert_eq(screen.title_label.text, "Grandshelt Isles", "Title should update to chapter name")

	# Select map 100100
	var map1 = PlaybackService.get_maps(1001)[0]
	screen.show_scene_view(map1)
	assert_true(int(screen.current_view) == 2, "Should transition to SCENES (2)")
	assert_eq(screen.title_label.text, "Falling Star", "Title should update to map name")

	# Back button navigation
	screen._on_back_pressed()
	assert_true(int(screen.current_view) == 1, "Back should return to EPISODES (1)")
	assert_eq(screen.title_label.text, "Grandshelt Isles", "Title should return to chapter name")

	screen._on_back_pressed()
	assert_true(int(screen.current_view) == 0, "Back should return to CHAPTERS (0)")
	assert_eq(screen.title_label.text, "Book of Recollection", "Title should return to Book of Recollection")

	# Verify episode item styling
	var ep_item: Control = screen._create_episode_item(map1)
	assert_true(ep_item is TextureButton, "Episode item should be a TextureButton")
	var ep_lbl: Label = ep_item.get_child(0) as Label
	assert_true(ep_lbl != null, "Episode item should have a label child")
	assert_eq(ep_lbl.size, Vector2(624, 112), "Episode label should fill the plate size")
	assert_eq(ep_lbl.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER, "Episode label should be centered horizontally")
	assert_eq(ep_lbl.vertical_alignment, VERTICAL_ALIGNMENT_CENTER, "Episode label should be centered vertically")
	ep_item.free()

	# Verify scene extraction and dialog trigger
	var opening_ev: Dictionary = PlaybackService.get_events(100100)[0]
	var se_ids: Array[String] = screen._get_story_event_ids(opening_ev)
	assert_eq(se_ids, ["1001000", "1001001"], "Opening should have story event IDs 1001000 and 1001001")

	# Verify story event scenes in GameDatabase
	var sc0: Dictionary = StoryFlow.story_event_scene("1001000")
	assert_eq(sc0.get("bin_id"), "111010105", "Event 1001000 bin_id should be 111010105")
	assert_eq(sc0.get("layer"), 61, "Event 1001000 layer should be 61")

	var sc1: Dictionary = StoryFlow.story_event_scene("1001001")
	assert_eq(sc1.get("bin_id"), "111010105", "Event 1001001 bin_id should be 111010105")
	assert_eq(sc1.get("layer"), 61, "Event 1001001 layer should be 61")

	# Verify Town of Mitra (1003001) and Farplane (1003004) scene resolution
	var sc_mitra: Dictionary = StoryFlow.story_event_scene("1003001")
	assert_eq(sc_mitra.get("bin_id"), "111020101", "Mitra event bin_id should be 111020101")
	assert_eq(sc_mitra.get("layer"), 56, "Mitra event layer should be 56")

	var sc_farplane: Dictionary = StoryFlow.story_event_scene("1003004")
	assert_eq(sc_farplane.get("bin_id"), "211020101", "Farplane event bin_id should be 211020101")

	# Trigger scene selection on Opening (both story and battle runs sequentially, no menu popup)
	screen._on_scene_selected(opening_ev)
	assert_false(screen.action_dialog.visible, "Action dialog should NOT show; flow runs sequentially without menu")

	screen.free()
