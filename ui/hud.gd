class_name GameHUD
extends CanvasLayer

signal run_toggled(enabled: bool)

const Protocol = preload("res://network/protocol.gd")
const HUDStateScript = preload("res://ui/hud_state.gd")
const UIScale = preload("res://ui/ui_scale.gd")
var state = HUDStateScript.new()
@onready var inventory: PanelContainer = $InventoryPanel
@onready var chatbox: PanelContainer = $Chatbox
@onready var skill_label: Label = $SkillPanel/SkillLabel
@onready var run_button: Button = $RunButton

func _ready() -> void:
	run_button.toggled.connect(_on_run_button_toggled)
	inventory.drop_requested.connect(func(slot: int): get_parent().get_node("InteractionController").drop_slot(slot))
	chatbox.nearby_submitted.connect(func(text: String): get_parent().get_node("InteractionController").send_nearby_chat(text))
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()

func configure(content_bundle) -> void:
	inventory.configure(content_bundle)

func _apply_layout() -> void:
	var logical_size := get_viewport().get_visible_rect().size
	var window_size := DisplayServer.window_get_size()
	if window_size.x <= 0 or window_size.y <= 0:
		window_size = Vector2i(logical_size)
	var safe := DisplayServer.get_display_safe_area()
	if safe.size.x <= 0 or safe.size.y <= 0:
		safe = Rect2i(Vector2i.ZERO, window_size)
	var layout := UIScale.safe_layout(window_size, safe, UIScale.parse_override(OS.get_environment("UI_SCALE")))
	var conversion := Vector2(logical_size.x / window_size.x, logical_size.y / window_size.y)
	_apply_rect($SkillPanel, _to_logical_rect(layout.skill_rect, conversion))
	_apply_rect(run_button, _to_logical_rect(layout.run_rect, conversion))
	_apply_rect(inventory, _to_logical_rect(layout.inventory_rect, conversion))
	_apply_rect(chatbox, _to_logical_rect(layout.chat_rect, conversion))

func _to_logical_rect(rect: Rect2, conversion: Vector2) -> Rect2:
	return Rect2(rect.position * conversion, rect.size * conversion)

func _apply_rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size

func set_run_enabled(enabled: bool) -> void:
	if run_button.button_pressed == enabled:
		return
	run_button.button_pressed = enabled

func is_run_enabled() -> bool:
	return run_button.button_pressed

func _on_run_button_toggled(enabled: bool) -> void:
	run_toggled.emit(enabled)

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
