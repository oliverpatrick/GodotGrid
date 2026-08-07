extends RefCounted

const HUDScene = preload("uid://01ughi8s4iax") # ui/player_hud/hud.tscn

class FakeNetwork:
	extends RefCounted
	var frames: Array[PackedByteArray] = []

	func send_frame(frame: PackedByteArray) -> void:
		frames.append(frame)


static func run() -> bool:
	var root := Node.new()
	Engine.get_main_loop().root.add_child(root)
	var hud = HUDScene.instantiate()
	root.add_child(hud)
	var tabs: GameTabs = hud.game_tabs
	var aggressive: Button = tabs.get_node("HSplitContainer/TabContainer/CombatTab/StyleOptions/Aggressive")
	var defensive: Button = tabs.get_node("HSplitContainer/TabContainer/CombatTab/StyleOptions/Defensive")
	if not aggressive.disabled or not defensive.disabled or aggressive.button_pressed or defensive.button_pressed:
		root.free()
		return false
	tabs.acknowledge_combat_style(0)
	if aggressive.disabled or defensive.disabled or not aggressive.button_pressed or defensive.button_pressed:
		root.free()
		return false
	var requested: Array[int] = []
	tabs.combat_style_requested.connect(func(style: int): requested.append(style))
	defensive.button_pressed = true
	defensive.pressed.emit()
	if requested != [1] or not aggressive.button_pressed or defensive.button_pressed:
		root.free()
		return false
	tabs.acknowledge_combat_style(1)
	if aggressive.button_pressed or not defensive.button_pressed:
		root.free()
		return false
	var controller := InteractionController.new()
	var network := FakeNetwork.new()
	controller.configure(network)
	if controller.build_combat_style_request(1).hex_encode() != "0021000101":
		controller.free()
		root.free()
		return false
	controller.set_combat_style(0)
	if network.frames.size() != 1 or network.frames[0].hex_encode() != "0021000100":
		controller.free()
		root.free()
		return false
	hud.handle_message(GameProtocol.COMBAT_STYLE, {"style": 0})
	var acknowledged := aggressive.button_pressed and not defensive.button_pressed
	controller.free()
	root.free()
	return acknowledged
