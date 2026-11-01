extends RefCounted
const D=preload("res://scripts/creature_detail.gd")
const COLORS=["40323f","716075","c6ae9a","211e2d","ff945b","9c7778"]
static func build(e: Node3D) -> void:
	var v=D.batch(COLORS)
	# A deep resonant chest and long tapered abdomen distinguish it from the Maw.
	D.body(v,Vector3(0,1.9,-1.3),3.2,[1.1,1.9,2.35,2.1,1.65,1.1,.55],[1.6,2.1,2.2,1.75,1.4,1,.6])
	for side in [-1.0,1.0]:
		for row in range(7): D.taper(v,"plate",Vector3(side*.45,2.87,-.9+row*.4),Vector3(side*(1.1-row*.08),1.55,-.8+row*.4),.17,.08,7)
		D.taper(v,"trim",Vector3(side*.38,3.07,-1.34),Vector3(side*.89,3.73,-1.05),.21,.035,9)
		v.add("dark",Vector3(side*.42,2.75,-1.88),Vector3(.39,.32,.11))
		v.add("eye",Vector3(side*.42,2.75,-1.95),Vector3(.16,.08,.035))
	# Fluted mask frames the throat instead of an armored furnace shutter.
	for side in [-1.0,1.0]:
		for tier in range(6): v.add("plate",Vector3(side*(.57-absf(tier-2)*.055),1.65+tier*.19,-1.87),Vector3(.22,.22,.42))
	v.finish(e.rig)
	var throat=D.pivot(e.rig,Vector3(0,2.05,-1.96)); throat.name="Throat"; v=D.batch(COLORS)
	v.add("dark",Vector3.ZERO,Vector3(.89,1.05,.23))
	for row in range(6):
		v.add("eye",Vector3(0,-.44+row*.17,-.13),Vector3(.68-absf(row-2)*.075,.10,.04))
		v.add("trim",Vector3(0,-.38+row*.17,-.17),Vector3(.78-absf(row-2)*.075,.04,.05))
	v.finish(throat)
	for side in [-1.0,1.0]:
		for row in range(3):
			var leg=D.pivot(e.rig,Vector3(side*1.05,1.25,-.9+row*.9)); e.legs.append(leg); v=D.batch(COLORS)
			D.taper(v,"plate",Vector3.ZERO,Vector3(side*.44,-.42,.1),.4,.26,5)
			D.taper(v,"hide",Vector3(side*.44,-.42,.1),Vector3(side*.55,-1.1,-.12),.23,.1,7)
			for toe in [-1,1]: D.taper(v,"trim",Vector3(side*.55,-1.08,-.12),Vector3(side*.55+toe*.12,-1.17,-.42),.11,.02,5)
			v.finish(leg)
		var wing=D.pivot(e.rig,Vector3(side*1.2,2.7,.2)); e.wings.append(wing); v=D.batch(COLORS)
		for finger in range(6):
			var end=Vector3(side*(.5+finger*.36),-.12*finger,-.8+finger*.3)
			D.taper(v,"trim",Vector3.ZERO,end,.15,.045,10)
			for tier in range(6):
				var at=end+Vector3(0,-tier*.09,.18+tier*.24)
				v.add("plate" if finger%2 else "accent",at,Vector3(.34,.065,.26-tier*.015))
			D.taper(v,"dark",end,end+Vector3(0,-.55,1.5),.06,.025,9)
		v.finish(wing)
