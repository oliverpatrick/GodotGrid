extends RefCounted

const ContextAction = preload("uid://dttp4mcn4r8xm") # ui/context_menu/context_action.gd
const ContextMenuScene = preload("uid://caafyydy1os1") # ui/context_menu/context_menu.tscn

static func run() -> bool:
	var child = ContextAction.create("Child", "child.action")
	var parent = ContextAction.create("Parent", "parent.action", [child])
	if parent.label != "Parent" or parent.children.size() != 1 or parent.children[0].action_id != "child.action":
		return false
	var menu = ContextMenuScene.instantiate()
	Engine.get_main_loop().root.add_child(menu)
	var selected: Array[String] = []
	menu.action_selected.connect(func(action_id: String): selected.append(action_id))
	menu.open([ContextAction.create("Inspect", "world.inspect"), ContextAction.create("Close", "context.close")], Vector2(100000, 100000))
	var viewport: Rect2 = menu.get_viewport().get_visible_rect()
	if not viewport.encloses(Rect2(menu.position, menu.size)):
		menu.free()
		return false
	menu.select_action("world.inspect")
	var ok: bool = selected == ["world.inspect"] and not menu.visible
	menu.free()
	return ok

static func placement_is_clamped() -> bool:
	var menu = ContextMenuScene.instantiate()
	Engine.get_main_loop().root.add_child(menu)
	var viewport := Rect2i(0, 0, 512, 512)
	var popup_size := Vector2i(97, 62)
	var pointer := Vector2(320, 240)
	var pointer_rect: Rect2i = menu.popup_rect_for(pointer, viewport, popup_size)
	var bottom_right: Rect2i = menu.popup_rect_for(Vector2(viewport.end) - Vector2.ONE, viewport, popup_size)
	var top_left: Rect2i = menu.popup_rect_for(Vector2(-10, -10), viewport, popup_size)
	var oversized: Rect2i = menu.popup_rect_for(Vector2(250, 250), viewport, Vector2i(600, 600))
	var appears_at_pointer: bool = pointer_rect.position == Vector2i(pointer)
	var stays_inside_viewport: bool = viewport.encloses(bottom_right) and top_left.position == viewport.position
	var oversized_anchors_to_origin: bool = oversized.position == viewport.position
	menu.free()
	return appears_at_pointer and stays_inside_viewport and oversized_anchors_to_origin
