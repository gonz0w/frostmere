extends RefCounted
const D=preload("res://scripts/creature_detail.gd")
static func build(e: Node3D, kind: String) -> void:
	var crab: bool=kind=="crab"; var solar: bool=kind=="solar"
	var colors=["47686d","78928d","c9bca2","293e45","f5d67d","a6b7a1"] if crab else ["776246","c3a568","e5d1a0","483e33","f9db83","977d4f"] if solar else ["394c67","637c84","c6d7c2","202d40","80f2a8","788b99"]
	var v=D.batch(colors)
	var y: float=1.4 if crab or solar else 1.8
	D.body(v,Vector3(0,y,-1.1),2.25 if crab else 2.8,[1.6,2.4,2.9,2.75,2.1,1.4] if crab else [1.4,2.1,2.5,2.35,1.9,1.25],[1.1,1.4,1.6,1.4,1.1,.7])
	for row in range(8):
		var z: float=-1.05+row*.35
		for side in [-1.0,1.0]:
			for tier in range(3):
				v.add("plate",Vector3(side*(.27+tier*.34),y+.85-tier*.16-absf(row-3)*.035,z),Vector3(.39,.19,.31))
			v.add("accent",Vector3(side*1.1,y+.28,z),Vector3(.22,.24,.3))
	if crab:
		# Hollow barnacle cups, in uneven clusters rather than a regular crown.
		for i in range(9):
			var at=Vector3(sin(i*2.4)*.8,2.24+sin(i)*.08,cos(i*1.8)*.7)
			v.add("dark",at,Vector3(.13,.17,.13))
			for side in [-1.0,1.0]:
				v.add("trim",at+Vector3(side*.095,.05,0),Vector3(.065,.18,.25))
				v.add("trim",at+Vector3(0,.05,side*.095),Vector3(.16,.18,.065))
	if not solar:
		var core_at=Vector3(0,1.4,-1.25) if crab else Vector3(0,2.45,-2.34)
		if not crab: D.body(v,Vector3(0,2.02,-2.15),.7,[1.1,1.65,1.8],[.75,1.1,.8])
		e.core=e.piece(e.rig,core_at,Vector3(1,.65,.2) if crab else Vector3(.8,.6,.16),Color("e2b884") if crab else Color("80f2a8"))
		if not crab:
			e.core.mesh.material.emission_enabled=true; e.core.mesh.material.emission=Color("80f2a8")
			e.charge=e.piece(e.rig,Vector3(0,1.9,-2.8),Vector3(.55,.55,.55),Color("ffbd74"))
			e.charge.mesh.material.emission_enabled=true; e.charge.mesh.material.emission=Color("ffbd74"); e.charge.hide()
	for side in [-1.0,1.0]:
		if crab:
			D.taper(v,"hide",Vector3(side*.7,y+.55,-1),Vector3(side*.79,y+1.12,-1.12),.17,.1,6)
			v.add("dark",Vector3(side*.79,y+1.13,-1.13),Vector3(.3,.22,.28))
			v.add("eye",Vector3(side*.79,y+1.16,-1.28),Vector3(.18,.09,.045))
		else:
			for eye in range(2 if solar else 3):
				var at=Vector3(side*(.56+eye*.19),y+.56-eye*.10,-1.36 if solar else -2.28)
				v.add("dark",at,Vector3(.22,.2,.16))
				v.add("eye",at+Vector3(0,.02,-.09),Vector3(.10,.06,.035))
				v.add("plate",at+Vector3(0,.13,0),Vector3(.25,.08,.22))
	v.finish(e.rig)
	for side in [-1.0,1.0]:
		if not solar:
			var plate=D.pivot(e.rig,Vector3(side*.4,1.4 if crab else 2.45,-1.45 if crab else -2.45)); e.plates.append(plate); v=D.batch(colors)
			for row in range(5):
				v.add("plate",Vector3(0,-.34+row*.17,-.02),Vector3(.77,.15,.24))
				v.add("trim",Vector3(side*.28,-.34+row*.17,-.15),Vector3(.07,.07,.035))
			v.finish(plate)
		var claw=D.pivot(e.rig,Vector3(side*(1.4 if crab else 1.1 if solar else .85),1.35 if crab else 1.3 if solar else 1.65,-.8 if crab else -1.8 if solar else -1.9))
		if crab: e.claws.append(claw)
		elif not solar: e.mandibles.append(claw)
		v=D.batch(colors)
		D.taper(v,"plate",Vector3.ZERO,Vector3(side*.26,0,-.7),.48 if crab else .32,.35,7)
		for finger in ([-1.0,1.0] if crab or solar else [0.0]):
			D.taper(v,"trim",Vector3(side*.26+finger*.22,0,-.67),Vector3(side*.26+finger*.28,0,-1.15),.23,.13,5)
			D.taper(v,"trim",Vector3(side*.26+finger*.28,0,-1.15),Vector3(side*.26+finger*.11,0,-1.45),.13,.025,5)
			for tooth in range(3): v.add("accent",Vector3(side*.26+finger*.14,0,-.85-tooth*.16),Vector3(.15,.1,.08))
		v.finish(claw)
		for i in range(3 if crab else 4):
			var at=Vector3(side*1.2,1.1,-.7+i*.7) if crab else Vector3(side*1.1,1.2 if solar else 1.9,-1+i*.65 if solar else -1.2+i*.85)
			var leg=D.pivot(e.rig,at); e.legs.append(leg); v=D.batch(colors)
			var reach: float=.92 if crab or solar else 1.25
			D.taper(v,"plate",Vector3.ZERO,Vector3(side*reach,-.18,0),.32,.24,7)
			v.add("dark",Vector3(side*reach,-.24,0),Vector3(.32,.32,.32))
			D.taper(v,"hide",Vector3(side*reach,-.32,0),Vector3(side*(reach+.18),-at.y+.12,.1),.23,.08,9)
			v.add("trim",Vector3(side*(reach+.18),-at.y+.08,-.07),Vector3(.16,.13,.32)); v.finish(leg)
	if solar:
		e.tail=D.pivot(e.rig,Vector3(0,1.75,1.1)); v=D.batch(colors)
		var points=[Vector3.ZERO,Vector3(0,.55,.2),Vector3(0,1.15,.1),Vector3(0,1.75,-.3),Vector3(0,2.15,-.85),Vector3(0,2.13,-1.5)]
		for i in range(points.size()-1):
			D.taper(v,"plate",points[i],points[i+1],.48-i*.04,.41-i*.04,5)
			v.add("dark",points[i],Vector3(.48-i*.04,.1,.48-i*.04))
		v.add("dark",Vector3(0,2.13,-1.53),Vector3(.55,.48,.45))
		v.add("eye",Vector3(0,2.13,-1.79),Vector3(.33,.3,.05))
		for side in [-1.0,1.0]: v.add("trim",Vector3(side*.27,2.13,-1.65),Vector3(.09,.55,.38))
		v.finish(e.tail)
