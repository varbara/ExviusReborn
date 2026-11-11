extends RefCounted
class_name EffectSpawner

## Effect frame offsets are in frames (1/60 s), the unit of effectFrames.
const FRAMES_PER_SECOND: float = 60.0
const IMPACT_WHITE: String = "res://assets/battle_effect/atk_impact_001_white_flashcut.efkefc"
const IMPACT_ORANGE: String = "res://assets/battle_effect/atk_impact_001_orange_flashcut.efkefc"
const IMPACT_BLUE: String = "res://assets/battle_effect/atk_impact_001_blue_flashcut.efkefc"

var _host: Node
var spawned_paths: Array[String] = []


func _init(host: Node) -> void:
	_host = host


## Plays a skill's effects (its record's `effect_frames`) in the middle of `container`,
## each starting its frame offset into the cast. `speed` is the battle's speed, so the
## effects keep pace with the hits at 2x or 4x.
func spawn(effect_data: Array, container: Control, speed: float = 1.0) -> int:
	if container == null or _host == null or not is_instance_valid(_host):
		return 0
	var count: int = 0
	for group in effect_data:
		if not (group is Array):
			continue
		for eff in group:
			if not (eff is Dictionary):
				continue
			var effect_names: Array = GameDatabase.get_effect_data(int(eff.get("effect_id", 0)))
			var delay: float = float(eff.get("frame_offset", 0)) / FRAMES_PER_SECOND / maxf(speed, 0.01)
			for e in effect_names:
				var file_name: String = str(e).replace(".bmb", ".efkefc")
				var path: String = "res://assets/battle_effect/" + file_name
				if spawn_one(path, container, delay) != null:
					count += 1
	return count


## Spawns a single `.efkefc` effect centred inside `container`.
func spawn_one(path: String, container: Control, delay: float = 0.0) -> SkillEffectWrapper:
	if container == null or _host == null or not is_instance_valid(_host):
		return null
	if not ResourceLoader.exists(path):
		return null
	var wrapper := SkillEffectWrapper.new()
	wrapper.z_index = 10
	wrapper.setup(path, delay)
	container.add_child(wrapper)
	wrapper.position = container.size * 0.5
	spawned_paths.append(path)
	return wrapper


## Spawns an immediate hit-spark impact effect on `container`.
func spawn_hit_impact(container: Control, spark: bool = false, magic: bool = false) -> SkillEffectWrapper:
	var path: String = IMPACT_ORANGE if spark else (IMPACT_BLUE if magic else IMPACT_WHITE)
	return spawn_one(path, container, 0.0)
