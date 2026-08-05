class_name Pathfinder
extends RefCounted

static func world_to_tile(position: Vector3) -> Vector3i:
	return Vector3i(floori(position.x), 0, floori(position.z))

static func tile_to_world(tile: Vector3i, height: float = 0.0) -> Vector3:
	return Vector3(tile.x + 0.5, height, tile.z + 0.5)
