extends RefCounted
## Authored east-bank slice. Visual columns sit over a matching smooth walking surface.
static func height_at(x: float,z: float) -> float:
	var edge: float=clampf((x-18)/2,0,1)*clampf((25-x)/2,0,1)*clampf((z+11)/2,0,1)*clampf((11-z)/2,0,1)
	var gathering_clear: float=smoothstep(.75,1.8,Vector2(x-23,z+6).length())
	return -.1+edge*gathering_clear*(.20+.38*pow(sin((z+11)*.22),2)+.12*sin(x*1.3+z*.35))
func build(world: Node3D) -> void:
	var b: RefCounted=world.blocks
	var rng=RandomNumberGenerator.new(); rng.seed=9051
	var faces=PackedVector3Array()
	for xi in range(14):
		for zi in range(44):
			var x: float=18+xi*.5; var z: float=-11+zi*.5
			var a=Vector3(x,height_at(x,z),z); var c=Vector3(x+.5,height_at(x+.5,z),z)
			var d=Vector3(x+.5,height_at(x+.5,z+.5),z+.5); var e=Vector3(x,height_at(x,z+.5),z+.5)
			faces.append_array(PackedVector3Array([a,c,e,c,d,e]))
			var h: float=height_at(x+.25,z+.25)
			b.add("earth",Vector3(x+.25,(h-.30)/2,z+.25),Vector3(.5,h+.20,.5))
			b.add("grass" if sin(x*.61+z*.35)+cos(z*.54)>.1 else "grass_dark",Vector3(x+.25,h-.028,z+.25),Vector3(.50,.045,.50))
			# Patchy low ground cover, with an open walking strip through the bank.
			if absf(x+.25-21)>.65 and rng.randf()<.48:
				for blade in range(3):
					var bx: float=x+rng.randf()*.45; var bz: float=z+rng.randf()*.45
					var bh: float=.08+rng.randf()*.16
					b.add("grass_dark" if blade%2 else "pine_light",Vector3(bx,height_at(bx,bz)+bh*.5,bz),Vector3(.032,bh,.04))
			if xi<3 or xi>11:
				if rng.randf()<.24: fern(b,Vector3(x+.25,h,z+.25),rng.randf_range(.6,1.15))
	var body=StaticBody3D.new(); body.name="RefinedRiverbank"; body.set_meta("footstep","terrain")
	var shape=ConcavePolygonShape3D.new(); shape.set_faces(faces)
	var collider=CollisionShape3D.new(); collider.shape=shape; body.add_child(collider); world.add_child(body)
	shoreline(world)
	western_shelf(world)
	# Lichen-covered rock shelves on the far edge, clear of the bank's central walk.
	for z in [-7.0,1.0,8.0]:
		var at=Vector3(24.15,height_at(24.15,z),z)
		for tier in range(4):
			var size=Vector3(1.1-tier*.19,.19,1.35-tier*.20)
			b.add("stone" if tier%2 else "stone_dark",at+Vector3(tier*.045,.08+tier*.15,0),size)
			if tier>1: b.add("pine_light",at+Vector3(tier*.045,.18+tier*.15,.10),Vector3(size.x*.55,.022,size.z*.5))
		world._solid(at+Vector3(.05,.30,0),Vector3(.95,.60,1.2))
	for p in [Vector3(23.8,0,-4),Vector3(24,0,5)]:
		var clear:=true
		for site in world.tree_sites:
			if Vector2(site.position.x-p.x,site.position.z-p.z).length()<2: clear=false
		if clear:
			p.y=height_at(p.x,p.z)
			spruce(world,p,5.5 if p.z<0 else 6.4)

func fern(b: RefCounted,at: Vector3,scale: float) -> void:
	for branch in range(5):
		var angle: float=branch*TAU/5
		for step in range(4):
			var d: float=(step+1)*.075*scale
			b.add("pine_light" if step%2 else "grass_dark",at+Vector3(cos(angle)*d,(.21-step*.035)*scale,sin(angle)*d),Vector3(.12*scale,.045*scale,.085*scale),angle)

func spruce(world: Node3D,at: Vector3,height: float) -> void:
	var b: RefCounted=world.blocks
	for row in range(12):
		var w: float=.32-row*.014
		b.add("timber" if row%3 else "wood",at+Vector3(0,(row+.5)*height/12,0),Vector3(w,height/12+.01,w))
	world._solid(at+Vector3(0,1.7,0),Vector3(.38,3.4,.38),"wood")
	world.tree_sites.append({"position":at,"height":height})
	for tier in range(7):
		var y: float=1.25+tier*(height-1.35)/6
		for branch in range(5):
			var angle: float=branch*TAU/5+tier*.61
			var reach: float=(1-float(tier)/8)*1.5
			for step in range(5):
				var d: float=reach*float(step+1)/5
				var p=at+Vector3(cos(angle)*d,y-d*.22,sin(angle)*d)
				b.add("wood",p,Vector3(.18,.07,.10),angle)
				b.add("pine" if (tier+branch)%3 else "pine_light",p+Vector3(0,.09,0),Vector3(.43,.23,.37),angle)
				for side in [-1.0,1.0]:
					var wing=p+Vector3(-sin(angle)*side*.18,.03,cos(angle)*side*.18)
					b.add("pine",wing,Vector3(.28,.17,.25),angle)
				if (tier+branch+step)%7==0: b.add("snow",p+Vector3(0,.19,0),Vector3(.29,.035,.23),angle)
	b.add("pine_light",at+Vector3(0,height-.15,0),Vector3(.16,.4,.16))

static func shore_x(z: float) -> float:
	var fade: float=clampf((z+11)/2,0,1)*clampf((11-z)/2,0,1)
	return 18-fade*(.28+1.28*pow(sin(z*.32+.8),2)+.20*pow(sin(z*.81),2))

static func shelf_height(fraction: float) -> float:
	return lerpf(-.62,-.10,fraction)

func shoreline(world: Node3D) -> void:
	var b: RefCounted=world.blocks
	var faces=PackedVector3Array()
	# A continuous tapered shelf joins the existing bank; its wet edge varies with z.
	for row in range(55):
		var z: float=-11+row*.4
		var left: float=shore_x(z); var next: float=shore_x(z+.4)
		for col in range(6):
			var u: float=float(col)/6; var end: float=float(col+1)/6
			var a=Vector3(lerpf(left,18,u),shelf_height(u),z)
			var c=Vector3(lerpf(left,18,end),shelf_height(end),z)
			var e=Vector3(lerpf(next,18,u),shelf_height(u),z+.4)
			var d=Vector3(lerpf(next,18,end),shelf_height(end),z+.4)
			if maxf(18-left,18-next)>.01: faces.append_array(PackedVector3Array([a,c,e,c,d,e]))
			var width: float=(18-shore_x(z+.2))/6
			if width<.008: continue
			var x: float=shore_x(z+.2)+(col+.5)*width
			var h: float=shelf_height((col+.5)/6.0)
			b.add("stone_dark" if col<2 else "earth",Vector3(x,(h-1)/2,z+.2),Vector3(width+.006,h+1,.402))
			if col>3:
				b.add("grass_dark",Vector3(x,h+.007,z+.2),Vector3(width,.014,.39))
	var body=StaticBody3D.new(); body.name="ScallopedShore"; body.set_meta("footstep","terrain")
	var shape=ConcavePolygonShape3D.new(); shape.set_faces(faces)
	var collider=CollisionShape3D.new(); collider.shape=shape; body.add_child(collider); world.add_child(body)
	# Clustered rock noses replace the continuous repeated curb.
	for z in [-8.0,-2.8,4.4,8.2]:
		var edge: float=shore_x(z)
		for rock in range(3):
			var at=Vector3(edge+.20+rock*.28,-.40,z+(rock-1)*.31)
			var h: float=.34+(.16 if rock==1 else .03)
			for tier in range(3):
				b.add("stone_dark" if tier==0 else "stone",at+Vector3(.035*tier,h*tier/3,0),Vector3(.65-tier*.12,h/3+.025,.70-tier*.13))
			b.add("pine_light",at+Vector3(.07,h-.04,0),Vector3(.29,.023,.28))
			if rock==1: b.add("snow",at+Vector3(.12,h-.016,.05),Vector3(.22,.03,.19))
			world._solid(at+Vector3(.04,h/2-.025,0),Vector3(.50,h,.55))
	var rng=RandomNumberGenerator.new(); rng.seed=7153
	for center in [-9.0,-5.7,.5,3.0,7.0]:
		for reed in range(15):
			var z: float=center+rng.randf_range(-.65,.65)
			var x: float=shore_x(z)+rng.randf_range(.06,.28)
			var h: float=rng.randf_range(.3,.66)
			b.add("grass_dark",Vector3(x,-.60+h/2,z),Vector3(.027,h,.027))
			if reed%3==0: b.add("leather",Vector3(x,-.60+h,z),Vector3(.045,.085,.045))

static func west_edge(z: float) -> float:
	var fade: float=clampf((z+11)/2,0,1)*clampf((11-z)/2,0,1)
	return 10+fade*(.70+.80*pow(sin(z*.26-1.1),2))

func western_shelf(world: Node3D) -> void:
	var b: RefCounted=world.blocks
	var faces=PackedVector3Array()
	for row in range(55):
		var z: float=-11+row*.4
		var edge: float=west_edge(z); var next: float=west_edge(z+.4)
		for col in range(6):
			var u: float=float(col)/6; var end: float=float(col+1)/6
			var a=Vector3(lerpf(10,edge,u),shelf_height(1-u),z)
			var c=Vector3(lerpf(10,edge,end),shelf_height(1-end),z)
			var e=Vector3(lerpf(10,next,u),shelf_height(1-u),z+.4)
			var d=Vector3(lerpf(10,next,end),shelf_height(1-end),z+.4)
			if maxf(edge-10,next-10)>.01: faces.append_array(PackedVector3Array([a,c,e,c,d,e]))
			var width: float=(west_edge(z+.2)-10)/6
			if width<.008: continue
			var x: float=10+(col+.5)*width
			var h: float=shelf_height(1-(col+.5)/6.0)
			b.add("earth" if col<4 else "stone_dark",Vector3(x,(h-1)/2,z+.2),Vector3(width+.006,h+1,.402))
			if col<2: b.add("grass_dark",Vector3(x,h+.008,z+.2),Vector3(width,.014,.39))
	var body=StaticBody3D.new(); body.name="WesternShore"; body.set_meta("footstep","terrain")
	var shape=ConcavePolygonShape3D.new(); shape.set_faces(faces)
	var collider=CollisionShape3D.new(); collider.shape=shape; body.add_child(collider); world.add_child(body)
	# Isolated waterline boulders and rushes leave the landward shop side untouched.
	for z in [-8.5,-4.1,2.3,7.5]:
		var x: float=west_edge(z)-.16
		for tier in range(4):
			b.add("stone_dark" if tier==0 else "stone",Vector3(x-tier*.03,-.50+tier*.105,z),Vector3(.63-tier*.11,.13,.74-tier*.12))
		b.add("grass_dark",Vector3(x-.08,-.13,z),Vector3(.26,.027,.29))
		world._solid(Vector3(x-.03,-.30,z),Vector3(.42,.40,.51))
	for patch in [-6.5,-1.0,5.0]:
		for reed in range(11):
			var z: float=patch+sin(reed*2.3)*.47
			var x: float=west_edge(z)-.04-(reed%3)*.07
			var h: float=.36+(reed%4)*.075
			b.add("grass_dark",Vector3(x,-.60+h/2,z),Vector3(.028,h,.028))
			if reed%3==0: b.add("leather",Vector3(x,-.60+h,z),Vector3(.047,.09,.047))
