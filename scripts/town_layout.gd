extends RefCounted
const HOMES = [Vector3(-17,0,-30),Vector3(-18,0,18),Vector3(5,0,20)]
const LANES = [
	[Vector2(-10,-2),Vector2(-8,0),Vector2(-4,1),Vector2(0,2)],
	[Vector2(-17,-24),Vector2(-15,-21),Vector2(-9,-19),Vector2(-4,-18),Vector2(0,-18)],
	[Vector2(-18,23),Vector2(-14,25),Vector2(-8,24),Vector2(-3,20),Vector2(0,17)],
	[Vector2(5,24),Vector2(2,26),Vector2(-3,24),Vector2(-3,20)],
	[Vector2(6,11),Vector2(4,13),Vector2(1,14)],
	[Vector2(-10,8),Vector2(-7,10),Vector2(-3,8),Vector2(0,5)]
]
static func path_at(x: float, z: float) -> bool:
	var point := Vector2(x,z)
	if z>-43 and z<24 and absf(x-sin(z*.13)*1.1)<2: return true
	if pow((x+3)/4.5,2)+pow((z-3)/4.0,2)<1: return true
	for lane in LANES:
		for i in range(lane.size()-1):
			if Geometry2D.get_closest_point_to_segment(point,lane[i],lane[i+1]).distance_to(point)<1.2: return true
	return false
static func clearing(x: float, z: float) -> bool:
	if path_at(x,z) or path_at(x-2,z) or path_at(x+2,z): return true
	for home: Vector3 in HOMES:
		if absf(x-home.x)<6 and absf(z-home.z)<7: return true
	return false
func build(world: Node3D) -> void:
	var b = world.blocks
	# A round well anchors an irregular green, away from the walking lanes.
	var well := Vector3(-3,0,3)
	for row in range(3):
		for i in range(14):
			var angle := TAU*(i+row*.5)/14
			b.add("stone" if i%3 else "stone_dark",well+Vector3(cos(angle)*.85,.15+row*.25,sin(angle)*.85),Vector3(.35,.23,.35))
	b.add("water",well+Vector3(0,.3,0),Vector3(1.1,.05,1.1)) if b.materials.has("water") else b.add("coal",well+Vector3(0,.3,0),Vector3(1.1,.05,1.1))
	world._solid(well+Vector3(0,.4,0),Vector3(1.8,.8,1.8))
	for side in [-1,1]: b.add("timber",well+Vector3(side*.95,1.3,0),Vector3(.16,2.6,.16))
	b.add("wood",well+Vector3(0,2.5,0),Vector3(2.2,.18,.25))
	b.add("timber",well+Vector3(0,1.6,0),Vector3(.06,1.6,.06))
	# Market awnings, crates and produce make the widening west of the green useful-looking.
	for origin in [Vector3(-10,0,6),Vector3(-12,0,11)]:
		b.add("wood",origin+Vector3(0,.85,0),Vector3(2.8,.18,1.2))
		world._solid(origin+Vector3(0,.5,0),Vector3(2.8,1,1.2))
		for side in [-1,1]:
			b.add("timber",origin+Vector3(side*1.3,1.3,-.45),Vector3(.13,2.6,.13))
		for strip in range(12):
			b.add("cloth" if strip%2 else "roof",origin+Vector3(-1.5+strip*.27,2.5,.1),Vector3(.26,.1,1.8))
		for i in range(7): b.add("pine_light" if i%2 else "gold",origin+Vector3(-1.1+i*.35,1.05,0),Vector3(.24,.24,.24))
	# Gardens and stacked firewood sit behind the homes, with the front approach open.
	for origin: Vector3 in HOMES:
		for row in range(3):
			for i in range(8):
				b.add("earth",origin+Vector3(-2+i*.5,.05,-6-row*.4),Vector3(.45,.12,.35))
				b.add("pine_light",origin+Vector3(-2+i*.5,.2,-6-row*.4),Vector3(.2,.22,.2))
		for i in range(8): b.add("timber",origin+Vector3(4.1,.15+(i/4)*.24,-1+(i%4)*.24),Vector3(.8,.2,.2))
	for origin in [Vector3(-7,0,3),Vector3(8,0,12),Vector3(-13,0,22)]:
		b.add("wood",origin+Vector3(0,.5,0),Vector3(1.6,.15,.5))
		for side in [-1,1]: b.add("timber",origin+Vector3(side*.55,.2,0),Vector3(.16,.45,.4))
		world._solid(origin+Vector3(0,.3,0),Vector3(1.6,.6,.5))
