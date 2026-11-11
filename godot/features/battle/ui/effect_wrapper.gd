class_name SkillEffectWrapper
extends Node2D

const MAX_EFFECT_LIFETIME_SECONDS: float = 3.0

## Used when a skill names an effect file that is not in the project. Most of
## these come from newer data rows than the bundled effect set, so without a
## stand-in the attack plays silently with no visual at all. A short impact flash
## keeps the hit readable.
const FALLBACK_EFFECT_PATH: String = "res://assets/battle_effect/atk_impact_001_white_flashcut.efkefc"

var effect_path: String = ""
## True when the requested file was absent and the stand-in is playing instead.
var used_fallback: bool = false
var _delay: float = 0.0
var _emitter: EffekseerEmitter2D = null


func setup(path: String, delay: float) -> void:
	effect_path = path
	_delay = delay
	var resolved: String = path
	if not ResourceLoader.exists(resolved):
		print("Resource for effect not found: " + path)
		if ResourceLoader.exists(FALLBACK_EFFECT_PATH):
			resolved = FALLBACK_EFFECT_PATH
			used_fallback = true
	if ResourceLoader.exists(resolved):
		_emitter = EffekseerEmitter2D.new()
		_emitter.effect = load(resolved)
		add_child(_emitter)


func _ready() -> void:
	if not is_instance_valid(_emitter):
		# Neither the effect nor the stand-in exists: nothing would ever play or
		# finish, so free immediately instead of lingering as an invisible node.
		queue_free()
		return
	if _delay > 0.0:
		var tween: Tween = create_tween()
		tween.bind_node(self)
		tween.tween_callback(play_effect).set_delay(_delay)
	else:
		play_effect()


func play_effect() -> void:
	if is_instance_valid(_emitter):
		if DisplayServer.get_name() != "headless":
			_emitter.play()
		if _emitter.has_user_signal("finished") or _emitter.has_signal("finished"):
			if not _emitter.is_connected("finished", _on_effect_finished):
				_emitter.connect("finished", _on_effect_finished)
		var cleanup: Tween = create_tween()
		cleanup.bind_node(self)
		cleanup.tween_callback(_on_effect_finished).set_delay(MAX_EFFECT_LIFETIME_SECONDS)


func _on_effect_finished() -> void:
	queue_free()
