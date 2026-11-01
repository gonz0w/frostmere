extends RefCounted
## Authored identity mapping, shared by worn and held equipment.
const GROUPS={
"watch":["oldwatch_oath","northwatch_head","northwatch_greatsword"],
"stone":["stoneguard_main_hand","stoneguard_chest","stoneguard_off_hand"],
"storm":["stormweaver_main_hand","stormweaver_chest","stormweaver_off_hand"],
"lantern":["echo_blade","lantern_conductor","lantern_keystone","sealed_memory_ring"],
"grove":["briar_vestment","amberbough_bow","groveheart_chest","pactkeeper_axe","seedkeeper_charm","pactmender_ring","oldpromise_talisman"],
"tide":["tideglass_saber","tideguard_shell","signal_focus","breakwater_mantle","starsignal_staff","netmender_ring"],
"sun":["sunsteel_saber","lenswarden_chest","horizon_staff","dawnforged_sword","dawnforged_bow","dawnforged_staff"],
"song":["resonance_blade","cantors_chest","cantors_staff","memorial_ring"],
"road":["wayfarer_shield","pathfinder_feet","witness_pendant"],
"station":["station_rifle","station_chest","void_cutter"],
"moss":["mossfang_blade","mossheart_amulet"],
"frost":["rimefang_maul","frostmaw_chest"],
"ward":["wardkeeper_amulet","clan_voice_signet"]}
static func style(item: Dictionary) -> String:
	var id: String=item.get("base_id",item.get("id",""))
	for key in GROUPS:
		if id in GROUPS[key]: return key
	return item.get("material",item.get("family",""))
static func emblem(v: RefCounted, key: String, at: Vector3, size: float, theme: String) -> void:
	# Embossed geometry: leaf chevrons, sun rays, grille or angular knot.
	if theme in ["grove","moss","leather","fur"]:
		v.add(key,at,Vector3(size*.10,size,.018))
		for side in [-1,1]:
			for row in range(3): v.add(key,at+Vector3(side*size*(.12+row*.06),size*(.28-row*.22),0),Vector3(size*.32,size*.10,.02))
	elif theme in ["sun","storm","crystal","aether","ward"]:
		for i in range(8):
			var angle=TAU*i/8
			v.add(key,at+Vector3(cos(angle)*size*.38,sin(angle)*size*.38,0),Vector3(size*.13,size*.13,.025))
		v.add(key,at,Vector3(size*.25,size*.25,.03))
	elif theme in ["station","cinder","song","lantern"]:
		for row in range(4): v.add(key,at+Vector3(0,(row-1.5)*size*.23,0),Vector3(size*(.55+row*.1),size*.10,.025))
	else:
		for side in [-1,1]:
			v.add(key,at+Vector3(side*size*.27,0,0),Vector3(size*.13,size,.02))
			v.add(key,at+Vector3(0,side*size*.31,0),Vector3(size*.68,size*.12,.02))
static func armor(v: RefCounted,item: Dictionary,slot: String) -> void:
	var theme=style(item)
	if slot=="chest":
		if theme in ["fur","frost"]: preload("res://scripts/refined_armor.gd").collar(v)
		if theme in ["chain","tide"]:
			for row in range(5):
				for col in range(5):
					v.add("chest",Vector3((col-2)*.092+(row%2)*.025,1.30-row*.077,-.258),Vector3(.087,.058,.025))
		elif theme in ["station","cinder"]:
			for side in [-1,1]:
				v.add("iron",Vector3(side*.16,1.18,-.26),Vector3(.22,.32,.055))
				for row in range(5): v.add("coal",Vector3(side*.16,1.28-row*.05,-.294),Vector3(.17,.023,.012))
		elif theme in ["grove","moss","leather"]:
			for side in [-1,1]:
				for row in range(5): v.add("chest",Vector3(side*(.08+row*.023),1.3-row*.085,-.253),Vector3(.16,.09,.03))
		elif theme in ["obsidian","aether","crystal","storm"]:
			for side in [-1,1]:
				for row in range(5): v.add("chest",Vector3(side*(.08+row*.034),1.29-row*.055,-.27),Vector3(.065,.16-row*.014,.055))
		else:
			for side in [-1,1]:
				v.add("chest",Vector3(side*.18,1.17,-.25),Vector3(.19,.37,.045))
		emblem(v,"gold" if theme in ["sun","watch","stone"] else "iron",Vector3(0,1.22,-.315),.18,theme)
	elif slot=="head":
		if theme in ["cloth","leather","fur","grove"]:
			for side in [-1,1]: v.add("head",Vector3(side*.22,1.58,.12),Vector3(.08,.18,.17))
		elif theme in ["obsidian","crystal","storm","aether"]:
			for row in range(5): v.add("head",Vector3(0,1.94+row*.045,.07-row*.025),Vector3(.11-row*.016,.055,.15-row*.018))
		elif theme in ["iron","chain","steel","stone","watch"]:
			for row in range(6): v.add("iron",Vector3(0,1.945,-.16+row*.062),Vector3(.065,.055,.067))
		if theme=="watch": emblem(v,"gold",Vector3(0,1.86,-.22),.095,"watch")
static func limb(v: RefCounted,item: Dictionary,slot: String) -> void:
	if item.is_empty(): return
	var theme=style(item)
	if slot=="feet" and theme=="road":
		for side in [-1,1]:
			v.add("leather",Vector3(side*.13,-.55,.06),Vector3(.045,.23,.21))
			v.add("gold",Vector3(side*.155,-.55,-.015),Vector3(.014,.06,.075))
	elif slot=="legs":
		for side in [-1,1]:
			v.add("legs",Vector3(side*.11,-.22,-.13),Vector3(.055,.30,.04))
		if theme in ["cinder","aether","crystal","obsidian"]: emblem(v,"iron",Vector3(0,-.34,-.19),.095,theme)
static func jewelry(v: RefCounted,item: Dictionary,first_person: bool=false,ring: bool=false) -> void:
	if item.is_empty(): return
	var theme=style(item)
	if ring:
		var at=Vector3(.02,.037,-.064) if first_person else Vector3(.02,-.604,.037)
		v.add("gold",at,Vector3(.041,.012,.039))
		var width: float=.034 if theme in ["ward","stone","watch"] else .021
		v.add("window" if theme in ["lantern","moss","grove"] else "iron",at+Vector3(0,.013,0),Vector3(width,.02,.026))
		if theme in ["tide","song"]:
			for side in [-1,1]: v.add("gold",at+Vector3(side*.019,.012,0),Vector3(.009,.019,.042))
	else:
		for side in [-1,1]:
			for i in range(7): v.add("gold",Vector3(side*(.17-i*.023),1.42-i*.038,-.32),Vector3(.025,.028,.018))
		v.add("gold",Vector3(0,1.13,-.335),Vector3(.10,.13,.022))
		emblem(v,"window" if theme in ["lantern","ward","moss"] else "iron",Vector3(0,1.13,-.355),.073,theme)
static func weapon(v: RefCounted,item: Dictionary) -> void:
	var theme=style(item); var family: String=item.family
	if family in ["sword","dagger","greatsword"]:
		for side in [-1,1]:
			if theme in ["grove","moss","tide"]:
				for row in range(6): v.add("gear",Vector3(side*(.13+sin(row*.5)*.035),0,-.20-row*.035),Vector3(.035,.043,.043))
			elif theme in ["sun","aether","crystal","storm"]:
				for row in range(4): v.add("edge",Vector3(side*(.10+row*.025),0,-.24-row*.02),Vector3(.04-row*.007,.042,.10))
			elif theme in ["station","obsidian"]:
				v.add("gear",Vector3(side*.085,0,-.35),Vector3(.06,.06,.24))
			else: v.add("gear",Vector3(side*.12,0,-.23),Vector3(.065,.075,.075))
		if theme=="lantern":
			for side in [-1,1]:
				for row in range(7): v.add("edge",Vector3(side*.12,0,-.17+row*.045),Vector3(.025,.037,.05))
		elif theme=="song":
			for side in [-1,1]: v.add("edge",Vector3(side*.047,0,.21),Vector3(.025,.05,.15))
		elif theme=="stone":
			v.add("gear",Vector3(0,0,-.21),Vector3(.37,.08,.08))
		if theme in ["watch","stone","song","lantern"]:
			for row in range(4): v.add("gold" if theme=="watch" else "edge",Vector3(0,.028,-.40-row*.085),Vector3(.044,.007,.025))
	elif family=="shield": emblem(v,"edge",Vector3(0,.25,-.36),.28,theme)
	elif family=="mace" and theme=="frost":
		for side in [-1,1]:
			for row in range(5):
				v.add("edge",Vector3(side*(.17+row*.02),0,-.70-row*.023),Vector3(.07-row*.011,.075-row*.01,.13))
	elif family in ["axe","battleaxe"]:
		if theme in ["grove","cinder"]:
			for row in range(5): v.add("edge",Vector3(.12+row*.025,.047,-(.98 if family=="battleaxe" else .68)),Vector3(.025,.025,.08+row*.035))
	elif family=="staff":
		if theme in ["sun","song","lantern","storm","tide"]:
			for side in [-1,1]:
				for row in range(5):
					var reach: float=.19+(.04*sin(row*.8) if theme in ["sun","tide"] else row*.01)
					v.add("gold" if theme=="sun" else "edge",Vector3(side*reach,.90+row*.066,-.15),Vector3(.027,.04,.065))
	elif family=="bow":
		if theme in ["grove","sun"]:
			for side in [-1,1]:
				for row in range(5): v.add("wood" if theme=="grove" else "edge",Vector3(.04,side*(.22+row*.065),-.34+row*.022),Vector3(.08-row*.01,.038,.045))
	elif family=="machine_gun" and theme=="station":
		for z in [-.22,-.43]: v.add("iron",Vector3(0,.21,z),Vector3(.07,.13,.055))
		v.add("gear",Vector3(0,.285,-.325),Vector3(.095,.065,.29))
		v.add("window",Vector3(0,.285,-.48),Vector3(.06,.04,.014))
	elif family=="focus": emblem(v,"edge",Vector3(0,.10,-.32),.18,theme)

static func skirt(v: RefCounted,chest: Dictionary) -> void:
	if chest.is_empty() or (chest.family!="cloth" and style(chest) not in ["grove","song","lantern"]): return
	# Each panel follows its own thigh instead of intersecting moving legs.
	for face in [-1,1]:
		for row in range(4):
			v.add("chest",Vector3(0,-.02-row*.075,face*.19),Vector3(.255,.081,.035))
			v.add("gold" if style(chest)=="song" else "timber",Vector3(.10,-.02-row*.075,face*.214),Vector3(.016,.076,.012))

static func hand_details(v: RefCounted,item: Dictionary,key: String,first_person: bool) -> void:
	if item.is_empty(): return
	var theme=style(item)
	for row in range(3):
		var at=Vector3(0,.075,.045+row*.046)
		var size=Vector3(.13,.014,.024)
		if not first_person:
			at=Vector3(at.x,-.54+at.z,at.y); size=Vector3(size.x,size.z,size.y)
		v.add("window" if theme=="cinder" else "snow" if theme in ["aether","crystal"] else "timber" if theme in ["fur","leather","cloth"] else "iron",at,size)
