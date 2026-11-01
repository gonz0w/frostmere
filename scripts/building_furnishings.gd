extends RefCounted
## Room contents reflect work, storage and daily life; central interaction routes stay clear.
var a: RefCounted
func add(key: String,p: Vector3,size: Vector3,angle: float=0) -> void: a.add(key,p,size,angle)
func build(architecture: RefCounted) -> void:
	a=architecture
	var w: float=a.w; var d: float=a.d; var use: String=a.spec.use
	# Preserve the counter envelope used by merchants and the original approach.
	add("wood",Vector3(0,1.05,-1.2),Vector3(w*.5,.18,1.1)); a.solid(Vector3(0,.65,-1.2),Vector3(w*.5,1.1,1.1),"wood")
	for side in [-1,1]:
		add("timber",Vector3(side*w*.2,.65,-1.2),Vector3(.18,.8,.65))
		for z in [-1.65,-.73]: add("iron",Vector3(side*w*.2,.8,z),Vector3(.05,.4,.03))
	if use not in ["home","shelter","council","maps","music","weaver","nets"]:
		for i in range(ceili(w*.5/.25)):
			add("wood",Vector3(-w*.25+(i+.5)*.25,.77,-.62),Vector3(.23,.46,.045))
	# A woven runner and border make the entry welcoming without raised collision.
	add(a.accent,Vector3(0,.29,d*.25),Vector3(minf(w-1.3,3.2),.018,1.5))
	for side in [-1,1]:
		add("fur",Vector3(side*minf((w-1.5)/2,1.45),.304,d*.25),Vector3(.055,.009,1.4))
		for i in range(9): add("fur",Vector3(-1.0+i*.25,.305,d*.25+side*.7),Vector3(.035,.01,.14))
	# Hearth on the rear side, away from the keeper / merchant centerline.
	var at:=Vector3(w*.30,.3,-d/2+.2 if w<=6 else -d*.26)
	add("stone_dark",at+Vector3(0,a.h/2,0),Vector3(.84,a.h,.8))
	add("coal",at+Vector3(0,.5,.44),Vector3(.9,.85,.035))
	for side in [-1,1]:
		for row in range(5): add("stone",at+Vector3(side*.54,.13+row*.22,.4),Vector3(.23,.20,.36))
	add("stone",at+Vector3(0,1.2,.4),Vector3(1.5,.17,.55))
	for i in range(4):
		add("timber",at+Vector3(-.28+i*.18,.15,.48),Vector3(.13,.15,.28),.3)
		add("window",at+Vector3(-.26+i*.17,.28+(i%2)*.10,.54),Vector3(.12,.21,.09))
	a.world._warm_light(a.o+at+Vector3(0,.65,.8),3.2,.55)
	# Pegged wall boards and a lantern chandelier add human-scale construction.
	for side in [-1,1]:
		for row in range(4): add("wood",Vector3(side*(w/2-.19),.45+row*.15,0),Vector3(.035,.13,d-.5))
		add("timber",Vector3(side*(w/2-.22),1.03,0),Vector3(.08,.09,d-.5))
	var lamp:=Vector3(0,a.h-.65,d*.1)
	add("iron",lamp+Vector3.UP*.23,Vector3(.035,.55,.035))
	add("timber",lamp,Vector3(1.25,.10,.18))
	for side in [-1,1]:
		add("coal",lamp+Vector3(side*.48,-.27,0),Vector3(.22,.4,.22))
		add("window",lamp+Vector3(side*.48,-.27,.12),Vector3(.14,.25,.025))
	if use in ["council","provisions","library","hunter"] and w>=7:
		var bench:=Vector3(w/2-1,.55,d*.22)
		add("wood",bench,Vector3(1.25,.14,1.7))
		for z in [-.65,.65]: add("timber",bench+Vector3(0,-.18,z),Vector3(.9,.4,.12))
		add(a.accent,bench+Vector3(0,.10,0),Vector3(1.15,.07,1.55))
		a.solid(bench-Vector3.UP*.15,Vector3(1.25,.6,1.7),"wood")
	# One shallow bank of shelves, built against the wall. Other wall gets a bespoke use.
	var shelf:=Vector3(-w/2+.5,0,-d*.25)
	for y in [.55,1.25,1.95]:
		add("wood",shelf+Vector3(0,y,0),Vector3(.55,.1,d*.42))
		for i in range(maxi(2,int(d*.6))):
			var q:=shelf+Vector3(0,y+.06,-d*.18+i*.57)
			if use in ["library","runes","maps","music","astronomy"]: books(q,i)
			elif use in ["store","armory","smith","hunter"]: bundles(q,i)
			else: jar(q,"pine_light" if i%3==0 else a.accent if i%3==1 else "leather")
	for z in [-d*.46,-d*.04]: add("timber",Vector3(shelf.x,1.2,z),Vector3(.10,2,.10))
	a.solid(shelf+Vector3(0,1.1,0),Vector3(.55,1.8,d*.42),"wood")
	match use:
		"herbs":
			for i in range(5):
				var q:=Vector3(-w*.18+i*w*.09,1.15,-1.2)
				jar(q,"pine_light" if i%2 else a.accent)
				add("fur",q+Vector3(0,.12,.115),Vector3(.12,.07,.02))
			# Suspended drying herbs and a pestle, entirely above walking headroom.
			add("timber",Vector3(0,a.h-.6,-d*.3),Vector3(w*.6,.10,.12))
			for i in range(7):
				var x: float=-w*.24+i*w*.08
				add("leather",Vector3(x,a.h-.75,-d*.3),Vector3(.025,.3,.025))
				for j in range(3): add("pine_light",Vector3(x+(j-1)*.065,a.h-.92-j*.045,-d*.3),Vector3(.1,.22,.15))
			add("stone",Vector3(.25,1.19,-.92),Vector3(.3,.1,.25)); add("stone_dark",Vector3(.25,1.25,-.92),Vector3(.12,.18,.12))
		"smith","armory":
			var rack:=Vector3(0,1.6,-d/2+.25)
			add("timber",rack,Vector3(w*.6,.16,.2))
			for i in range(5):
				var x: float=-w*.22+i*w*.11
				add("iron",rack+Vector3(x,-.15,.2),Vector3(.08,1.15,.10))
				add("wood",rack+Vector3(x,-.78,.2),Vector3(.075,.22,.08))
				add("iron",rack+Vector3(x,-.60,.2),Vector3(.30,.05,.12))
			for i in range(5): add("iron",Vector3(-.7+i*.3,1.20,-1.2),Vector3(.25,.12,.35))
			add("coal",Vector3(.8,1.16,-.9),Vector3(.22,.05,.22))
		"runes","astronomy":
			book_open(Vector3(-.5,1.15,-1.2))
			for i in range(16):
				var angle: float=TAU*i/16
				add("gold",Vector3(.65+cos(angle)*.33,1.55+sin(angle)*.33,-1.2),Vector3(.06,.06,.07))
			add("iron",Vector3(.65,1.35,-1.2),Vector3(.08,.40,.08))
			add("window",Vector3(.65,1.55,-1.2),Vector3(.10,.10,.10))
			wall_panel("runes")
		"library","maps","council":
			book_open(Vector3(-.45,1.15,-1.2)); jar(Vector3(.7,1.15,-1.2),"coal",.55)
			wall_panel("map")
			for i in range(3): add("fur",Vector3(-.8+i*.22,1.18,-.88),Vector3(.14,.05,.3))
		"music":
			book_open(Vector3(0,1.15,-1.2)); wall_panel("pipes")
			for x in [-.8,.8]: candle(Vector3(x,1.15,-1.2))
		"weaver","nets":
			var at2:=Vector3(w/2-.6,0,d*.20)
			for z in [-.65,.65]: add("timber",at2+Vector3(0,1.2,z),Vector3(.15,2.2,.15))
			for y in [.5,2.2]: add("wood",at2+Vector3(0,y,0),Vector3(.15,.12,1.5))
			for i in range(11): add("fur",at2+Vector3(-.03,1.38,-.6+i*.12),Vector3(.028,1.55,.025))
			for i in range(10): add(a.accent if use=="weaver" else "leather",at2+Vector3(-.05,.65+i*.13,0),Vector3(.04,.045,1.28))
			a.solid(at2+Vector3(0,1.1,0),Vector3(.3,2.2,1.5),"wood")
			for i in range(4): bundles(Vector3(-.7+i*.45,1.15,-1.2),i)
		"shelter","home":
			var bed:=Vector3(w/2-.9,.45,d/2-1.8)
			add("timber",bed,Vector3(1.4,.3,1.7)); add(a.accent,bed+Vector3(0,.23,0),Vector3(1.26,.17,1.6)); add("fur",bed+Vector3(0,.34,-.5),Vector3(.9,.13,.4))
			a.solid(bed,Vector3(1.4,.6,1.7),"wood")
			jar(Vector3(.5,1.15,-1.2),"leather"); candle(Vector3(-.5,1.15,-1.2))
		"hunter":
			wall_panel("antlers"); bundles(Vector3(0,1.15,-1.2),1)
		_:
			for i in range(4): jar(Vector3(-.7+i*.45,1.15,-1.2),"leather",.7)
			for i in range(3): bundles(Vector3(-.5+i*.35,1.15,-.86),i)
	# Asymmetric front display sits beside the porch and outside its walking envelope.
	if a.w>=7 and a.spec.id!="outfitter":
		var crate:=Vector3(-a.w*.30,.28,a.d/2+.65)
		for row in range(4):
			add("wood",crate+Vector3(0,.1+row*.15,0),Vector3(.8,.13,.65))
		for x in [-.28,.28]: add("iron",crate+Vector3(x,.32,.34),Vector3(.05,.65,.025))
		a.solid(crate+Vector3(0,.32,0),Vector3(.8,.64,.65),"wood")
		if use in ["herbs","hunter"]:
			for i in range(3): add("pine_light",crate+Vector3(-.2+i*.2,.78,0),Vector3(.18,.35,.24))
		elif use=="smith":
			for i in range(3): add("iron",crate+Vector3(-.22+i*.22,.75,0),Vector3(.18,.2,.38))
		else: bundles(crate+Vector3(0,.66,0),0)
func jar(at: Vector3,key: String,scale: float=1) -> void:
	for row in range(4):
		var width: float=[.14,.23,.22,.12][row]*scale
		add(key,at+Vector3(0,(.035+row*.065)*scale,0),Vector3(width,.07*scale,width))
	add("wood",at+Vector3(0,.275*scale,0),Vector3(.14,.045,.14)*scale)
func books(at: Vector3,index: int) -> void:
	for i in range(3):
		var y: float=.06+i*.09
		add(a.accent if (i+index)%2 else "leather",at+Vector3(0,y,0),Vector3(.32,.07,.32-i*.025))
		add("fur",at+Vector3(.165,y,0),Vector3(.012,.044,.26-i*.025))
func bundles(at: Vector3,index: int) -> void:
	for i in range(3):
		add("leather" if index%2 else a.accent,at+Vector3(0,.04+i*.065,0),Vector3(.36-i*.02,.05,.29))
	add("fur",at+Vector3(0,.12,.155),Vector3(.055,.23,.025))
func book_open(at: Vector3) -> void:
	add("leather",at,Vector3(.7,.04,.45))
	for side in [-1,1]:
		add("fur",at+Vector3(side*.17,.03,0),Vector3(.31,.025,.4))
		for row in range(6): add("timber",at+Vector3(side*.17,.045,-.15+row*.052),Vector3(.22,.008,.009))
func candle(at: Vector3) -> void:
	add("gold",at+Vector3.UP*.035,Vector3(.16,.07,.16)); add("fur",at+Vector3.UP*.17,Vector3(.07,.24,.07)); add("window",at+Vector3.UP*.33,Vector3(.045,.08,.045))
func wall_panel(kind: String) -> void:
	var at:=Vector3(0,2,-a.d/2+.23)
	add("timber",at,Vector3(a.w*.5,1.5,.12))
	if kind=="pipes":
		for i in range(9):
			var height: float=1.2-absf(i-4)*.14
			add("iron",at+Vector3((i-4)*.25,(height-1)/2,.12),Vector3(.14,height,.15))
	elif kind=="antlers":
		for side in [-1,1]:
			for i in range(7):
				add("fur",at+Vector3(side*(.15+i*.12),-.4+i*.12,.15),Vector3(.16,.14,.15))
				if i%2==0: add("fur",at+Vector3(side*(.15+i*.12),-.2+i*.12,.15),Vector3(.07,.3,.07))
	else:
		add("fur" if kind=="map" else a.accent,at+Vector3(0,0,.07),Vector3(a.w*.45,1.27,.03))
		for i in range(12):
			var x: float=-a.w*.19+i*a.w*.035
			add("wood" if kind=="map" else "gold",at+Vector3(x,sin(i*1.2)*.33,.095),Vector3(.15,.05,.016))
