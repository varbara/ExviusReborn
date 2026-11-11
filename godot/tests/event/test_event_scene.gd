extends "res://tests/test_case.gd"

## Event.tscn playing the three story events of the recording (CUTSCENE-PLAN.md section
## 8.1), frame by frame with every line tapped away: the right lines in the right order,
## the setup the recording shows, and where everyone ends up. The map is not drawn
## except in the last test.

const EVENT_SCENE: PackedScene = preload("res://features/event/Event.tscn")

var _player: EventPlayer
var _finished: Array = []


func before_each() -> void:
	_player = EVENT_SCENE.instantiate()
	_player.auto_start = false
	_player.get_node("Stage").draw_map = false
	_player.finished.connect(func(reason: String) -> void: _finished.append(reason))
	(Engine.get_main_loop() as SceneTree).root.add_child(_player)


func after_each() -> void:
	_player.get_parent().remove_child(_player)
	_player.free()


## Steps until the cutscene ends, tapping each line away once its cursor shows.
## Returns the frames it took.
func _play_to_end(max_frames: int = 30000) -> int:
	var frames: int = 0
	while _player.running and frames < max_frames:
		_player.step_frame()
		frames += 1
		if _player.stage.dialogue.state == EventDialogue.State.CURSOR:
			_player.stage.tap()
	return frames


func test_the_prologue_sets_up_rain_and_lasswell_on_the_deck() -> void:
	assert_true(_player.play_story_event("1001001"))
	_player.step_frame()
	var stage: EventStage = _player.stage
	assert_eq(stage.layer_id, 61)
	assert_eq(stage.actors["pc1"].position, Vector2(1305, 696), "Rain")
	assert_eq(stage.actors["pc2"].position, Vector2(1421, 725), "Lasswell")
	assert_eq(stage.actors["pc1"].facing, EventActor.UP)
	assert_eq(stage.actors["pc2"].facing, EventActor.UP)
	assert_eq(stage.camera_position(), Vector2(1392, 812))
	assert_eq(stage.fade_alpha(), 1.0, "it opens on a fade-in from black")


func test_the_opening_movie_story_event_plays_op_clip_and_opening_bgm() -> void:
	assert_true(_player.play_story_event("1001000"))
	var stage: EventStage = _player.stage
	_player.step_frame()
	assert_eq(stage.movies_played, ["op_clip.usm"] as Array[String])
	assert_true(stage.is_movie_playing())
	assert_false(stage.dialogue._window.visible, "dialogue window stays hidden when no dialogue is shown")
	stage.tap()
	assert_false(stage.is_movie_playing())


func test_the_prologue_plays_its_twelve_lines_and_ends_on_the_bridge() -> void:
	assert_true(_player.play_story_event("1001001"))
	var frames: int = _play_to_end()
	var stage: EventStage = _player.stage
	assert_eq(stage.lines_shown, [210806, 210807, 210830, 210808, 210809, 210810, 210811, 210812, 210813, 210814, 210815, 210816] as Array[int])
	assert_eq(_finished, ["end"])
	assert_eq(stage.actors["pc1"].position, Vector2(464, 1044), "Rain on the bridge")
	assert_eq(stage.actors["pc2"].position, Vector2(522, 870), "Lasswell on the bridge")
	assert_eq(stage.camera_position(), Vector2(493, 771), "after the closing scroll")
	assert_eq(stage.fade_alpha(), 1.0, "it ends faded out")
	assert_eq(_player.next_location, {"type": 0, "id": 1110101}, "on to the Earth Shrine mission")
	# About 64 s with every line tapped away the moment its cursor shows; the
	# recording's 102 s include the player's reading time.
	assert_true(frames > 3000 and frames < 6000, "%d frames" % frames)


## A click arrives as a mouse button and an emulated touch in the same frame. It must
## complete the line that is appearing, not complete it and dismiss it.
func test_1007001_play() -> void:
	_player.get_node("Stage").draw_map = true
	assert_true(_player.play_story_event("1007001"))
	for i in 600:
		_player.step_frame()
		if _player.stage.dialogue.state == EventDialogue.State.CURSOR:
			print("Frame %d: showing line '%s', tapping..." % [i, _player.stage.dialogue.shown_text()])
			_player.stage.tap()
		if not _player.running:
			print("Cutscene finished at frame %d!" % i)
			break
	print("Running:", _player.running, "finished:", _finished)


func test_town_mitra_and_farplane_playback() -> void:
	# Test Town of Mitra (1003001) can play and shows dialogue
	assert_true(_player.play_story_event("1003001"))
	_play_to_end(1000)
	assert_true(_player.stage.lines_shown.has(210073), "Mitra line 210073 was shown")

	# Test Farplane (1003004) can play and shows dialogue
	_player.stop("test")
	assert_true(_player.play_story_event("1003004"))
	for i in 800:
		_player.step_frame()
		if _player.stage.dialogue.state == EventDialogue.State.CURSOR:
			_player.stage.tap()
		if not _player.running:
			break
	assert_true(_player.stage.lines_shown.has(210001), "Farplane line 210001 was shown")


func test_earth_shrine_3_initial_actors_visibility() -> void:
	assert_true(_player.play_story_event("1001006"))
	_player.step_frame()
	var stage: EventStage = _player.stage
	assert_false(stage.actors["e2"].visible, "collapsed Rain must start hidden")
	assert_false(stage.actors["e15"].visible, "staged Rain must start hidden")
	assert_false(stage.actors["e19"].visible, "collapsed Lasswell must start hidden")
	assert_false(stage.actors["e20"].visible, "struggling Rain must start hidden")
	assert_false(stage.actors["e21"].visible, "struggling Lasswell must start hidden")
	assert_true(stage.actors["e1"].visible, "Veritas of the Dark is visible at the crystal")


func test_one_click_completes_a_line_and_waits() -> void:
	assert_true(_player.play_story_event("1001001"))
	var dialogue: EventDialogue = _player.stage.dialogue
	var frames: int = 0
	while dialogue.state != EventDialogue.State.REVEAL and frames < 2000:
		_player.step_frame()
		frames += 1
	_player.step_frame()
	assert_eq(dialogue.state, EventDialogue.State.REVEAL, "the first line is appearing")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	_player._unhandled_input(click)
	_player._unhandled_input(touch)
	assert_eq(dialogue.state, EventDialogue.State.CURSOR, "completed, waiting for the next press")
	assert_true(dialogue.shown_text() == "นั่นมัน...ผลึกงั้นเหรอ!?" or dialogue.shown_text() == "Is that...a crystal!?", "whole line, its pause and speed ignored")


func test_common_image_list_reads_without_utf8() -> void:
	var images: Dictionary = EventStage._read_csv("res://assets/map_common/common_image.txt", false)
	assert_true(str(images.get(11001, "")).begins_with("pc100000101.png"))


func test_the_crystal_girl_is_named_and_slow() -> void:
	assert_true(_player.play_story_event("1001001"))
	var stage: EventStage = _player.stage
	var frames: int = 0
	while not stage.lines_shown.has(210807) and frames < 5000:
		_player.step_frame()
		frames += 1
		if stage.dialogue.state == EventDialogue.State.CURSOR:
			stage.tap()
	for i in 10:
		_player.step_frame()
	assert_eq(stage.dialogue.shown_name(), "???")
	assert_true(stage.dialogue.shown_text().length() <= 3, "<speed=8> reveals a character every 4 frames")


func test_the_mission_opening_plays_in_two_story_events() -> void:
	assert_true(_player.play_story_event("1001002"))
	_play_to_end()
	var stage: EventStage = _player.stage
	assert_eq(stage.layer_id, 65)
	assert_eq(stage.lines_shown, [210817, 210818, 210819, 210820, 210821, 210822, 210823, 210824, 210825, 210826] as Array[int])
	assert_false(stage.actors["pc1"].visible, "Rain went ahead into the shrine")
	assert_eq(stage.actors["pc2"].position, Vector2(812, 406), "Lasswell follows")

	_finished.clear()
	assert_true(_player.play_story_event("1001003"))
	_play_to_end()
	assert_eq(_player.stage.layer_id, 67)
	assert_eq(_player.stage.lines_shown, [210746, 210749, 210750, 210751, 210752, 210754, 210755, 210756] as Array[int])
	assert_eq(_finished, ["end"])


## Mitra (the second recording): the arrival on layer 56 warps into the forge
## (layer 66), the forge sets 10004001 and warps back, and the record that played the
## arrival now shows its other page. Story switches select every step.
func test_the_town_arrival_chains_its_scenes_through_warps() -> void:
	assert_true(_player.play("111020101"))
	assert_eq(_player.stage.layer_id, 56, "the bin's start layer")
	_play_to_end()
	assert_eq(_player.stage.lines_shown, [
		210073,  # villager: "I saw that, you two."
		210118, 210091, 210092, 210104, 210093, 210116,  # the forge
		210068, 210069, 210070, 210071, 210072,  # back outside: "That was quite generous of him."
	] as Array[int])
	assert_eq(_player.switches.get(10004001), 1, "set in the forge")
	assert_eq(_player.switches.get(10004002), 1, "set at the portal")
	assert_eq(_player.next_location, {"type": 1, "id": 9001}, "on to the Farplane")
	assert_eq(_finished, ["end"])


func test_soldiers_on_the_shrine_layer_use_their_sheets() -> void:
	assert_true(_player.play_story_event("1001002"))
	var stage: EventStage = _player.stage
	assert_true(stage.actors.has("e2"), "the Grandshelt soldier record is on stage from the start")
	assert_true(stage.actors["e2"].has_sprite(), "npc200100120.png")
	assert_true(stage.actors["e1"].has_sprite(), "map_character13.png")


func test_the_stage_draws_the_scene_layer() -> void:
	var stage: EventStage = _player.stage
	stage.draw_map = true
	assert_true(_player.play_story_event("1001001"))
	var tile_map: Node = stage.get_node("TileMap")
	assert_eq(str(tile_map.get("town_id")), "111010100")
	assert_eq(int(tile_map.get("target_chunk")), int(tile_map.call("chunk_index_for_lid", 61)))
	assert_eq(stage.ssbp_played, ["opening_bg/anime"] as Array[String])
	assert_true(stage.active_ssbp.has(1501), "airship sky backdrop ev_opening.ssbp is active")
	var sky: SsbpPlayer = stage.active_ssbp[1501][0]
	assert_eq(sky.position, Vector2(1073, 0))
	assert_eq(sky.z_index, -1)


func test_the_prologue_spawns_and_stops_crystal_fina_vfx() -> void:
	assert_true(_player.play_story_event("1001001"))
	var stage: EventStage = _player.stage
	var frames: int = 0
	while not stage.lines_shown.has(210807) and frames < 5000:
		_player.step_frame()
		frames += 1
		if stage.dialogue.state == EventDialogue.State.CURSOR:
			stage.tap()
	assert_eq(stage.vfx_played, ["map_crystal_fina_001_fadein.bmb", "map_crystal_fina_001.bmb"] as Array[String])
	assert_true(stage.active_vfx.has(19), "crystal Fina VFX stays active while Fina speaks")
	var crystal_node: Node2D = stage.active_vfx[19]["node"]
	assert_eq(crystal_node.position, Vector2(1398, 435))
	_play_to_end()
	assert_false(stage.active_vfx.has(19), "op 0x66 stops crystal Fina VFX after she vanishes")


## The forge's own shopkeeper stood next to the cutscene's Gylbart until the map's NPCs
## were kept out; in the recording only the bin's actors are on the layer.
func test_the_map_brings_no_npcs_of_its_own() -> void:
	var stage: EventStage = _player.stage
	stage.draw_map = true
	assert_true(_player.play("111020101", 66))
	var tile_map: Node = stage.get_node("TileMap")
	assert_null(tile_map.get_node_or_null("NpcSprites"))
	assert_eq(tile_map.find_children("*", "Area2D", true, false).size(), 0, "no chests or warp triggers")
