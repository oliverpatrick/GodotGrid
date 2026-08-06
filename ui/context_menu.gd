class_name GameContextMenu
extends PopupMenu

signal action_selected(action_id: String)

var _actions: Dictionary = {}
var _next_id := 1

func _ready() -> void:
	id_pressed.connect(_on_id_pressed)

func open(actions: Array, screen_position: Vector2) -> void:
	clear()
	_clear_submenus()
	_actions.clear()
	_next_id = 1
	_add_actions(self, actions)
	reset_size()
	var viewport_size := Vector2i(get_viewport().get_visible_rect().size)
	var wanted := Vector2i(screen_position)
	wanted.x = clampi(wanted.x, 0, maxi(0, viewport_size.x - size.x))
	wanted.y = clampi(wanted.y, 0, maxi(0, viewport_size.y - size.y))
	position = wanted
	popup()

func select_action(action_id: String) -> void:
	if action_id == "context.close":
		hide()
		return
	action_selected.emit(action_id)
	hide()

func _add_actions(menu: PopupMenu, actions: Array) -> void:
	for action in actions:
		if action.children.is_empty():
			var item_id := _next_id
			_next_id += 1
			menu.add_item(action.label, item_id)
			_actions[item_id] = action.action_id
		else:
			var submenu := PopupMenu.new()
			submenu.name = "Submenu_%d" % _next_id
			submenu.id_pressed.connect(_on_id_pressed)
			menu.add_child(submenu)
			_add_actions(submenu, action.children)
			menu.add_submenu_item(action.label, submenu.name)

func _on_id_pressed(item_id: int) -> void:
	select_action(str(_actions.get(item_id, "context.close")))

func _clear_submenus() -> void:
	for child in get_children():
		if child is PopupMenu:
			child.queue_free()
