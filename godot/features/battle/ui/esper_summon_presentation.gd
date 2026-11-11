class_name EsperSummonPresentation
extends Control

## Battle-only presentation for Esper casts whose primary Effekseer resource is absent.

signal sequence_finished(action_id: int)

const ESPER_DIR: String = "res://assets/esper/"
const SHADE_IN_SECONDS: float = 0.25
const ESPER_MOVE_SECONDS: float = 0.65
const EFFECT_HOLD_SECONDS: float = 0.45
const FADE_OUT_SECONDS: float = 0.25
const ESPER_SIZE: Vector2 = Vector2(420.0, 350.0)

static var _texture_cache: Dictionary = {}

var _jobs: Array[Dictionary] = []
var _running: bool = false
var _shade: ColorRect
var _esper: TextureRect
var _held_hits: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 100
	_shade = ColorRect.new()
	_shade.name = "SummonShade"
	_shade.color = Color(0.0, 0.0, 0.0, 0.0)
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shade)
	_esper = TextureRect.new()
	_esper.name = "EsperPortrait"
	_esper.custom_minimum_size = ESPER_SIZE
	_esper.size = ESPER_SIZE
	_esper.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_esper.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_esper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_esper.visible = false
	add_child(_esper)


static func should_fallback(is_evocation: bool, has_primary_effect: bool) -> bool:
	return is_evocation and not has_primary_effect


static func image_path_for_esper(esper_id: int) -> String:
	if esper_id <= 0:
		return ""
	var data: Dictionary = GameDatabase.get_esper(esper_id)
	var image_name: String = str(data.get("beastImage", "")).strip_edges()
	if image_name == "" or image_name.get_file() != image_name:
		return ""
	return ESPER_DIR + image_name


static func texture_for_esper(esper_id: int) -> Texture2D:
	var path: String = image_path_for_esper(esper_id)
	if path == "":
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var texture: Texture2D = ResourceLoader.load(path) as Texture2D if ResourceLoader.exists(path) else null
	_texture_cache[path] = texture
	return texture


static func sequence_stages(has_texture: bool) -> Array[String]:
	var stages: Array[String] = ["dim"]
	if has_texture:
		stages.append("esper_enters")
	stages.append("available_effects")
	stages.append("damage")
	return stages


static func _effect_file_names(effect_frames: Array) -> Array[String]:
	var names: Array[String] = []
	for group in effect_frames:
		if not (group is Array):
			continue
		for effect in group:
			if not (effect is Dictionary):
				continue
			var effect_names: Array = GameDatabase.get_effect_data(int(effect.get("effect_id", 0)))
			for effect_name_variant in effect_names:
				var effect_name: String = str(effect_name_variant).get_file()
				var is_esper_effect: bool = effect_name.begins_with("sm_") or effect_name.begins_with("summom_")
				if is_esper_effect and not effect_name.contains("_bg"):
					names.append(effect_name)
	return names


static func is_primary_esper_effect(effect_frames: Array) -> bool:
	for effect_name in _effect_file_names(effect_frames):
		var path: String = "res://assets/battle_effect/" + effect_name.replace(".bmb", ".efkefc")
		if ResourceLoader.exists(path):
			return true
	return false


static func available_effect_frames(effect_frames: Array) -> Array:
	var available: Array = []
	for group in effect_frames:
		if not (group is Array):
			continue
		var available_group: Array = []
		for effect in group:
			if not (effect is Dictionary):
				continue
			var effect_id: int = int(effect.get("effect_id", 0))
			var effect_names: Array = GameDatabase.get_effect_data(effect_id)
			var has_existing_effect: bool = false
			for effect_name_variant in effect_names:
				var effect_name: String = str(effect_name_variant).get_file()
				var effect_path: String = "res://assets/battle_effect/" + effect_name.replace(".bmb", ".efkefc")
				if ResourceLoader.exists(effect_path):
					has_existing_effect = true
					break
			if has_existing_effect:
				available_group.append(effect.duplicate(true))
		if not available_group.is_empty():
			available.append(available_group)
	return available


func enqueue(action_id: int, esper_id: int, effect_frames: Array, effect_player: Callable, speed: float = 1.0) -> void:
	_jobs.append({
		"action_id": action_id,
		"esper_id": esper_id,
		"effect_frames": effect_frames.duplicate(true),
		"speed": maxf(speed, 0.25),
		"effect_player": effect_player,
	})
	if not _running:
		_running = true
		_run_next.call_deferred()


func hold_hit(action_id: int, event: Dictionary) -> bool:
	if not _held_hits.has(action_id):
		return false
	(_held_hits[action_id] as Array).append(event.duplicate(true))
	return true


func begin_holding_hits(action_id: int) -> void:
	_held_hits[action_id] = []


func release_hits(action_id: int) -> Array[Dictionary]:
	var hits: Array[Dictionary] = []
	for event in _held_hits.get(action_id, []):
		hits.append(event)
	_held_hits.erase(action_id)
	return hits


func clear() -> void:
	_jobs.clear()
	_held_hits.clear()
	_running = false
	if is_instance_valid(_esper):
		_esper.visible = false
	if is_instance_valid(_shade):
		_shade.color.a = 0.0


func _run_next() -> void:
	if _jobs.is_empty() or not is_inside_tree():
		_running = false
		return
	var job: Dictionary = _jobs.pop_front()
	var texture: Texture2D = texture_for_esper(int(job["esper_id"]))
	_shade.color.a = 0.0
	_esper.visible = texture != null
	_esper.texture = texture
	_esper.modulate.a = 1.0
	if texture != null:
		_esper.position = Vector2(size.x, (size.y - ESPER_SIZE.y) * 0.5)
	var intro: Tween = create_tween().set_parallel()
	intro.tween_property(_shade, "color:a", 0.72, SHADE_IN_SECONDS)
	if texture != null:
		intro.tween_property(_esper, "position:x", (size.x - ESPER_SIZE.x) * 0.5, ESPER_MOVE_SECONDS) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await intro.finished
	var play_effect: Callable = job["effect_player"]
	if play_effect.is_valid():
		play_effect.call(job["effect_frames"])
	await get_tree().create_timer(EFFECT_HOLD_SECONDS / maxf(float(job.get("speed", 1.0)), 0.25)).timeout
	var outro: Tween = create_tween().set_parallel()
	outro.tween_property(_shade, "color:a", 0.0, FADE_OUT_SECONDS)
	if texture != null:
		outro.tween_property(_esper, "modulate:a", 0.0, FADE_OUT_SECONDS)
	await outro.finished
	_esper.visible = false
	sequence_finished.emit(int(job["action_id"]))
	_run_next.call_deferred()
