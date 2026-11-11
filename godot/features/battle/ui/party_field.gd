class_name PartyField
extends Control

## The party half of the battle field, on %PlayerSpritesContainer: one sprite per party
## member on the UnitDot0 to UnitDot5 spots, keyed by combatant id, with its poses,
## damage numbers, the skill effects, the limit crystals flying in, a covering unit's
## dot stepping forward, a jumping unit rising out of sight and dropping back, and the
## victory poses. A long press asks for the member's info. The battle screen pushes
## everything in.

signal unit_long_pressed(unit_id: int)

## The party slot each dot shows (the sixth dot stays empty). The bottom panels follow
## the same order (BattleMenus).
const GRID_TO_PARTY_MAP: Array[int] = [0, 3, 1, 4, 2, -1]
## Where a unit covering the whole party stands.
const COVER_TARGET_POSITION: Vector2 = Vector2(260, 240)
const COVER_MOVE_SECONDS: float = 0.2
## How far a unit in the air (a jump) rises while it fades out, and how long it takes.
const AWAY_RISE: Vector2 = Vector2(0, -160)
const AWAY_MOVE_SECONDS: float = 0.25
const LIMIT_CRYSTAL_SECONDS: float = 0.5
const CRYSTAL_START_OFFSET: Vector2 = Vector2(36, -14)
const CRYSTAL_END_OFFSET: Vector2 = Vector2(40, 40)
## The victory poses give up after this long (a sprite that never reports back: a
## missing sheet, a freed node), so the result screen still opens.
const VICTORY_TIMEOUT_SECONDS: float = 10.0

## Where the crystals fly (the screen's root, above the fields), and the crystal to copy.
var overlay: Control = null
var crystal_template: AnimatedSprite2D = null

## Unit id -> its CombatSprite, its dot and the dot's damage number container.
var _sprites: Dictionary = {}
var _dots: Dictionary = {}
var _damage_containers: Dictionary = {}
## Each dot's place in the scene, where it returns after covering.
var _dot_homes: Dictionary = {}
## Unit id -> its sprite's position before it left the field, for the units in the air.
var _away: Dictionary = {}
var _active_tweens: Dictionary = {}
var _damage_numbers: DamageNumberSpawner
var _effects: EffectSpawner


func _ready() -> void:
	_damage_numbers = DamageNumberSpawner.new(self)
	_effects = EffectSpawner.new(self)
	for dot in get_children():
		if dot is Control:
			_dot_homes[dot] = (dot as Control).position


func _exit_tree() -> void:
	_damage_numbers.clear_pool()


## Replaces the sprites with one per member: each { id, slot, template_id (the unit id),
## sprite_scale, hp, max_hp }.
func build(members: Array) -> void:
	for child in get_children():
		if not (child is Control) or not child.name.begins_with("UnitDot"):
			remove_child(child)
			child.queue_free()
			continue
		for sub in child.get_children():
			child.remove_child(sub)
			sub.queue_free()
	_sprites.clear()
	_dots.clear()
	_damage_containers.clear()
	_away.clear()
	var by_slot: Dictionary = {}
	for member in members:
		by_slot[int(member["slot"])] = member
	for grid_index in range(mini(get_child_count(), GRID_TO_PARTY_MAP.size())):
		var member: Dictionary = by_slot.get(GRID_TO_PARTY_MAP[grid_index], {})
		if member.is_empty():
			continue
		var unit_id: int = int(member["id"])
		var dot: Control = get_child(grid_index)
		var sprite := CombatSprite.new()
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		sprite.scale *= float(member.get("sprite_scale", 1.0))
		sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
		sprite.setup(unit_id, str(member.get("template_id", "")), false)
		sprite.set_hp(int(member.get("hp", 1)), int(member.get("max_hp", 1)))
		sprite.long_pressed.connect(unit_long_pressed.emit)
		sprite.action_finished.connect(func(_idx: int, state: CombatSprite.AnimState) -> void:
			if state == CombatSprite.AnimState.ATK:
				attack_return(unit_id)
		)
		dot.add_child(sprite)

		var damage := Control.new()
		damage.name = "DamageContainer"
		damage.set_anchors_preset(Control.PRESET_FULL_RECT)
		damage.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.add_child(damage)
		_sprites[unit_id] = sprite
		_dots[unit_id] = dot
		_damage_containers[unit_id] = damage


func set_hp(unit_id: int, hp: int, max_hp: int) -> void:
	if _sprites.has(unit_id):
		(_sprites[unit_id] as CombatSprite).set_hp(hp, max_hp)


## An action pose (CombatSprite.AnimState: ATK, MAGIC_ATK, LIMIT_ATK).
func play_action(unit_id: int, state: CombatSprite.AnimState) -> void:
	if _sprites.has(unit_id):
		(_sprites[unit_id] as CombatSprite).play_action(state)


## Dashes the unit to target_pos (in party_field local coordinates) over duration seconds.
func attack_approach(unit_id: int, target_pos: Vector2, duration: float = 0.18) -> void:
	if not _dots.has(unit_id):
		return
	var dot: Control = _dots[unit_id]
	if _active_tweens.has(unit_id):
		var old_tw: Variant = _active_tweens[unit_id]
		if old_tw is Tween and (old_tw as Tween).is_running():
			(old_tw as Tween).kill()
	var tw: Tween = create_tween().bind_node(dot)
	tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dot, "position", target_pos, duration)
	_active_tweens[unit_id] = tw


## Returns the unit from its melee target back to its home dot position.
func attack_return(unit_id: int, duration: float = 0.22) -> void:
	if not _dots.has(unit_id):
		return
	var dot: Control = _dots[unit_id]
	var home: Vector2 = _dot_homes.get(dot, dot.position)
	if dot.position.is_equal_approx(home):
		return
	if _active_tweens.has(unit_id):
		var old_tw: Variant = _active_tweens[unit_id]
		if old_tw is Tween and (old_tw as Tween).is_running():
			(old_tw as Tween).kill()
	var tw: Tween = create_tween().bind_node(dot)
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(dot, "position", home, duration)
	_active_tweens[unit_id] = tw


## The pose for a queued command (STANDBY, MAGIC_STANDBY, IDLE).
func play_queued(unit_id: int, state: CombatSprite.AnimState) -> void:
	if _sprites.has(unit_id):
		(_sprites[unit_id] as CombatSprite).play_queued(state)


## A hit: the sprite shakes, impact VFX plays, and the damage floats up.
func show_hit(unit_id: int, amount: int, overkill: bool = false, spark: bool = false, magic: bool = false) -> void:
	if not _sprites.has(unit_id):
		return
	BattleTweens.shake(_sprites[unit_id])
	if _dots.has(unit_id):
		_effects.spawn_hit_impact(_dots[unit_id], spark, magic)
	_damage_numbers.spawn(amount, _damage_containers[unit_id], overkill)


func show_heal(unit_id: int, amount: int) -> void:
	if _damage_containers.has(unit_id):
		_damage_numbers.spawn_heal(amount, _damage_containers[unit_id])


func show_miss(unit_id: int, text: String = "MISS") -> void:
	if _damage_containers.has(unit_id):
		_damage_numbers.spawn_status_text(text, _damage_containers[unit_id])


func show_status_text(unit_id: int, text: String, color: Color = Color(0.9, 0.95, 1.0, 1.0)) -> void:
	if _damage_containers.has(unit_id):
		_damage_numbers.spawn_status_text(text, _damage_containers[unit_id], color)


func update_status_visual(unit_id: int, statuses: Array) -> void:
	if _sprites.has(unit_id):
		(_sprites[unit_id] as CombatSprite).update_status_visual(statuses)


## A skill's effects (its record's `effect_frames`), on `unit_id` or in the middle of the
## field, timed for the battle's `speed`.
func spawn_effects(effect_frames: Array, speed: float, unit_id: int = -1) -> void:
	var target_container: Control = _dots[unit_id] if _dots.has(unit_id) else self
	_effects.spawn(effect_frames, target_container, speed)


func effect_paths() -> Array[String]:
	return _effects.spawned_paths if _effects != null else ([] as Array[String])


## A limit crystal flies from `from_position` (on screen) to `unit_id`; `on_arrival`
## runs when it lands.
func fly_crystal(from_position: Vector2, unit_id: int, on_arrival: Callable) -> void:
	if not _sprites.has(unit_id) or crystal_template == null or overlay == null:
		on_arrival.call()
		return
	var crystal: AnimatedSprite2D = crystal_template.duplicate()
	crystal.visible = true
	crystal.scale = Vector2(1.2, 1.2)
	crystal.z_index = 80
	crystal.play()
	overlay.add_child(crystal)
	var jitter: Vector2 = Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	crystal.global_position = from_position + CRYSTAL_START_OFFSET + jitter
	var target: Vector2 = (_sprites[unit_id] as Control).global_position + CRYSTAL_END_OFFSET
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(crystal, "global_position", target, LIMIT_CRYSTAL_SECONDS)
	tween.tween_callback(crystal.queue_free)
	tween.tween_callback(on_arrival)


## A unit covering the whole party steps forward; it steps back when the cover ends.
func set_covering(unit_id: int, covering: bool) -> void:
	if not _dots.has(unit_id):
		return
	var dot: Control = _dots[unit_id]
	var target: Vector2 = COVER_TARGET_POSITION if covering else _dot_homes.get(dot, dot.position)
	var tween: Tween = create_tween().bind_node(dot)
	tween.tween_property(dot, "position", target, COVER_MOVE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


## A unit in the air (a jump, BattleStatus.AWAY): its sprite rises and fades out of sight;
## it drops back when the unit lands or the jump is cancelled.
func set_away(unit_id: int, away: bool) -> void:
	if not _sprites.has(unit_id) or _away.has(unit_id) == away:
		return
	var sprite: Control = _sprites[unit_id]
	if away:
		_away[unit_id] = sprite.position
	var home: Vector2 = _away.get(unit_id, sprite.position)
	if not away:
		_away.erase(unit_id)
	var tween: Tween = create_tween().bind_node(sprite).set_parallel()
	tween.tween_property(sprite, "position", home + AWAY_RISE if away else home, AWAY_MOVE_SECONDS)
	tween.tween_property(sprite, "modulate:a", 0.0 if away else 1.0, AWAY_MOVE_SECONDS)


## Whether `unit_id` shows as in the air.
func is_away(unit_id: int) -> bool:
	return _away.has(unit_id)


## The victory pose (win_before, then win) on each of `unit_ids`; returns once they
## have all played out, or after VICTORY_TIMEOUT_SECONDS.
func play_victory(unit_ids: Array) -> void:
	var sprites: Array[CombatSprite] = []
	for unit_id in unit_ids:
		if _sprites.has(unit_id):
			sprites.append(_sprites[unit_id])
	if sprites.is_empty():
		return
	# One shared counter for the one-shot handlers.
	var pending: Array[int] = [sprites.size()]
	for sprite in sprites:
		sprite.win_finished.connect(func(_index: int) -> void: pending[0] -= 1, CONNECT_ONE_SHOT)
		sprite.play_win()
	var elapsed: float = 0.0
	while pending[0] > 0 and elapsed < VICTORY_TIMEOUT_SECONDS:
		elapsed += get_process_delta_time()
		await get_tree().process_frame
