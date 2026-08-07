class_name GameHUD
extends CanvasLayer

const Protocol = preload("res://network/protocol.gd")
const HUDStateScript = preload("res://ui/hud_state.gd")
var state = HUDStateScript.new()
@onready var inventory: PanelContainer = $InventoryPanel
@onready var chatbox: PanelContainer = $Chatbox
@onready var skill_label: Label = $SkillPanel/SkillLabel

func _ready() -> void:
	inventory.drop_requested.connect(func(slot: int): get_parent().get_node("InteractionController").drop_slot(slot))
	chatbox.nearby_submitted.connect(func(text: String): get_parent().get_node("InteractionController").send_nearby_chat(text))

func handle_message(id: int, message) -> void:
	if message == null:
		return
	match id:
		Protocol.INVENTORY:
			state.apply_inventory(message.slots)
			inventory.render_slots(state.slots)
		Protocol.SKILL:
			state.apply_skill(message.skill, message.xp)
			skill_label.text = "Harvesting  %d\nXP  %d" % [state.harvesting_level, state.harvesting_xp]
		Protocol.CHAT_MESSAGE:
			add_system_message("[Nearby] Player %d: %s" % [message.sender, message.text])
		Protocol.SYSTEM_MESSAGE:
			add_system_message(message.text)
		Protocol.RESOURCE_STATE:
			state.apply_resource(message.entity, message.state)

func add_system_message(text: String) -> void:
	state.add_message(text)
	chatbox.add_message(text)
