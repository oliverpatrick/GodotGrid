class_name PlayerAnimationController
extends RefCounted

const IDLE_ANIMATION := "Idle"
const WALK_ANIMATION := "Walk"
const RUN_ANIMATION := "Jog_Fwd"
const HARVEST_ANIMATION := "Sword_Attack"

var animation_player: AnimationPlayer
var action := 0
var moving := false
var movement_animation := WALK_ANIMATION

func _init(player: AnimationPlayer) -> void:
	animation_player = player
	var harvest := animation_player.get_animation(HARVEST_ANIMATION)
	if harvest != null:
		harvest.loop_mode = Animation.LOOP_LINEAR
	refresh()

func set_action(next_action: int) -> void:
	action = next_action
	refresh()

func movement_started(tile_distance: int) -> void:
	moving = true
	movement_animation = RUN_ANIMATION if tile_distance >= 2 else WALK_ANIMATION
	refresh()

func movement_finished() -> void:
	moving = false
	refresh()

func refresh() -> void:
	var wanted := movement_animation if moving else (HARVEST_ANIMATION if action == 1 else IDLE_ANIMATION)
	if not animation_player.has_animation(wanted):
		push_warning("Missing player animation: %s" % wanted)
		wanted = IDLE_ANIMATION
	if animation_player.has_animation(wanted) and animation_player.current_animation != wanted:
		animation_player.play(wanted)
