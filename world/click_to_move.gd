class_name ClickToMove
extends Node

const Protocol = preload("res://network/protocol.gd")

signal destination_requested(tile: Vector3i, mode: int, sequence: int)
signal system_message(text: String)
signal entity_clicked(entity: int)

var camera: Camera3D
var stream
var network
var sequence := 0

func configure(view_camera: Camera3D, world_stream, network_client) -> void:
	camera = view_camera
	stream = world_stream
	network = network_client

static func world_to_visible_tile(point: Vector3, loaded_regions: Dictionary):
	var x := int(floor(point.x))
	var z := int(floor(point.z))
	if x < 0 or z < 0 or x >= 256 or z >= 256:
		return null
	var key := "%d:%d:0" % [x / 64, z / 64]
	if not loaded_regions.has(key):
		return null
	return Vector3i(x, 0, z)

func _unhandled_input(event: InputEvent) -> void:
	var screen_position := Vector2.ZERO
	var pressed := false
	var run_mode := 0
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		screen_position = event.position
		pressed = event.pressed
		run_mode = 1 if event.shift_pressed else 0
	elif event is InputEventScreenTouch:
		screen_position = event.position
		pressed = event.pressed
	if pressed:
		request_screen_destination(screen_position, run_mode)

func request_screen_destination(screen_position: Vector2, mode: int = 0):
	if camera == null or stream == null:
		return reject_unreachable()
	var origin := camera.project_ray_origin(screen_position)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(screen_position) * 2000.0)
	var hit := camera.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return reject_unreachable()
	if hit.collider != null and hit.collider.has_meta("entity_id"):
		var entity: int = hit.collider.get_meta("entity_id")
		entity_clicked.emit(entity)
		return entity
	var tile = world_to_visible_tile(hit.position, stream.loaded)
	if tile == null:
		return reject_unreachable()
	sequence += 1
	var frame := Protocol.encode_move(tile.x, tile.z, 0, mode, sequence)
	if network == null or network.send_frame(frame) != OK:
		return reject_unreachable()
	destination_requested.emit(tile, mode, sequence)
	return tile

func reject_unreachable():
	system_message.emit("I can't reach that")
	return null
