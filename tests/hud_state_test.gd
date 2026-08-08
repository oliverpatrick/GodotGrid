extends RefCounted

const HUDState = preload("uid://donlsyshgyxjl") # ui/player_hud/hud_state.gd
const InteractionController = preload("res://gameplay/interaction_controller.gd")
const NetworkClient = preload("res://network/network_client.gd")

static func run() -> bool:
	var state = HUDState.new()
	state.apply_inventory([{"slot": 1, "item": 1, "quantity": 1}, {"slot": 2, "item": 1, "quantity": 1}])
	if state.slots.size() != 30 or state.slots[1].quantity != 1 or state.slots[2].quantity != 1:
		return false
	state.apply_skill(0, 0)
	if state.health_xp != 0 or state.health_level != 1:
		return false
	state.apply_skill(1, 20)
	state.apply_skill(2, 30)
	state.apply_skill(3, 40)
	state.apply_skill(4, 50)
	if state.attack_xp != 20 or state.defence_xp != 30 or state.harvesting_xp != 40 or state.perception_xp != 50:
		return false
	state.apply_skill(99, 999)
	if state.perception_xp != 50 or state.health_xp != 0:
		return false
	state.apply_resource(0x8000002a, 2)
	if state.resources[0x8000002a] != 2:
		return false
	state.add_message("inventory is full")
	if state.messages[-1] != "inventory is full":
		return false
	var controller: Node = InteractionController.new()
	var network: Node = NetworkClient.new()
	controller.configure(network)
	var frame: PackedByteArray = controller.build_drop_request(3)
	controller.free()
	network.free()
	return frame.hex_encode() == "0012000703000100000001"
