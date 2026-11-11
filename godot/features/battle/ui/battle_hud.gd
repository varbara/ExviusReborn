class_name BattleHud
extends RefCounted

const BattleStatusIconHelper = preload("res://features/battle/ui/battle_status_icon_helper.gd")

## The battle screen's labels and gauges, which span several nodes of BattleUI.tscn:
## the targeted enemy's name and HP bars, the turn and chain labels, the action feedback
## line, the party's esper (summon) gauge, the wave counter with its roll between
## waves, and the FFBE Chain / Spark / Element Chain + Total Damage overlay.

const ACTION_FEEDBACK_SECONDS: float = 1.5
const COMBO_HOLD_SECONDS: float = 1.2
const COMBO_FADE_SECONDS: float = 0.25
const WAVE_FADE_SECONDS: float = 0.3
const WAVE_INTRO_HOLD_SECONDS: float = 1.0
const WAVE_ROLL_HOLD_SECONDS: float = 0.5
const WAVE_ROLL_SECONDS: float = 0.4

const CHAIN_BANNER_PATH: String = "res://assets/ui/quest/battle_anitxt_chain.tres"
const DAMAGE_BANNER_PATH: String = "res://assets/ui/quest/battle_anitxt_damage.tres"

var _host: Control
var _turn_label: Label
var _chain_label: Label
var _enemy_name: Label
var _enemy_hp_bar: ProgressBar
var _enemy_hp_pct: Label
var _enemy_hp_sprite: Sprite2D
var _feedback: Label
var _transition: Control
var _esper_gauge: Range
var _enemy_status_container: HBoxContainer
## A newer feedback line wins: only the latest one hides itself.
var _feedback_token: int = 0
var _combo_token: int = 0

var _combo_overlay: Control
var _chain_box: VBoxContainer
var _chain_type_label: Label
var _chain_num_label: Label
var _damage_row: HBoxContainer
var _damage_num_label: Label

var total_damage: int = 0
var max_chain: int = 0
var last_chain_type: StringName = &""


## `host` is the battle screen's root (BattleUI.tscn), which owns the nodes and runs the
## tweens.
func _init(host: Control) -> void:
	_host = host
	_turn_label = host.get_node("%TurnLabel")
	_chain_label = host.get_node("%ChainCountLabel")
	_enemy_name = host.get_node("%EnemyNameLabel")
	_enemy_hp_bar = host.get_node("%EnemyHPBar")
	_enemy_hp_pct = host.get_node("%EnemyHPPctLabel")
	_enemy_hp_sprite = host.get_node("BattleEnemyHpBar1")
	_feedback = host.get_node("%ActionFeedbackLabel")
	_transition = host.get_node("%TransitionUI")
	_esper_gauge = host.get_node("VisualLayer/SummonGaugeBg/BattleSummonBar")
	if host.has_node("%EnemyStatusContainer"):
		_enemy_status_container = host.get_node("%EnemyStatusContainer") as HBoxContainer
	_build_combo_overlay(host)


func set_turn(turn: int) -> void:
	_turn_label.text = "Turn %d" % turn
	total_damage = 0


func set_chain(chain: int) -> void:
	_chain_label.text = "Chain: %d" % chain
	if chain == 0:
		total_damage = 0
		last_chain_type = &""
		if _combo_overlay != null:
			_combo_overlay.visible = false


## Records a landed hit on the HUD: updates the chain counter, accumulates turn damage,
## and pops the FFBE Chain / Spark / Element Chain + Total Damage banner.
func record_hit(amount: int, chain: int, spark: bool = false, element_chain: int = 0, is_enemy_target: bool = true) -> void:
	_chain_label.text = "Chain: %d" % chain
	if is_enemy_target and amount > 0:
		total_damage += amount
	if chain > max_chain:
		max_chain = chain
	if chain > 0:
		if spark:
			last_chain_type = &"spark"
		elif element_chain > 0:
			last_chain_type = &"element"
		else:
			last_chain_type = &"normal"
	else:
		last_chain_type = &""

	if _combo_overlay == null:
		return
	if chain <= 0 and (not is_enemy_target or total_damage <= 0):
		return

	_combo_overlay.visible = true
	_combo_overlay.modulate.a = 1.0

	if chain > 0:
		_chain_box.visible = true
		_chain_num_label.text = str(chain)
		if spark:
			_chain_type_label.text = "SPARK CHAIN!!"
			_chain_type_label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0, 1.0))
			_chain_type_label.visible = true
		elif element_chain > 0:
			_chain_type_label.text = "ELEMENT CHAIN!"
			_chain_type_label.add_theme_color_override("font_color", Color(1.0, 0.68, 0.2, 1.0))
			_chain_type_label.visible = true
		else:
			_chain_type_label.visible = false
		_chain_box.pivot_offset = _chain_box.size * 0.5
		_chain_box.scale = Vector2(1.28, 1.28)
		var pop: Tween = _host.create_tween()
		pop.tween_property(_chain_box, "scale", Vector2.ONE, 0.12) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_chain_box.visible = false

	if is_enemy_target and total_damage > 0:
		_damage_row.visible = true
		_damage_num_label.text = _format_commas(total_damage)
	else:
		_damage_row.visible = false

	_combo_token += 1
	var token: int = _combo_token
	var fade: Tween = _host.create_tween()
	fade.tween_interval(COMBO_HOLD_SECONDS)
	fade.tween_callback(func() -> void:
		if token != _combo_token or _combo_overlay == null:
			return
		var hide_tween: Tween = _host.create_tween()
		hide_tween.tween_property(_combo_overlay, "modulate:a", 0.0, COMBO_FADE_SECONDS)
		hide_tween.tween_callback(_combo_overlay.hide))


## The top bar for the targeted enemy.
func show_target(enemy_name: String, hp: int, max_hp: int, statuses: Array = []) -> void:
	_enemy_name.text = enemy_name
	var ratio: float = clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	_enemy_hp_sprite.scale.x = ratio
	_enemy_hp_bar.max_value = max_hp
	_enemy_hp_bar.value = hp
	_enemy_hp_pct.text = "%d%%" % int(ratio * 100.0)
	if _enemy_status_container != null:
		for child in _enemy_status_container.get_children():
			child.queue_free()
		var count: int = 0
		for st in statuses:
			if count >= 8:
				break
			if st is BattleStatus:
				var tex: Texture2D = BattleStatusIconHelper.get_status_texture(st)
				if tex != null:
					var rect := TextureRect.new()
					rect.texture = tex
					rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
					rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
					rect.custom_minimum_size = Vector2(22, 22)
					_enemy_status_container.add_child(rect)
					count += 1


## No enemy left to target (the wave is down).
func show_no_target() -> void:
	_enemy_name.text = "Cleared"
	if _enemy_status_container != null:
		for child in _enemy_status_container.get_children():
			child.queue_free()


## Shows `text` ("Unit - Skill") for ACTION_FEEDBACK_SECONDS.
func show_feedback(text: String) -> void:
	_feedback.text = text
	_feedback.visible = true
	_feedback.modulate.a = 1.0
	_feedback_token += 1
	var token: int = _feedback_token
	var tween: Tween = _host.create_tween()
	tween.tween_interval(ACTION_FEEDBACK_SECONDS)
	tween.tween_callback(func() -> void:
		if token == _feedback_token:
			_feedback.visible = false)


## The party's esper gauge: `orbs` of `max_orbs`.
func set_esper_gauge(orbs: int, max_orbs: int) -> void:
	_esper_gauge.max_value = maxi(1, max_orbs)
	_esper_gauge.value = orbs


## "Wave 1 / N" fades in, holds and fades out as the battle opens.
func play_wave_intro(total_waves: int) -> void:
	_wave_labels("1", "", total_waves)
	_transition.show()
	_transition.modulate.a = 0.0
	var tween: Tween = _host.create_tween()
	tween.tween_property(_transition, "modulate:a", 1.0, WAVE_FADE_SECONDS)
	tween.tween_interval(WAVE_INTRO_HOLD_SECONDS)
	tween.tween_property(_transition, "modulate:a", 0.0, WAVE_FADE_SECONDS)
	tween.tween_callback(_transition.hide)


## The wave counter rolls from `wave` to `next_wave` of `total_waves`. Returns the
## signal emitted when the roll is over.
func play_wave_transition(wave: int, next_wave: int, total_waves: int) -> Signal:
	var labels: Array[Label] = _wave_labels(str(wave), str(next_wave), total_waves)
	_transition.show()
	_transition.modulate.a = 0.0
	var tween: Tween = _host.create_tween()
	tween.tween_property(_transition, "modulate:a", 1.0, WAVE_FADE_SECONDS)
	tween.tween_interval(WAVE_ROLL_HOLD_SECONDS)
	# The odometer push: the current number rolls up and out as the next one rolls in.
	tween.parallel().tween_property(labels[0], "position:y", -60, WAVE_ROLL_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(labels[1], "position:y", 0, WAVE_ROLL_SECONDS) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(WAVE_ROLL_HOLD_SECONDS)
	tween.tween_property(_transition, "modulate:a", 0.0, WAVE_FADE_SECONDS)
	tween.tween_callback(_transition.hide)
	return tween.finished


## Sets the counter's labels and puts the two numbers back in place; returns
## [current, next].
func _wave_labels(current: String, next: String, total_waves: int) -> Array[Label]:
	var current_num: Label = _transition.get_node("HBox/NumberMask/CurrentNum")
	var next_num: Label = _transition.get_node("HBox/NumberMask/NextNum")
	var total_label: Label = _transition.get_node("HBox/TotalWavesLabel")
	current_num.text = current
	next_num.text = next
	total_label.text = " / " + str(total_waves)
	current_num.position.y = 0
	next_num.position.y = 50
	var labels: Array[Label] = [current_num, next_num]
	return labels


func _build_combo_overlay(host: Control) -> void:
	_combo_overlay = Control.new()
	_combo_overlay.name = "ComboOverlay"
	_combo_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_overlay.offset_left = 240.0
	_combo_overlay.offset_top = 46.0
	_combo_overlay.offset_right = 628.0
	_combo_overlay.offset_bottom = 190.0
	_combo_overlay.visible = false
	host.add_child(_combo_overlay)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	_combo_overlay.add_child(vbox)

	_chain_box = VBoxContainer.new()
	_chain_box.name = "ChainBox"
	_chain_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chain_box.add_theme_constant_override("separation", -4)
	vbox.add_child(_chain_box)

	_chain_type_label = Label.new()
	_chain_type_label.name = "ChainTypeLabel"
	_chain_type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_chain_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chain_type_label.add_theme_font_size_override("font_size", 20)
	_chain_type_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_chain_type_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_chain_type_label.add_theme_constant_override("outline_size", 6)
	_chain_type_label.visible = false
	_chain_box.add_child(_chain_type_label)

	var chain_row := HBoxContainer.new()
	chain_row.name = "ChainRow"
	chain_row.alignment = BoxContainer.ALIGNMENT_END
	chain_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chain_row.add_theme_constant_override("separation", 6)
	_chain_box.add_child(chain_row)

	_chain_num_label = Label.new()
	_chain_num_label.name = "ChainNumLabel"
	_chain_num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chain_num_label.add_theme_font_size_override("font_size", 42)
	_chain_num_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	_chain_num_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_chain_num_label.add_theme_constant_override("outline_size", 6)
	chain_row.add_child(_chain_num_label)

	var chain_tex := TextureRect.new()
	chain_tex.name = "ChainBanner"
	chain_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chain_tex.custom_minimum_size = Vector2(132, 39)
	chain_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	chain_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(CHAIN_BANNER_PATH):
		chain_tex.texture = ResourceLoader.load(CHAIN_BANNER_PATH) as Texture2D
	chain_row.add_child(chain_tex)

	_damage_row = HBoxContainer.new()
	_damage_row.name = "DamageRow"
	_damage_row.alignment = BoxContainer.ALIGNMENT_END
	_damage_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_row.add_theme_constant_override("separation", 6)
	vbox.add_child(_damage_row)

	_damage_num_label = Label.new()
	_damage_num_label.name = "DamageNumLabel"
	_damage_num_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_num_label.add_theme_font_size_override("font_size", 32)
	_damage_num_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.2, 1.0))
	_damage_num_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_damage_num_label.add_theme_constant_override("outline_size", 5)
	_damage_row.add_child(_damage_num_label)

	var dmg_tex := TextureRect.new()
	dmg_tex.name = "DamageBanner"
	dmg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dmg_tex.custom_minimum_size = Vector2(132, 39)
	dmg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dmg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(DAMAGE_BANNER_PATH):
		dmg_tex.texture = ResourceLoader.load(DAMAGE_BANNER_PATH) as Texture2D
	_damage_row.add_child(dmg_tex)


static func _format_commas(value: int) -> String:
	var raw: String = str(maxi(0, value))
	var out: String = ""
	var count: int = 0
	for i in range(raw.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			out = "," + out
		out = raw[i] + out
		count += 1
	return out
