extends RefCounted
static func build(v: RefCounted, origin: Dictionary, covered: bool) -> void:
	var shape: String=origin.shape
	var id: String=origin.id
	var hair=v.materials.timber.duplicate(); hair.albedo_color=Color({"frostkin":"695443","sunborn":"3c302c","grove_elf":"806346","dusk_elf":"c0bac8","stoneborn":"80583c","orckin":"383b2e","wildcat":"73523e","scaleborn":"425e48"}.get(id,"554638")); v.materials.hair=hair
	# Tapered jaw, cheeks and nose keep a clear eye line inside open helmets.
	for tier in range(6):
		var width: float=[.26,.31,.36,.37,.36,.33][tier]
		v.add("skin",Vector3(0,1.505+tier*.062,0),Vector3(width,.07,.34))
	v.add("skin",Vector3(0,1.65,-.192),Vector3(.07,.12,.055))
	for side in [-1,1]:
		v.add("fur",Vector3(side*.093,1.705,-.18),Vector3(.075,.043,.016))
		v.add("coal",Vector3(side*.10,1.705,-.193),Vector3(.028,.035,.015))
		v.add("hair",Vector3(side*.093,1.748,-.185),Vector3(.087,.023,.024))
		v.add("skin",Vector3(side*.12,1.64,-.182),Vector3(.07,.055,.025))
		if shape in ["elf","orc"]:
			for tier in range(5): v.add("skin",Vector3(side*(.19+tier*.026),1.69+tier*.023,0),Vector3(.039,.075-tier*.01,.06))
		elif shape not in ["cat","lizard"]: v.add("skin",Vector3(side*.19,1.68,.01),Vector3(.04,.095,.08))
	v.add("hair",Vector3(0,1.567,-.18),Vector3(.105,.015,.02))
	if shape in ["cat","lizard"]:
		for row in range(4): v.add("skin",Vector3(0,1.605,-.19-row*.032),Vector3(.22-row*.032,.105-row*.012,.04))
		v.add("coal",Vector3(0,1.63,-.315),Vector3(.072,.036,.018))
		for side in [-1,1]:
			if shape=="cat":
				for tier in range(5): v.add("skin",Vector3(side*(.19 if not covered else .255),1.81+tier*.05,.015),Vector3(.13-tier*.022,.057,.105-tier*.016))
			else:
				for row in range(4): v.add("hair",Vector3(side*.13,1.58+row*.05,-.179),Vector3(.045,.025,.013))
		for row in range(10): v.add("skin",Vector3(0,.77-row*.045,.20+row*.07),Vector3(.13-row*.009,.11-row*.006,.09))
	if shape=="orc":
		for side in [-1,1]:
			for tier in range(4): v.add("fur",Vector3(side*.1,1.53+tier*.034,-.215-tier*.008),Vector3(.047-tier*.009,.04,.045-tier*.006))
	if not covered:
		for row in range(6):
			for col in range(6): v.add("hair",Vector3((col-2.5)*.061,1.875-absf(col-2.5)*.007,-.12+row*.061),Vector3(.063,.07,.064))
		for side in [-1,1]:
			for row in range(4 if shape in ["elf","dwarf"] else 2): v.add("hair",Vector3(side*.182,1.80-row*.066,.1),Vector3(.05,.075,.2))
	if shape=="dwarf":
		for col in range(7):
			for row in range(4):
				v.add("hair",Vector3((col-3)*.046,1.55-row*.061,-.19-row*.012),Vector3(.05,.073,.085))
		for side in [-1,1]: v.add("gold",Vector3(side*.09,1.32,-.235),Vector3(.061,.043,.094))
