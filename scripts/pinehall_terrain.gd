extends RefCounted
const HILLS = [Vector4(-36,-49,11,18),Vector4(35,-56,10,17),Vector4(-35,-8,10,15),Vector4(36,19,10,16)]
const HEIGHTS = [3.4,4.0,2.6,3.2]
static func height_at(x: float,z: float) -> float:
	var result:=0.0
	for i in range(HILLS.size()):
		var h: Vector4=HILLS[i]
		var radius:=pow((x-h.x)/h.z,2)+pow((z-h.y)/h.w,2)
		if radius<1: result=maxf(result,HEIGHTS[i]*pow(1-radius,2))
	return result
static func tree_sites() -> Array[Vector4]:
	var sites: Array[Vector4]=[]
	for side in [-1,1]:
		for i in range(19):
			var x: float=side*(28+(i%3)*4+sin(i*2.3+side)*1.4)
			var z: float=-77+i*6+sin(i*1.7)*1.8
			# The western building and its lane need space beyond their outer walls.
			if x<0 and z>17 and z<36 and x> -30: continue
			sites.append(Vector4(x,height_at(x,z),z,5.8+fmod(i*1.37+(side+1),3.3)))
	return sites
static func collision_vertices() -> PackedVector3Array:
	var vertices:=PackedVector3Array()
	for ix in range(-44,44):
		for iz in range(-83,47):
			var x: float=ix+.5; var z: float=iz+.5
			var a:=Vector3(x,height_at(x,z)-.1,z)
			var b:=Vector3(x+1,height_at(x+1,z)-.1,z)
			var c:=Vector3(x,height_at(x,z+1)-.1,z+1)
			var d:=Vector3(x+1,height_at(x+1,z+1)-.1,z+1)
			vertices.append_array(PackedVector3Array([a,b,c,b,d,c]))
	return vertices
