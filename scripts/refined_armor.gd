extends RefCounted
## Construction details share the rig's slot materials and batched geometry.
static func torso(v: RefCounted, item: Dictionary) -> void:
	var heavy: bool = item.get("weight_class", "") == "heavy"
	for face in [-1.0, 1.0]:
		if heavy:
			# Separate breastplate halves and overlapping abdominal lames.
			for side in [-1.0, 1.0]:
				for row in range(3):
					v.add("chest", Vector3(side * .14, 1.33-row*.075, face*.218), Vector3(.255-row*.018,.08,.07))
			for row in range(4):
				v.add("chest", Vector3(0,1.08-row*.065,face*(.213+row*.006)),Vector3(.50-row*.025,.075,.055))
			v.add("iron",Vector3(0,1.27,face*.262),Vector3(.024,.27,.015))
		else:
			# Tailored vertical panels with seams, rather than a metal tile grid.
			for col in range(5):
				v.add("chest",Vector3((col-2)*.103,1.14,face*.195),Vector3(.096,.46,.025))
			for side in [-1.0,1.0]:
				v.add("timber",Vector3(side*.18,1.19,face*.219),Vector3(.036,.43,.022))
		for side in [-1.0,1.0]:
			for row in range(4):
				v.add("gold" if heavy else "fur",Vector3(side*.205,1.31-row*.11,face*.26),Vector3(.019,.018,.012))
	# Split tassets leave the leg joints clear.
	if heavy:
		for side in [-1.0,1.0]:
			for row in range(3):
				v.add("chest",Vector3(side*.19,.77-row*.057,-.20),Vector3(.18-row*.012,.065,.055))
	for side in [-1.0,1.0]:
		v.add("timber",Vector3(side*.22,.90,-.238),Vector3(.065,.12,.028))
		v.add("iron",Vector3(side*.22,.94,-.258),Vector3(.08,.018,.012))

static func helmet(v: RefCounted, item: Dictionary) -> void:
	var heavy: bool = item.get("weight_class", "") == "heavy"
	# Brow follows the open face; cheek guards never cross the eyes or muzzle.
	v.add("iron" if heavy else "fur",Vector3(0,1.80,-.22),Vector3(.40,.032,.025))
	for side in [-1.0,1.0]:
		for row in range(3):
			v.add("head",Vector3(side*(.207-row*.009),1.66-row*.045,-.16),Vector3(.047,.051,.105-row*.018))
		for row in range(3):
			v.add("iron" if heavy else "fur",Vector3(side*.253,1.77-row*.09,.02),Vector3(.012,.019,.022))
	if heavy:
		for row in range(4):
			v.add("iron",Vector3(0,1.905+row*.035,.11-row*.052),Vector3(.033,.042,.067))

static func limb(v: RefCounted, state: RefCounted, leg: bool) -> void:
	if leg:
		if not state.item_at("legs").is_empty():
			for side in [-1.0,1.0]:
				v.add("timber",Vector3(side*.124,-.25,0),Vector3(.02,.035,.27))
			if state.item_at("legs").get("weight_class", "") == "heavy":
				v.add("legs",Vector3(0,-.40,-.15),Vector3(.17,.12,.05))
		if not state.item_at("feet").is_empty():
			v.add("coal",Vector3(0,-.745,-.055),Vector3(.267,.032,.37))
			for row in range(3):
				v.add("feet",Vector3(0,-.57-row*.047,-.16-row*.018),Vector3(.225-row*.014,.043,.07))
			for row in range(2):
				v.add("timber",Vector3(0,-.53-row*.075,-.162),Vector3(.235,.024,.024))
				v.add("iron",Vector3(.083,-.53-row*.075,-.18),Vector3(.042,.034,.012))
	else:
		if not state.item_at("chest").is_empty():
			if state.item_at("chest").get("weight_class", "") == "heavy":
				for row in range(3):
					v.add("iron",Vector3(0,-row*.065-.033,-.179+row*.0125),Vector3(.285-row*.025,.013,.016))
			for side in [-1.0,1.0]:
				v.add("iron",Vector3(side*.137,-.075,-.115),Vector3(.019,.02,.019))
			v.add("timber",Vector3(0,-.23,-.145),Vector3(.23,.035,.018))

static func hand(v: RefCounted, key: String, armored: bool, first_person: bool, handedness: float=1.0) -> void:
	# Build in first-person hand space, then map into the downward-facing rig hand.
	var pieces: Array = []
	pieces.append([key,Vector3(0,-.025,.015),Vector3(.16,.12,.17)])
	pieces.append([key,Vector3(0,-.045,.145),Vector3(.185,.155,.13)])
	for finger in range(4):
		pieces.append([key,Vector3((finger-1.5)*.04,-.027,-.078),Vector3(.034,.105,.045)])
		if armored: pieces.append(["iron",Vector3((finger-1.5)*.04,.038,-.045),Vector3(.03,.025,.043)])
	pieces.append([key,Vector3(.096,-.058,-.005),Vector3(.048,.066,.10)])
	if armored:
		for row in range(3):
			pieces.append([key,Vector3(0,.038,.045+row*.041),Vector3(.178+row*.009,.034,.046)])
		pieces.append(["timber",Vector3(0,-.047,.188),Vector3(.204,.17,.021)])
		pieces.append(["iron",Vector3(.075,.043,.188),Vector3(.039,.034,.031)])
	for piece in pieces:
		var pos: Vector3=piece[1]; var size: Vector3=piece[2]
		pos.x*=handedness
		if not first_person:
			pos=Vector3(pos.x,-.54+pos.z,pos.y)
			size=Vector3(size.x,size.z,size.y)
		v.add(piece[0],pos,size)

static func collar(v: RefCounted) -> void:
	var under: StandardMaterial3D=v.materials.fur.duplicate()
	under.albedo_color=under.albedo_color.darkened(.20); v.materials.fur_under=under
	# Staggered, tapered tufts form a dipped neckline and drape over the shoulders.
	for face in [-1.0,1.0]:
		for col in range(15):
			var x: float=(col-7)*.047
			var y: float=1.37+absf(x)*.22
			for tier in range(3):
				var length: float=.07+float((col*3+tier)%5)*.009
				v.add("fur_under" if tier==0 else "fur",Vector3(x+(tier%2)*.012,y-tier*.033,face*(.207+tier*.026)),Vector3(.059-tier*.009,length,.069-tier*.011))
	for side in [-1.0,1.0]:
		for row in range(4):
			for col in range(3):
				v.add("fur",Vector3(side*(.32+row*.035),1.44-row*.042,(col-1)*.10),Vector3(.075-row*.007,.07,.085))
