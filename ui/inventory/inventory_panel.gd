class_name InventoryPanel
extends PanelContainer

signal context_requested(slot: int, screen_position: Vector2)
signal slot_clicked(slot: int)
var buttons: Array[Button] = []
var rendered_slots: Array = []
var bundle

func configure(content_bundle) -> void:
	bundle = content_bundle

func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	add_child(grid)
	for slot in range(30):
		var button := Button.new()
		button.custom_minimum_size = Vector2(48, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Empty"
		button.gui_input.connect(_slot_input.bind(slot))
		grid.add_child(button)
		buttons.append(button)

func render_slots(slots: Array) -> void:
	rendered_slots = slots
	for index in range(30):
		var item = slots[index]
		if item == null:
			buttons[index].text = ""
			buttons[index].tooltip_text = "Empty"
		else:
			buttons[index].text = "AXE" if item.item == 0 else "LOG"
			buttons[index].tooltip_text = "Basic axe" if item.item == 0 else "Mutated log — right-click to drop"

func _slot_input(event: InputEvent, slot: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if slot < rendered_slots.size() and rendered_slots[slot] != null:
			context_requested.emit(slot, buttons[slot].global_position + event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if slot < rendered_slots.size() and rendered_slots[slot] != null:
			slot_clicked.emit(slot)

func item_droppable(slot: int) -> bool:
	if bundle == null or slot < 0 or slot >= rendered_slots.size() or rendered_slots[slot] == null:
		return false
	var definition = bundle.item_by_wire_id(rendered_slots[slot].item)
	return definition != null and bool(definition.get("droppable", false))

func set_selected_slot(slot: int) -> void:
	for index in range(buttons.size()):
		buttons[index].modulate = Color(0.55, 1.0, 0.65) if index == slot else Color.WHITE
