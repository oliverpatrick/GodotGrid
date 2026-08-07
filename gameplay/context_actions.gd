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

static func ground_item_actions(stacks: Array) -> Array:
	var result: Array = []
	for stack in stacks:
		result.append(Action.create("Pick up %s (%d)" % [stack.name, stack.quantity], "ground.pickup:%d" % stack.entity))
	result.append(Action.create("Inspect", "world.inspect"))
	result.append(Action.create("Close", "context.close"))
	return result

static func npc_actions(definition: Dictionary) -> Array:
	var result: Array = []
	var name := str(definition.get("name", ""))
	var level := int(definition.get("combat", {}).get("level", 0))
	for action in definition.get("actions", []):
		match str(action):
			"Talk-to": result.append(Action.create("Talk-to", "npc.talk"))
			"Attack": result.append(Action.create("Attack %s (level-%d)" % [name, level], "npc.attack"))
			"Inspect": result.append(Action.create("Inspect", "world.inspect"))
	result.append(Action.create("Close", "context.close"))
	return result
