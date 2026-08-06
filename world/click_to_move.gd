class_name ClickToMove
extends Node

const Protocol = preload("uid://bvppiqbq80y0l") # network/protocol.gd

signal destination_requested(tile: Vector3i, mode: int, sequence: int)
signal system_message(text: String)
signal entity_clicked(entity: int)
signal context_requested(entity: int, screen_position: Vector2)

var camera: Camera3D
var stream
var network
var _run_enabled := false
var _touch_started_ms := 0
var _touch_started_position := Vector2.ZERO

func configure(view_camera: Camera3D, world_stream, network_client) -> void:
	camera = view_camera
	stream = world_stream
	network = network_client

func set_run_enabled(enabled: bool) -> void:
	_run_enabled = enabled

func is_run_enabled() -> bool:
	return _run_enabled

func effective_movement_mode(ctrl_pressed: bool) -> int:
	return 1 if _run_enabled or ctrl_pressed else 0

static func world_to_visible_tile(point: Vector3, loaded_regions: Dictionary):
	var x := int(floor(point.x))
	var z := int(floor(point.z))
	if x < 0 or z < 0 or x >= 256 or z >= 256:
		return null
	var key := "%d:%d:0" % [x >> 6, z >> 6]
	if not loaded_regions.has(key):
		return null
	return Vector3i(x, 0, z)

static func is_long_press(duration_ms: int, travel: float) -> bool:
	return duration_ms >= 500 and travel <= 12.0

func _unhandled_input(event: InputEvent) -> void:
	var screen_position := Vector2.ZERO
	var pressed := false
	var run_mode := 0
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		screen_position = event.position
		pressed = event.pressed
		run_mode = effective_movement_mode(event.ctrl_pressed)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			request_screen_context(event.position)
		return
	elif event is InputEventScreenTouch:
		screen_position = event.position
		run_mode = effective_movement_mode(false)
		if event.pressed:
			_touch_started_ms = Time.get_ticks_msec()
			_touch_started_position = event.position
			return
		var duration := Time.get_ticks_msec() - _touch_started_ms
		if is_long_press(duration, event.position.distance_to(_touch_started_position)):
			request_screen_context(event.position)
			return
		pressed = true
	if pressed:
		request_screen_destination(screen_position, run_mode)

func request_screen_context(screen_position: Vector2):
	var hit = _screen_hit(screen_position)
	if hit.is_empty() or hit.collider == null or not hit.collider.has_meta("entity_id"):
		return null
	var entity: int = hit.collider.get_meta("entity_id")
	context_requested.emit(entity, screen_position)
	return entity

func request_screen_destination(screen_position: Vector2, mode: int = 0):
	if camera == null or stream == null:
		return reject_unreachable()
	var hit = _screen_hit(screen_position)
	if hit.is_empty():
		return reject_unreachable()
	if hit.collider != null and hit.collider.has_meta("entity_id"):
		var entity: int = hit.collider.get_meta("entity_id")
		entity_clicked.emit(entity)
		return entity
	var tile = world_to_visible_tile(hit.position, stream.loaded)
	if tile == null:
		return reject_unreachable()
	var frame := build_move_request(tile, mode)
	if network == null or network.send_frame(frame) != OK:
		return reject_unreachable()
	destination_requested.emit(tile, mode, _frame_sequence(frame))
	return tile

func _screen_hit(screen_position: Vector2) -> Dictionary:
	if camera == null:
		return {}
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen_position) * 2000.0)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)

func build_move_request(tile: Vector3i, mode: int) -> PackedByteArray:
	if network == null:
		return PackedByteArray()
	return Protocol.encode_move(tile.x, tile.z, tile.y, mode, network.next_world_sequence())

func _frame_sequence(frame: PackedByteArray) -> int:
	var size := frame.size()
	return (frame[size - 4] << 24) | (frame[size - 3] << 16) | (frame[size - 2] << 8) | frame[size - 1]

func reject_unreachable():
	system_message.emit("I can't reach that")
	return null
