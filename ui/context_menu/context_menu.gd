class_name GameContextMenu
extends PopupMenu

signal action_selected(action_id: String)

var _actions: Dictionary = {}
var _next_id := 1

func _ready() -> void:
	# Keep menus in the game viewport so pointer and popup coordinates share the
	# same space on desktop, mobile, and embedded-window configurations.
	get_viewport().gui_embed_subwindows = true
	id_pressed.connect(_on_id_pressed)
	window_input.connect(_on_window_input)

func open(actions: Array, screen_position: Vector2) -> void:
	clear()
	_clear_submenus()
	_actions.clear()
	_next_id = 1
	_add_actions(self, actions)
	reset_size()
	var viewport_rect := Rect2i(get_tree().root.get_visible_rect())
	popup(popup_rect_for(screen_position, viewport_rect, size))

func popup_rect_for(screen_position: Vector2, viewport_rect: Rect2i, popup_size: Vector2i) -> Rect2i:
	var wanted := Vector2i(screen_position)
	var furthest_x := maxi(viewport_rect.position.x, viewport_rect.end.x - popup_size.x)
	var furthest_y := maxi(viewport_rect.position.y, viewport_rect.end.y - popup_size.y)
	wanted.x = clampi(wanted.x, viewport_rect.position.x, furthest_x)
	wanted.y = clampi(wanted.y, viewport_rect.position.y, furthest_y)
	return Rect2i(wanted, popup_size)

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

func _on_window_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		hide()
		get_viewport().set_input_as_handled()

func _clear_submenus() -> void:
	for child in get_children():
		if child is PopupMenu:
			child.queue_free()
