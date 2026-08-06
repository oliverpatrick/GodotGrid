class_name ContextActions
extends RefCounted

const Action = preload("uid://dttp4mcn4r8xm") # ui/context_menu/context_action.gd

static func world_actions(kind: String) -> Array:
	var primary := "Chop" if kind == "resource" else "Pick up"
	return [Action.create(primary, "world.primary"), Action.create("Inspect", "world.inspect"), Action.create("Close", "context.close")]

static func inventory_actions(droppable: bool) -> Array:
	var actions := [Action.create("Use", "inventory.use"), Action.create("Inspect", "inventory.inspect")]
	if droppable:
		actions.append(Action.create("Drop", "inventory.drop"))
	actions.append(Action.create("Close", "context.close"))
	return actions
