extends RefCounted
## Shared held/world equipment geometry; projectiles and firing origins are unchanged.
static func build(v: RefCounted, item: Dictionary) -> void:
	match item.family:
		"staff": staff(v,item)
		"bow": bow(v,item)
		"machine_gun": gun(v,item)
		"focus": focus(v,item)

static func crystal(v: RefCounted, at: Vector3, size: float) -> void:
	for tier in range(7):
		var width: float=size*(1-absf(tier-3)*.24)
		v.add("gear",at+Vector3(0,(tier-3)*size*.21,0),Vector3(width,size*.23,width))
	v.add("window",at+Vector3(0,0,-size*.51),Vector3(size*.16,size*.40,.009))

static func staff(v: RefCounted, item: Dictionary) -> void:
	var arcane: bool=item.get("material","") in ["crystal","aether","obsidian"]
	v.add("wood",Vector3(0,.13,-.15),Vector3(.067,1.5,.067))
	# Longitudinal inlay and separate leather wraps at the hand.
	for side in [-1.0,1.0]:
		v.add("recess",Vector3(side*.027,.34,-.187),Vector3(.012,.72,.008))
	for row in range(10):
		v.add("leather" if row%2==0 else "timber",Vector3(0,-.12+row*.029,-.15),Vector3(.082,.023,.084))
	for y in [-.60,-.16,.17,.77]:
		v.add("gear",Vector3(0,y,-.15),Vector3(.095,.039,.095))
		v.add("edge",Vector3(0,y+.018,-.15),Vector3(.103,.012,.103))
	v.add("gear",Vector3(0,-.65,-.15),Vector3(.06,.07,.06))
	v.add("gold",Vector3(0,.84,-.15),Vector3(.17,.07,.17))
	crystal(v,Vector3(0,1.04,-.15),.18 if arcane else .13)
	# Forked head leaves negative space around its faceted core.
	for side in [-1.0,1.0]:
		for tier in range(6):
			var x: float=.075+sin(float(tier)/5*PI)*.085
			v.add("gear",Vector3(side*x,.87+tier*.065,-.15),Vector3(.043,.074,.067))
			v.add("edge",Vector3(side*x,.89+tier*.065,-.19),Vector3(.018,.021,.012))
		if item.get("effect","")=="chain_lightning":
			v.add("gold",Vector3(side*.205,1.045,-.15),Vector3(.028,.33,.035))
			v.add("window",Vector3(side*.205,1.235,-.15),Vector3(.065,.07,.065))
	if item.get("enchant","")!="":
		for row in range(4): v.add("window",Vector3(0,.35+row*.085,-.19),Vector3(.025,.036,.009))
	preload("res://scripts/refined_equipment.gd").socket(v,item,Vector3(0,.84,-.25))

static func bow(v: RefCounted, item: Dictionary) -> void:
	for row in range(33):
		var y: float=-.60+row*.0375
		var bend: float=1-pow(y/.60,2)
		var z: float=-.10-bend*.23
		var width: float=.036+.022*bend
		v.add("wood",Vector3(0,y,z),Vector3(width,.040,.055))
		v.add("gear",Vector3(0,y,z-.033),Vector3(width+.008,.039,.014))
		for side in [-1.0,1.0]:
			v.add("edge",Vector3(side*(width*.5+.003),y,z-.037),Vector3(.009,.039,.010))
		if row%6==0:
			v.add("leather",Vector3(0,y,z),Vector3(width+.017,.026,.084))
	for side in [-1.0,1.0]:
		v.add("gear",Vector3(0,side*.61,-.095),Vector3(.068,.06,.075))
		v.add("recess",Vector3(0,side*.61,-.051),Vector3(.016,.025,.018))
	v.add("fur",Vector3(0,0,-.068),Vector3(.007,1.22,.007))
	for row in range(7):
		v.add("leather" if row%2==0 else "timber",Vector3(0,-.075+row*.025,-.33),Vector3(.080,.020,.083))
	v.add("gear",Vector3(.045,.10,-.32),Vector3(.06,.025,.055))
	if item.get("enchant","")!="":
		for side in [-1.0,1.0]:
			for row in range(3): v.add("window",Vector3(0,side*(.20+row*.06),-.35+row*.024),Vector3(.022,.023,.014))
	preload("res://scripts/refined_equipment.gd").socket(v,item,Vector3(0,.13,-.37))

static func gun(v: RefCounted, item: Dictionary) -> void:
	var infernal: bool=item.get("material","")=="cinder"
	v.add("recess",Vector3(0,.045,-.34),Vector3(.18,.17,.58))
	for side in [-1.0,1.0]:
		v.add("gear",Vector3(side*.096,.055,-.30),Vector3(.027,.14,.45))
		for z in [-.12,-.30,-.49]:
			v.add("edge",Vector3(side*.113,.078,z),Vector3(.011,.023,.023))
		for row in range(6):
			v.add("gear",Vector3(side*.095,.055,-.56-row*.035),Vector3(.035,.115,.026))
			v.add("window" if infernal else "recess",Vector3(side*.114,.055,-.565-row*.035),Vector3(.009,.047,.014))
	v.add("iron",Vector3(0,.066,-.87),Vector3(.067,.067,.40))
	for z in [-.78,-1.05]:
		v.add("gear",Vector3(0,.066,z),Vector3(.105,.105,.05))
	v.add("recess",Vector3(0,.066,-1.079),Vector3(.044,.044,.012))
	# Sculpted stock, pad and pistol grip; separate magazine and open trigger guard.
	for row in range(4):
		v.add("gear",Vector3(0,.015-row*.017,.025+row*.05),Vector3(.14,.14+row*.025,.055))
	v.add("leather",Vector3(0,-.04,.205),Vector3(.16,.23,.028))
	v.add("leather",Vector3(0,-.16,-.10),Vector3(.105,.23,.12))
	for row in range(5): v.add("timber",Vector3(0,-.075-row*.037,-.10),Vector3(.113,.011,.128))
	v.add("gear",Vector3(0,-.21,-.38),Vector3(.13,.27,.17))
	v.add("edge",Vector3(0,-.35,-.38),Vector3(.15,.03,.19))
	for side in [-1.0,1.0]:
		for row in range(3): v.add("recess",Vector3(side*.068,-.13-row*.062,-.38),Vector3(.009,.015,.12))
	v.add("gear",Vector3(0,-.22,-.23),Vector3(.035,.025,.14))
	v.add("gear",Vector3(0,-.16,-.29),Vector3(.035,.14,.025))
	v.add("iron",Vector3(0,-.10,-.21),Vector3(.025,.065,.02))
	for row in range(10): v.add("edge",Vector3(0,.15,-.11-row*.045),Vector3(.09,.023,.024))
	for z in [-.13,-.74]:
		v.add("gear",Vector3(0,.165,z),Vector3(.09,.045,.035))
		v.add("edge",Vector3(0,.20,z),Vector3(.02,.03,.02))
	if item.get("enchant","")!="": v.add("window",Vector3(.115,.055,-.21),Vector3(.009,.035,.11))
	preload("res://scripts/refined_equipment.gd").socket(v,item,Vector3(0,.17,-.36))

static func focus(v: RefCounted, item: Dictionary) -> void:
	v.add("gold",Vector3(0,.045,-.18),Vector3(.24,.045,.24))
	v.add("recess",Vector3(0,.08,-.18),Vector3(.19,.03,.19))
	crystal(v,Vector3(0,.21,-.18),.16)
	for side in [-1.0,1.0]:
		for tier in range(3):
			v.add("gear",Vector3(side*(.105-tier*.015),.09+tier*.055,-.18),Vector3(.026,.062,.035))
	preload("res://scripts/refined_equipment.gd").socket(v,item,Vector3(0,.05,-.32))
