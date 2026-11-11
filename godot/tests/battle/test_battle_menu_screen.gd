extends "res://tests/test_case.gd"

## The battle menu's contract, without a battle: it opens over the scene, the first
## enabled command takes the focus, Back or Esc closes it once and tells the screen, and
## a greyed command reports nothing. BattleMenuModel's rules are checked too, for the
## state before a battle exists. Headless: the renderer draws nothing, the widgets' state
## is what is checked.

const MENU_SCRIPT = preload("res://features/battle/ui/battle_menu_screen.gd")
const CMD_GIVE_UP: StringName = BattleMenuModel.CMD_GIVE_UP
const CMD_REPEAT_INFO: StringName = BattleMenuModel.CMD_REPEAT_INFO

var _menu: BattleMenuScreen = null
var _closed: int = 0
var _chosen: Array[StringName] = []


func before_each() -> void:
	_menu = MENU_SCRIPT.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(_menu)
	_menu.closed.connect(func() -> void: _closed += 1)
	_menu.command_chosen.connect(func(command: StringName) -> void: _chosen.append(command))


func after_each() -> void:
	_menu.get_parent().remove_child(_menu)
	_menu.queue_free()


static func _commands(repeat_reason: String = "") -> Array[Dictionary]:
	return [
		{"command": CMD_GIVE_UP, "label": BattleMenuModel.LABEL_GIVE_UP, "disabled_reason": ""},
		{"command": CMD_REPEAT_INFO, "label": BattleMenuModel.LABEL_REPEAT_INFO, "disabled_reason": repeat_reason},
	]


# === Contract ===

func test_it_opens_over_the_battle_and_closes_with_its_signal() -> void:
	assert_false(_menu.is_open(), "hidden until asked")
	assert_false(_menu.visible)
	_menu.open(_commands())
	assert_true(_menu.is_open())
	assert_true(_menu.visible)
	assert_eq(_menu.z_index, 0, "a child of the battle screen, drawn over its siblings")
	assert_eq([_menu.anchor_right, _menu.anchor_bottom], [1.0, 1.0], "it covers the screen, so no tap gets past")
	assert_eq(_menu.mouse_filter, Control.MOUSE_FILTER_STOP, "a tap lands on the menu, never on a panel behind it")
	assert_true(_menu.size.x > 0.0 and _menu.size.y > 0.0, "a real rect to draw in, not 0x0: %s" % _menu.size)
	assert_eq(_menu.size, _menu.get_parent_area_size(), "the parent's whole area")
	_menu.close()
	assert_false(_menu.is_open())
	assert_false(_menu.visible)
	assert_eq(_closed, 1)


func test_cancel_closes_once_and_only_while_open() -> void:
	assert_false(_menu.cancel(), "nothing to cancel before it is open")
	_menu.open(_commands())
	assert_true(_menu.cancel())
	assert_false(_menu.is_open())
	assert_eq(_closed, 1)
	assert_false(_menu.cancel(), "already closed")
	assert_eq(_closed, 1, "the screen is told once")


func test_the_first_enabled_command_takes_the_focus() -> void:
	_menu.open(_commands(BattleMenuModel.REASON_NOT_PLAYER_TURN))
	var focused: Control = _menu.get_viewport().gui_get_focus_owner()
	assert_eq(focused, _menu.button(CMD_GIVE_UP), "the greyed Repeat Info is skipped")


func test_a_disabled_command_reports_nothing_and_an_enabled_one_names_itself() -> void:
	_menu.open(_commands(BattleMenuModel.REASON_NOT_PLAYER_TURN))
	assert_false(_menu.is_enabled(CMD_REPEAT_INFO))
	_menu.button(CMD_REPEAT_INFO).pressed.emit()
	assert_eq(_chosen, [], "a greyed command never reaches the battle")
	_menu.button(CMD_GIVE_UP).pressed.emit()
	assert_eq(_chosen, [CMD_GIVE_UP])


func test_a_press_after_the_menu_closed_is_ignored() -> void:
	_menu.open(_commands())
	var button: Button = _menu.button(CMD_GIVE_UP)
	_menu.close()
	button.pressed.emit()
	assert_eq(_chosen, [], "the panel is shut, its buttons are dead")


func test_the_member_list_names_the_party_or_says_there_is_none() -> void:
	_menu.open(_commands())
	_menu.set_members([])
	assert_eq(_label_texts(), ["No party"])
	_menu.set_members([
		{"id": 1, "name": "Rain", "hp": 320, "max_hp": 400, "mp": 12, "max_mp": 40, "down": false},
		{"id": 2, "name": "Lasswell", "hp": 0, "max_hp": 380, "mp": 5, "max_mp": 36, "down": true},
	])
	assert_eq(_label_texts(), ["Rain  HP 320/400  MP 12/40", "Lasswell  HP 0/380  MP 5/36"])


## The lines of the member list, in order.
func _label_texts() -> Array[String]:
	var texts: Array[String] = []
	for label in _menu.find_children("*", "Label", true, false):
		if (label as Label).get_parent() == _menu._members:
			texts.append((label as Label).text)
	return texts


# === Before a battle ===

func test_every_command_is_greyed_with_nothing_to_act_on() -> void:
	var commands: Array[Dictionary] = BattleMenuModel.commands(null, null)
	assert_eq(commands.map(func(entry: Dictionary) -> StringName: return entry["command"]), [CMD_GIVE_UP, CMD_REPEAT_INFO])
	for entry in commands:
		assert_eq(entry["disabled_reason"], BattleMenuModel.REASON_NO_BATTLE, str(entry["command"]))
	assert_eq(BattleMenuModel.members(null), [], "no member list before the battle")
