extends RefCounted
const D=preload("res://scripts/creature_detail.gd")
static func build(e: Node3D) -> void:
	var boar: bool=e.species=="boar"
	var colors=["685345","856852","e6d9bd","372e2b","edc875","493e35"] if boar else ["80949d","b1bdbe","e6d9bd","35424b","edc875","62727b"]
	var v=D.batch(colors)
	D.body(v,Vector3(0,.82,-.5),1.0,[.52,.75,.78,.67,.51] if boar else [.44,.66,.59,.42,.49],[.65,.8,.76,.65,.55] if boar else [.58,.65,.55,.42,.5])
	for row in range(9):
		if boar: D.taper(v,"accent",Vector3(0,1.11,-.55+row*.13),Vector3(0,1.42-row*.025,-.48+row*.13),.08,.025,3)
		else:
			for side in [-1.0,1.0]: v.add("plate",Vector3(side*(.22+row%2*.03),1.02-row*.027,-.55+row*.085),Vector3(.12,.18,.14))
	D.taper(v,"hide",Vector3(0,.98,.57),Vector3(.09,.87,.92) if boar else Vector3(0,.52,1.25),.14 if boar else .22,.05,9)
	v.finish(e.rig)
	for side in [-1.0,1.0]:
		for z in [-.45,.45]:
			var leg=D.pivot(e.rig,Vector3(side*.27,.5,z)); e.legs.append(leg); v=D.batch(colors)
			D.taper(v,"hide",Vector3(0,.13,0),Vector3(0,-.27,.035 if z>0 else 0),.22,.12,5)
			v.add("dark",Vector3(0,-.41,-.06),Vector3(.19,.14,.25))
			for toe in [-1,1]: v.add("trim" if not boar else "accent",Vector3(toe*.05,-.43,-.18),Vector3(.05,.06,.09))
			v.finish(leg)
	e.bite_head=D.pivot(e.rig,Vector3(0,1,-.82)); v=D.batch(colors)
	D.body(v,Vector3(0,.06,-.17),.35,[.38,.54,.43],[.36,.46,.38])
	D.taper(v,"hide",Vector3(0,-.08,-.17),Vector3(0,-.14,-.55),.26,.20 if boar else .12,6)
	v.add("dark",Vector3(0,-.13,-.58),Vector3(.27 if boar else .2,.15,.07))
	for side in [-1.0,1.0]:
		v.add("dark",Vector3(side*.245,.105,-.15),Vector3(.045,.12,.16))
		v.add("eye",Vector3(side*.269,.12,-.17),Vector3(.02,.043,.075))
		D.taper(v,"plate",Vector3(side*.18,.2,.07),Vector3(side*(.35 if boar else .21),.4 if boar else .52,.02),.16,.025,5)
		if boar:
			D.taper(v,"trim",Vector3(side*.19,-.17,-.46),Vector3(side*.29,-.10,-.58),.11,.075,4)
			D.taper(v,"trim",Vector3(side*.29,-.10,-.58),Vector3(side*.30,.18,-.62),.075,.015,6)
	v.finish(e.bite_head)
	e.bite_jaw=D.pivot(e.bite_head,Vector3(0,-.23,-.12)); v=D.batch(colors)
	v.add("hide",Vector3(0,0,-.23),Vector3(.28,.10,.43))
	for side in [-1.0,1.0]:
		for tooth in range(3): v.add("trim",Vector3(side*.10,.07,-.16-tooth*.1),Vector3(.04,.08,.045))
	v.finish(e.bite_jaw)
