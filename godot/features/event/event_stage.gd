class_name EventStage
extends Node2D

## What a cutscene draws: the map layer, the actors, the camera, the screen fade and
## flash, and the cinema window (CUTSCENE-PLAN.md sections 4.3 and 8). EventInterpreter
## drives it through the methods below; tick() advances everything one frame.
##
## World coordinates are map pixels (58 px tiles). The camera position is the centre of
## the screen and the view is 640 px wide, as the recording shows.

signal line_shown(text_id: int)

const MAP_COMMON: String = "res://assets/map_common/"
const TOWN_DATA: String = "res://assets/town_data/"
const MOVIES_DIR: String = "res://assets/movies/"
const BGM_DIR: String = "res://assets/audio/bgm/"
const SSBP_DIR: String = "res://assets/map_effect/"
const VFX_DIR: String = "res://assets/battle_effect/"
const MOVIE_ASPECT_RATIO: float = 640.0 / 1136.0
const DEFAULT_MOVIE_FRAMES: int = 900
## Where the camera position is drawn, as a share of the screen height: 52.0% in the
## first recording (640 x 1107) and 51.5% in the second (640 x 917), measured by lining
## up the map. The cinema window scales the same way (EventDialogue.TOP_FRACTION).
const CAMERA_FRACTION: float = 0.517
## The flashes peaked between half and full white in the recordings.
const FLASH_ALPHA: float = 0.9

## Off in tests that only need the script's effects: building a map's tileset is slow.
@export var draw_map: bool = true

var bin: EventBin = null
var bin_id: String = ""
var layer_id: int = -1
var actors: Dictionary = {}  # key ("pc1", "e9") -> EventActor
## Text ids in the order they were shown.
var lines_shown: Array[int] = []
var movies_played: Array[String] = []
var bgm_played: Array[String] = []
var ssbp_played: Array[String] = []
var vfx_played: Array[String] = []
var active_ssbp: Dictionary = {}  # eff_id (int) -> Array[SsbpPlayer]
var active_vfx: Dictionary = {}   # vfx_id (int) -> Dictionary
var dialogue: EventDialogue
var banner: EventBanner
var camera: Camera2D

var _texts: Dictionary = {}    # text id -> raw line
var _tellers: Dictionary = {}  # teller id -> display name
var _images: Dictionary = {}   # image id -> texture path
var _tile_map: Node = null
var _actor_root: Node2D
var _screen_effects: Node2D
var _camera_target: Vector2 = Vector2.ZERO
var _camera_speed: float = 0.0
var _camera_moving: bool = false
var _fade: ColorRect
var _fade_from: float = 0.0
var _fade_to: float = 0.0
var _fade_frames: int = 0
var _fade_age: int = 0
var _flash: ColorRect
var _flash_frames: int = 0
var _flash_age: int = 0
var _flash_half_period: int = 1
var _movie_root: ColorRect
var _movie_player: VideoStreamPlayer
var _movie_playing: bool = false
var _movie_frames_left: int = 0


func _ready() -> void:
	_tile_map = get_node_or_null("TileMap")
	_actor_root = Node2D.new()
	_actor_root.name = "Actors"
	_actor_root.y_sort_enabled = true
	_actor_root.z_index = 5
	add_child(_actor_root)
	camera = Camera2D.new()
	camera.name = "Camera"
	add_child(camera)
	camera.make_current()
	var screen_height: float = get_viewport().get_visible_rect().size.y
	camera.offset = Vector2(0, screen_height * (0.5 - CAMERA_FRACTION))

	var screen := CanvasLayer.new()
	screen.name = "Screen"
	screen.layer = 10
	add_child(screen)
	_screen_effects = Node2D.new()
	_screen_effects.name = "ScreenEffects"
	screen.add_child(_screen_effects)
	# The flash covers the map but not the cinema window; the fade covers both.
	_flash = _screen_rect(screen, "Flash")
	banner = EventBanner.new()
	banner.name = "Banner"
	screen.add_child(banner)
	dialogue = EventDialogue.new()
	dialogue.name = "Dialogue"
	dialogue.name_resolver = _speaker_name
	screen.add_child(dialogue)
	_movie_root = _screen_rect(screen, "Movie")
	_movie_root.color = Color.BLACK
	var movie_aspect := AspectRatioContainer.new()
	movie_aspect.name = "Aspect"
	movie_aspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	movie_aspect.ratio = MOVIE_ASPECT_RATIO
	movie_aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	movie_aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_movie_root.add_child(movie_aspect)
	_movie_player = VideoStreamPlayer.new()
	_movie_player.name = "Video"
	_movie_player.expand = true
	_movie_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_movie_player.finished.connect(_on_movie_finished)
	movie_aspect.add_child(_movie_player)
	_fade = _screen_rect(screen, "Fade")
	_fade.color = Color.BLACK


## Loads what the bin's scenes need besides the bin: its text and teller files and the
## images its records can show.
func setup(event_bin: EventBin, id: String) -> void:
	bin = event_bin
	bin_id = id
	lines_shown.clear()
	movies_played.clear()
	bgm_played.clear()
	ssbp_played.clear()
	vfx_played.clear()
	clear_effects()
	stop_movie()
	stop_ambient(0.0)
	var folder: String = bin.path.get_base_dir()
	_texts = _read_csv(folder.path_join("%s_event_text.txt" % id))
	# Teller ids are local to a town (200020 is "Villager" in Mitra), so the map's own
	# list comes before the common one, and the bin's before both.
	_tellers = _read_csv(MAP_COMMON + "common_teller.txt")
	_tellers.merge(_read_csv(TOWN_DATA + _map_id() + "/map_teller.txt"), true)
	_tellers.merge(_read_csv(folder.path_join("%s_event_teller.txt" % id)), true)
	# Image ids resolve through the bin's manifest, then the map's (record images such
	# as 20027 are mapchips of the map), then map_common/common_image.txt.
	_images.clear()
	var common: Dictionary = _read_csv(MAP_COMMON + "common_image.txt", false)
	for image_id in common:
		_images[image_id] = MAP_COMMON + str(common[image_id]).split(",")[0]
	_images.merge(_read_map_manifest(_map_id()), true)
	for marker in bin.assets:
		_images[marker] = folder.path_join(str(bin.assets[marker]))


## Shows layer `id`: draws it (when the map exists) and puts out the records whose live
## page has a graphic. Clears every actor from the previous layer.
func load_layer(id: int, switches: Dictionary) -> void:
	layer_id = id
	for actor in actors.values():
		actor.queue_free()
	actors.clear()
	clear_effects()
	_draw_map_layer(id)
	var layer: EventBin.Layer = bin.get_layer(id)
	if layer == null:
		push_warning("EventStage: bin %s has no layer %d" % [bin_id, id])
		return
	for record in layer.records:
		var page: EventBin.Page = record.active_page(switches)
		if page != null and not page.graphic.is_empty():
			record_actor(record.slot, switches)


## The party member with cast index `index` (map_character<index>.png), created on first
## use at the world origin.
func party_actor(index: int) -> EventActor:
	var key: String = "pc%d" % index
	if actors.has(key):
		return actors[key]
	var actor: EventActor = _new_actor(key)
	if not actor.use_party_sheet(index):
		push_warning("EventStage: no map_character%d.png" % index)
	return actor


## The record in `slot` on the current layer, created on first use at its own position
## with its live page's graphic (invisible when it has none).
func record_actor(slot: int, switches: Dictionary = {}) -> EventActor:
	var key: String = "e%d" % slot
	if actors.has(key):
		return actors[key]
	var actor: EventActor = _new_actor(key)
	var layer: EventBin.Layer = bin.get_layer(layer_id) if bin != null else null
	var record: EventBin.Record = layer.record_by_slot(slot) if layer != null else null
	if record != null:
		actor.position = Vector2(record.x, record.y)
		var page: EventBin.Page = record.active_page(switches)
		if page != null and not page.graphic.is_empty():
			if not actor.use_graphic(page.graphic, _images, Vector2i(record.width, record.height)):
				push_warning("EventStage: cannot draw graphic %s of record %d" % [page.graphic, slot])
			actor.visible = page.visible
	return actor


## Moves the camera so that `target` is the centre of the screen, at `speed` px per
## frame; 0 jumps.
func camera_to(target: Vector2, speed: float) -> void:
	if speed <= 0.0:
		camera.position = target
		_camera_moving = false
		for entry in active_vfx.values():
			var node: Node2D = entry.get("node") as Node2D
			if is_instance_valid(node):
				var sp: Vector2 = _world_to_screen(node.position)
				for em_name in ["emitter", "emitter2"]:
					var em: Node2D = entry.get(em_name) as Node2D
					if is_instance_valid(em) and em.get_parent() == _screen_effects:
						em.position = sp
		return
	_camera_target = target
	_camera_speed = speed
	_camera_moving = not target.is_equal_approx(camera.position)


func camera_position() -> Vector2:
	return camera.position


## Fades the screen out to `color` or back in over `frames` frames.
func fade(fade_out: bool, color: Color, frames: int) -> void:
	_fade.color = Color(color, _fade.color.a)
	_fade_from = _fade.color.a
	_fade_to = 1.0 if fade_out else 0.0
	_fade_frames = maxi(frames, 0)
	_fade_age = 0
	if _fade_frames == 0:
		_set_fade_alpha(_fade_to)


## Starts the screen fully faded out (scenes that open with a fade-in).
func set_black() -> void:
	_fade.color = Color.BLACK
	_fade_frames = 0
	_fade_to = 1.0
	_set_fade_alpha(1.0)


func fade_alpha() -> float:
	return _fade.color.a


## `pulses` flashes of `color` over the map, each on for `half_period` frames and off
## for as many (❓ CUTSCENE-PLAN.md section 8.6).
func flash(color: Color, half_period: int, pulses: int) -> void:
	_flash.color = Color(color, 0.0)
	_flash_half_period = maxi(half_period, 1)
	_flash_frames = _flash_half_period * 2 * maxi(pulses, 1)
	_flash_age = 0
	_flash.visible = true
	_flash.color.a = FLASH_ALPHA


## The location banner of op 0x6e.
func show_banner(file_name: String, hold_frames: int) -> void:
	banner.show_banner(file_name, hold_frames)


## Plays movie `file_name` (e.g. "op_clip.usm" -> res://assets/movies/op_clip.ogv)
## full-screen and blocks the stage until playback completes or is skipped.
func play_movie(file_name: String) -> void:
	movies_played.append(file_name)
	var stem: String = file_name.get_file().get_basename()
	var movie_path: String = MOVIES_DIR + stem + ".ogv"
	if not ResourceLoader.exists(movie_path):
		push_warning("EventStage: missing movie %s" % movie_path)
		return
	var res: Resource = ResourceLoader.load(movie_path)
	if not (res is VideoStream):
		push_warning("EventStage: invalid movie resource %s" % movie_path)
		return
	stop_bgm()
	if _fade != null:
		_fade.visible = false
		_fade.color.a = 0.0
	_movie_player.stream = res as VideoStream
	_movie_root.visible = true
	_movie_playing = true
	_movie_player.play()
	var length_sec: float = _movie_player.get_stream_length()
	if length_sec > 0.0:
		_movie_frames_left = int(ceilf(length_sec * 60.0)) + 30
	else:
		_movie_frames_left = DEFAULT_MOVIE_FRAMES


func stop_movie() -> void:
	if _movie_player != null and _movie_player.is_playing():
		_movie_player.stop()
	_movie_playing = false
	_movie_frames_left = 0
	if _movie_root != null:
		_movie_root.visible = false


func is_movie_playing() -> bool:
	return _movie_playing


func play_bgm(file_name: String, fade_in_sec: float = 0.0) -> void:
	bgm_played.append(file_name)
	var stem: String = file_name.get_file().get_basename()
	while stem.begins_with("!"):
		stem = stem.substr(1)
	for ext in [".ogg", ".wav", ".mp3"]:
		var candidate: String = BGM_DIR + stem + ext
		if ResourceLoader.exists(candidate) or FileAccess.file_exists(candidate):
			if AudioService.is_music_playing() and AudioService.current_music_path() == candidate:
				return
			if fade_in_sec > 0.05:
				AudioService.fade_in_music(candidate, fade_in_sec)
			else:
				AudioService.play_music(candidate)
			return
	push_warning("EventStage: missing BGM %s (%s)" % [file_name, stem])


func stop_bgm(fade_sec: float = 0.0) -> void:
	if fade_sec > 0.05:
		AudioService.fade_out_music(fade_sec)
	else:
		# Use a smooth 0.2s micro-fade to avoid audio popping and abrupt cuts
		AudioService.fade_out_music(0.2)


func stop_ambient(fade_sec: float = 0.5) -> void:
	AudioService.stop_ambient(fade_sec)


func stop_se(_fade_sec: float = 0.0) -> void:
	AudioService.stop_all_sfx()


const SE_EVENT_MAP: Dictionary = {
	107: "res://assets/audio/sfx/se_ev_crystal_appeare.wav",
	106: "res://assets/audio/sfx/se_ev_crystal_appeare.wav",
	55: "res://assets/audio/sfx/se_ev_crystal_disappeare.wav",
	35: "res://assets/audio/sfx/se_ev_crystal_appeare.wav",
	36: "res://assets/audio/sfx/se_ev_crystal_disappeare.wav",
	4: "res://assets/audio/sfx/se_ev_airship_bang.wav",
	1: "res://assets/audio/sfx/se_ev_common_impact1.wav",
	2: "res://assets/audio/sfx/se_ev_common_flush.wav",
	10: "res://assets/audio/sfx/se_ev_light_pray.wav",
	30: "res://assets/audio/sfx/se_ev_thunder.wav",
}

var _se_map: Dictionary = {}

func _load_se_map() -> void:
	if not _se_map.is_empty():
		return
	if FileAccess.file_exists("res://assets/audio/system_se_map.json"):
		var f: FileAccess = FileAccess.open("res://assets/audio/system_se_map.json", FileAccess.READ)
		if f:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Dictionary:
				for k in (parsed as Dictionary):
					_se_map[int(k)] = str((parsed as Dictionary)[k])


func play_se(se_id: int) -> void:
	_load_se_map()
	var path: String = SE_EVENT_MAP.get(se_id, "")
	if path == "":
		var sfx_name: String = _se_map.get(se_id, "")
		if sfx_name != "":
			if ";" in sfx_name:
				sfx_name = sfx_name.split(";")[0].strip_edges()
			path = "res://assets/audio/sfx/" + sfx_name + ".wav"
	if path != "" and (ResourceLoader.exists(path) or FileAccess.file_exists(path)):
		AudioService.play_sfx(path)


func play_map_ambient(map_id: String) -> void:
	if "cave" in map_id.to_lower():
		var amb: String = BGM_DIR + "bg_Cave.ogg"
		if FileAccess.file_exists(amb):
			AudioService.play_ambient(amb, true, -18.0)
	else:
		if AudioService.is_ambient_playing():
			AudioService.stop_ambient(0.5)


## Spawns a SpriteStudio (.ssbp) map/event effect (op 0x55 or map effect_spawner).
## World-space backdrops (z <= 5, e.g. ev_opening.ssbp on the airship deck) draw at
## z_index -1 behind TileMap sublayer 0 so they show through transparent railing and
## sky cutouts; foreground effects (z >= 6) draw at z_index 7 above the actors.
## Screen-space effects (screen_space == true) sit inside the Screen CanvasLayer.
func play_ssbp(eff_id: int, file_name: String, anim_ref: String, pos: Vector2, z: int, screen_space: bool = false) -> SsbpPlayer:
	ssbp_played.append(anim_ref)
	var ssbp_path: String = SSBP_DIR + file_name.get_file()
	if not FileAccess.file_exists(ssbp_path):
		push_warning("EventStage: missing ssbp %s" % ssbp_path)
		return null
	var list: Array = active_ssbp.get(eff_id, [])
	for i in range(list.size() - 1, -1, -1):
		var existing: SsbpPlayer = list[i]
		if is_instance_valid(existing) and existing.position.is_equal_approx(pos) and existing.animation == anim_ref:
			if existing.get_parent() != null:
				existing.get_parent().remove_child(existing)
			existing.free()
			list.remove_at(i)
	var player := SsbpPlayer.new()
	player.name = "Ssbp_%d_%s" % [eff_id, anim_ref.replace("/", "_")]
	player.position = pos
	if screen_space and _screen_effects != null:
		_screen_effects.add_child(player)
	else:
		player.z_index = -1 if z <= 5 else 7
		add_child(player)
	player.open(ssbp_path, anim_ref)
	list.append(player)
	active_ssbp[eff_id] = list
	return player


func stop_ssbp(eff_id: int = 0) -> void:
	if eff_id <= 0:
		for id in active_ssbp.keys():
			for player in active_ssbp[id]:
				if is_instance_valid(player):
					if player.get_parent() != null:
						player.get_parent().remove_child(player)
					player.free()
		active_ssbp.clear()
		return
	if not active_ssbp.has(eff_id):
		return
	for player in active_ssbp[eff_id]:
		if is_instance_valid(player):
			if player.get_parent() != null:
				player.get_parent().remove_child(player)
			player.free()
	active_ssbp.erase(eff_id)


## Spawns an Effekseer (.bmb -> .efkefc) visual effect (op 0x5f or map effect_spawner).
## z <= 5 draws at z_index 4 behind actors (_actor_root.z_index == 5); z >= 6 draws in
## front of actors. When `loop` is true, tick() restarts the emitter whenever its
## particle cycle ends until stop_vfx(vfx_id) (op 0x66) or layer transition.
func play_vfx(vfx_id: int, file_name: String, pos: Vector2, z: int, scale_pct: int = 100, loop: bool = false) -> Node2D:
	vfx_played.append(file_name)
	if vfx_id > 0 and active_vfx.has(vfx_id):
		stop_vfx(vfx_id)
	var stem: String = file_name.get_file().get_basename()
	var efk_path: String = VFX_DIR + stem + ".efkefc"
	var holder := Node2D.new()
	holder.name = "Vfx_%d_%s" % [vfx_id, stem]
	holder.position = pos
	holder.z_index = 4 if z <= 5 else z
	var scale_factor: float = float(scale_pct if scale_pct > 0 else 100) / 100.0
	holder.scale = Vector2(scale_factor, scale_factor)
	add_child(holder)
	var emitter: Node2D = null
	var emitter2: Node2D = null
	if ResourceLoader.exists(efk_path) and ClassDB.class_exists("EffekseerEmitter2D"):
		var res: Resource = ResourceLoader.load(efk_path)
		if res != null:
			var inst: Variant = ClassDB.instantiate("EffekseerEmitter2D")
			if inst is Node2D:
				emitter = inst as Node2D
				emitter.set("effect", res)
				emitter.set("autoplay", false)
				emitter.scale = Vector2(scale_factor, scale_factor)
				if _screen_effects != null:
					_screen_effects.add_child(emitter)
					emitter.position = _world_to_screen(pos)
				else:
					holder.add_child(emitter)
				emitter.call("play")
			if loop:
				var inst2: Variant = ClassDB.instantiate("EffekseerEmitter2D")
				if inst2 is Node2D:
					emitter2 = inst2 as Node2D
					emitter2.set("effect", res)
					emitter2.set("autoplay", false)
					emitter2.scale = Vector2(scale_factor, scale_factor)
					if _screen_effects != null:
						_screen_effects.add_child(emitter2)
						emitter2.position = _world_to_screen(pos)
					else:
						holder.add_child(emitter2)
	active_vfx[vfx_id] = {
		"node": holder,
		"emitter": emitter,
		"emitter2": emitter2,
		"loop": loop,
		"file_name": file_name,
		"age": 0,
	}
	return holder


func _world_to_screen(world_pos: Vector2) -> Vector2:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var cam_center: Vector2 = camera.position + camera.offset if camera != null else view_size * 0.5
	return world_pos - cam_center + view_size * 0.5


func stop_vfx(vfx_id: int) -> void:
	if not active_vfx.has(vfx_id):
		return
	var entry: Dictionary = active_vfx[vfx_id]
	for em_name in ["emitter", "emitter2"]:
		var em: Node = entry.get(em_name)
		if is_instance_valid(em):
			if em.get_parent() != null:
				em.get_parent().remove_child(em)
			em.free()
	var node: Node = entry.get("node")
	if is_instance_valid(node):
		if node.get_parent() != null:
			node.get_parent().remove_child(node)
		node.free()
	active_vfx.erase(vfx_id)


func clear_effects() -> void:
	stop_ssbp(0)
	for vfx_id in active_vfx.keys():
		var entry: Dictionary = active_vfx[vfx_id]
		for em_name in ["emitter", "emitter2"]:
			var em: Node = entry.get(em_name)
			if is_instance_valid(em):
				if em.get_parent() != null:
					em.get_parent().remove_child(em)
				em.free()
		var node: Node = entry.get("node")
		if is_instance_valid(node):
			if node.get_parent() != null:
				node.get_parent().remove_child(node)
			node.free()
	active_vfx.clear()


func _on_movie_finished() -> void:
	_movie_playing = false
	_movie_frames_left = 0
	if _movie_root != null:
		_movie_root.visible = false


func show_text(text_id: int) -> void:
	var raw: String = str(_texts.get(text_id, "[text %d]" % text_id))
	dialogue.show_line(text_id, raw)
	lines_shown.append(text_id)
	line_shown.emit(text_id)


func set_panel_visible(shown: bool) -> void:
	dialogue.visible = shown


func panel_visible() -> bool:
	return dialogue.visible


## A tap from the player; true when dialogue or movie used it.
func tap() -> bool:
	if _movie_playing:
		stop_movie()
		return true
	return dialogue.tap()


## One frame of every running movement and effect.
func tick() -> void:
	for actor in actors.values():
		actor.tick()
	if _camera_moving:
		var delta: Vector2 = _camera_target - camera.position
		var distance: float = delta.length()
		if distance <= _camera_speed:
			camera.position = _camera_target
			_camera_moving = false
		else:
			camera.position += delta / distance * _camera_speed
	if _fade_frames > 0 and _fade_age < _fade_frames:
		_fade_age += 1
		_set_fade_alpha(lerpf(_fade_from, _fade_to, float(_fade_age) / float(_fade_frames)))
	if _flash.visible:
		_flash_age += 1
		if _flash_age >= _flash_frames:
			_flash.visible = false
		else:
			var lit: bool = (_flash_age / _flash_half_period) % 2 == 0
			_flash.color.a = FLASH_ALPHA if lit else 0.0
	if _movie_playing:
		_movie_frames_left -= 1
		if _movie_frames_left <= 0 or not _movie_player.is_playing():
			stop_movie()
	for vfx_id in active_vfx.keys():
		var entry: Dictionary = active_vfx[vfx_id]
		var node: Node2D = entry.get("node") as Node2D
		if is_instance_valid(node):
			var sp: Vector2 = _world_to_screen(node.position)
			for em_name in ["emitter", "emitter2"]:
				var em: Node2D = entry.get(em_name) as Node2D
				if is_instance_valid(em) and em.get_parent() == _screen_effects:
					em.position = sp
		if DisplayServer.get_name() != "headless" and bool(entry.get("loop", false)):
			entry["age"] = int(entry.get("age", 0)) + 1
			var age: int = int(entry["age"])
			var emitter: Node2D = entry.get("emitter") as Node2D
			var emitter2: Node2D = entry.get("emitter2") as Node2D
			if is_instance_valid(emitter) and is_instance_valid(emitter2):
				if age % 100 == 0:
					var cycle: int = (age / 100) % 2
					if cycle == 1:
						emitter2.call("play")
					else:
						emitter.call("play")
			elif is_instance_valid(emitter) and not bool(emitter.call("is_playing")):
				emitter.call("play")
	banner.tick()
	dialogue.tick()


## Anything still moving or waiting on the player: what `advance` waits for.
func is_busy() -> bool:
	if _movie_playing or _camera_moving or _flash.visible or dialogue.is_busy():
		return true
	if _fade_frames > 0 and _fade_age < _fade_frames:
		return true
	for actor in actors.values():
		if actor.is_busy():
			return true
	return false


func _new_actor(key: String) -> EventActor:
	var actor := EventActor.new()
	actor.key = key
	actor.name = key
	_actor_root.add_child(actor)
	actors[key] = actor
	return actor


## Event bins sit on the map whose folder shares their first seven digits
## (111010105 -> 111010100).
func _map_id() -> String:
	return bin_id.substr(0, 7) + "00" if bin_id.length() >= 7 else ""


## A map.bin's texture manifest: atlas id -> path. The 32-byte header ends with the
## entry count; entries are u16 atlas id, u16 length, file name.
static func _read_map_manifest(map_id: String) -> Dictionary:
	var out: Dictionary = {}
	var map_path: String = TOWN_DATA + map_id + "/map.bin"
	if map_id == "" or not FileAccess.file_exists(map_path):
		return out
	var file := FileAccess.open(map_path, FileAccess.READ)
	file.big_endian = true
	file.seek(28)
	var count: int = file.get_32()
	for i in count:
		var atlas_id: int = file.get_16()
		var file_name: String = file.get_buffer(file.get_16()).get_string_from_ascii()
		out[atlas_id] = TOWN_DATA + map_id + "/" + file_name
	return out


func _draw_map_layer(id: int) -> void:
	if not draw_map or _tile_map == null:
		return
	var map_id: String = _map_id()
	if map_id == "" or not FileAccess.file_exists(TOWN_DATA + map_id + "/map.bin"):
		push_warning("EventStage: no map %s for bin %s" % [map_id, bin_id])
		return
	if str(_tile_map.get("town_id")) != map_id:
		_tile_map.call("load_town", map_id)
	if not bool(_tile_map.call("show_layer", id)):
		push_warning("EventStage: map %s has no layer %d" % [map_id, id])
		return
	play_map_ambient(map_id)
	_spawn_chunk_effects(_tile_map.get("_active_chunk_data"))


func _spawn_chunk_effects(chunk_data: Variant) -> void:
	if not (chunk_data is Dictionary):
		return
	var objects: Variant = (chunk_data as Dictionary).get("objects")
	if not (objects is Dictionary):
		return
	var entities: Variant = (objects as Dictionary).get("dynamic_entities")
	if not (entities is Array):
		return
	for entity in entities as Array:
		if not (entity is Dictionary):
			continue
		var e: Dictionary = entity as Dictionary
		if String(e.get("kind", "")) != "effect_spawner":
			continue
		var payload_hex: String = String(e.get("payload_hex", ""))
		if payload_hex == "":
			continue
		var commands: Array[Dictionary] = EventInterpreter.extract_spawner_effects(payload_hex.hex_decode())
		for cmd in commands:
			var op: int = int(cmd.get("op", 0))
			if op == EventInterpreter.OP_PLAY_SSBP:
				play_ssbp(
					int(cmd["eff_id"]),
					str(cmd["file_name"]),
					str(cmd["anim_ref"]),
					cmd["pos"] as Vector2,
					int(cmd["z"]),
					bool(cmd["screen_space"])
				)
			elif op == EventInterpreter.OP_PLAY_VFX:
				var file_name: String = str(cmd["file_name"])
				var loop: bool = int(cmd["end_flag"]) != 0 or EventInterpreter.is_persistent_crystal(file_name)
				play_vfx(
					int(cmd["vfx_id"]),
					file_name,
					cmd["pos"] as Vector2,
					int(cmd["z"]),
					int(cmd["scale_pct"]),
					loop
				)


func _set_fade_alpha(alpha: float) -> void:
	_fade.color.a = alpha
	_fade.visible = alpha > 0.0


func _speaker_name(id: int, kind: String) -> String:
	if kind == "name" and _tellers.has(id):
		return str(_tellers[id])
	var npc_name: String = GameDatabase.get_npc_name(id)
	if npc_name != "":
		return npc_name
	return str(_tellers.get(id, ""))


func _screen_rect(parent: Node, node_name: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.color = Color(1, 1, 1, 0)
	rect.visible = false
	parent.add_child(rect)
	return rect


## `<int id>,<rest of the line>` files: text, teller and image lists. The text and
## teller files are UTF-8; common_image.txt carries Shift-JIS descriptions after its
## ASCII id and file name, so it is read as bytes (`utf8` false) instead of making
## Godot report an invalid UTF-8 byte.
static func _read_csv(file_path: String, utf8: bool = true) -> Dictionary:
	var out: Dictionary = {}
	if not FileAccess.file_exists(file_path):
		return out
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(file_path)
	var text: String = bytes.get_string_from_utf8() if utf8 else bytes.get_string_from_ascii()
	for line in text.split("\n"):
		var comma: int = line.find(",")
		if comma <= 0:
			continue
		var key: String = line.substr(0, comma).strip_edges()
		if key.is_valid_int():
			out[int(key)] = line.substr(comma + 1).strip_edges(false, true)
	return out
