extends Node
## AudioService — autoload that owns music playback, a pooled SFX/UI player
## set, lazy stream caching, and device-wide volume/mute persistence.
##
## Buses (defined in `res://default_bus_layout.tres`):
##   Master, Music, SFX, UI
##
## Public API is intentionally small; missing audio paths are logged and
## swallowed so the game keeps running while assets are still being added.

const SETTINGS_DIR: String = "user://settings/"
const SETTINGS_PATH: String = "user://settings/audio.json"
const SETTINGS_VERSION: int = 1

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"

const MANAGED_BUSES: Array[String] = [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_UI]

const SFX_POOL_SIZE: int = 8
const LOG_TAG: String = "Audio"

var _music_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _stream_cache: Dictionary = {}
var _current_music_path: String = ""
var _current_ambient_path: String = ""
var _music_tween: Tween = null
var _ambient_tween: Tween = null


# === Lifecycle ===

func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientPlayer"
	_ambient_player.bus = BUS_SFX
	add_child(_ambient_player)

	for i in range(SFX_POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SfxPlayer%d" % i
		p.bus = BUS_SFX
		add_child(p)
		_sfx_pool.append(p)

	_load_settings()
	_log_info("AudioService ready (%d buses, %d SFX players)" % [
		MANAGED_BUSES.size(), SFX_POOL_SIZE,
	])


# === Public API: music ===

func play_music(path: String, loop: bool = true) -> void:
	if path == _current_music_path and _music_player.playing:
		if _music_tween and _music_tween.is_valid():
			_music_tween.kill()
		_music_player.volume_db = 0.0
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	var stream: AudioStream = _load_stream(path)
	if stream == null:
		return
	_apply_loop(stream, loop)
	_music_player.volume_db = 0.0
	_music_player.stream = stream
	_music_player.play()
	_current_music_path = path


func fade_in_music(path: String, duration_sec: float, loop: bool = true) -> void:
	if path == _current_music_path and _music_player.playing:
		if _music_tween and _music_tween.is_valid():
			_music_tween.kill()
		_music_player.volume_db = 0.0
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	var stream: AudioStream = _load_stream(path)
	if stream == null:
		return
	_apply_loop(stream, loop)
	if duration_sec <= 0.05:
		_music_player.volume_db = 0.0
		_music_player.stream = stream
		_music_player.play()
		_current_music_path = path
		return
	_music_player.volume_db = -80.0
	_music_player.stream = stream
	_music_player.play()
	_current_music_path = path
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", 0.0, duration_sec)


func stop_music() -> void:
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_player.stop()
	_music_player.volume_db = 0.0
	_current_music_path = ""


func fade_out_music(duration_sec: float) -> void:
	if not _music_player.playing:
		_current_music_path = ""
		return
	if duration_sec <= 0.05:
		stop_music()
		return
	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -80.0, duration_sec)
	_music_tween.tween_callback(func() -> void:
		_music_player.stop()
		_music_player.volume_db = 0.0
		_current_music_path = ""
	)


func is_music_playing() -> bool:
	return _music_player != null and _music_player.playing


func current_music_path() -> String:
	return _current_music_path


# === Public API: ambient ===

func play_ambient(path: String, loop: bool = true, volume_db: float = -6.0) -> void:
	if path == _current_ambient_path and _ambient_player.playing:
		return
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	var stream: AudioStream = _load_stream(path)
	if stream == null:
		return
	_apply_loop(stream, loop)
	_ambient_player.volume_db = volume_db
	_ambient_player.stream = stream
	_ambient_player.play()
	_current_ambient_path = path


func stop_ambient(fade_sec: float = 1.0) -> void:
	if not _ambient_player.playing:
		_current_ambient_path = ""
		return
	if fade_sec <= 0.05:
		_ambient_player.stop()
		_current_ambient_path = ""
		return
	if _ambient_tween and _ambient_tween.is_valid():
		_ambient_tween.kill()
	_ambient_tween = create_tween()
	_ambient_tween.tween_property(_ambient_player, "volume_db", -80.0, fade_sec)
	_ambient_tween.tween_callback(func() -> void:
		_ambient_player.stop()
		_ambient_player.volume_db = -6.0
		_current_ambient_path = ""
	)


func is_ambient_playing() -> bool:
	return _ambient_player != null and _ambient_player.playing


# === Public API: one-shots ===

func play_sfx(path: String) -> void:
	_play_one_shot(path, BUS_SFX)


func stop_all_sfx() -> void:
	for p in _sfx_pool:
		if is_instance_valid(p) and p.playing:
			p.stop()


func play_ui(path: String) -> void:
	_play_one_shot(path, BUS_UI)


# === Public API: volume / mute ===

func set_bus_volume_linear(bus: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		_log_warn("set_bus_volume_linear: unknown bus %s" % bus)
		return
	var clamped: float = clamp(linear, 0.0, 1.0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(clamped, 0.0001)))
	_save_settings()


func get_bus_volume_linear(bus: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func set_bus_mute(bus: String, muted: bool) -> void:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		_log_warn("set_bus_mute: unknown bus %s" % bus)
		return
	AudioServer.set_bus_mute(idx, muted)
	_save_settings()


func is_bus_muted(bus: String) -> bool:
	var idx: int = AudioServer.get_bus_index(bus)
	if idx < 0:
		return false
	return AudioServer.is_bus_mute(idx)


# === Internals: playback ===

func _play_one_shot(path: String, bus: String) -> void:
	var stream: AudioStream = _load_stream(path)
	if stream == null:
		return
	var player: AudioStreamPlayer = _pick_idle_player()
	player.bus = bus
	player.stream = stream
	player.play()


func _pick_idle_player() -> AudioStreamPlayer:
	for p in _sfx_pool:
		if not p.playing:
			return p
	# All busy — recycle the first one (oldest-ish). Acceptable for a small pool.
	return _sfx_pool[0]


func _load_stream(path: String) -> AudioStream:
	if path.is_empty():
		return null
	if _stream_cache.has(path):
		return _stream_cache[path]
	# For Vorbis audio and disk BGM, load directly from file to ensure we play
	# the genuine uncorrupted files without hitting stale Godot import caches.
	if FileAccess.file_exists(path):
		if path.ends_with(".ogg"):
			var ogg: AudioStreamOggVorbis = AudioStreamOggVorbis.load_from_file(path)
			if ogg != null:
				_stream_cache[path] = ogg
				return ogg
		elif path.ends_with(".wav") and path.begins_with("res://assets/audio/bgm/"):
			var wav: AudioStreamWAV = _load_wav_from_file(path)
			if wav != null:
				_stream_cache[path] = wav
				return wav
	if ResourceLoader.exists(path):
		var res: Resource = ResourceLoader.load(path)
		if res != null and res is AudioStream:
			_stream_cache[path] = res
			return res
	if FileAccess.file_exists(path) and path.ends_with(".wav"):
		var wav: AudioStreamWAV = _load_wav_from_file(path)
		if wav != null:
			_stream_cache[path] = wav
			return wav
	_log_warn("missing audio: %s" % path)
	return null


func _load_wav_from_file(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return null
	var wav := AudioStreamWAV.new()
	var channels: int = bytes.decode_u16(22)
	var sample_rate: int = bytes.decode_u32(24)
	var bits_per_sample: int = bytes.decode_u16(34)
	wav.stereo = (channels == 2)
	wav.mix_rate = sample_rate
	if bits_per_sample == 16:
		wav.format = AudioStreamWAV.FORMAT_16_BITS
	elif bits_per_sample == 8:
		wav.format = AudioStreamWAV.FORMAT_8_BITS

	var idx: int = 12
	while idx + 8 <= bytes.size():
		var chunk_id: String = bytes.slice(idx, idx + 4).get_string_from_ascii()
		var chunk_size: int = bytes.decode_u32(idx + 4)
		if chunk_id == "data":
			wav.data = bytes.slice(idx + 8, mini(idx + 8 + chunk_size, bytes.size()))
			var bytes_per_sample_val: int = 2 if bits_per_sample == 16 else 1
			var bytes_per_frame: int = channels * bytes_per_sample_val
			if bytes_per_frame > 0:
				wav.loop_end = wav.data.size() / bytes_per_frame
			return wav
		idx += 8 + chunk_size
	return null


func _apply_loop(stream: AudioStream, loop: bool) -> void:
	# Stream subclasses expose looping differently:
	#   - AudioStreamOggVorbis / AudioStreamMP3: bool `loop`
	#   - AudioStreamWAV: enum `loop_mode` (0 = disabled, 1 = forward)
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if loop:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			if wav.loop_end <= wav.loop_begin:
				var bytes_per_sample: int = 2 if wav.format == AudioStreamWAV.FORMAT_16_BITS else (1 if wav.format == AudioStreamWAV.FORMAT_8_BITS else 4)
				var channels: int = 2 if wav.stereo else 1
				var bytes_per_frame: int = channels * bytes_per_sample
				if bytes_per_frame > 0 and wav.data.size() > 0:
					wav.loop_end = wav.data.size() / bytes_per_frame
		else:
			wav.loop_mode = AudioStreamWAV.LOOP_DISABLED
	elif "loop_mode" in stream:
		stream.set("loop_mode", 1 if loop else 0)
	elif "loop" in stream:
		stream.set("loop", loop)


# === Internals: settings persistence ===

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var text: String = FileAccess.get_file_as_string(SETTINGS_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return
	var data: Dictionary = parsed
	var buses_variant: Variant = data.get("buses", {})
	if not (buses_variant is Dictionary):
		return
	var buses: Dictionary = buses_variant
	for bus in MANAGED_BUSES:
		if not buses.has(bus):
			continue
		var entry_variant: Variant = buses[bus]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var idx: int = AudioServer.get_bus_index(bus)
		if idx < 0:
			continue
		var vol: float = clamp(float(entry.get("volume", 1.0)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(vol, 0.0001)))
		AudioServer.set_bus_mute(idx, bool(entry.get("muted", false)))


func _save_settings() -> void:
	DirAccess.make_dir_recursive_absolute(SETTINGS_DIR)
	var buses: Dictionary = {}
	for bus in MANAGED_BUSES:
		var idx: int = AudioServer.get_bus_index(bus)
		if idx < 0:
			continue
		buses[bus] = {
			"volume": db_to_linear(AudioServer.get_bus_volume_db(idx)),
			"muted": AudioServer.is_bus_mute(idx),
		}
	var payload: Dictionary = {
		"version": SETTINGS_VERSION,
		"buses": buses,
	}
	var file: FileAccess = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		_log_warn("failed to write %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()


# === Internals: logging shim ===
# `Log` is an autoload but may not be present in isolated tool/editor contexts;
# fall back to print/push_warning so this service never crashes the editor.

func _log_info(msg: String) -> void:
	if Engine.has_singleton("Log"):
		Engine.get_singleton("Log").info(msg, LOG_TAG)
	elif typeof(get_node_or_null("/root/Log")) == TYPE_OBJECT:
		get_node("/root/Log").info(msg, LOG_TAG)
	else:
		print("[INFO][%s] %s" % [LOG_TAG, msg])


func _log_warn(msg: String) -> void:
	var log_node: Node = get_node_or_null("/root/Log")
	if log_node != null:
		log_node.warn(msg, LOG_TAG)
	else:
		push_warning("[%s] %s" % [LOG_TAG, msg])
