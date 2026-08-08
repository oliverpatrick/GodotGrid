extends RefCounted

const DialogueBoxScene = preload("res://ui/dialogue_box/dialogue_box.tscn")
const HUDScene = preload("uid://01ughi8s4iax") # ui/player_hud/hud.tscn

static func run() -> bool:
	var dialogue = DialogueBoxScene.instantiate()
	Engine.get_main_loop().root.add_child(dialogue)
	dialogue.show_line("Man", "Hello there.")
	if not dialogue.visible or dialogue.speaker_label.text != "Man" or dialogue.line_label.text != "Hello there.":
		printerr("standalone dialogue failed: visible=%s speaker=%s line=%s" % [dialogue.visible, dialogue.speaker_label.text, dialogue.line_label.text])
		dialogue.free()
		return false
	var closed: Array[bool] = []
	dialogue.closed.connect(func(): closed.append(true))
	dialogue.close()
	if dialogue.visible or closed != [true]:
		printerr("dialogue close failed: visible=%s closed=%s" % [dialogue.visible, closed])
		dialogue.free()
		return false
	dialogue.free()

	var hud = HUDScene.instantiate()
	Engine.get_main_loop().root.add_child(hud)
	var chatbox: Control = hud.get_node("Chatbox")
	var hud_dialogue: Control = hud.get_node("DialogueBox")
	if chatbox.position != hud_dialogue.position or chatbox.size != hud_dialogue.size:
		printerr("dialogue rect mismatch: chat=%s/%s dialogue=%s/%s" % [chatbox.position, chatbox.size, hud_dialogue.position, hud_dialogue.size])
		hud.free()
		return false
	hud.show_dialogue("Man", "First")
	hud.show_dialogue("Merchant Aldric", "Second")
	if chatbox.visible or not hud_dialogue.visible or hud_dialogue.speaker_label.text != "Merchant Aldric" or hud_dialogue.line_label.text != "Second":
		printerr("hud dialogue failed: chat=%s dialogue=%s speaker=%s line=%s" % [chatbox.visible, hud_dialogue.visible, hud_dialogue.speaker_label.text, hud_dialogue.line_label.text])
		hud.free()
		return false
	hud_dialogue.close()
	var ok: bool = chatbox.visible and not hud_dialogue.visible
	if not ok:
		printerr("hud close failed: chat=%s dialogue=%s" % [chatbox.visible, hud_dialogue.visible])
	hud.free()
	return ok
