extends "res://tests/test_case.gd"

const BATTLE_SCENE: PackedScene = preload("res://features/battle/ui/BattleUI.tscn")
const PRESENTATION_SCRIPT = preload("res://features/battle/ui/esper_summon_presentation.gd")
const Fixtures = preload("res://tests/battle/battle_fixtures.gd")

var _screen: BattleScreen = null
var _effect_calls: Array = []


func before_each() -> void:
	if not SkillResolver.opcode_schemas_ready:
		SkillResolver.load_schemas()
	_screen = BATTLE_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_screen)
	var director: BattleDirector = _screen.director
	director.print_monster_ai = false
	director.finisher = func(_win: bool, _mission_id: String, _used_items: Dictionary, _results: Array, _drops: Array, _unit_exp: int, _gil: int) -> void: pass
	director.kill_recorder = func(_template_id: String) -> void: pass
	director.wait = func(_seconds: float) -> Variant: return null
	_effect_calls.clear()


func after_each() -> void:
	_screen.get_parent().remove_child(_screen)
	_screen.queue_free()


func _start_esper(esper_id: int, skill_id: String, effect_frames: Array) -> Array:
	var catalog: SkillCatalog = Fixtures.catalog()
	catalog.add_record(BattleSkill.KIND_ESPER, skill_id, Fixtures.record("Test Evocation",
		[[SkillEffect.AREA_ALL, SkillEffect.TARGET_OPPONENT, 15, Fixtures.magic_params(100)]],
		"10:100", {"attack_type": BattleSkill.ATTACK_NONE, "effect_frames": effect_frames}))
	var hero: Combatant = Fixtures.unit("Esper Tester", {"esper_id": esper_id, "esper_skill_id": skill_id})
	var foe: Combatant = Fixtures.monster("Target", {"brain": IdleEnemyBrain.new()})
	_screen.director.factory = func(seed_value: int) -> BattleEngine:
		return Fixtures.engine([hero], [foe], null, catalog, seed_value)
	# BattleScreen turns history off; this test reads the engine's events back.
	_screen.session.keep_history = true
	_screen.director.start({}, 7)
	var engine: BattleEngine = _screen.session.engine
	engine.esper_orbs = engine.rules.esper_gauge_max
	var before: int = _screen.get_node("EsperSummonPresentation").get_child_count()
	_screen.session.execute(hero.id, BattleCommand.evoke())
	for _i in range(600):
		if not engine.events.of_type(BattleEventLog.ACTION_ENDED).is_empty():
			break
		_screen.session.step(1)
	return [engine, hero, foe, before]


func _effect_player(frames: Array) -> void:
	_effect_calls.append(frames.duplicate(true))


func test_missing_primary_effect_runs_fallback_in_order_then_replays_engine_damage() -> void:
	var frames: Array = [[{"effect_id": 12000000, "frame_offset": 0}], [{"effect_id": 12000001, "frame_offset": 1}]]
	assert_false(PRESENTATION_SCRIPT.is_primary_esper_effect(frames), "Siren rank 1 primary resource is absent")
	var engine_and_units: Array = _start_esper(1, "10101", frames)
	var engine: BattleEngine = engine_and_units[0]
	var hero: Combatant = engine_and_units[1]
	var foe: Combatant = engine_and_units[2]
	var presentation: Variant = _screen.get_node("EsperSummonPresentation")
	var action_id: int = -1
	for event in engine.events.of_type(BattleEventLog.ACTION_STARTED):
		if int(event.get("actor", -1)) == hero.id:
			action_id = int(event["action"])
	assert_true(action_id >= 0, "engine emitted the evocation action")
	var damage_events: Array[Dictionary] = []
	for event in engine.events.of_type(BattleEventLog.HIT_LANDED):
		if int(event.get("target", -1)) == foe.id:
			damage_events.append(event)
	assert_false(damage_events.is_empty(), "the engine produced damage events")
	assert_eq(presentation.sequence_stages(false), ["dim", "available_effects", "damage"])
	assert_eq(presentation.sequence_stages(true), ["dim", "esper_enters", "available_effects", "damage"])
	assert_eq((presentation._held_hits[action_id] as Array).size(), damage_events.size(), "the UI holds each engine hit once")
	assert_false(presentation.hold_hit(action_id + 1, damage_events[0]), "other action damage is untouched")
	var engine_hits_before_release: Array[Dictionary] = engine.events.of_type(BattleEventLog.HIT_LANDED)
	assert_eq(presentation.release_hits(action_id), damage_events)
	assert_eq(int(damage_events[0]["amount"]), int(engine_hits_before_release[0]["amount"]))
	assert_eq(engine.events.of_type(BattleEventLog.HIT_LANDED), engine_hits_before_release, "presentation does not mutate engine events")


func test_existing_primary_esper_effect_keeps_original_path() -> void:
	var frames: Array = [[{"effect_id": 12000102, "frame_offset": 0}]]
	assert_true(PRESENTATION_SCRIPT.is_primary_esper_effect(frames), "Ifrit rank 2 primary resource is installed")
	assert_false(PRESENTATION_SCRIPT.should_fallback(true, true))
	assert_false(PRESENTATION_SCRIPT.should_fallback(false, false))


func test_missing_esper_image_is_cached_as_null_without_interrupting_hit_events() -> void:
	assert_eq(PRESENTATION_SCRIPT.texture_for_esper(-1), null)
	assert_eq(PRESENTATION_SCRIPT.texture_for_esper(-1), null)
	assert_eq(PRESENTATION_SCRIPT.sequence_stages(false).back(), "damage")


func test_fallback_filters_missing_resources_and_replays_only_available_effects() -> void:
	var frames: Array = [[{"effect_id": 12000000, "frame_offset": 0}], [{"effect_id": 12000001, "frame_offset": 1}]]
	var available: Array = PRESENTATION_SCRIPT.available_effect_frames(frames)
	assert_eq(available, [[{"effect_id": 12000001, "frame_offset": 1}]], "keeps available background, drops missing primary")
