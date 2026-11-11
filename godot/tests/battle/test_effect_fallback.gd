extends "res://tests/test_case.gd"

## Many abilities name effect files that the bundled effect set does not contain
## (the data is newer than the assets). Before this, such an effect produced
## nothing at all in battle: the wrapper freed itself silently. The wrapper now
## substitutes a stand-in so the hit stays readable, and it says so.

const WRAPPER_SCRIPT = preload("res://features/battle/ui/effect_wrapper.gd")


## The stand-in itself has to exist, or the fallback is theatre.
func test_fallback_effect_file_exists() -> void:
	assert_true(ResourceLoader.exists(WRAPPER_SCRIPT.FALLBACK_EFFECT_PATH),
		"the fallback effect ships with the project")


## A missing file falls back instead of playing nothing. The wrapper is not added
## to the tree here, so its children are inspected directly instead of running
## _ready (which would free the node).
func test_missing_effect_uses_the_fallback() -> void:
	var wrapper: Node2D = WRAPPER_SCRIPT.new()
	wrapper.setup("res://assets/battle_effect/this_effect_does_not_exist_98765.efkefc", 0.0)
	assert_true(wrapper.used_fallback, "a missing effect falls back")
	assert_eq(wrapper.get_child_count(), 1, "a stand-in emitter was added")
	wrapper.free()


## A real effect must still load directly and not be replaced by the stand-in.
func test_present_effect_is_not_replaced() -> void:
	var wrapper: Node2D = WRAPPER_SCRIPT.new()
	wrapper.setup(WRAPPER_SCRIPT.FALLBACK_EFFECT_PATH, 0.0)
	assert_false(wrapper.used_fallback, "an existing effect is used as-is")
	assert_eq(wrapper.effect_path, WRAPPER_SCRIPT.FALLBACK_EFFECT_PATH,
		"the requested path is preserved on the wrapper")
	wrapper.free()


## The scale of the problem: most abilities in the DB reference effects that the
## project does not ship. This keeps the fallback from becoming quietly pointless
## -- if every effect is ever present, this test should be revisited.
func test_some_effect_references_are_still_missing() -> void:
	var refs: Array = GameDatabase.query(
		"SELECT effectFrames FROM ability WHERE effectFrames IS NOT NULL AND effectFrames != ''"
	)
	assert_true(refs.size() > 1000, "the ability table has effect data")
	var missing: int = 0
	var total: int = 0
	for row in refs:
		for chunk in str(row.get("effectFrames", "")).split("&"):
			var parts: PackedStringArray = chunk.split(":")
			if parts.size() < 2 or not parts[1].is_valid_int():
				continue
			total += 1
			for name_value in GameDatabase.get_effect_data(int(parts[1])):
				var file_name: String = str(name_value).replace(".bmb", ".efkefc")
				if not ResourceLoader.exists("res://assets/battle_effect/" + file_name):
					missing += 1
					break
	assert_true(total > 10000, "effect references were counted")
	assert_true(missing > 0,
		"some effects are still missing, which is what the fallback covers")
