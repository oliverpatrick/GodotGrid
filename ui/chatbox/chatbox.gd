class_name Chatbox
extends PanelContainer

signal nearby_submitted(text: String)
var history: RichTextLabel
var input: LineEdit

func _ready() -> void:
	var layout := VBoxContainer.new()
	add_child(layout)
	var channel := OptionButton.new()
	channel.add_item("Nearby")
	channel.add_item("Friends (deferred)")
	channel.set_item_disabled(1, true)
	layout.add_child(channel)
	history = RichTextLabel.new()
	history.bbcode_enabled = true
	history.custom_minimum_size = Vector2(0, 128)
	history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	history.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history.scroll_following = true
	layout.add_child(history)
	input = LineEdit.new()
	input.placeholder_text = "Press Enter to chat nearby"
	input.max_length = 160
	input.custom_minimum_size.y = 48
	input.text_submitted.connect(_submit)
	layout.add_child(input)

func add_message(text: String) -> void:
	history.append_text(text + "\n")

func _submit(text: String) -> void:
	if not text.strip_edges().is_empty():
		nearby_submitted.emit(text)
	input.clear()
