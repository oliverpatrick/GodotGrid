class_name TerrainHeight
extends RefCounted

const HEIGHT_SCALE := 0.18

static func sample(bundle, x: float, z: float, plane: int = 0) -> float:
	if bundle == null or plane != 0 or x < 0.0 or z < 0.0:
		return 0.0
	var region_x := int(floor(x / 64.0))
	var region_z := int(floor(z / 64.0))
	var key := "%d:%d:%d" % [region_x, region_z, plane]
	if not bundle.regions.has(key):
		return 0.0
	var region: Dictionary = bundle.regions[key]
	var local_x := clampf(x - region_x * 64.0, 0.0, 64.0)
	var local_z := clampf(z - region_z * 64.0, 0.0, 64.0)
	var x0 := int(floor(local_x))
	var z0 := int(floor(local_z))
	var x1 := mini(x0 + 1, 64)
	var z1 := mini(z0 + 1, 64)
	var fx := local_x - x0
	var fz := local_z - z0
	var north := lerpf(float(region.heights[z0][x0]), float(region.heights[z0][x1]), fx)
	var south := lerpf(float(region.heights[z1][x0]), float(region.heights[z1][x1]), fx)
	return lerpf(north, south, fz) * HEIGHT_SCALE
