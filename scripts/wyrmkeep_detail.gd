extends RefCounted
## Worn winter lanes link existing doors and services without moving saved actors.
const LANES = [
	[Vector2(0,40),Vector2(0,30),Vector2(3,23),Vector2(1,15),Vector2(-1,6),Vector2(0,-2),Vector2(2,-14),Vector2(0,-23)],
	[Vector2(0,-2),Vector2(-12,-2),Vector2(-22,-6)],
	[Vector2(0,-2),Vector2(12,-3),Vector2(22,-6)],
	[Vector2(0,-21),Vector2(11,-23),Vector2(12,-38),Vector2(8,-46),Vector2(0,-50),Vector2(0,-70)],
	[Vector2(1,15),Vector2(-10,18),Vector2(-11,21),Vector2(-18,22),Vector2(-28,20),Vector2(-32,18.5)],
	[Vector2(1,15),Vector2(11,21),Vector2(18,21),Vector2(28,21),Vector2(32,18.5)],
	[Vector2(-10,18),Vector2(-11,9)],
	[Vector2(11,21),Vector2(11,9)],
	[Vector2(22,-4),Vector2(32,-4),Vector2(33,-10),Vector2(37,-32),Vector2(30,-43),Vector2(30,-51)],
	[Vector2(-22,-6),Vector2(-31,0),Vector2(-29,7)],
	[Vector2(22,-6),Vector2(31,0),Vector2(29,7)],
]
const WELL = Vector3(7,0,-12)
static func path_at(x: float, z: float) -> bool:
	var point := Vector2(x,z)
	# An irregular paved meeting place connects the halls and their approach lanes.
	if pow((x-1)/5.5,2)+pow((z+2)/4.5,2)<1: return true
	for lane in LANES:
		for i in range(lane.size()-1):
			if Geometry2D.get_closest_point_to_segment(point,lane[i],lane[i+1]).distance_to(point)<1.65: return true
	return false
func build(world: Node3D, origin: Vector3) -> void:
	var b = world.blocks
	# A covered, frozen well sits beside the main approach, not across it.
	for row in range(3):
		for i in range(16):
			var angle := TAU*(i+row*.5)/16
			b.add("stone" if i%3 else "stone_dark",origin+WELL+Vector3(cos(angle)*.9,.15+row*.25,sin(angle)*.9),Vector3(.34,.23,.34))
	b.add("window",origin+WELL+Vector3(0,.25,0),Vector3(1.2,.05,1.2))
	world._solid(origin+WELL+Vector3(0,.4,0),Vector3(2,.8,2))
	for side in [-1,1]:
		b.add("timber",origin+WELL+Vector3(side*1.1,1.4,0),Vector3(.2,2.8,.2))
		for step in range(6):
			b.add("roof",origin+WELL+Vector3(side*(.12+step*.23),3-step*.12,0),Vector3(.26,.14,2))
			b.add("snow",origin+WELL+Vector3(side*(.12+step*.23),3.1-step*.12,0),Vector3(.25,.08,2.05))
	b.add("timber",origin+WELL+Vector3(0,1.9,0),Vector3(.06,1.8,.06))
	# Different storage yards give the mirrored residences individual silhouettes.
	for at in [Vector3(-23,0,24),Vector3(23,0,12),Vector3(-29,0,-17)]:
		for row in range(3):
			for log in range(6-row):
				b.add("timber",origin+at+Vector3(log*.26+row*.13,.16+row*.25,0),Vector3(.23,.23,1.3))
		b.add("snow",origin+at+Vector3(.7,.84,0),Vector3(1.8,.12,1.4))
		world._solid(origin+at+Vector3(.7,.4,0),Vector3(1.8,.8,1.4))
	# Council approach markers and low snow banks frame, rather than wall off, the road.
	for at in [Vector3(-4,0,-20),Vector3(6,0,-21),Vector3(16,0,-30),Vector3(13,0,-44)]:
		b.add("stone_dark",origin+at+Vector3.UP*.3,Vector3(.65,.6,.65))
		b.add("snow",origin+at+Vector3.UP*.65,Vector3(.8,.12,.8))
		world._solid(origin+at+Vector3.UP*.3,Vector3(.65,.6,.65))
	for at in [Vector3(-10,0,-15),Vector3(13,0,28),Vector3(-27,0,27),Vector3(31,0,-24)]:
		for tier in range(3):
			b.add("snow",origin+at+Vector3(tier*.2,.1+tier*.14,0),Vector3(3-tier*.65,.2,1.9-tier*.35))
