class_name InventoryPanel
extends PanelContainer

signal drop_requested(slot: int)
var buttons: Array[Button] = []

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
		drop_requested.emit(slot)
