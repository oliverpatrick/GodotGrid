class_name RegionKey
extends RefCounted

var x: int
var z: int
var plane: int

func _init(region_x: int, region_z: int, region_plane: int = 0):
	x = region_x
	z = region_z
	plane = region_plane

func encoded() -> String:
	return "%d:%d:%d" % [x, z, plane]
