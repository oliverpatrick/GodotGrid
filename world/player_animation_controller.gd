class_name PlayerAnimationController
extends RefCounted

const IDLE_ANIMATION := "Idle"
const WALK_ANIMATION := "Walk"
const RUN_ANIMATION := "Jog_Fwd"
const HARVEST_ANIMATION := "Sword_Attack"
const PUNCH_CROSS_ANIMATION := "Punch_Cross"
const PUNCH_JAB_ANIMATION := "Punch_Jab"
const DEATH_ANIMATION := "Death01"

var animation_player: AnimationPlayer
var action := 0
var moving := false
var movement_animation := WALK_ANIMATION

func _init(player: AnimationPlayer) -> void:
	animation_player = player
	var harvest := animation_player.get_animation(HARVEST_ANIMATION)
	if harvest != null:
		harvest.loop_mode = Animation.LOOP_LINEAR
	for animation_name in [PUNCH_CROSS_ANIMATION, PUNCH_JAB_ANIMATION, DEATH_ANIMATION]:
		if animation_player.has_animation(animation_name):
			animation_player.get_animation(animation_name).loop_mode = Animation.LOOP_NONE
	if not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)
	refresh()

func set_action(next_action: int) -> void:
	if action == 4 and next_action != 0:
		return
	var was_dead := action == 4
	action = next_action
	if action == 2:
		_play_once(PUNCH_CROSS_ANIMATION)
	elif action == 3:
		_play_once(PUNCH_JAB_ANIMATION)
	elif action == 4:
		_play_once(DEATH_ANIMATION)
	else:
		if was_dead:
			moving = false
		refresh()

func movement_started(tile_distance: int) -> void:
	moving = true
	movement_animation = RUN_ANIMATION if tile_distance >= 2 else WALK_ANIMATION
	refresh()

func movement_finished() -> void:
	moving = false
	refresh()

func refresh() -> void:
	if action == 4 or _punch_is_playing():
		return
	var wanted := movement_animation if moving else (HARVEST_ANIMATION if action == 1 else IDLE_ANIMATION)
	if not animation_player.has_animation(wanted):
		push_warning("Missing player animation: %s" % wanted)
		wanted = IDLE_ANIMATION
	if animation_player.has_animation(wanted) and animation_player.current_animation != wanted:
		animation_player.play(wanted)

func _play_once(animation_name: String) -> void:
	if not animation_player.has_animation(animation_name):
		push_warning("Missing player animation: %s" % animation_name)
		if animation_name == DEATH_ANIMATION:
			animation_player.pause()
		elif animation_player.has_animation(IDLE_ANIMATION):
			animation_player.play(IDLE_ANIMATION)
		return
	animation_player.stop()
	animation_player.play(animation_name)

func _punch_is_playing() -> bool:
	return animation_player.is_playing() and animation_player.current_animation in [PUNCH_CROSS_ANIMATION, PUNCH_JAB_ANIMATION]

func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name == PUNCH_CROSS_ANIMATION or animation_name == PUNCH_JAB_ANIMATION:
		refresh()
