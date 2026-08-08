class_name DialogueBox
extends PanelContainer

signal closed

@onready var speaker_label: Label = $Layout/Speaker
@onready var line_label: Label = $Layout/Line
@onready var close_button: Button = $Layout/Close

func _ready() -> void:
	close_button.pressed.connect(close)

func show_line(speaker_name: String, text: String) -> void:
	speaker_label.text = speaker_name
	line_label.text = text
	show()

func close() -> void:
	hide()
	closed.emit()
