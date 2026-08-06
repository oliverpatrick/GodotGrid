extends RefCounted

const ContextAction = preload("res://ui/context_action.gd")
const ContextMenuScene = preload("res://ui/context_menu.tscn")

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
