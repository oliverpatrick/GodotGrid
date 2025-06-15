# CameraController.gd - Attach to Camera3D
extends Camera3D

#@export var target_position: Vector3 = Vector3(8, 0, 8)  # Center of 8x8 terrain
@export var distance: float = 20.0
@export var height: float = 15.0
@export var rotation_speed: float = 1.0
@export var zoom_speed: float = 10.0
@export var min_distance: float = 5.0
@export var max_distance: float = 50.0

@onready var terrain = get_parent().get_parent()
@onready var player = get_parent()

@onready var tile_indicator_scene = preload("res://tile_indicator.tscn")
var tile_indicator: Node3D = null

var angle: float = 0.0

func _ready():
	# Position camera to look at terrain
	position_camera()

func _process(delta):
	# Optional: Rotate around the terrain
	if Input.is_action_pressed("ui_left"):
		angle -= rotation_speed * delta
		position_camera()
	elif Input.is_action_pressed("ui_right"):
		angle += rotation_speed * delta
		position_camera()
	
	# Zoom in/out
	if Input.is_action_pressed("ui_up"):
		distance = max(5.0, distance - zoom_speed * delta)
		position_camera()
	elif Input.is_action_pressed("ui_down"):
		distance += zoom_speed * delta
		position_camera()

func position_camera():
	var offset = Vector3(
		cos(angle) * distance,
		height,
		sin(angle) * distance
	)
	
	global_position = player.global_position + offset
	look_at(player.global_position, Vector3.UP)
	print("Camera at: ", position, " looking at: ", player.global_position)
	
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var from = project_ray_origin(event.position)
		var to = from + project_ray_normal(event.position) * 1000

		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.new()
		query.from = from
		query.to = to
		query.collision_mask = 1  # Adjust if using different physics layers

		var result = space_state.intersect_ray(query)

		if result:
			var collider = result.collider

			# 🌳 Check if clicked object is a tree
			if collider.is_in_group("Trees"):
				print("Clicked on tree at:", collider.global_position)
				player.call("move_to", collider.global_position)
				player.call("start_cutting_tree", collider)
				return
				
		var plane := Plane(Vector3.UP, 0)  # y=0 plane
		var hit = plane.intersects_ray(from, to)
		if hit == null:
			print("No intersection with ground plane")
			return

		var grid_x = int(floor(hit.x / terrain.tile_size))
		var grid_y = int(floor(hit.z / terrain.tile_size))

		if grid_x >= 0 and grid_x < terrain.terrain_width and grid_y >= 0 and grid_y < terrain.terrain_height:
			var tile = terrain.tile_data[grid_x][grid_y]

			if tile.walkable:
				print("Move to:", tile.world_position)
					
				var center_offset = Vector3(terrain.tile_size * 0.5, 0, terrain.tile_size * 0.5)
				var indicator_pos = tile.world_position + center_offset

				if tile_indicator == null:
					tile_indicator = tile_indicator_scene.instantiate() as TileIndicator
					terrain.add_child(tile_indicator)

				tile_indicator.global_position = tile.world_position
				tile_indicator.set_tile_shape(tile.corners)

				player.call("move_to", tile.world_position)

			else:
				print("Tile not walkable:", grid_x, grid_y)
		else:
			print("Clicked outside terrain")
