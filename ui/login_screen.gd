class_name LoginScreen
extends CanvasLayer

const UIScale = preload("res://ui/ui_scale.gd")

signal submitted(email: String, password: String)

var email: LineEdit
var password: LineEdit
var submit: Button
var status: Label

func _ready() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.035, 0.035, 0.96)
	add_child(backdrop)
	var panel := PanelContainer.new()
	var user_scale := UIScale.parse_override(OS.get_environment("UI_SCALE"))
	panel.custom_minimum_size = Vector2(420, 300) * user_scale
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = panel.custom_minimum_size * -0.5
	backdrop.add_child(panel)
	var fields := VBoxContainer.new()
	fields.add_theme_constant_override("separation", 14)
	panel.add_child(fields)
	var title := Label.new()
	title.text = "COLLIDED REALMS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	fields.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "World access terminal"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fields.add_child(subtitle)
	email = LineEdit.new()
	email.placeholder_text = "Email"
	email.virtual_keyboard_type = LineEdit.KEYBOARD_TYPE_EMAIL_ADDRESS
	fields.add_child(email)
	password = LineEdit.new()
	password.placeholder_text = "Password"
	password.secret = true
	fields.add_child(password)
	submit = Button.new()
	submit.text = "Enter world"
	submit.custom_minimum_size.y = 48
	submit.pressed.connect(_submit)
	fields.add_child(submit)
	status = Label.new()
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	fields.add_child(status)
	password.text_submitted.connect(func(_value: String): _submit())

func _submit() -> void:
	if email.text.strip_edges().is_empty() or password.text.is_empty():
		show_error("Enter your email and password")
		return
	set_busy(true)
	submitted.emit(email.text, password.text)

func set_busy(busy: bool) -> void:
	submit.disabled = busy
	status.text = "Connecting..." if busy else ""

func show_error(message: String) -> void:
	submit.disabled = false
	status.text = message
