extends RefCounted
## Layered angular construction, shared by world avatars and first-person equipment.
static func build(vox: RefCounted,item: Dictionary) -> void:
	var edge: StandardMaterial3D=vox.materials.gear.duplicate()
	edge.albedo_color=edge.albedo_color.lightened(.28); edge.metallic=.65; edge.roughness=.32
	vox.materials.edge=edge
	var recess: StandardMaterial3D=vox.materials.gear.duplicate()
	recess.albedo_color=recess.albedo_color.darkened(.4); recess.roughness=.65
	vox.materials.recess=recess
	if item.family=="shield": shield(vox,item)
	elif item.family in ["axe","battleaxe","mace"]: impact_weapon(vox,item)
	elif item.family in ["staff","bow","machine_gun","focus"]: preload("res://scripts/refined_ranged.gd").build(vox,item)
	else: blade(vox,item)
	preload("res://scripts/equipment_identity.gd").weapon(vox,item)

static func blade(v: RefCounted,item: Dictionary) -> void:
	var dagger: bool=item.family=="dagger"
	var length: float=.45 if dagger else 1.25 if item.get("two_handed",false) else .8
	var theme: String=preload("res://scripts/equipment_identity.gd").style(item)
	var width: float=.12*({"aether":1.7,"obsidian":1.25,"crystal":1.12,"station":1.3,"stone":1.2}.get(theme,1.0))
	var id: String=item.get("base_id",item.get("id",""))
	var rows: int=ceili(length/.035)
	# A dark central fuller and two stepped edge strips give the blade a cross-section.
	for i in range(rows):
		var taper: float=1-clampf((float(i)/rows-.73)/.27,0,.9)
		var curve: float=sin(float(i)/rows*PI*.6)*(.08 if id in ["tideglass_saber","sunsteel_saber","aether_saber"] else 0.0)
		var w: float=width*taper; var z: float=-.25-(i+.5)*length/rows
		v.add("gear",Vector3(curve,0,z),Vector3(w,.045,length/rows+.001))
		for side in [-1,1]:
			v.add("edge",Vector3(curve+side*(w*.5+.007),0,z),Vector3(.014,.022,length/rows+.001))
		if i>1 and i<rows-5:
			for side in [-1,1]: v.add("recess",Vector3(curve,side*.024,z),Vector3(.022,.004,length/rows+.001))
	# Bound grip, ferrules, faceted pommel, swept stepped guard and rivets.
	v.add("leather",Vector3(0,0,-.025),Vector3(.075,.075,.29))
	for i in range(8): v.add("timber",Vector3(0,0,.09-i*.033),Vector3(.08,.081,.008))
	for z in [.125,-.17]: v.add("gear",Vector3(0,0,z),Vector3(.10,.095,.034))
	v.add("gear",Vector3(0,0,.165),Vector3(.115,.095,.07))
	v.add("edge",Vector3(0,0,.203),Vector3(.075,.07,.018))
	var guard: float=.105 if dagger else .15
	for side in [-1,1]:
		for i in range(4):
			v.add("gear",Vector3(side*(.025+i*guard/4),0,-.205-i*.009),Vector3(guard/4+.006,.063-i*.007,.055))
		v.add("edge",Vector3(side*guard,0,-.239),Vector3(.035,.045,.048))
		v.add("gold",Vector3(side*.047,.035,-.205),Vector3(.015,.01,.02))
	if item.get("enchant","")!="" or item.get("effect","")=="stamina_on_kill":
		for side in [-1,1]:
			for i in range(4):
				v.add("window",Vector3(0,side*.027,-.32-i*.075),Vector3(.014,.008,.035))
				v.add("window",Vector3(.013,side*.027,-.33-i*.075),Vector3(.026,.008,.009))
	socket(v,item,Vector3(0,.041,-.205))

static func shield(v: RefCounted,item: Dictionary) -> void:
	var stock: String=item.get("material",item.get("base_id","").get_slice("_",0))
	var ornate: bool=stock in ["crystal","aether","cinder","obsidian"]
	# Individual boards/panels, thick stepped perimeter, front bands and rear fittings.
	for row in range(17):
		var y: float=.49-row*.038
		var width: float=.55-maxf(0,row-10)*.052
		v.add("recess",Vector3(0,y,-.20),Vector3(width,.039,.06))
		var count: int=maxi(1,floori((width-.06)/.07))
		for col in range(count):
			var x: float=(col-(count-1)*.5)*.07
			v.add("gear" if ornate else "wood",Vector3(x,y,-.246),Vector3(.066,.036,.045))
			v.add("timber",Vector3(x,y,-.162),Vector3(.066,.036,.014))
		for side in [-1,1]:
			v.add("gear",Vector3(side*(width*.5-.013),y,-.249),Vector3(.032,.04,.07))
			if row%3==0: v.add("edge",Vector3(side*(width*.5-.013),y,-.287),Vector3(.017,.017,.009))
	v.add("gear",Vector3(0,.514,-.249),Vector3(.56,.03,.07))
	for y in [.37,.04]:
		v.add("gear",Vector3(0,y,-.274),Vector3(.46,.025,.018))
		v.add("timber",Vector3(0,y,-.157),Vector3(.44,.035,.03))
	for tier in range(3):
		v.add("gear" if tier%2==0 else "edge",Vector3(0,.23,-.285-tier*.018),Vector3(.17-tier*.037,.17-tier*.037,.024))
	for x in [-.12,.12]:
		v.add("leather",Vector3(x,.20,-.126),Vector3(.038,.24,.024))
		for y in [.095,.305]: v.add("edge",Vector3(x,y,-.109),Vector3(.06,.025,.016))
	v.add("leather",Vector3(0,.2,-.097),Vector3(.20,.042,.035))
	if item.get("enchant","")!="":
		for side in [-1,1]:
			for i in range(3): v.add("window",Vector3(side*(.07+i*.034),.4-i*.035,-.276),Vector3(.022,.018,.009))
	socket(v,item,Vector3(0,.23,-.35))

static func socket(v: RefCounted,item: Dictionary,at: Vector3) -> void:
	if item.get("gem","")=="": return
	var mat: StandardMaterial3D=v.materials.edge.duplicate()
	mat.albedo_color=Color({"ruby":"c55568","sapphire":"5d8cd5","emerald":"65b884"}.get(item.gem,"8fbcd6"))
	v.materials.socket=mat
	v.add("gold",at,Vector3(.065,.04,.044))
	v.add("socket",at+Vector3(0,.008,-.008),Vector3(.041,.045,.038))

static func impact_weapon(v: RefCounted,item: Dictionary) -> void:
	var length: float=1.1 if item.get("two_handed",false) else .70
	v.add("wood",Vector3(0,0,-length*.47),Vector3(.068,.07,length+.19))
	for row in range(10):
		v.add("leather" if row%2 else "timber",Vector3(0,0,.07-row*.032),Vector3(.083,.085,.025))
	for z in [.105,-.27,-length+.11]:
		v.add("gear",Vector3(0,0,z),Vector3(.102,.102,.037))
		v.add("edge",Vector3(0,0,z+.017),Vector3(.11,.11,.012))
	v.add("gear",Vector3(0,0,-length),Vector3(.13,.12,.20))
	if item.family=="mace":
		v.add("recess",Vector3(0,0,-length),Vector3(.18,.18,.24))
		for side in [-1.0,1.0]:
			for row in range(5):
				var reach: float=.12+(2-absf(row-2))*.025
				var z: float=-length-.10+row*.05
				v.add("gear",Vector3(side*reach,0,z),Vector3(.10,.045,.055))
				v.add("gear",Vector3(0,side*reach,z),Vector3(.045,.10,.055))
				v.add("edge",Vector3(side*(reach+.052),0,z),Vector3(.012,.035,.05))
				v.add("edge",Vector3(0,side*(reach+.052),z),Vector3(.035,.012,.05))
		v.add("gear",Vector3(0,0,-length-.145),Vector3(.115,.115,.06))
		v.add("edge",Vector3(0,0,-length-.18),Vector3(.065,.065,.025))
	else:
		var sides: Array=[-1.0,1.0] if item.family=="battleaxe" else [1.0]
		for side in sides:
			for row in range(9):
				var z: float=-length-.16+row*.04
				var span: float=.19+sin(float(row)/8*PI)*.075
				v.add("gear",Vector3(side*(.08+span*.5),0,z),Vector3(span,.046,.045))
				v.add("edge",Vector3(side*(.08+span+.012),0,z),Vector3(.031,.019,.043))
				v.add("recess",Vector3(side*.115,.025,z),Vector3(.021,.009,.029))
			v.add("gold",Vector3(side*.083,.069,-length),Vector3(.023,.012,.032))
		if item.family=="axe": v.add("gear",Vector3(-.095,0,-length),Vector3(.14,.10,.11))
	if item.get("enchant","")!="":
		for row in range(3): v.add("window",Vector3(.073,.066,-length-.075+row*.055),Vector3(.025,.012,.027))
	socket(v,item,Vector3(0,.076,-length))
