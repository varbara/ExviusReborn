extends "res://tests/test_case.gd"

## Tests for Battle Status & Barrier visualization:
## Floating callouts, CombatSprite visual modulation (tint/pause), UnitPanel barrier gauge,
## and status icons on UnitPanel & BattleHud.

const Fixtures = preload("res://tests/battle/battle_fixtures.gd")
const BATTLE_SCENE: PackedScene = preload("res://features/battle/ui/BattleUI.tscn")
const UNIT_PANEL_SCENE: PackedScene = preload("res://features/battle/ui/UnitPanel.tscn")
const BattleStatusIconHelper = preload("res://features/battle/ui/battle_status_icon_helper.gd")

var _screen: BattleScreen = null


func before_each() -> void:
	if not SkillResolver.opcode_schemas_ready:
		SkillResolver.load_schemas()


func after_each() -> void:
	if _screen != null and is_instance_valid(_screen) and _screen.get_parent() != null:
		_screen.get_parent().remove_child(_screen)
		_screen.queue_free()
		_screen = null


func test_battle_status_icon_helper_textures() -> void:
	var sleep_status := BattleStatus.make(BattleStatus.AILMENT, "SLEEP", 0, 3)
	var poison_status := BattleStatus.make(BattleStatus.AILMENT, "POISON", 0, 3)
	var atk_up_status := BattleStatus.make(BattleStatus.STAT, "ATK", 50, 3)
	var def_down_status := BattleStatus.make(BattleStatus.STAT, "DEF", -40, 3)
	var shield_status := BattleStatus.make(BattleStatus.SHIELD, "", 1000, 3)

	var sleep_tex: Texture2D = BattleStatusIconHelper.get_status_texture(sleep_status)
	assert_true(sleep_tex != null, "Sleep texture should not be null")
	assert_true(sleep_tex is AtlasTexture, "Should be an AtlasTexture")
	var sleep_atlas := sleep_tex as AtlasTexture
	assert_eq(sleep_atlas.region, Rect2(72, 0, 36, 34), "Sleep icon should match col 2 row 0 of state_icon_bad")

	var poison_tex: Texture2D = BattleStatusIconHelper.get_status_texture(poison_status)
	assert_true(poison_tex != null, "Poison texture should not be null")
	assert_eq((poison_tex as AtlasTexture).region, Rect2(0, 0, 36, 34), "Poison icon should match col 0 row 0")

	var atk_tex: Texture2D = BattleStatusIconHelper.get_status_texture(atk_up_status)
	assert_true(atk_tex != null, "ATK UP texture should not be null")
	assert_eq((atk_tex as AtlasTexture).region, Rect2(0, 0, 36, 34), "ATK UP icon should match col 0 of state_icon_up")

	var def_down_tex: Texture2D = BattleStatusIconHelper.get_status_texture(def_down_status)
	assert_true(def_down_tex != null, "DEF DOWN texture should not be null")
	assert_eq((def_down_tex as AtlasTexture).region, Rect2(36, 0, 36, 34), "DEF DOWN icon should match col 1 of state_icon_down")

	var shield_tex: Texture2D = BattleStatusIconHelper.get_status_texture(shield_status)
	assert_true(shield_tex != null, "Shield texture should not be null")


func test_battle_status_callouts() -> void:
	var sleep_callout: Dictionary = BattleStatusIconHelper.get_callout(BattleStatus.AILMENT, "SLEEP", 0)
	assert_eq(sleep_callout.get("text", ""), "SLEEP")
	assert_eq(sleep_callout.get("color"), Color(0.4, 0.7, 1.0))

	var shield_callout: Dictionary = BattleStatusIconHelper.get_callout(BattleStatus.SHIELD, "", 500)
	assert_eq(shield_callout.get("text", ""), "BARRIER")
	assert_eq(shield_callout.get("color"), Color(1.0, 0.85, 0.2))

	var atk_up_callout: Dictionary = BattleStatusIconHelper.get_callout(BattleStatus.STAT, "ATK", 100)
	assert_eq(atk_up_callout.get("text", ""), "ATK UP")

	var def_down_callout: Dictionary = BattleStatusIconHelper.get_callout(BattleStatus.STAT, "DEF", -50)
	assert_eq(def_down_callout.get("text", ""), "DEF DOWN")


func test_unit_panel_barrier_and_status_badges() -> void:
	var panel: UnitPanel = UNIT_PANEL_SCENE.instantiate() as UnitPanel
	(Engine.get_main_loop() as SceneTree).root.add_child(panel)

	# Initially barrier is hidden
	assert_false(panel.barrier_gage.visible)
	assert_false(panel.barrier_bar.visible)

	# Set barrier to 50%
	panel.set_barrier_gauge(0.5)
	assert_true(panel.barrier_gage.visible)
	assert_true(panel.barrier_bar.visible)
	assert_eq(panel.barrier_gage.modulate.a, 1.0)
	assert_eq(panel.barrier_bar.scale.x, 0.5)
	assert_eq(panel.barrier_bar.centered, false)

	# Set barrier to 0% -> hidden
	panel.set_barrier_gauge(0.0)
	assert_false(panel.barrier_gage.visible)
	assert_false(panel.barrier_bar.visible)

	# Set statuses on panel
	var statuses: Array[BattleStatus] = [
		BattleStatus.make(BattleStatus.AILMENT, "SLEEP", 0, 3),
		BattleStatus.make(BattleStatus.STAT, "DEF", -30, 2),
	]
	panel.set_statuses(statuses)
	assert_eq(panel.status_container.get_child_count(), 2)

	panel.get_parent().remove_child(panel)
	panel.queue_free()


func test_combat_sprite_status_visual_modulation() -> void:
	var sprite := CombatSprite.new()
	var sleep := BattleStatus.make(BattleStatus.AILMENT, "SLEEP", 0, 3)
	var petrify := BattleStatus.make(BattleStatus.AILMENT, "PETRIFY", 0, 3)
	var poison := BattleStatus.make(BattleStatus.AILMENT, "POISON", 0, 3)

	# Apply sleep -> tinted blue and paused
	sprite.update_status_visual([sleep])
	assert_eq(sprite.modulate, Color(0.65, 0.75, 1.0))
	assert_true(sprite._is_status_paused)

	# Apply petrify (higher priority) -> gray and paused
	sprite.update_status_visual([sleep, petrify])
	assert_eq(sprite.modulate, Color(0.45, 0.45, 0.45))
	assert_true(sprite._is_status_paused)

	# Poison only -> purple and not paused
	sprite.update_status_visual([poison])
	assert_eq(sprite.modulate, Color(0.85, 0.55, 1.0))
	assert_false(sprite._is_status_paused)

	# Cleared -> white and not paused
	sprite.update_status_visual([])
	assert_eq(sprite.modulate, Color.WHITE)
	assert_false(sprite._is_status_paused)

	sprite.free()


func test_battle_screen_barrier_and_sleep_events() -> void:
	_screen = BATTLE_SCENE.instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(_screen)
	var director: BattleDirector = _screen.director
	director.print_monster_ai = false
	director.wait = func(_s: float) -> Variant: return null
	director.finisher = func(_w: bool, _m: String, _u: Dictionary, _r: Array, _d: Array, _x: int, _g: int) -> void: pass

	_screen.director.start({}, 42)
	var engine: BattleEngine = _screen.session.engine
	var leader: Combatant = engine.party_members()[0]
	var panel: UnitPanel = _screen.menus.panel(leader.id)

	# Apply barrier status to leader
	var barrier := BattleStatus.make(BattleStatus.SHIELD, "", 500, 3)
	leader.add_status(barrier)
	_screen._handle(engine, {
		"type": BattleEventLog.STATUS_ADDED,
		"target": leader.id,
		"kind": BattleStatus.SHIELD,
		"key": "",
		"value": 500,
	})

	assert_true(panel.barrier_gage.visible, "Barrier gauge frame should be visible after STATUS_ADDED")
	assert_true(panel.barrier_bar.visible, "Barrier bar should be visible after STATUS_ADDED")

	# Leader takes a hit that absorbs 100 barrier
	barrier.value = 400
	_screen._handle(engine, {
		"type": BattleEventLog.HIT_LANDED,
		"target": leader.id,
		"amount": 100,
		"absorbed": 100,
		"hp_lost": 0,
		"hp": leader.hp,
		"max_hp": leader.max_hp,
	})
	assert_true(panel.barrier_bar.visible)

	# Leader falls asleep
	var sleep_st := BattleStatus.make(BattleStatus.AILMENT, "SLEEP", 0, 3)
	leader.add_status(sleep_st)
	_screen._handle(engine, {
		"type": BattleEventLog.STATUS_ADDED,
		"target": leader.id,
		"kind": BattleStatus.AILMENT,
		"key": "SLEEP",
		"value": 0,
	})

	assert_true(panel.status_container.get_child_count() > 0, "Panel should have status icon for sleep")
	assert_true(panel.is_acted(), "Sleeping member should be marked acted / cannot act")

	# Physical hit wakes leader up
	leader.remove_status(sleep_st)
	_screen._handle(engine, {
		"type": BattleEventLog.STATUS_REMOVED,
		"target": leader.id,
		"kind": BattleStatus.AILMENT,
		"key": "SLEEP",
		"reason": &"damaged",
	})

	assert_false(leader.has_ailment("SLEEP"), "Leader should no longer have sleep ailment")
