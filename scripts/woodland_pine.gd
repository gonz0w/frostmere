extends RefCounted
## Bounded, deterministic branch clusters in the existing voxel material batches.
static func pieces(height: float, seed_value: int) -> Array[Dictionary]:
	var rng:=RandomNumberGenerator.new(); rng.seed=seed_value
	var out: Array[Dictionary]=[]
	var rotation: float=rng.randf_range(0,TAU)
	for tier in range(12):
		var u:=float(tier)/12
		var y: float=height*(.27+u*.7)
		var radius: float=height*.28*pow(1-u,.9)
		out.append({"key":"pine","at":Vector3(0,y,0),"size":Vector3(.5,.38,.5)})
		for branch in range(6):
			var angle: float=rotation+branch*TAU/6+tier*.47+rng.randf_range(-.12,.12)
			var direction:=Vector3(cos(angle),0,sin(angle))
			var sideways:=Vector3(-sin(angle),0,cos(angle))
			var reach: float=radius*rng.randf_range(.76,1.0)
			var steps:=maxi(1,ceili(reach/.34))
			for step in range(1,steps+1):
				var distance: float=reach*step/steps
				var point: Vector3=direction*distance+Vector3.UP*(y-distance*.16)
				var width: float=lerpf(.56,.27,float(step)/steps)
				out.append({"key":"pine_light" if (branch+tier)%5==0 else "pine","at":point,"size":Vector3(width,.28,width)})
				if step%2==0 and tier<9:
					out.append({"key":"pine","at":point+sideways*.23+Vector3.DOWN*.06,"size":Vector3(.35,.22,.35)})
				if tier in [0,3] and step<steps:
					out.append({"key":"timber","at":point+Vector3.DOWN*.17,"size":Vector3(.15,.12,.15)})
	for tip in range(5):
		out.append({"key":"pine_light","at":Vector3(0,height*(.9+tip*.0225),0),"size":Vector3(.24-tip*.025,.26,.24-tip*.025)})
	return out
static func build(camp: Node3D, site: Vector4) -> void:
	var at:=Vector3(site.x,site.y,site.z)
	var seed_value:=int(roundf(site.x*193+site.z*977))
	for piece in pieces(site.w,seed_value): camp.box(at+piece.at,piece.size,piece.key)
