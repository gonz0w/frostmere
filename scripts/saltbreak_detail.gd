extends RefCounted
## Working waterfront scenery; no new shop or quest transactions.
func build(coast: Node3D) -> void:
	var origin: Vector3=coast.ORIGIN
	# Continue the existing pier onto land, with a shallow supported approach.
	for i in range(13):
		coast.box(Vector3(-4.35+i*.65,.05,26),Vector3(.62,.22,3.4),"wood",true,"wood")
	for i in range(3):
		coast.box(Vector3(3.9+i*.3,.025-i*.035,26),Vector3(.32,.16,3.4),"wood",true,"wood")
	# Low side ropes leave the entire center lane and net interaction open.
	for x in [-7.0,-13.0,-19.0,-24.0]:
		for z in [24.5,27.5]:
			coast.box(Vector3(x,.55,z),Vector3(.24,1.15,.24),"timber",true)
			coast.box(Vector3(x,.95,z),Vector3(.4,.13,.4),"iron")
		for side in [-1,1]:
			for ring in range(2):
				for part in range(12):
					var angle:=TAU*part/12
					coast.box(Vector3(x+cos(angle)*(.28+ring*.12),.2,26+side*1.05+sin(angle)*(.28+ring*.12)),Vector3(.13,.07,.13),"cloth")
	for span in [[-7.0,-13.0],[-13.0,-19.0],[-19.0,-24.0]]:
		for side in [-1,1]:
			for i in range(20):
				var t:=float(i)/19
				coast.box(Vector3(lerpf(span[0],span[1],t),.8-sin(t*PI)*.19,26+side*1.5),Vector3(.34,.06,.06),"cloth")
	# A covered sorting table is offset south of the shoreward boardwalk.
	var stall:=Vector3(-1,0,32)
	coast.box(stall+Vector3(0,.7,0),Vector3(3.6,.18,1.3),"wood")
	coast.world._solid(origin+stall+Vector3.UP*.4,Vector3(3.6,.8,1.3))
	for x in [-1.8,1.8]:
		for z in [-.9,.9]: coast.box(stall+Vector3(x,1.35,z),Vector3(.16,2.7,.16),"timber",true)
	for i in range(16):
		coast.box(stall+Vector3(-2+i*.26,2.7-absf(i-7.5)*.025,0),Vector3(.25,.09,2.4),"cloth" if i%4 else "roof")
	for i in range(9):
		coast.box(stall+Vector3(-1.4+i*.34,.86,.15*sin(i)),Vector3(.12,.12,.46),"iron")
	for at in [Vector3(-4,0,33),Vector3(2.5,0,34)]:
		coast.box(at+Vector3.UP*.35,Vector3(.9,.7,.85),"wood",true)
		for y in [.17,.53]: coast.box(at+Vector3.UP*y,Vector3(.96,.06,.91),"iron")
	# Lanterns mark the landward turn without narrowing the pier.
	coast.world._lantern(origin+Vector3(5.5,0,29),false)
	coast.world._lantern(origin+Vector3(-4,0,29.5),false)
