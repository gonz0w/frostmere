extends RefCounted
## Authored Copper Stag dressing, sharing static world batches and existing routes.
func build(world: Node3D) -> void:
	var b: RefCounted=world.blocks
	var o=Vector3(-10,0,-8)
	# Pegged and carved doorway posts outside the clear entrance.
	for side in [-1.0,1.0]:
		for row in range(12):
			var y: float=.55+row*.16
			b.add("wood",o+Vector3(side*1.05,y,4.78),Vector3(.17,.135,.055))
			b.add("gold" if row%4==0 else "timber",o+Vector3(side*(1.05+(.035 if row%2 else -.035)),y,4.815),Vector3(.047,.066,.018))
		b.add("iron",o+Vector3(side*1.05,.48,4.81),Vector3(.23,.08,.027))
		b.add("iron",o+Vector3(side*1.05,2.50,4.81),Vector3(.23,.08,.027))
	# Stag relief on a projecting porch plaque.
	b.add("timber",o+Vector3(0,3.19,6.23),Vector3(.91,.65,.08))
	b.add("wood",o+Vector3(0,3.14,6.30),Vector3(.20,.29,.065))
	for side in [-1.0,1.0]:
		for step in range(5):
			b.add("fur",o+Vector3(side*(.09+step*.065),3.25+step*.05,6.34),Vector3(.075,.064,.035))
			if step%2==0: b.add("fur",o+Vector3(side*(.09+step*.065),3.33+step*.05,6.34),Vector3(.032,.12,.035))
	# An uneven edge course and drain sit beside the approach, never over the ramp.
	for side in [-1.0,1.0]:
		for row in range(11):
			var z: float=5.1+row*.24
			b.add("stone_dark",o+Vector3(side*1.22,.025,z),Vector3(.17,.06,.23))
			b.add("stone",o+Vector3(side*(1.40+(row%3)*.018),.065,z),Vector3(.22,.10,.21))
			if row%4==0: b.add("grass_dark",o+Vector3(side*1.57,.07,z),Vector3(.12,.06,.10))
	# Display crate beside the porch, clear of its posts and the central route.
	crate(b,o+Vector3(-2.55,.15,5.25),Vector3(1.15,.72,.70))
	world._solid(o+Vector3(-2.55,.51,5.25),Vector3(1.15,.72,.70),"wood")
	for row in range(4):
		b.add("cloth" if row%2 else "leather",o+Vector3(-2.55,.91+row*.09,5.25),Vector3(.78-row*.07,.078,.48))
		b.add("fur",o+Vector3(-2.55,.94+row*.09,5.50),Vector3(.60-row*.07,.025,.025))
	# Counter apron and inset panels fit entirely inside the existing counter collider.
	for col in range(15):
		b.add("wood" if col%3 else "timber",o+Vector3(-1.86+col*.266,.76,-.65),Vector3(.248,.50,.06))
	for y in [.51,1.02]: b.add("timber",o+Vector3(0,y,-.607),Vector3(4.02,.07,.055))
	for x in [-1.78,0,1.78]:
		b.add("iron",o+Vector3(x,.76,-.57),Vector3(.034,.43,.014))
		for y in [.58,.94]: b.add("gold",o+Vector3(x,y,-.581),Vector3(.023,.023,.009))
	# Ledger, open pages, inkwell and weighing balance atop the existing table.
	b.add("leather",o+Vector3(.73,1.163,-.90),Vector3(.50,.035,.33))
	for side in [-1.0,1.0]:
		b.add("fur",o+Vector3(.73+side*.12,1.187,-.90),Vector3(.225,.015,.29))
		for row in range(5): b.add("timber",o+Vector3(.73+side*.12,1.197,-1.00+row*.04),Vector3(.17,.004,.008))
	b.add("coal",o+Vector3(1.15,1.19,-.92),Vector3(.10,.10,.10))
	b.add("gold",o+Vector3(-1.5,1.17,-1.25),Vector3(.35,.045,.26))
	b.add("iron",o+Vector3(-1.5,1.43,-1.25),Vector3(.035,.50,.035))
	b.add("gold",o+Vector3(-1.5,1.67,-1.25),Vector3(.55,.03,.035))
	for side in [-1.0,1.0]:
		b.add("iron",o+Vector3(-1.5+side*.23,1.53,-1.25),Vector3(.008,.25,.008))
		b.add("gold",o+Vector3(-1.5+side*.23,1.40,-1.25),Vector3(.22,.027,.20))
	# Rear display stays behind the merchant, against the wall.
	for x in [-1.45,1.45]: b.add("timber",o+Vector3(x,1.57,-4.20),Vector3(.13,2.4,.13))
	for y in [.53,1.52,2.73]: b.add("wood",o+Vector3(0,y,-4.18),Vector3(3.02,.12,.16))
	for col in range(9): b.add("wood" if col%2 else "timber",o+Vector3(-1.28+col*.32,1.64,-4.32),Vector3(.30,2.25,.07))
	var state=preload("res://scripts/character_state.gd").new(); state.persist=false
	for i in range(3):
		var mount=Node3D.new(); world.add_child(mount)
		mount.position=o+Vector3(-.96+i*.96,1.53,-4.00)
		mount.rotation.x=PI/2 if i!=1 else 0.0
		mount.rotation.y=PI
		mount.scale=Vector3.ONE*.80
		preload("res://scripts/character_visual.gd").make_weapon(mount,state.describe_item(state.add_item(["iron_sword","iron_shield","steel_sword"][i])))
	# A work mat and leather offcuts on the side shelving add an outfitter identity.
	for row in range(4):
		b.add("leather",o+Vector3(-3.4,1.36+row*.045,-1.7),Vector3(.46,.035,.43-row*.04))
	b.add("iron",o+Vector3(-3.4,1.57,-1.7),Vector3(.035,.025,.30))

func crate(b: RefCounted, at: Vector3, size: Vector3) -> void:
	for side in [-1.0,1.0]:
		for row in range(5):
			b.add("wood",at+Vector3(0,size.y*(row+.5)/5,side*size.z/2),Vector3(size.x,size.y/5-.014,.06))
			b.add("wood",at+Vector3(side*size.x/2,size.y*(row+.5)/5,0),Vector3(.06,size.y/5-.014,size.z))
		for x in [-size.x*.35,size.x*.35]:
			b.add("iron",at+Vector3(x,size.y/2,side*(size.z/2+.036)),Vector3(.055,size.y,.018))
			for y in [.08,size.y-.08]: b.add("gold",at+Vector3(x,y,side*(size.z/2+.049)),Vector3(.022,.022,.010))
	for col in range(6): b.add("wood",at+Vector3((col-2.5)*size.x/6,size.y,0),Vector3(size.x/6-.01,.055,size.z))
