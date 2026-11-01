extends RefCounted
const Blocks = preload("res://scripts/blocks.gd")
static var hide_texture: Texture2D
static func batch() -> RefCounted:
	var v=Blocks.new()
	if hide_texture==null:
		var img=Image.create(16,16,false,Image.FORMAT_RGB8)
		var rng=RandomNumberGenerator.new(); rng.seed=8137
		for y in range(16):
			for x in range(16):
				var tone: float=rng.randf_range(.94,1.0)
				img.set_pixel(x,y,Color(tone,tone,tone))
		img.generate_mipmaps(); hide_texture=ImageTexture.create_from_image(img)
	for key in {"hide":"81949e","mantle":"b3c6ca","ice":"a2dce5","bone":"e2eeea","dark":"34444e","eye":"efbd63"}:
		var m=StandardMaterial3D.new(); m.albedo_color=Color({"hide":"81949e","mantle":"b3c6ca","ice":"a2dce5","bone":"e2eeea","dark":"34444e","eye":"efbd63"}[key]); m.roughness=.48 if key=="ice" else .9
		if key=="eye": m.emission_enabled=true; m.emission=m.albedo_color; m.emission_energy_multiplier=.5
		if key in ["hide","mantle"]:
			m.albedo_texture=hide_texture
			m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
		v.materials[key]=m
	return v

static func build(beast: Node3D) -> Node3D:
	# Replace the inherited coarse mesh, retaining the gameplay root and its collision.
	for child in beast.rig.get_children():
		beast.rig.remove_child(child); child.queue_free()
	beast.legs.clear()
	var v=batch()
	# A deep shoulder, tucked belly and separate haunch break the rectangular trunk.
	var widths=[.50,.70,.82,.78,.66,.57,.61,.65,.48]
	var heights=[.54,.70,.76,.69,.57,.49,.53,.55,.43]
	for row in range(9):
		var z: float=-.56+row*.145
		var width: float=widths[row]; var h: float=heights[row]
		var center: float=.82+(.06 if row<4 else .015)
		for tier in range(5):
			var taper: float=1-absf(tier-2)*.14
			v.add("hide",Vector3(0,center+(tier-2)*h/5,z),Vector3(width*taper,h/5+.008,.157))
	for side in [-1.0,1.0]:
		# Swept shoulder tufts; smaller rump tufts leave a visible waist.
		for row in range(5):
			var z: float=-.53+row*.12
			for tier in range(4):
				var span: float=.28+sin(float(tier)/3*PI)*.13
				v.add("mantle",Vector3(side*span,1.22-tier*.115-row*.026,z+tier*.025),Vector3(.13-tier*.015,.14,.15))
		for row in range(3):
			for tier in range(3):
				v.add("mantle",Vector3(side*(.28+tier*.026),1.03-tier*.10,.30+row*.095),Vector3(.105-tier*.018,.12,.13))
		# Subtle scars follow the side of the tucked flank, rather than vertical vents.
		for mark in range(3):
			v.add("dark",Vector3(side*(.303-mark*.014),.98-mark*.037,.09+mark*.048),Vector3(.015,.016,.08))
	# Uneven ice growth concentrates around the shoulders and diminishes to the tail.
	var crests=[.25,.40,.33,.26,.21,.16,.10]
	for ridge in range(7):
		var height: float=crests[ridge]
		var base: float=1.24 if ridge<3 else 1.13 if ridge<5 else 1.08
		for tier in range(5):
			var taper: float=1-float(tier)*.18
			v.add("ice",Vector3((ridge%2)*.032,base+tier*height/5,-.45+ridge*.18+tier*.020),Vector3(.18*taper,height/5+.018,.15*taper))
		for side in [-1.0,1.0]:
			v.add("mantle",Vector3(side*.08,base-.025,-.45+ridge*.18),Vector3(.14,.075,.16))
	for row in range(6):
		v.add("hide" if row<4 else "mantle",Vector3(0,.91-row*.025,.70+row*.095),Vector3(.19-row*.022,.18-row*.017,.13))
	v.finish(beast.rig)
	for side in [-1.0,1.0]:
		for z in [-.45,.45]:
			var leg=Node3D.new(); leg.position=Vector3(side*.27,.5,z); beast.rig.add_child(leg); beast.legs.append(leg)
			v=batch()
			var front: bool=z<0
			# Front limbs carry the shoulder; rear limbs sweep back into a narrower hock.
			for tier in range(4):
				var offset: float=0 if front else .035+tier*.018
				v.add("hide",Vector3(0,-.04-tier*.075,offset),Vector3(.27-tier*.026,.09,.27-tier*.022))
			for tier in range(3):
				v.add("mantle",Vector3(side*(.065-tier*.008),-.02-tier*.07,-.005),Vector3(.22-tier*.028,.09,.27-tier*.025))
			v.add("dark",Vector3(0,-.31,.025 if front else .08),Vector3(.14,.13,.15))
			v.add("hide",Vector3(0,-.37,-.025),Vector3(.20,.12,.23))
			v.add("hide",Vector3(0,-.425,-.10),Vector3(.26,.11,.25))
			for toe in range(3):
				v.add("mantle",Vector3((toe-1)*.085,-.405,-.19),Vector3(.075,.105,.12))
				v.add("bone",Vector3((toe-1)*.085,-.425,-.255),Vector3(.045,.055,.085))
			v.finish(leg)
	beast.charge_head=Node3D.new(); beast.charge_head.position=Vector3(0,1,-.8); beast.rig.add_child(beast.charge_head)
	v=batch()
	for tier in range(4):
		v.add("hide",Vector3(0,-.12+tier*.105,0),Vector3(.56-absf(tier-1)*.055,.12,.48-absf(tier-1)*.04))
	v.add("dark",Vector3(0,-.135,-.33),Vector3(.35,.105,.34))
	for tier in range(3):
		v.add("mantle",Vector3(0,-.07+tier*.065,-.29+tier*.035),Vector3(.37-tier*.025,.075,.35-tier*.05))
	v.add("dark",Vector3(0,-.015,-.48),Vector3(.26,.105,.085))
	for side in [-1.0,1.0]:
		v.add("dark",Vector3(side*.258,.065,-.17),Vector3(.025,.12,.15))
		v.add("eye",Vector3(side*.275,.075,-.205),Vector3(.02,.045,.075))
		v.add("mantle",Vector3(side*.25,.145,-.17),Vector3(.11,.07,.24))
		for tier in range(3):
			v.add("mantle",Vector3(side*(.23+tier*.018),.25+tier*.075,.09),Vector3(.15-tier*.035,.09,.16-tier*.025))
		for tuft in range(4):
			v.add("mantle",Vector3(side*(.255+tuft*.022),.02-tuft*.075,.08+tuft*.025),Vector3(.10,.105,.22))
		# Swept saber tusks, built from a broad root to a small upturned tip.
		for segment in range(8):
			var size: float=.115-segment*.010
			v.add("bone",Vector3(side*(.265+segment*.012),-.14+maxi(0,segment-3)*.065,-.32-segment*.075),Vector3(size,.11,size+.025))
		for tooth in range(3):
			v.add("bone",Vector3(side*.125,-.115,-.25-tooth*.08),Vector3(.035,.075,.04))
	v.finish(beast.charge_head)
	var jaw=Node3D.new(); jaw.position=Vector3(0,-.22,-.10); beast.charge_head.add_child(jaw)
	v=batch(); v.add("hide",Vector3(0,-.035,-.20),Vector3(.33,.11,.40))
	v.add("mantle",Vector3(0,-.10,-.12),Vector3(.25,.07,.22))
	for side in [-1.0,1.0]:
		for tooth in range(3): v.add("bone",Vector3(side*.12,.035,-.12-tooth*.09),Vector3(.035,.06,.045))
	v.finish(jaw)
	return jaw
