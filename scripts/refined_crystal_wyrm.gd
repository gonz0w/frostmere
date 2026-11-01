extends RefCounted
const Blocks=preload("res://scripts/blocks.gd")
static var materials: Dictionary={}
static func batch() -> RefCounted:
	if materials.is_empty():
		var palette={"scale":"7fa4d4","pale":"b7d1ed","dark":"42557e","violet":"d7b5f1","crystal":"a8e6f4","eye":"ffe88b"}
		for key in palette:
			var m=StandardMaterial3D.new(); m.albedo_color=Color(palette[key]); m.roughness=.35 if key in ["violet","crystal"] else .82
			if key=="eye": m.emission_enabled=true; m.emission=m.albedo_color; m.emission_energy_multiplier=.6
			materials[key]=m
	var v=Blocks.new(); v.materials=materials; v.spatial_batching=false
	return v
static func build(beast: Node3D) -> void:
	var v=batch()
	for row in range(9):
		var width: float=[1.1,1.55,1.8,1.7,1.48,1.28,1.2,1.02,.75][row]
		for tier in range(5):
			v.add("scale",Vector3(0,1.45+(tier-2)*.27,-1.2+row*.32),Vector3(width*(1-absf(tier-2)*.14),.29,.35))
		v.add("pale",Vector3(0,.86,-1.2+row*.32),Vector3(width*.65,.16,.29))
		for side in [-1.0,1.0]:
			for tier in range(3):
				v.add("pale",Vector3(side*(width*.43-tier*.025),1.9-tier*.31,-1.2+row*.32),Vector3(.14,.24,.27))
		for tier in range(3):
			v.add("violet",Vector3(0,2.12+tier*.12,-1.2+row*.32+tier*.04),Vector3(.23-tier*.065,.14,.21-tier*.045))
	for side in [-1.0,1.0]:
		for z in [-.8,.9]:
			for tier in range(5):
				v.add("scale",Vector3(side*(.64+tier*.025),.86-tier*.15,z+tier*.035),Vector3(.48-tier*.045,.18,.53-tier*.04))
			v.add("pale",Vector3(side*.75,.13,z-.13),Vector3(.42,.21,.56))
			for toe in range(3): v.add("violet",Vector3(side*.75+(toe-1)*.14,.1,z-.43),Vector3(.09,.1,.22))
	for row in range(12):
		var width: float=.64-row*.047
		v.add("scale",Vector3(sin(row*.23)*.2,1.22-row*.071,1.48+row*.22),Vector3(width,.4-row*.022,.29))
		v.add("pale",Vector3(sin(row*.23)*.2,1.42-row*.08,1.48+row*.22),Vector3(width*.65,.07,.25))
	v.finish(beast.rig)
	beast.head=Node3D.new(); beast.head.position=Vector3(0,2,-1.6); beast.rig.add_child(beast.head)
	v=batch()
	for tier in range(5):
		v.add("pale",Vector3(0,-.25+tier*.25,0),Vector3(.94-absf(tier-2)*.09,.28,.8-absf(tier-2)*.06))
	for row in range(5):
		v.add("scale",Vector3(0,.29-row*.025,-.35-row*.18),Vector3(.87-row*.065,.42-row*.025,.23))
	v.add("dark",Vector3(0,.28,-1.16),Vector3(.48,.16,.045))
	for side in [-1.0,1.0]:
		v.add("dark",Vector3(side*.43,.57,-.41),Vector3(.06,.23,.36))
		v.add("eye",Vector3(side*.47,.59,-.46),Vector3(.045,.085,.20))
		v.add("violet",Vector3(side*.43,.75,-.36),Vector3(.18,.13,.46))
		for row in range(7):
			v.add("violet",Vector3(side*(.34+row*.035),.84+row*.13,.12+row*.07),Vector3(.23-row*.027,.16,.24-row*.026))
		for row in range(4):
			v.add("pale",Vector3(side*(.42+row*.08),.24-row*.11,.17+row*.07),Vector3(.22-row*.03,.15,.42))
	v.finish(beast.head)
	beast.jaw=Node3D.new(); beast.jaw.position=Vector3(0,-.05,-.3); beast.head.add_child(beast.jaw)
	v=batch()
	for row in range(5): v.add("pale",Vector3(0,-row*.015,-.1-row*.17),Vector3(.8-row*.045,.17,.22))
	for side in [-1.0,1.0]:
		for row in range(4): v.add("violet",Vector3(side*(.32-row*.02),.15,-.16-row*.18),Vector3(.075,.22,.085))
	v.finish(beast.jaw)
	# Preserve the ten individually animated/fractured wing shards and their order.
	for side in [-1.0,1.0]:
		var wing=Node3D.new(); wing.position=Vector3(side*.8,2,0); beast.rig.add_child(wing); beast.wings.append(wing)
		for i in range(5):
			var shard=Node3D.new(); shard.position=Vector3(side*(.4+i*.55),i*.24,.3+i*.13); wing.add_child(shard); beast.shards.append(shard)
			v=batch()
			var length: float=2.4-i*.3
			for row in range(9):
				var taper: float=sin((row+1)/10.0*PI)
				var z: float=-length*.5+row*length/8
				v.add("violet" if i%2 else "crystal",Vector3(0,0,z),Vector3(.48*taper,.15+.10*taper,length/8+.02))
				v.add("pale",Vector3(side*.12*taper,.13,z),Vector3(.07*taper,.04,length/8+.015))
			v.add("dark",Vector3(0,-.02,0),Vector3(.055,.27,length*.8))
			v.finish(shard)
