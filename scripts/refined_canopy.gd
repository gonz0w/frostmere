extends RefCounted
## Broadleaf crowns built around forks, with broken edges and visible sky gaps.
static func build(b: RefCounted,at: Vector3,height: float,radius: float,leaf: String,moss: String) -> void:
	for arm in range(7):
		var angle: float=arm*TAU/7+.24
		var axis=Vector3(cos(angle),0,sin(angle))
		for step in range(4):
			var d: float=radius*(step+1)/4
			var p: Vector3=at+axis*d+Vector3.UP*(height*.69+step*.42+sin(arm*1.8)*.3)
			b.add("wood",p,Vector3(radius/3,.26-step*.035,.28-step*.04),-angle)
			if step<1: continue
			for tier in range(3):
				var w: float=(2.3-tier*.55)*(1+sin(arm*1.7+step)*.12)
				b.add(leaf if (arm+step+tier)%4 else moss,p+Vector3(sin(arm+tier)*.2,.35+tier*.42,cos(step+tier)*.2),Vector3(w,.48,w*.85),angle*.5)
				b.add(leaf,p+Vector3(cos(angle+1)*w*.55,.32+tier*.38,sin(angle+1)*w*.55),Vector3(.65,.34,.6),angle)
	b.add(leaf,at+Vector3(0,height*.9,0),Vector3(1.9,.8,1.7))
