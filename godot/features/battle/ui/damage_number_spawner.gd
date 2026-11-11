extends RefCounted
class_name DamageNumberSpawner

## Spawns floating damage-number labels, heal numbers, miss/dodge callouts, and
## OVERKILL badges inside a target Control and animates them.
## Holds a tiny pool of recycled Labels so multi-hit bursts don't churn allocations.

const PUSH_AMOUNT: float = 36.0
const PUSH_DURATION: float = 0.14
const POP_DURATION: float = 0.12
const FADE_DURATION: float = 0.95
const OVERKILL_FADE_DURATION: float = 1.15
const DAMAGE_FONT_SIZE: int = 32
const CALLOUT_FONT_SIZE: int = 24
const POOL_CAP: int = 16

const DAMAGE_COLOR: Color = Color(1.0, 0.25, 0.25, 1.0)
const HEAL_COLOR: Color = Color(0.3, 1.0, 0.45, 1.0)
const OVERKILL_COLOR: Color = Color(1.0, 0.82, 0.15, 1.0)
const OVERKILL_OUTLINE_COLOR: Color = Color(0.22, 0.02, 0.0, 1.0)
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 1.0)
const OUTLINE_SIZE: int = 5
const OVERKILL_OUTLINE_SIZE: int = 8

var _host: Node
var _pool: Array[Label] = []
var overkill_count: int = 0


## `host` is the Node used to create_tween() against (needs a scene tree).
func _init(host: Node) -> void:
	_host = host


## Spawn a damage number inside `container`. Existing labels in the container
## get pushed up to make room. When `overkill` is true, also spawns an OVERKILL!! badge.
func spawn(damage: int, container: Control, overkill: bool = false) -> void:
	if container == null or _host == null or not is_instance_valid(_host):
		return

	_push_existing_labels(container)

	var label: Label = _acquire_label()
	label.name = "DamageLabel"
	label.text = str(damage)
	label.add_theme_color_override("font_color", DAMAGE_COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	container.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.position = Vector2.ZERO
	label.pivot_offset = container.size * 0.5
	label.scale = Vector2(1.3, 1.3)
	label.modulate = Color.WHITE

	var pop_tween: Tween = _host.create_tween()
	pop_tween.tween_property(label, "scale", Vector2.ONE, POP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fade_tween: Tween = _host.create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(func() -> void: _release_label(label))

	if overkill:
		spawn_overkill(container)


## Spawns a green HP recovery number inside `container`.
func spawn_heal(amount: int, container: Control) -> void:
	if amount <= 0 or container == null or _host == null or not is_instance_valid(_host):
		return

	_push_existing_labels(container)

	var label: Label = _acquire_label()
	label.name = "HealLabel"
	label.text = str(amount)
	label.add_theme_color_override("font_color", HEAL_COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	container.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.position = Vector2.ZERO
	label.pivot_offset = container.size * 0.5
	label.scale = Vector2(1.2, 1.2)
	label.modulate = Color.WHITE

	var pop_tween: Tween = _host.create_tween()
	pop_tween.tween_property(label, "scale", Vector2.ONE, POP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var fade_tween: Tween = _host.create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(func() -> void: _release_label(label))


## Spawns an "OVERKILL!!" badge above the target inside `container`.
func spawn_overkill(container: Control) -> Label:
	if container == null or _host == null or not is_instance_valid(_host):
		return null
	overkill_count += 1
	# Remove an older OverkillLabel in the same container so rapid hits pop cleanly.
	for child in container.get_children():
		if child is Label and child.name.begins_with("OverkillLabel"):
			child.queue_free()

	var badge := Label.new()
	badge.name = "OverkillLabel"
	badge.z_index = 20
	badge.text = "OVERKILL!!"
	badge.add_theme_font_size_override("font_size", CALLOUT_FONT_SIZE)
	badge.add_theme_color_override("font_color", OVERKILL_COLOR)
	badge.add_theme_color_override("font_outline_color", OVERKILL_OUTLINE_COLOR)
	badge.add_theme_constant_override("outline_size", OVERKILL_OUTLINE_SIZE)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.position = Vector2(0.0, -34.0)
	badge.pivot_offset = container.size * 0.5
	badge.scale = Vector2(1.45, 1.45)
	badge.modulate = Color.WHITE

	var tween: Tween = _host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", Vector2.ONE, POP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "position:y", -52.0, OVERKILL_FADE_DURATION) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate:a", 0.0, OVERKILL_FADE_DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(badge.queue_free)
	return badge


## Spawns a short status callout ("MISS", "DODGE", "RESIST") on `container`.
func spawn_status_text(text: String, container: Control, color: Color = Color(0.9, 0.95, 1.0, 1.0)) -> Label:
	if text == "" or container == null or _host == null or not is_instance_valid(_host):
		return null
	_push_existing_labels(container)
	var label := Label.new()
	label.name = "StatusCalloutLabel"
	label.text = text
	label.add_theme_font_size_override("font_size", CALLOUT_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.position = Vector2.ZERO
	label.modulate = Color.WHITE

	var fade_tween: Tween = _host.create_tween()
	fade_tween.tween_property(label, "modulate:a", 0.0, FADE_DURATION) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	fade_tween.finished.connect(label.queue_free)
	return label


## Drop pooled labels (call on scene exit to avoid hanging references).
func clear_pool() -> void:
	for label in _pool:
		if is_instance_valid(label):
			label.queue_free()
	_pool.clear()


# --- internals --------------------------------------------------------------

func _push_existing_labels(container: Control) -> void:
	for child in container.get_children():
		if child is Label and not child.name.begins_with("OverkillLabel"):
			var move_tween: Tween = _host.create_tween()
			move_tween.tween_property(child, "position:y", child.position.y - PUSH_AMOUNT, PUSH_DURATION) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _acquire_label() -> Label:
	while not _pool.is_empty():
		var candidate: Label = _pool.pop_back()
		if is_instance_valid(candidate):
			return candidate
	return _make_label()


func _release_label(label: Label) -> void:
	if not is_instance_valid(label):
		return
	if label.get_parent() != null:
		label.get_parent().remove_child(label)
	label.remove_theme_font_override("font")
	label.scale = Vector2.ONE
	if _pool.size() < POOL_CAP:
		_pool.append(label)
	else:
		label.queue_free()


func _make_label() -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", DAMAGE_FONT_SIZE)
	label.add_theme_color_override("font_color", DAMAGE_COLOR)
	label.add_theme_color_override("font_outline_color", OUTLINE_COLOR)
	label.add_theme_constant_override("outline_size", OUTLINE_SIZE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
