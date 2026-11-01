extends RefCounted
const HILLS = [Vector4(-28,-42,8,12),Vector4(33,-52,8,12),Vector4(-25,-63,8,8)]
const HEIGHTS = [3.2,2.8,2.4]
static func height_at(x: float, z: float) -> float:
	var result := 0.0
	for i in range(HILLS.size()):
		var hill: Vector4 = HILLS[i]
		var radius := pow((x-hill.x)/hill.z,2) + pow((z-hill.y)/hill.w,2)
		if radius < 1: result = maxf(result, HEIGHTS[i] * pow(1-radius,2))
	return result
static func path_at(x: float, z: float) -> bool:
	if height_at(x,z) < 0.04: return false
	for hill: Vector4 in HILLS:
		if absf(z-hill.y) < hill.w and absf(x-hill.x-sin((z-hill.y)*0.25)*1.8)<1.3: return true
	return false
static func collision_vertices() -> PackedVector3Array:
	var vertices := PackedVector3Array()
	for x in range(-36,42):
		for z in range(-72,-29):
			var a := Vector3(x,height_at(x,z)-0.1,z)
			var b := Vector3(x+1,height_at(x+1,z)-0.1,z)
			var c := Vector3(x,height_at(x,z+1)-0.1,z+1)
			var d := Vector3(x+1,height_at(x+1,z+1)-0.1,z+1)
			if maxf(maxf(a.y,b.y),maxf(c.y,d.y)) <= -0.1: continue
			vertices.append_array(PackedVector3Array([a,b,c,b,d,c]))
	return vertices
