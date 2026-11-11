extends "res://tests/test_case.gd"

func test_wav_playback_behavior() -> void:
	var as_script = load("res://core/services/audio_service.gd")
	var audio_service = as_script.new()
	
	var p_wav = "res://assets/audio/bgm/la101_event_initiate.wav"
	var s_wav = audio_service._load_wav_from_file(p_wav)
	assert_not_null(s_wav)
	assert_true(s_wav.loop_end > 0, "WAV loop_end must be non-zero")
	
	audio_service._apply_loop(s_wav, true)
	assert_eq(s_wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_true(s_wav.loop_end > s_wav.loop_begin)


func test_ogg_stream_loading() -> void:
	var as_script = load("res://core/services/audio_service.gd")
	var audio_service = as_script.new()
	
	var p_ogg = "res://assets/audio/bgm/la101_event_initiate.ogg"
	var s_ogg = audio_service._load_stream(p_ogg)
	assert_not_null(s_ogg)
	audio_service._apply_loop(s_ogg, true)
	assert_true(s_ogg.loop)
	# Verify that the loaded audio is the genuine clean track (~125.1s) and not the stale 59s broken cache
	assert_true(s_ogg.get_length() > 120.0, "Stream must be the clean full track (~125s), not the stale 59s cache")



func test_stage_play_bgm_strips_prefix_and_prefers_ogg() -> void:
	var stage := EventStage.new()
	stage.play_bgm("!la101_event_initiate.acb")
	assert_eq(stage.bgm_played.size(), 1)
	assert_eq(stage.bgm_played[0], "!la101_event_initiate.acb")
	assert_eq(AudioService.current_music_path(), "res://assets/audio/bgm/la101_event_initiate.ogg")
	stage.stop_bgm()
	stage.free()


## A defeat must not reuse the clear fanfare: the result screen says "Mission
## Failed!", so it needs its own theme and that theme must actually load.
func test_defeat_uses_its_own_music() -> void:
	var battle_screen = load("res://features/battle/ui/battle_screen.gd")
	assert_ne(battle_screen.BATTLE_DEFEAT_MUSIC, battle_screen.BATTLE_END_MUSIC,
		"the defeat theme is not the victory fanfare")
	assert_true(battle_screen.BATTLE_DEFEAT_MUSIC.begins_with("res://assets/audio/bgm/"),
		"the defeat theme points into the bgm folder")
	var as_script = load("res://core/services/audio_service.gd")
	var audio_service = as_script.new()
	var stream: AudioStream = audio_service._load_stream(battle_screen.BATTLE_DEFEAT_MUSIC)
	assert_not_null(stream, "the defeat theme loads")
	audio_service.free()

