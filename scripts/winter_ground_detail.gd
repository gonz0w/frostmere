extends RefCounted
const Pines=preload("res://scripts/winter_pines.gd")
const ROCKS=[Vector3(-34,0,35),Vector3(-33,0,-34),Vector3(36,0,33),Vector3(44,0,-29),Vector3(23,0,-72),Vector3(-25,0,-72)]
static func pieces() -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	for i in range(Pines.SITES.size()):
		var site: Vector4=Pines.SITES[i]
		var at:=Vector3(site.x,0,site.z)
		for tier in range(3):
			var size:=Vector3(2.8-tier*.7,.12,1.8-tier*.35)
			out.append({"key":"snow","at":at+Vector3(tier*.16,.01+tier*.1,(i%3-1)*.18),"size":size,"surface":"snow"})
	for i in range(ROCKS.size()):
		for j in range(3):
			var height: float=.65+(i%3)*.12-j*.14
			var at: Vector3=ROCKS[i]+Vector3(j*.48,height*.5-.06,(j%2)*.32)
			var size:=Vector3(.85-j*.1,height,.75)
			out.append({"key":"stone_dark" if j%2==0 else "stone","at":at,"size":size,"surface":"stone"})
			out.append({"key":"snow","at":at+Vector3(-.05,height*.5+.025,0),"size":Vector3(size.x*.8,.05,.62),"surface":"snow"})
	return out
static func build(world: Node3D, origin: Vector3) -> void:
	for part in pieces():
		world.blocks.add(part.key,origin+part.at,part.size)
		world._solid(origin+part.at,part.size,part.surface)
