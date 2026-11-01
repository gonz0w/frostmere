extends RefCounted
const LANES = [
	[Vector2(0,40),Vector2(0,30),Vector2(-2,24),Vector2(0,18),Vector2(1,12),Vector2(-1,2),Vector2(0,-12),Vector2(0,-27)],
	[Vector2(0,14),Vector2(-6,13),Vector2(-14,13)],
	[Vector2(0,14),Vector2(6,13),Vector2(14,13)],
	[Vector2(0,30),Vector2(-10,34),Vector2(-23,33.5)],
	[Vector2(1,26),Vector2(5,28),Vector2(8,28)],
]
static func path_at(x: float,z: float) -> bool:
	if z < -22 and absf(x)<3: return true
	var point:=Vector2(x,z)
	for lane in LANES:
		for i in range(lane.size()-1):
			if Geometry2D.get_closest_point_to_segment(point,lane[i],lane[i+1]).distance_to(point)<1.5: return true
	return false
static func surface_at(x: float,z: float) -> String:
	if absf(x)<=10.5 and z>=-72 and z<=-28: return "stone"
	return "stone" if path_at(roundf(x),roundf(z)) else "grass"
func build(camp: Node3D) -> void:
	# A sheltered communal reading table, clear of Iven's return location.
	var at:=Vector3(9,0,25)
	camp.box(at+Vector3.UP*.85,Vector3(3.4,.18,1.4),"wood")
	camp.world._solid(camp.ORIGIN+at+Vector3.UP*.45,Vector3(3.4,.9,1.4))
	for x in [-1.8,1.8]:
		for z in [-1,1]: camp.box(at+Vector3(x,1.4,z),Vector3(.16,2.8,.16),"timber",true)
	for i in range(16): camp.box(at+Vector3(-2+i*.26,2.85-absf(i-7.5)*.04,0),Vector3(.25,.1,2.6),"roof" if i%3 else "wood")
	for i in range(5):
		camp.box(at+Vector3(-1.1+i*.52,.99,.1),Vector3(.38,.1,.55),"leather" if i%2 else "cloth")
		camp.box(at+Vector3(-1.1+i*.52,1.05,.1),Vector3(.32,.025,.5),"stone")
	# Tended herbs and stored fuel make the faction halls feel inhabited.
	for garden in [Vector3(-20,0,-5),Vector3(20,0,-5)]:
		camp.box(garden+Vector3.UP*.15,Vector3(3.2,.3,2),"timber")
		camp.box(garden+Vector3.UP*.31,Vector3(2.9,.08,1.7),"earth")
		camp.world._solid(camp.ORIGIN+garden+Vector3.UP*.15,Vector3(3.2,.3,2))
		for row in range(3):
			for i in range(7):
				camp.box(garden+Vector3(-1.2+i*.4,.5+(i%2)*.07,-.6+row*.6),Vector3(.22,.3,.22),"pine_light")
	for stack in [Vector3(-21,0,0),Vector3(20,0,5),Vector3(-18,0,29)]:
		for row in range(3):
			for i in range(5-row): camp.box(stack+Vector3(i*.25+row*.12,.14+row*.24,0),Vector3(.22,.22,1),"timber")
		camp.world._solid(camp.ORIGIN+stack+Vector3(.5,.36,0),Vector3(1.3,.72,1))
	camp.world._lantern(camp.ORIGIN+Vector3(12,0,28),false)
