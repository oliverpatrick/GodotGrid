extends RefCounted

const ContextActions = preload("res://gameplay/context_actions.gd")
const UseTargeting = preload("res://gameplay/use_targeting.gd")
const ClickToMove = preload("res://world/click_to_move.gd")
const ContentLoader = preload("res://content/content_loader.gd")
const InteractionController = preload("res://gameplay/interaction_controller.gd")
const NetworkClient = preload("res://network/network_client.gd")
const Protocol = preload("res://network/protocol.gd")
const ObjectRegistry = preload("res://world/object_registry.gd")

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
	var bundle = ContentLoader.load_bundle(OS.get_environment("GAME_CONTENT_ROOT"))
	var man = bundle.npc_by_id("npc.man")
	var merchant = bundle.npc_by_id("npc.merchant_aldric")
	if _labels(ContextActions.npc_actions(man)) != ["Talk-to", "Attack Man (level-2)", "Inspect", "Close"]:
		return false
	if _labels(ContextActions.npc_actions(merchant)) != ["Talk-to", "Inspect", "Close"]:
		return false
	var network := NetworkClient.new()
	var controller := InteractionController.new()
	controller.configure(network)
	var talk = Protocol.decode_frame(controller.build_interaction_request(0x8000002a, 0))
	var attack = Protocol.decode_frame(controller.build_interaction_request(0x8000002a, 1))
	controller.free()
	network.free()
	if talk == null or attack == null or talk.payload[4] != 0 or attack.payload[4] != 1:
		return false
	var registry := ObjectRegistry.new()
	registry.configure(bundle)
	registry.handle_message(Protocol.ENTITY_SPAWN, {"entity": 0x8000002a, "type": 3, "x": 85, "z": 85, "plane": 0, "name": "bones", "definition_id": "item.bones"})
	registry.handle_message(Protocol.ENTITY_SPAWN, {"entity": 0x8000002b, "type": 3, "x": 85, "z": 85, "plane": 0, "name": "coins", "definition_id": "item.coins"})
	registry.handle_message(Protocol.GROUND_ITEM, {"entity": 0x8000002a, "quantity": 1})
	registry.handle_message(Protocol.GROUND_ITEM, {"entity": 0x8000002b, "quantity": 5})
	var stacks: Array = registry.ground_items_at(0x8000002a)
	var stack_labels := _labels(ContextActions.ground_item_actions(stacks))
	registry.free()
	if stack_labels != ["Pick up Bones (1)", "Pick up Coins (5)", "Inspect", "Close"]:
		return false
	var targeting = UseTargeting.new()
	targeting.select_source(3)
	if targeting.source_slot() != 3:
		return false
	if targeting.take_source() != 3 or targeting.source_slot() != -1:
		return false
	return ClickToMove.is_long_press(500, 0.0) and not ClickToMove.is_long_press(499, 0.0) and not ClickToMove.is_long_press(500, 20.0)
