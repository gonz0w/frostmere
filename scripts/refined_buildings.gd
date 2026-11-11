extends RefCounted
## Authored architectural variants over stable, playable room/door footprints.
const Profiles=preload("res://scripts/building_profiles.gd")
const Furnish=preload("res://scripts/building_furnishings.gd")
var world: Node3D
var b: RefCounted
var o: Vector3
var w: float
var d: float
var h: float
var spec: Dictionary
var wall: String
var tile: String
var trim: String
var accent: String
func add(key: String,p: Vector3,size: Vector3,angle: float=0) -> void: b.add(key,o+p,size,angle)
func solid(p: Vector3,size: Vector3,surface: String="stone") -> void: world._solid(o+p,size,surface)
func build(owner: Node3D,origin: Vector3,width: float,depth: float,height: float,_grand: bool,id: String) -> void:
	world=owner; b=world.blocks; o=origin; w=width; d=depth; h=height; spec=Profiles.get_design(id)
	palette()
	wall="arch_"+spec.region; tile="arch_roof_"+spec.region; trim="stone" if spec.region in ["mountain","sun","ash"] else "timber"; accent="arch_accent_"+spec.region
	var before:=0
	for batch in b.batches.values(): before+=batch.size()
	shell(); masonry(); framing(); roof(); windows(); entrance(); silhouette(); chimney(); facade_identity()
	Furnish.new().build(self)
	var after:=0
	for batch in b.batches.values(): after+=batch.size()
	world.building_records.append({"id":id,"name":spec.name,"origin":o,"width":w,"depth":d,"height":h,"region":spec.region,"use":spec.use,"roofline":spec.roofline,"cuboids":after-before})
func palette() -> void:
	if b.materials.has("arch_nordic"): return
	var colors={"nordic":["8b6748","555d63","385263"],"mountain":["858c91","454f5f","32435d"],"grove":["89846a","486956","9c7444"],"woodland":["77624c","526655","92643e"],"coast":["87928c","8b5c46","3f6975"],"sun":["b8a184","657c80","b99952"],"ash":["655c64","413d4f","796478"],"winter":["70655a","525e66","7f4f43"]}
	for region in colors:
		for i in range(3):
			var material: StandardMaterial3D=b.materials["stone" if region in ["mountain","sun","ash"] and i==0 else "wood" if i==0 else "roof" if i==1 else "cloth"].duplicate()
			material.albedo_color=Color(colors[region][i]); material.roughness=.95
			b.materials[["arch_","arch_roof_","arch_accent_"][i]+region]=material
func shell() -> void:
	add("stone_dark",Vector3(0,.06,0),Vector3(w+.5,.32,d+.5)); solid(Vector3(0,.06,0),Vector3(w+.5,.32,d+.5))
	var boards:=ceili((w-.6)/.28)
	for i in range(boards): add("wood",Vector3(-w/2+.3+(i+.5)*(w-.6)/boards,.264,0),Vector3((w-.6)/boards-.014,.04,d-.6))
	solid(Vector3(0,.235,0),Vector3(w-.6,.03,d-.6),"wood")
	for side in [-1,1]:
		add(wall,Vector3(side*w/2,h/2,0),Vector3(.35,h,d)); solid(Vector3(side*w/2,h/2,0),Vector3(.35,h,d))
		var section:=w/2-.95
		add(wall,Vector3(side*(w/4+.475),h/2,d/2),Vector3(section,h,.35)); solid(Vector3(side*(w/4+.475),h/2,d/2),Vector3(section,h,.35))
	add(wall,Vector3(0,h/2,-d/2),Vector3(w,h,.35)); solid(Vector3(0,h/2,-d/2),Vector3(w,h,.35))
	var lintel:=minf(1.3,h-2.45)
	add(trim,Vector3(0,h-lintel/2,d/2),Vector3(2,lintel,.45)); solid(Vector3(0,h-lintel/2,d/2),Vector3(2,lintel,.45))
	solid(Vector3(0,h+.1,0),Vector3(w,.3,d))
	# Draw shallow stone treads over the same smooth entrance ramp used by
	# player movement and saved approaches.
	const RAMP_LENGTH := 1.5
	const RAMP_THICKNESS := .16
	const TREADS := 8
	var slope := atan(.32 / 1.4)
	var ramp_center := Vector3(0, -.015, d / 2 + .7)
	var ramp_basis := Basis(Vector3.RIGHT, slope)
	for index in range(TREADS):
		var local_z := ((index + .5) / TREADS - .5) * RAMP_LENGTH
		var tread_top := ramp_center + ramp_basis * Vector3(0, RAMP_THICKNESS / 2, local_z)
		add("path", tread_top - Vector3.UP * .11, Vector3(2.3, .22, RAMP_LENGTH * cos(slope) / TREADS))
	var body := StaticBody3D.new()
	body.position = o + ramp_center
	body.rotation.x = slope
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.3, RAMP_THICKNESS, RAMP_LENGTH)
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
func masonry() -> void:
	var stone_height: float=h if spec.region in ["mountain","sun","ash"] else .9
	for end in [-1,1]:
		for row in range(ceili(stone_height/.25)):
			var y:=.2+row*.25
			for col in range(ceili(w/.55)):
				var x: float=-w/2+.28+col*.55+(.12 if row%2 else 0)
				if x>w/2-.1 or (end==1 and absf(x)<1.18): continue
				if end==1 and y>1.45 and y<2.8 and absf(absf(x)-w*.32)<.64: continue
				add(wall if stone_height>1 else "stone",Vector3(x,y,end*(d/2+.23)),Vector3(.52,.225,.15+(.025 if (row+col)%4==0 else 0)))
	for side in [-1,1]:
		for row in range(ceili(stone_height/.25)):
			var y:=.2+row*.25
			for col in range(ceili(d/.55)):
				var z: float=-d/2+.28+col*.55+(.12 if row%2 else 0)
				if z>d/2-.1 or (y>1.45 and y<2.8 and absf(absf(z)-d*.25)<.64): continue
				add(wall if stone_height>1 else "stone",Vector3(side*(w/2+.23),y,z),Vector3(.15,.225,.52))
		for end in [-1,1]:
			for row in range(ceili(h/.35)):
				add("stone" if spec.region!="sun" else wall,Vector3(side*w/2,.23+row*.35,end*d/2),Vector3(.52 if row%2 else .65,.31,.65 if row%2 else .52))
func framing() -> void:
	for side in [-1,1]:
		for z in [-d/2,0,d/2]:
			add(trim,Vector3(side*(w/2+.12),h/2,z),Vector3(.29,h,.27))
			for y in [.8,h-.35]: add("iron",Vector3(side*(w/2+.28),y,z),Vector3(.03,.10,.14))
			for step in range(5): add(trim,Vector3(side*(w/2+.15+step*.1),h-.5+step*.1,z),Vector3(.18,.17,.22))
		add(trim,Vector3(side*(w/2+.44),h-.02,0),Vector3(.24,.24,d+1.25))
		for end in [-1,1]:
			# Timber panels with diagonal braces under the windows.
			for i in range(8): add(trim,Vector3(side*(w*.32+(i-3.5)*.085),1.22-i*.055,end*(d/2+.33)),Vector3(.12,.13,.1))
			for y in [.88,h-.15]: add(trim,Vector3(side*(w*.30),y,end*(d/2+.25)),Vector3(w*.37,.15,.16))
	if spec.region not in ["mountain","sun","ash"]:
		for side in [-1,1]:
			for i in range(ceili(d/.24)):
				var z: float=-d/2+.12+i*.24
				var top: float=1.42 if absf(absf(z)-d*.25)<.62 else h-.2
				add(wall,Vector3(side*(w/2+.20),(top+.9)/2,z),Vector3(.055,top-.9,.224))
		for end in [-1,1]:
			for i in range(ceili(w/.24)):
				var x: float=-w/2+.12+i*.24
				if end==1 and absf(x)<1.18: continue
				var top: float=1.42 if end==1 and absf(absf(x)-w*.32)<.62 else h-.2
				add(wall,Vector3(x,(top+.9)/2,end*(d/2+.2)),Vector3(.224,top-.9,.055))
	# Interior joists have visible pegs; no extra ground-level posts in NPC routes.
	for z in range(ceili(d/1.5)):
		var at: float=-d/2+.55+z*1.5
		add("timber",Vector3(0,h-.14,at),Vector3(w,.22,.19))
		for side in [-1,1]: add("wood",Vector3(side*(w/2-.25),h-.32,at),Vector3(.45,.17,.28))
func roof() -> void:
	# Continuous boarded ceiling prevents light leaking through stepped shingle joints.
	for board in range(ceili(w/.35)):
		add("wood",Vector3(-w/2+(board+.5)*w/ceili(w/.35),h+.02,0),Vector3(w/ceili(w/.35)+.006,.12,d))
	var pitch: float=spec.pitch
	var half:=w/2+.65
	var hip: bool=spec.roofline=="hip"
	var rows:=ceili(half/.22)
	for row in range(rows+1):
		var x: float=row*half/rows
		var y: float=h+(half-x)*pitch
		var length: float=d+1.4-(maxf(0,half-x)*1.1 if hip else 0)
		for side in [-1,1]:
			for shingle in range(ceili(length/.45)):
				var z: float=-length/2+(shingle+.5)*length/ceili(length/.45)
				add(tile,Vector3(side*x,y,z),Vector3(half/rows+.045,maxf(.19,half/rows*pitch+.07),length/ceili(length/.45)+.005))
				# Coherent snow drifts hug the lee eave; no checkerboard snow pattern.
				if spec.region in ["nordic","mountain","winter"] and side==-1 and row>rows-4 and z<0:
					add("snow",Vector3(side*x,y+.1,z),Vector3(.24,.055,.44))
			for end in [-1,1]: add(trim,Vector3(side*x,y+.04,end*(length/2+.06)),Vector3(.24,.23,.2))
	# Close the volume with horizontal tapering courses; hips get sloping end caps.
	for row in range(ceili(half*pitch/.22)):
		var y: float=h+row*.22
		var width: float=maxf(.15,w-row*.44/pitch)
		var z: float=d/2-(row*.22/pitch*.55 if hip else 0)
		for end in [-1,1]:
			add(wall,Vector3(0,y,end*z),Vector3(width,.23,.26))
			if hip: add(tile,Vector3(0,y+.08,end*(z+.7)),Vector3(width+.8,.13,.8))
	var peak:=h+half*pitch
	add(trim,Vector3(0,peak+.09,0),Vector3(.25,.25,d+.9-(half*1.1 if hip else 0)))
	if not hip:
		for end in [-1,1]:
			add(trim,Vector3(0,h+(peak-h)*.44,end*(d/2+.22)),Vector3(.2,(peak-h)*.85,.18))
			for i in range(8):
				for side in [-1,1]: add(trim,Vector3(side*(.13+i*.15),peak-.1-i*.17,end*(d/2+.3)),Vector3(.22,.2,.18))
			for side in [-1,1]:
				for i in range(ceili(w/.24)):
					var x: float=i*.12
					var y: float=h+(w/2-x)*pitch*.78
					add(trim,Vector3(side*x,y,end*(d/2+.24)),Vector3(.18,.19,.15))
			crest(Vector3(0,h+.95,end*(d/2+.37)),end)
func crest(at: Vector3,facing: int=1) -> void:
	add(accent,at,Vector3(.85,1.25,.06))
	for y in [-.55,.55]: add("gold",at+Vector3(0,y,facing*.045),Vector3(.82,.06,.03))
	var use: String=spec.use
	if use in ["herbs","hunter"]:
		add("gold",at+Vector3(0,0,facing*.055),Vector3(.045,.8,.035))
		for side in [-1,1]:
			for i in range(4): add("fur",at+Vector3(side*(.09+i*.045),.35-i*.19,facing*.055),Vector3(.15,.09,.035))
	elif use in ["armory","smith"]:
		add("fur",at+Vector3(0,.12,facing*.055),Vector3(.09,.7,.035))
		add("gold",at+Vector3(0,-.18,facing*.055),Vector3(.48,.09,.035))
		add("fur",at+Vector3(0,-.32,facing*.055),Vector3(.08,.23,.035))
	elif use in ["runes","astronomy"]:
		for i in range(12):
			var angle:=TAU*i/12
			add("gold",at+Vector3(cos(angle)*.27,sin(angle)*.32,facing*.055),Vector3(.075,.075,.035))
		add("fur",at+Vector3(0,0,facing*.055),Vector3(.085,.3,.035))
	elif use in ["library","maps","council"]:
		for side in [-1,1]:
			add("fur",at+Vector3(side*.16,0,facing*.055),Vector3(.25,.53,.035))
			for row in range(4): add(accent,at+Vector3(side*.16,-.16+row*.11,facing*.077),Vector3(.16,.025,.015))
	elif use=="music":
		for i in range(5): add("fur",at+Vector3(-.24+i*.12,0,facing*.055),Vector3(.05,.8-absf(i-2)*.18,.035))
	else:
		for side in [-1,1]:
			for i in range(4): add("fur",at+Vector3(side*(.08+i*.07),.27-i*.14,facing*.052),Vector3(.075,.12,.035))
		add("gold",at+Vector3(0,0,facing*.055),Vector3(.06,.68,.035))
func window_at(at: Vector3,angle: float=0,wide: float=.88) -> void:
	var basis:=Basis(Vector3.UP,angle)
	for entry in [["coal",Vector3.ZERO,Vector3(wide+.2,1.24,.1)],["window",Vector3(0,0,.06),Vector3(wide,1.03,.04)]]:
		add(entry[0],at+basis*entry[1],entry[2],angle)
	for x in [-wide/2,0,wide/2]: add(trim,at+basis*Vector3(x,0,.11),Vector3(.065,1.2,.13),angle)
	for y in [-.57,0,.57]: add(trim,at+basis*Vector3(0,y,.11),Vector3(wide+.15,.065,.13),angle)
	add("stone" if trim=="stone" else "wood",at+basis*Vector3(0,-.67,.1),Vector3(wide+.38,.15,.34),angle)
	for side in [-1,1]:
		for i in range(3): add(accent,at+basis*Vector3(side*(wide/2+.17+i*.085),0,.04),Vector3(.078,1.06,.10),angle)
		for y in [-.38,.38]: add("iron",at+basis*Vector3(side*(wide/2+.24),y,.105),Vector3(.25,.035,.02),angle)
func windows() -> void:
	for side in [-1,1]:
		window_at(Vector3(side*w*.32,2.13,d/2+.25),0,.68 if w<5 else .88)
		for z in [-d*.25,d*.25]: window_at(Vector3(side*(w/2+.24),2.13,z),side*PI/2)
		# Indoor light panes are recessed against the same solid exterior shell.
		for z in [-d*.25,d*.25]:
			add("window",Vector3(side*(w/2-.182),2.13,z),Vector3(.018,.9,.7))
			add("timber",Vector3(side*(w/2-.20),2.13,z),Vector3(.05,.95,.045))
func entrance() -> void:
	var f:=d/2
	for side in [-1,1]:
		add(trim,Vector3(side*1.06,1.35,f+.2),Vector3(.22,2.7,.5))
		for i in range(10):
			add("wood" if trim=="timber" else "stone_dark",Vector3(side*1.06,.55+i*.19,f+.47),Vector3(.14,.15,.05))
			if i%3==0: add("iron",Vector3(side*1.06,.55+i*.19,f+.51),Vector3(.06,.045,.018))
	# Wide hall arcades versus compact awnings on cottages and workshops.
	var reach: float=1.4 if w>7 else .95
	var porch_width: float=3.6 if w>7 else 3.0
	for side in [-1,1]:
		var x: float=side*(porch_width/2-.15)
		add(trim,Vector3(x,1.45,f+reach),Vector3(.18,2.9,.18)); solid(Vector3(x,1.45,f+reach),Vector3(.18,2.9,.18))
		add("stone",Vector3(x,.25,f+reach),Vector3(.35,.5,.35))
		for i in range(4): add(trim,Vector3(x-side*i*.13,2.55+i*.13,f+reach),Vector3(.18,.18,.18))
	for i in range(ceili(porch_width/.22)):
		var x: float=-porch_width/2+i*.22
		add(tile,Vector3(x,3.05+(porch_width/2-absf(x))*.35,f+reach/2),Vector3(.235,.13,reach+1))
	add(trim,Vector3(0,2.8,f+reach+.16),Vector3(porch_width,.18,.17))
	# A fixed sign faces the approach; unique name comes from the authored identity.
	add("timber",Vector3(0,2.61,f+.49),Vector3(1.8,.28,.13))
	var label:=Label3D.new(); label.text=spec.name.to_upper(); label.font_size=28; label.pixel_size=.0018; label.position=o+Vector3(0,2.61,f+.565); label.modulate=Color("ead7a5"); label.outline_size=0; label.visibility_range_end=22; label.set_meta("architecture_sign",true); world.add_child(label)
	world._lantern(o+Vector3(-1.65,0,f+.6),false)
	world._warm_light(o+Vector3(0,2.6,0),maxf(4,w*.7),1.3)
func silhouette() -> void:
	var peak: float=h+(w/2+.65)*spec.pitch
	match spec.roofline:
		"dormer":
			# Front-facing, off-center loft breaks the main gable's symmetry.
			var x: float=-w*.25; var y: float=h+(w/2+.65-absf(x))*spec.pitch+.45; var z: float=d*.10
			add(wall,Vector3(x,y+.45,z),Vector3(1.65,1.2,2.8))
			window_at(Vector3(x,y+.42,z+1.46),0,.62)
			for step in range(5):
				for side in [-1,1]: add(tile,Vector3(x+side*step*.21,y+1.4-step*.15,z),Vector3(.24,.15,3.1))
		"lantern","bell","observatory":
			var x: float=w*.22 if spec.roofline=="observatory" else 0; var z: float=-d*.20
			add(trim,Vector3(x,peak+.28,z),Vector3(2.1,.24,2.1))
			for side in [-1,1]:
				for end in [-1,1]: add(trim,Vector3(x+side*.75,peak+1,z+end*.75),Vector3(.2,1.6,.2))
			if spec.roofline=="bell":
				for tier in range(5): add("gold",Vector3(x,peak+.6+tier*.16,z),Vector3(.85-tier*.11,.17,.85-tier*.11))
			elif spec.roofline=="observatory":
				for i in range(18):
					var a: float=TAU*i/18; add("gold",Vector3(x+cos(a)*1.1,peak+1+sin(a)*1.1,z),Vector3(.14,.14,.14))
			else:
				add("window",Vector3(x,peak+.95,z),Vector3(1.15,1.2,1.15))
				for side in [-1,1]:
					for offset in [-.4,0,.4]: add(trim,Vector3(x+offset,peak+1,z+side*.6),Vector3(.06,1.25,.1))
			for tier in range(7): add(tile,Vector3(x,peak+1.8+tier*.16,z),Vector3(2.25-tier*.28,.17,2.25-tier*.28))
		"clerestory":
			add(wall,Vector3(0,peak+.30,0),Vector3(2.1,.8,d*.6))
			for side in [-1,1]:
				for z in range(ceili(d*.6/.8)):
					add("window",Vector3(side*1.065,peak+.3,-d*.3+.4+z*.8),Vector3(.03,.45,.44))
			for tier in range(6): add(tile,Vector3(0,peak+.75+tier*.14,0),Vector3(2.5-tier*.38,.15,d*.65))
		"battlement":
			# Corner turrets are above the original wall footprint, leaving roads intact.
			for side in [-1,1]:
				var x: float=side*(w/2-.8)
				add(wall,Vector3(x,h+1.9,d/2-.8),Vector3(1.8,4.3,1.8))
				for dx in [-.7,.7]:
					for dz in [-.7,.7]: add("stone",Vector3(x+dx,h+4.3,d/2-.8+dz),Vector3(.5,.6,.5))
				add("coal",Vector3(x,h+2.7,d/2+.12),Vector3(.22,.95,.035))
		"vent":
			for side in [-1,1]:
				add("stone_dark",Vector3(side*w*.22,peak-.2,-d*.18),Vector3(.8,2.6,.8))
				for y in [-.9,0,.9]: add("iron",Vector3(side*w*.22,peak+y,-d*.18),Vector3(.94,.16,.94))
				add("coal",Vector3(side*w*.22,peak+1.17,-d*.18),Vector3(.62,.025,.62))
func chimney() -> void:
	var x:=w*.3; var z: float=-d/2+.2 if w<=6 else -d*.26
	var top: float=h+(w/2+.65-x)*spec.pitch+1.25
	for row in range(ceili((top-h+1)/.23)):
		for side in [-1,1]:
			for i in range(3):
				add("stone",Vector3(x+side*.44,h-1+row*.23,z-.3+i*.3),Vector3(.16,.21,.28))
				add("stone",Vector3(x-.3+i*.3,h-1+row*.23,z+side*.44),Vector3(.28,.21,.16))
	add("stone_dark",Vector3(x,top,z),Vector3(1.08,.16,1.08)); add("coal",Vector3(x,top+.09,z),Vector3(.64,.025,.64))

func facade_identity() -> void:
	# Strong vertical divisions reduce broad flat wall panels at normal play distance.
	for side in [-1,1]:
		for end in [-1,1]:
			if w>=6: add(trim,Vector3(side*w*.21,h*.5,end*(d/2+.3)),Vector3(.19,h-.1,.18))
			for step in range(5): add(trim,Vector3(side*(w*.21+step*.12),h-.75+step*.12,end*(d/2+.36)),Vector3(.18,.2,.16))
		for z in [-d*.35,d*.35]:
			for step in range(7): add(trim,Vector3(side*(w/2+.29),1.15+step*.18,z+step*.16),Vector3(.12,.22,.21))
	# Heavy carved lintel and an open plank door against the inner left jamb.
	add(trim,Vector3(0,2.78,d/2+.48),Vector3(2.45,.22,.35))
	for i in range(11): add("wood" if trim=="timber" else "stone_dark",Vector3(-1+i*.2,2.78,d/2+.67),Vector3(.10,.10,.025))
	for i in range(5): add("wood",Vector3(-1.14,1.35,d/2-.12-i*.15),Vector3(.075,2.1,.137))
	for y in [.65,2.1]:
		add("iron",Vector3(-1.09,y,d/2-.4),Vector3(.03,.075,.70))
		for z in [-.1,-.65]: add("gold",Vector3(-1.067,y,d/2+z),Vector3(.02,.038,.038))
	if spec.region in ["mountain","ash","sun"]:
		# Buttress shoes and recessed banding read as structural stone construction.
		for side in [-1,1]:
			for z in [-d/2,d/2]:
				for tier in range(6): add(wall,Vector3(side*(w/2+.12),.3+tier*.32,z),Vector3(.85-tier*.075,.30,.85-tier*.075))
			for row in range(3): add("stone_dark",Vector3(side*w*.31,h-.45-row*.16,d/2+.34),Vector3(w*.3,.045,.05))
	elif spec.region in ["grove","woodland"]:
		# Root-shaped brackets and herb planters belong to these living timber halls.
		for side in [-1,1]:
			for z in [-d*.25,d*.25]:
				add("timber",Vector3(side*(w/2+.45),1.38,z),Vector3(.42,.24,1.05))
				for sprig in range(6): add("pine_light",Vector3(side*(w/2+.44),1.6+(sprig%2)*.09,z-.4+sprig*.16),Vector3(.18,.22,.18))
			for i in range(5): add("wood",Vector3(side*(w/2+.05+i*.1),h-.6+i*.15,d/2),Vector3(.2,.24,.24))
	if spec.use in ["provisions","store","nets","smith"] and w>=7:
		# A one-sided shop canopy changes the frontage while keeping the central porch.
		var x: float=-w*.32
		for i in range(10):
			add(accent if spec.use!="smith" else tile,Vector3(x-1+i*.22,2.8-absf(i-4.5)*.025,d/2+.8),Vector3(.21,.10,1.5))
		for side in [-1,1]:
			add(trim,Vector3(x+side*.94,2.42,d/2+.5),Vector3(.08,.7,.08))
			for i in range(4): add(trim,Vector3(x+side*.94,2.2+i*.13,d/2+.28+i*.17),Vector3(.09,.15,.22))
	if spec.use in ["weaver","maps","music"] and w>=6:
		# Shallow upper gallery, supported by brackets, never a walkable second floor.
		var y: float=h-.15
		add(trim,Vector3(0,y,d/2+.48),Vector3(2.4,.15,.7))
		for x in [-1.05,-.7,-.35,0,.35,.7,1.05]: add(trim,Vector3(x,y+.35,d/2+.8),Vector3(.07,.6,.07))
		add("wood",Vector3(0,y+.67,d/2+.8),Vector3(2.45,.09,.09))
		for side in [-1,1]:
			for i in range(4): add(trim,Vector3(side*.9,y-.4+i*.1,d/2+.2+i*.1),Vector3(.15,.13,.17))
