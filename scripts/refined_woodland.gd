extends RefCounted
const D=preload("res://scripts/creature_detail.gd")
const BARK=["514333","79644a","b39c73","302e29","ccda71","69734c"]
const SPIRIT=["b3cec2","d5e0c5","e9eccf","688c82","efffc5","8eb6a6"]
static func build(e: Node3D) -> void:
	var v=D.batch(BARK)
	D.body(v,Vector3(0,1.95,-1.25),2.7,[1.4,2.1,2.3,1.9,1.65,1.7],[1.4,1.8,1.9,1.55,1.4,1.3])
	for side in [-1.0,1.0]:
		for row in range(9):
			D.taper(v,"plate",Vector3(side*.5,2.85,-1.25+row*.34),Vector3(side*(1.02-row*.025),1.4,-1.10+row*.34),.18,.10,8)
			v.add("accent",Vector3(side*.6,2.84-row*.035,-1.1+row*.31),Vector3(.49,.19,.38))
			if row%3==0: v.add("eye",Vector3(side*.77,2.78-row*.035,-1.1+row*.31),Vector3(.12,.08,.11))
	D.taper(v,"hide",Vector3(0,2.3,-1.25),Vector3(0,3.27,-1.5),.8,.62,8)
	D.body(v,Vector3(0,3.23,-2.15),.8,[.45,.8,.75],[.46,.67,.65])
	v.add("dark",Vector3(0,3.18,-2.4),Vector3(.43,.21,.1))
	for side in [-1.0,1.0]:
		v.add("dark",Vector3(side*.39,3.36,-1.96),Vector3(.06,.26,.38))
		v.add("eye",Vector3(side*.43,3.38,-2.01),Vector3(.035,.08,.20))
		D.antler(v,Vector3(side*.37,3.60,-1.38),side,1.15)
		D.taper(v,"plate",Vector3(side*.32,3.5,-1.46),Vector3(side*.8,3.62,-1.2),.25,.07,5)
	v.finish(e.rig)
	for side in [-1.0,1.0]:
		for z in [-.95,1.0]:
			var leg=D.pivot(e.rig,Vector3(side*.9,1.45,z)); e.legs.append(leg); v=D.batch(BARK)
			D.taper(v,"hide",Vector3(0,.05,0),Vector3(side*.03,-1.1,.1),.44,.24,9)
			for toe in range(3): D.taper(v,"plate",Vector3(side*.03,-1.13,0),Vector3((toe-1)*.24,-1.33,-.54),.19,.07,5)
			for line in [-1.0,1.0]: D.taper(v,"trim",Vector3(line*.15,0,-.2),Vector3(line*.07,-.94,-.12),.04,.02,7)
			v.finish(leg)
static func stag(parent: Node3D) -> void:
	var v=D.batch(SPIRIT)
	D.body(v,Vector3(0,1.05,-.52),1.05,[.42,.68,.59,.46,.54],[.59,.74,.62,.48,.52])
	D.taper(v,"plate",Vector3(0,1.2,-.55),Vector3(0,1.99,-.78),.37,.25,9)
	D.taper(v,"hide",Vector3(0,2,-.72),Vector3(0,1.9,-1.2),.36,.2,6)
	v.add("dark",Vector3(0,1.89,-1.25),Vector3(.21,.1,.08))
	for side in [-1.0,1.0]:
		v.add("eye",Vector3(side*.18,2.05,-.94),Vector3(.03,.06,.08))
		D.antler(v,Vector3(side*.17,2.16,-.71),side,.66)
		D.taper(v,"plate",Vector3(side*.15,2.13,-.75),Vector3(side*.43,2.24,-.59),.13,.03,5)
		for z in [-.42,.43]:
			D.taper(v,"hide",Vector3(side*.25,.88,z),Vector3(side*.26,.15,z+.05),.16,.085,9)
			v.add("dark",Vector3(side*.26,.09,z),Vector3(.13,.13,.20))
		for rib in range(5): D.taper(v,"plate",Vector3(side*.24,1.34,-.30+rib*.15),Vector3(side*.3,.91,-.22+rib*.15),.045,.028,5)
	D.taper(v,"plate",Vector3(0,1.27,.53),Vector3(0,1.13,.82),.18,.03,5)
	v.finish(parent)
	for mesh in parent.find_children("*","GeometryInstance3D",true,false): mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
