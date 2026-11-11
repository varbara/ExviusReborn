extends PanelContainer

@onready var home_button: Button = $HBox/HomeButton
@onready var units_button: Button = $HBox/UnitsButton
@onready var items_button: Button = $HBox/ItemsButton
@onready var shop_button: Button = $HBox/ShopButton
@onready var summon_button: Button = $HBox/SummonButton
@onready var friends_button: Button = $HBox/FriendsButton

func _ready() -> void:
	home_button.pressed.connect(func(): UIManager.set_root("game_ui"))
	units_button.pressed.connect(func(): UIManager.set_root("units_ui"))
	items_button.pressed.connect(func(): UIManager.set_root("items_ui"))
	shop_button.pressed.connect(func(): UIManager.set_root("shop_ui"))
	summon_button.pressed.connect(_on_summon_button_pressed)
	friends_button.pressed.connect(func(): UIManager.set_root("friends_ui"))
	
	_update_summon_button_state()
	var unit_svc: Node = get_node_or_null("/root/UnitService")
	if unit_svc != null and unit_svc.has_signal("units_updated"):
		unit_svc.units_updated.connect(func(_u): _update_summon_button_state())


func _update_summon_button_state() -> void:
	if not is_instance_valid(summon_button):
		return
	var unit_svc: Node = get_node_or_null("/root/UnitService")
	var is_unlocked: bool = bool(unit_svc.call("is_summon_system_unlocked")) if (unit_svc and unit_svc.has_method("is_summon_system_unlocked")) else false
	summon_button.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_unlocked else Color(0.55, 0.55, 0.60, 0.82)


func _on_summon_button_pressed() -> void:
	var unit_svc: Node = get_node_or_null("/root/UnitService")
	var is_unlocked: bool = bool(unit_svc.call("is_summon_system_unlocked")) if (unit_svc and unit_svc.has_method("is_summon_system_unlocked")) else false
	if not is_unlocked:
		var dialog := AcceptDialog.new()
		dialog.title = "ระบบยังไม่ปลดล็อก"
		dialog.dialog_text = "ระบบอัญเชิญวิชั่น (Summon) ยังไม่ปลดล็อก คูโปะ!\n\nต้องผ่านวิหารดิน (Earth Shrine) ก่อน จึงจะสามารถอัญเชิญเพื่อนได้"
		add_child(dialog)
		dialog.popup_centered()
		return

	if unit_svc != null and not bool(unit_svc.get("is_tutorial_summon_done")):
		UIManager.set_root("summon_ui", {"is_tutorial": true})
	else:
		UIManager.set_root("summon_ui")
