class_name BattleMenuScreen
extends Control

## The panel the battle's square MENU button opens, over the field: a short list of
## commands (BattleMenuModel.commands()), the party as the battle has it right now, and
## Back. It draws what it is given and reports what was pressed; the battle screen
## decides what each command does. While it is open it covers the whole screen and
## swallows input, so a tap cannot reach a unit panel behind it.

## The player pressed Back, or cancelled: the battle goes on.
signal closed
## An enabled command was pressed, by BattleMenuModel's name.
signal command_chosen(command: StringName)

const PANEL_WIDTH: float = 560.0
const BUTTON_HEIGHT: float = 64.0
const TITLE: String = "MENU"
const BACK_TEXT: String = "Back"
const SCRIM_COLOR := Color(0.0, 0.0, 0.02, 0.62)
const PANEL_COLOR := Color(0.06, 0.09, 0.16, 0.98)
const PANEL_BORDER := Color(0.62, 0.70, 0.86, 0.9)
const MUTED_COLOR := Color(0.72, 0.76, 0.84)
const BUTTON_COLOR := Color(0.12, 0.17, 0.28)
const BUTTON_HOVER_COLOR := Color(0.19, 0.26, 0.41)
const BUTTON_PRESSED_COLOR := Color(0.27, 0.36, 0.56)
const BUTTON_BORDER := Color(0.34, 0.42, 0.58)

## Commands in the order they are drawn, each { command, label, disabled_reason }.
var _commands: Array[Dictionary] = []
var _buttons: Dictionary = {}
var _open: bool = false

var _panel: PanelContainer
var _list: VBoxContainer
var _members: VBoxContainer
var _back_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(PANEL_WIDTH, 0)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = TITLE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	box.add_child(title)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	box.add_child(_list)

	box.add_child(HSeparator.new())

	_members = VBoxContainer.new()
	_members.add_theme_constant_override("separation", 6)
	box.add_child(_members)

	_back_button = Button.new()
	_back_button.text = BACK_TEXT
	_back_button.custom_minimum_size = Vector2(0, 52)
	_style_button(_back_button)
	_back_button.pressed.connect(cancel)
	box.add_child(_back_button)


## The battle screen's own buttons are drawn by its art; a panel made in code needs its
## own surface, or a command reads as plain text on the scrim.
static func _style_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = BUTTON_COLOR
	normal.border_color = BUTTON_BORDER
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(6)
	normal.set_content_margin_all(8)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = BUTTON_HOVER_COLOR
	hover.border_color = PANEL_BORDER
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = BUTTON_PRESSED_COLOR
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.93, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.52, 0.57, 0.67))


# === Contract ===

## Draws `commands` ({ command, label, disabled_reason }) and opens over the battle.
## The first enabled command takes the focus, so keys and a gamepad work from the start.
func open(commands: Array[Dictionary]) -> void:
	_commands = commands.duplicate(true)
	_rebuild()
	_open = true
	fill_parent()
	show()
	focus_first()


## Closes and tells the battle screen, which returns the battle its input.
func close() -> void:
	if not _open:
		return
	_open = false
	hide()
	closed.emit()


## The screen's cancel (Back, Esc): closes when open and says whether it did.
func cancel() -> bool:
	if not _open:
		return false
	close()
	return true


func is_open() -> bool:
	return _open


## Covers the battle screen it was added to. Anchors alone leave it 0x0 when it is added
## before the screen's first layout pass, so the rect is taken from the parent's area (or
## the viewport, before the parent has one).
func fill_parent() -> void:
	var area: Vector2 = get_parent_area_size()
	if area.x <= 0.0 or area.y <= 0.0:
		area = get_viewport_rect().size
	position = Vector2.ZERO
	size = area
	queue_redraw()


## The scrim, drawn on the menu's own rect: a child ColorRect sized itself to 0, which
## left the field behind the panel as bright as the panel.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), SCRIM_COLOR)


## The button of `command`, or null when that command is not drawn.
func button(command: StringName) -> Button:
	return _buttons.get(command, null)


## Whether `command` is drawn as pressable.
func is_enabled(command: StringName) -> bool:
	var found: Button = button(command)
	return found != null and not found.disabled


## Focuses the first enabled command, else Back.
func focus_first() -> void:
	for child in _list.get_children():
		if child is Button and not (child as Button).disabled:
			(child as Button).grab_focus()
			return
	_back_button.grab_focus()


# === Drawing ===

func _rebuild() -> void:
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for entry in _commands:
		var command: StringName = entry.get("command", &"")
		var disabled_reason: String = str(entry.get("disabled_reason", ""))
		var pressed_button := Button.new()
		pressed_button.text = str(entry.get("label", command))
		pressed_button.custom_minimum_size = Vector2(0, BUTTON_HEIGHT)
		pressed_button.disabled = disabled_reason != ""
		pressed_button.tooltip_text = disabled_reason
		_style_button(pressed_button)
		pressed_button.pressed.connect(_on_command_pressed.bind(command))
		_list.add_child(pressed_button)
		_buttons[command] = pressed_button


## The party as the battle has it: one line per member, or the reason there is none.
func set_members(rows: Array[Dictionary]) -> void:
	for child in _members.get_children():
		_members.remove_child(child)
		child.queue_free()
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "No party"
		empty.add_theme_color_override("font_color", MUTED_COLOR)
		_members.add_child(empty)
		return
	for row in rows:
		var line := Label.new()
		line.text = _member_text(row)
		line.add_theme_color_override("font_color", MUTED_COLOR if bool(row.get("down", false)) else Color(1, 1, 1))
		_members.add_child(line)


static func _member_text(row: Dictionary) -> String:
	return "%s  HP %d/%d  MP %d/%d" % [
		str(row.get("name", "")),
		int(row.get("hp", 0)), int(row.get("max_hp", 0)),
		int(row.get("mp", 0)), int(row.get("max_mp", 0)),
	]


func _on_command_pressed(command: StringName) -> void:
	if not _open:
		return
	var found: Button = button(command)
	if found == null or found.disabled:
		return
	command_chosen.emit(command)


## Esc, Back or the pad's cancel closes the menu and stops there: the tap must not
## reach the battle.
func _input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		cancel()
