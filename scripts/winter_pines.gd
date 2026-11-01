extends RefCounted
const Pine=preload("res://scripts/woodland_pine.gd")
# Sparse groups between the settlement lanes and enclosing ridges.
const SITES=[Vector4(-38,0,43,6.4),Vector4(-43,0,48,5.8),Vector4(-38,0,27,7.0),
	Vector4(-38,0,1,6.1),Vector4(-38,0,-25,7.2),Vector4(-37,0,-43,6.5),
	Vector4(-35,0,-66,5.9),Vector4(39,0,43,6.6),Vector4(43,0,48,5.8),
	Vector4(40,0,27,7.1),Vector4(40,0,10,6.2),Vector4(40,0,-12,6.7),Vector4(40,0,-73,6.1)]
static func pieces(site: Vector4) -> Array[Dictionary]:
	var out: Array[Dictionary]=Pine.pieces(site.w,int(roundf(site.x*193+site.z*977)))
	var caps: Array[Dictionary]=[]
	for i in range(out.size()):
		var part: Dictionary=out[i]
		if part.key!="timber" and i%3==0:
			caps.append({"key":"snow","at":part.at+Vector3.UP*(part.size.y*.5+.025),"size":Vector3(part.size.x*.9,.05,part.size.z*.85)})
	out.append_array(caps)
	return out
static func build(world: Node3D, origin: Vector3) -> void:
	for site in SITES:
		var at:=origin+Vector3(site.x,site.y,site.z)
		world.blocks.add("timber",at+Vector3.UP*site.w*.45,Vector3(.42,site.w*.9,.42))
		world._solid(at+Vector3.UP*site.w*.45,Vector3(.42,site.w*.9,.42),"wood")
		for part in pieces(site): world.blocks.add(part.key,at+part.at,part.size)
