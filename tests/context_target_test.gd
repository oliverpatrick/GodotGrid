extends RefCounted

const ContextActions = preload("res://gameplay/context_actions.gd")
const UseTargeting = preload("res://gameplay/use_targeting.gd")
const ClickToMove = preload("res://world/click_to_move.gd")

static func _labels(actions: Array) -> Array:
	return actions.map(func(action): return action.label)

static func run() -> bool:
	if _labels(ContextActions.world_actions("resource")) != ["Chop", "Inspect", "Close"]:
		return false
	if _labels(ContextActions.world_actions("ground_item")) != ["Pick up", "Inspect", "Close"]:
		return false
	if _labels(ContextActions.inventory_actions(false)) != ["Use", "Inspect", "Close"]:
		return false
	if _labels(ContextActions.inventory_actions(true)) != ["Use", "Inspect", "Drop", "Close"]:
		return false
	var targeting = UseTargeting.new()
	targeting.select_source(3)
	if targeting.source_slot() != 3:
		return false
	if targeting.take_source() != 3 or targeting.source_slot() != -1:
		return false
	return ClickToMove.is_long_press(500, 0.0) and not ClickToMove.is_long_press(499, 0.0) and not ClickToMove.is_long_press(500, 20.0)
