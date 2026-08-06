extends "res://world/remote_player.gd"

func _ready() -> void:
	super._ready()
	_ensure_animation_controller()
	if animation_controller != null:
		animation_controller.refresh()
