extends RefCounted
## Geometry only: the boss owns collision, attack timing and animated pivots.
const Blocks=preload("res://scripts/blocks.gd")
static var materials: Dictionary={}
static func batch() -> RefCounted:
	if materials.is_empty():
		for key in {"hide":"382c30","plate":"674749","edge":"927471","dark":"201e24","bone":"b6a28b","heat":"ff793e"}:
			var m=StandardMaterial3D.new()
			m.albedo_color=Color({"hide":"382c30","plate":"674749","edge":"927471","dark":"201e24","bone":"b6a28b","heat":"ff793e"}[key])
			m.roughness=.72 if key in ["plate","edge"] else .94
			if key=="heat": m.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
			materials[key]=m
	var v=Blocks.new(); v.materials=materials; v.spatial_batching=false
	return v
static func build(beast: Node3D) -> void:
	var v=batch()
	# Broad shoulders taper to a lower armored haunch, with a lifted belly.
	for row in range(9):
		var breadth: float=[2.05,2.48,2.65,2.52,2.3,2.12,1.92,1.65,1.28][row]
		var height: float=[1.65,1.95,2.05,1.95,1.85,1.7,1.55,1.4,1.1][row]
		for tier in range(5):
			v.add("hide",Vector3(0,1.85+(tier-2)*height/5,-1.4+row*.37),Vector3(breadth*(1-absf(tier-2)*.12),height/5+.025,.4))
		# Raised, staggered plates and an inset spine seam.
		var top: float=1.85+height*.5
		v.add("dark",Vector3(0,top,-1.4+row*.37),Vector3(.15,.12,.4))
		for side in [-1.0,1.0]:
			v.add("plate",Vector3(side*breadth*.23,top-.02,-1.4+row*.37),Vector3(breadth*.43,.18,.36))
			v.add("edge",Vector3(side*breadth*.23,top+.08,-1.54+row*.37),Vector3(breadth*.39,.035,.045))
			for tier in range(3):
				v.add("plate",Vector3(side*(breadth*.45-tier*.025),2.35-tier*.38,-1.4+row*.37),Vector3(.18,.32,.32))
				v.add("edge",Vector3(side*(breadth*.55-tier*.025),2.39-tier*.38,-1.4+row*.37),Vector3(.045,.065,.065))
	# Three exhaust stacks, hollow at their tops, backed by glowing recesses.
	for row in range(3):
		var z: float=-.75+row*.8
		var base: float=2.8-row*.07
		v.add("dark",Vector3(0,base+.25,z),Vector3(.55,.5,.5))
		v.add("heat",Vector3(0,base+.51,z),Vector3(.32,.015,.28))
		for side in [-1.0,1.0]:
			v.add("plate",Vector3(side*.25,base+.52,z),Vector3(.12,.22,.58))
			v.add("plate",Vector3(0,base+.52,z+side*.24),Vector3(.48,.22,.1))
	# Stepped brow and recessed eye sockets around the central furnace aperture.
	for tier in range(5):
		v.add("plate",Vector3(0,1.65+tier*.25,-1.95),Vector3(1.8-absf(tier-2)*.15,.28,.85-absf(tier-2)*.05))
	v.add("dark",Vector3(0,1.8,-2.43),Vector3(1.48,1.06,.12))
	v.add("heat",Vector3(0,1.8,-2.51),Vector3(1.3,.8,.08))
	for side in [-1.0,1.0]:
		v.add("dark",Vector3(side*.68,2.58,-2.4),Vector3(.42,.24,.12))
		v.add("heat",Vector3(side*.68,2.58,-2.47),Vector3(.23,.075,.04))
		v.add("edge",Vector3(side*.69,2.77,-2.37),Vector3(.52,.13,.25))
		# Horns sweep outward and backward; taper is legible from player height.
		for segment in range(10):
			var t: float=segment/9.0
			var width: float=.35*(1-t)+.055
			v.add("bone",Vector3(side*(.77+sin(t*PI*.75)*.65),2.8+t*1.1,-1.84+t*.4),Vector3(width,.17,width))
	v.finish(beast.rig)
	beast.jaw=Node3D.new(); beast.jaw.position=Vector3(0,1.3,-2.15); beast.rig.add_child(beast.jaw)
	v=batch()
	for row in range(4):
		v.add("plate",Vector3(0,-.02-row*.06,-.1-row*.19),Vector3(1.65-row*.12,.25,.24))
	for tooth in range(7):
		var x: float=(tooth-3)*.18
		v.add("bone",Vector3(x,.18,-.63),Vector3(.13,.27,.15))
		v.add("bone",Vector3(x,.34,-.64),Vector3(.075,.10,.09))
	v.finish(beast.jaw)
	for side in [-1.0,1.0]:
		for row in range(3):
			var leg=Node3D.new(); leg.position=Vector3(side*1.3,1.3,-1+row); beast.rig.add_child(leg); beast.legs.append(leg)
			v=batch()
			for tier in range(5):
				v.add("plate",Vector3(side*(.12+tier*.065),.15-tier*.19,0),Vector3(.65-tier*.055,.25,.64-tier*.035))
			v.add("dark",Vector3(side*.4,-.74,.04),Vector3(.38,.24,.4))
			v.add("plate",Vector3(side*.43,-1.01,-.12),Vector3(.53,.34,.7))
			for toe in range(3):
				v.add("bone",Vector3(side*.43+(toe-1)*.18,-1.13,-.5),Vector3(.12,.13,.32))
				v.add("edge",Vector3(side*.43+(toe-1)*.18,-.86,-.25),Vector3(.1,.08,.16))
			v.finish(leg)
		var bank=Node3D.new(); bank.position=Vector3(side*1.32,1.5,0); beast.rig.add_child(bank); beast.bellows.append(bank)
		v=batch()
		for row in range(4):
			v.add("heat",Vector3(0,row*.35,0),Vector3(.13,.13,2.5))
			v.add("dark",Vector3(side*.07,row*.35+.1,0),Vector3(.15,.09,2.58))
		v.finish(bank)
		var shutter=Node3D.new(); shutter.position=Vector3(side*.36,1.8,-2.58); beast.rig.add_child(shutter); beast.shutters.append(shutter)
		v=batch()
		v.add("dark",Vector3.ZERO,Vector3(.7,.95,.2))
		for row in range(5):
			v.add("plate",Vector3(0,-.38+row*.19,-.12),Vector3(.65,.155,.1))
			v.add("edge",Vector3(side*.25,-.38+row*.19,-.18),Vector3(.065,.065,.035))
		v.finish(shutter)
