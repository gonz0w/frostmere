extends RefCounted
## Authored regional dressing, with conservative route/interaction exclusions.
## Static cuboids are spatially batched; low ground cover has a bounded draw range.
const Blocks = preload("res://scripts/blocks.gd")
const Terrain = preload("res://scripts/terrain_profile.gd")
const PineGround = preload("res://scripts/pinehall_terrain.gd")
const REGIONS = [
 {"id":"frostmere","origin":Vector3.ZERO,"bounds":Rect2(-32,-72,74,104),"rock":"stone","cover":"grass_dark","accent":"snow","seed":101},
 {"id":"mountain","origin":Vector3(800,0,0),"bounds":Rect2(-49,-79,98,130),"rock":"stone_dark","cover":"snow","accent":"snow","seed":102},
 {"id":"archive_chapter","origin":Vector3(-800,0,0),"bounds":Rect2(-40,-78,80,120),"rock":"stone","cover":"pine_light","accent":"grass_dark","seed":103},
 {"id":"shore","origin":Vector3(-1200,0,0),"bounds":Rect2(-12,-100,65,150),"rock":"stone_dark","cover":"grass_dark","accent":"stone","seed":104},
 {"id":"lens","origin":Vector3(1200,0,0),"bounds":Rect2(-48,-89,96,137),"rock":"lens_stone","cover":"lens_sand","accent":"fur","seed":105},
 {"id":"roots","origin":Vector3(1440,0,0),"bounds":Rect2(-39,-77,78,115),"rock":"stone","cover":"roots_moss","accent":"roots_leaf","seed":106},
 {"id":"choir","origin":Vector3(1680,0,0),"bounds":Rect2(-25,-77,50,115),"rock":"choir_basalt","cover":"choir_ash","accent":"coal","seed":107},
 {"id":"convergence","origin":Vector3(1920,0,0),"bounds":Rect2(-54,-80,108,124),"rock":"stone_dark","cover":"grass_dark","accent":"pine_light","seed":108},
 {"id":"winter","origin":Vector3(2480,0,0),"bounds":Rect2(-28,-42,56,79),"rock":"stone_dark","cover":"winter_snow","accent":"snow","seed":109}
]
var world: Node3D
var b: RefCounted
var ground: RefCounted
var root: Node3D
var obstacles: Array[Rect2]=[]
var protected: Array[Vector3]=[]
var records: Array=[]
var rng := RandomNumberGenerator.new()
var region: Dictionary
func build(w: Node3D) -> void:
	world=w; b=Blocks.new(); ground=Blocks.new()
	# Reuse the actual chapter palette; no per-prop material allocation.
	for key in world.blocks.materials:
		b.materials[key]=world.blocks.materials[key]; ground.materials[key]=world.blocks.materials[key]
	var worn: StandardMaterial3D=b.materials.path.duplicate()
	worn.albedo_color=worn.albedo_color.darkened(.09)
	b.materials["worn_path"]=worn; ground.materials["worn_path"]=worn
	root=Node3D.new(); root.name="RegionalLandscape"; world.add_child(root)
	_collect_obstacles(world)
	for r in world.building_records:
		obstacles.append(Rect2(Vector2(r.origin.x-r.width/2-1,r.origin.z-r.depth/2-1),Vector2(r.width+2,r.depth+2)))
		protected.append(r.origin+Vector3(0,0,r.depth/2+1.8))
	for id in ["mountain","archive_chapter","shore","lens","roots","choir","convergence","winter","threshold"]:
		var chapter: Node3D=world.get(id)
		for p in chapter.NODES.values(): protected.append(chapter.ORIGIN+p)
	for enemy in world.combat_enemies(): protected.append(enemy.global_position)
	for site in preload("res://scripts/wilderness.gd").SITES: protected.append(site)
	for r in REGIONS:
		region=r; rng.seed=r.seed
		_settlement()
		_landscape()
		_streets()
	_destination_details()
	var count: int=b.finish(root)
	var low=Node3D.new(); low.name="GroundCover"; root.add_child(low)
	count+=ground.finish(low)
	for mesh: MultiMeshInstance3D in low.get_children():
		mesh.visibility_range_end=65
		mesh.visibility_range_end_margin=10
	root.set_meta("cuboids",count); root.set_meta("placements",records)
	world.block_count+=count
func _collect_obstacles(n: Node) -> void:
	if n is CollisionShape3D and n.shape is BoxShape3D and n.get_parent() is StaticBody3D:
		var at: Vector3=n.global_position; var size: Vector3=n.shape.size*n.global_basis.get_scale()
		# Ground slabs and high ceilings are not horizontal obstacles.
		if at.y+size.y/2>.22 and at.y-size.y/2<2.3:
			obstacles.append(Rect2(Vector2(at.x-size.x/2,at.z-size.z/2),Vector2(size.x,size.z)))
	for c in n.get_children(): _collect_obstacles(c)
func _height(p: Vector3) -> float:
	if region.id=="frostmere": return Terrain.height_at(p.x,p.z)-.10
	if region.id=="archive_chapter": return PineGround.height_at(p.x,p.z)-.10
	return -.10
func _clear(p: Vector3,radius: float) -> bool:
	var at: Vector3=region.origin+p
	var xy=Vector2(at.x,at.z)
	for rect in obstacles:
		if rect.grow(radius+.3).has_point(xy): return false
	for q in protected:
		if absf(q.y-at.y)<6 and Vector2(q.x,q.z).distance_to(xy)<radius+3.2: return false
	if region.id=="frostmere":
		if p.x>7 and p.x<22: return false
		if absf(p.z+16)<4 or absf(p.x)<4: return false
		if preload("res://scripts/town_layout.gd").path_at(p.x,p.z) or Terrain.path_at(p.x,p.z): return false
	elif region.id=="mountain":
		if preload("res://scripts/wyrmkeep_detail.gd").path_at(p.x,p.z): return false
	elif region.id=="archive_chapter":
		# Preserve the entire walkable hill shoulder, including unpaved ascent routes.
		if radius>.5:
			for hill in PineGround.HILLS:
				if pow((p.x-hill.x)/(hill.z+radius+1),2)+pow((p.z-hill.y)/(hill.w+radius+1),2)<1: return false
		if preload("res://scripts/pinehall_detail.gd").path_at(p.x,p.z): return false
	elif absf(p.x)<6: return false
	for i in range(9):
		var angle: float=i*TAU/8
		if _path(p.x+cos(angle)*(radius+1),p.z+sin(angle)*(radius+1)): return false
	return true
func _solid(p: Vector3,size: Vector3) -> void:
	var body=StaticBody3D.new(); body.position=p; body.set_meta("footstep","stone")
	var shape=CollisionShape3D.new(); var box=BoxShape3D.new(); box.size=size; shape.shape=box
	body.add_child(shape); root.add_child(body)
	obstacles.append(Rect2(Vector2(p.x-size.x/2,p.z-size.z/2),Vector2(size.x,size.z)))
func _record(kind: String,at: Vector3) -> void:
	records.append({"region":region.id,"kind":kind,"position":at})
func _settlement() -> void:
	for house in world.building_records:
		var local: Vector3=house.origin-region.origin
		if absf(local.x)>70 or absf(local.z)>100 or absf(local.y)>5: continue
		# Broken garden edges and one-sided storage, never a ring of clutter around a door.
		for side in [-1,1]:
			var p: Vector3=local+Vector3(side*(house.width/2+2.5),0,house.depth*.22)
			p.y=_height(p)
			if not _clear(p,1.0): continue
			var at: Vector3=region.origin+p
			if region.id in ["shore","choir","winter","mountain"]:
				_supply(at,region.id=="shore")
			else: _planter(at)
			_solid(at+Vector3(0,.3,0),Vector3(1.4,.6,1.8))
			_record("settlement",at)
		# Foundation skirt of gravel and weathering, flush enough to walk across.
		for i in range(22):
			var side: float=-1 if i%2 else 1
			var p: Vector3=local+Vector3(side*(house.width/2+.7),0,-house.depth/2+float(i/2)*house.depth/11)
			p.y=_height(p)
			ground.add(region.rock,region.origin+p+Vector3(0,.028,0),Vector3(.28,.045,.22),i*.71)
func _planter(at: Vector3) -> void:
	b.add("earth",at+Vector3(0,.17,0),Vector3(1.3,.34,1.7))
	for side in [-1,1]:
		b.add("timber",at+Vector3(side*.7,.24,0),Vector3(.12,.48,1.9))
		b.add("wood",at+Vector3(0,.24,side*.9),Vector3(1.4,.48,.12))
	for x in [-.4,0,.4]:
		for z in [-.55,0,.55]: _fern(b,at+Vector3(x,.37,z),region.cover,.7)
func _supply(at: Vector3,coastal: bool) -> void:
	for level in range(3):
		for i in range(4-level):
			var p: Vector3=at+Vector3((i-(3-level)*.5)*.3,.15+level*.26,0)
			b.add("wood",p,Vector3(.27,.24,1.5))
			b.add("timber",p+Vector3(0,0,.755),Vector3(.18,.16,.02))
	for side in [-1,1]: b.add("iron",at+Vector3(side*.53,.28,0),Vector3(.055,.6,1.6))
	if coastal:
		for i in range(8):
			b.add("fur",at+Vector3(-.64+i*.18,.84,0),Vector3(.035,.04,1.6))
			b.add("fur",at+Vector3(0,.86,-.7+i*.2),Vector3(1.35,.03,.035))
	else: b.add(region.accent,at+Vector3(0,.83,-.1),Vector3(1.1,.12,1.4))
func _fern(batch: RefCounted,at: Vector3,key: String,scale: float) -> void:
	for arm in range(5):
		var angle: float=arm*TAU/5
		for step in range(3):
			var d: float=(step+1)*.12*scale
			batch.add(key,at+Vector3(cos(angle)*d,(.29-step*.055)*scale,sin(angle)*d),Vector3(.24*scale,.065*scale,.13*scale),angle)
func _rock(at: Vector3,scale: float,cap: bool=true) -> void:
	for tier in range(5):
		var width: float=scale*(1-float(tier)*.13)
		b.add(region.rock,at+Vector3(sin(tier*1.7)*scale*.1,.11*scale+tier*.19*scale,0),Vector3(width,.24*scale,width*.8),.18)
		if cap and tier in [2,4]: b.add(region.accent,at+Vector3(.1*scale,.24*scale+tier*.19*scale,.05*scale),Vector3(width*.68,.045*scale,width*.54),.18)
	_solid(at+Vector3(0,.48*scale,0),Vector3(scale*.83,.96*scale,scale*.72))
	_record("outcrop",at)
func _tree(at: Vector3,height: float,broad: bool=false) -> void:
	# Separated boughs and visible taper replace solid cones at newly authored sites.
	for row in range(10):
		b.add("wood" if row%3==0 else "timber",at+Vector3(0,(row+.5)*height/10,0),Vector3(.55-row*.035,height/10+.03,.55-row*.035))
	for arm in range(5):
		var angle: float=arm*TAU/5
		for step in range(3): b.add("timber",at+Vector3(cos(angle)*(.3+step*.2),.18-step*.04,sin(angle)*(.3+step*.2)),Vector3(.32,.3-step*.055,.27),angle)
	if broad:
		preload("res://scripts/refined_canopy.gd").build(b,at,height,height*.3,region.accent,region.cover)
		_solid(at+Vector3(0,1.7,0),Vector3(.55,3.4,.55))
		_record("tree",at)
		return
	for level in range(6):
		var reach: float=(1-float(level)/7)*height*.25
		for arm in range(5):
			var angle: float=arm*TAU/5+level*.67
			for step in range(3):
				var d: float=reach*(step+1)/3
				var p: Vector3=at+Vector3(cos(angle)*d,height*(.35+level*.1)-d*.14,sin(angle)*d)
				b.add("timber",p,Vector3(.6,.10,.15),angle)
				b.add(region.accent if broad else "pine",p+Vector3(0,.15,0),Vector3(.85,.38,.7),angle)
				b.add(region.cover if broad else "pine_light",p+Vector3(.19,.3,.05),Vector3(.55,.24,.5),angle)
				if not broad and (arm+level)%4==0: b.add("snow",p+Vector3(0,.38,0),Vector3(.58,.04,.48),angle)
	_solid(at+Vector3(0,1.7,0),Vector3(.55,3.4,.55))
	_record("tree",at)
func _landscape() -> void:
	var bounds: Rect2=region.bounds
	# Ground-cover clusters follow bare/vegetated patches, rather than uniform noise.
	if region.id!="convergence":
		for i in range(520):
			var p=Vector3(rng.randf_range(bounds.position.x,bounds.end.x),0,rng.randf_range(bounds.position.y,bounds.end.y))
			p.y=_height(p)
			if not _clear(p,.25): continue
			var patch: float=sin(p.x*.31+p.z*.08)+cos(p.z*.24)
			if patch<.15: continue
			var at: Vector3=region.origin+p
			if region.id in ["lens","mountain","winter","choir"]:
				for j in range(4):
					ground.add(region.cover,at+Vector3(j*.22,.022,sin(j*2.3)*.3),Vector3(.35,.035,.28),j*.8)
			else: _fern(ground,at,region.cover,rng.randf_range(.6,1.1))
			if i%7==0: ground.add(region.accent,at+Vector3(.2,.035,.1),Vector3(.48,.055,.35),i)
			_record("ground",at)
	# A sparse set of substantial features gives open edges a stronger silhouette.
	for i in range(85):
		var p=Vector3(rng.randf_range(bounds.position.x,bounds.end.x),0,rng.randf_range(bounds.position.y,bounds.end.y))
		p.y=_height(p)
		if region.id=="convergence": continue
		if not _clear(p,2.2): continue
		if i%4==0 and region.id in ["frostmere","archive_chapter","roots","mountain"]:
			_tree(region.origin+p,rng.randf_range(5,8),region.id=="roots")
		else: _rock(region.origin+p,rng.randf_range(.8,1.8))
	_match_region()
func _match_region() -> void:
	match region.id:
		"mountain", "winter":
			# Jagged side spurs, beyond the settlement's walkable edge.
			for side in [-1,1]:
				for i in range(6): _ridge(region.origin+Vector3(side*(59+i%2*5),0,-73+i*20),9+i%3*2,true)
		"lens":
			for side in [-1,1]:
				for i in range(6): _ridge(region.origin+Vector3(side*(55+i%2*6),0,-75+i*23),6+i%3*2,false)
		"shore":
			for i in range(8): _ridge(region.origin+Vector3(61,0,-91+i*19),7+i%3*2,false)
			# Angular tidal skerries and reed tufts remain below the quay, away from boats.
			for i in range(12):
				var at: Vector3=region.origin+Vector3(-15-(i%3)*2,-1.6,-88+i*9)
				for tier in range(4): b.add("stone_dark",at+Vector3(.1*tier,.19*tier,0),Vector3(2.3-tier*.4,.22,1.6-tier*.25),.3)
		"choir":
			for side in [-1,1]:
				for i in range(9): _ridge(region.origin+Vector3(side*49,0,-80+i*15),7+i%4,false)
		"convergence": _marsh()
func _ridge(at: Vector3,height: float,snow: bool) -> void:
	for column in range(7):
		var h: float=height*(.6+.4*sin(column*.7+.3))
		for tier in range(8):
			var p: Vector3=at+Vector3((column-3)*1.25+sin(tier*.6)*.3,(tier+.5)*h/8,sin(column*2.1)*2)
			b.add(region.rock,p,Vector3(1.4,h/8+.03,4.8-tier*.34))
			if tier in [3,6]: b.add(region.accent,p+Vector3(0,h/16,.1),Vector3(1.42,.08,4.6-tier*.34))
		if snow: b.add("snow",at+Vector3((column-3)*1.25+.1,h+.08,sin(column*2.1)*2),Vector3(1.6,.18,2.7))
	_record("ridge",at)
func _marsh() -> void:
	for side in [-1,1]:
		for i in range(18):
			var at: Vector3=region.origin+Vector3(side*(34+i%3*6),-2,-73+i*7)
			for reed in range(12):
				var p: Vector3=at+Vector3(sin(reed*2.4)*1.7,0,cos(reed*1.8)*1.3)
				var height: float=1.2+(reed%4)*.2
				b.add("grass_dark",p+Vector3(0,height/2,0),Vector3(.045,height,.045))
				b.add("leather",p+Vector3(0,height,0),Vector3(.11,.25,.11))
			if i%3==0:
				for tier in range(8): b.add("timber",at+Vector3(side*tier*.14,tier*.6,0),Vector3(.65-tier*.055,.68,.6-tier*.05))
			_record("marsh",at)
func _destination_details() -> void:
	# Keep all dressing outside the existing platform widths and bridge corridors.
	for id in ["aeralis","crucible"]:
		var local=Blocks.new(); var node=Node3D.new(); node.name="LandscapeDetails"
		world.realms.roots[id].add_child(node)
		for z in [13,-9,-32]:
			for side in [-1,1]:
				if id=="aeralis":
					for cluster in range(4):
						var at=Vector3(side*(13.8+cluster*.7),-2-cluster*.55,z+cluster*1.4)
						for tier in range(5): local.add("stone",at+Vector3(0,-tier*.36,0),Vector3(2.6-tier*.43,.39,2.1-tier*.34))
						for tip in range(3):
							for tier in range(5-tip): local.add("window",at+Vector3((tip-1)*.45,.2+tier*.24,0),Vector3(.32-tier*.04,.25,.32-tier*.04))
				else:
					for rib in range(5):
						var at=Vector3(side*(17+rib*.65),-3,z+(rib-2)*1.4)
						for tier in range(9-rib): local.add("coal",at+Vector3(0,tier*.48,0),Vector3(1.5-tier*.08,.5,1.25-tier*.07))
		world.block_count+=local.finish(node)
	# Station floor-edge conduits and service recess dressings are clear of its central aisle.
	var origin: Vector3=world.threshold.ORIGIN
	for z in [25,-18,-68]:
		for side in [-1,1]:
			for i in range(8):
				b.add("iron",origin+Vector3(side*16.5,.18,z+i*.45),Vector3(.2,.22,.38))
				b.add("gold",origin+Vector3(side*16.5,.31,z+i*.45),Vector3(.22,.04,.14))

func _path(x: float,z: float) -> bool:
	match region.id:
		"frostmere": return preload("res://scripts/town_layout.gd").path_at(x,z) or Terrain.path_at(x,z) or (absf(z+16)<3 and x> -3 and x<35)
		"mountain": return preload("res://scripts/wyrmkeep_detail.gd").path_at(x,z)
		"archive_chapter": return preload("res://scripts/pinehall_detail.gd").path_at(x,z)
		"shore": return absf(x-22)<3.3 or (z>0 and absf(z-14)<2.8) or (z>23 and z<29 and x<5)
		"winter": return absf(x)<5
		_: return absf(x)<3
func _streets() -> void:
	if region.id in ["convergence","frostmere"]: return
	var bounds: Rect2=region.bounds
	for x in range(int(bounds.position.x),int(bounds.end.x)):
		for z in range(maxi(-45,int(bounds.position.y)),int(bounds.end.y)):
			if not _path(x,z): continue
			var p=Vector3(x,_height(Vector3(x,0,z)),z)
			var at: Vector3=region.origin+p
			var blocked:=false
			for rect in obstacles:
				if rect.grow(.4).has_point(Vector2(at.x,at.z)): blocked=true; break
			if blocked: continue
			# Fine, worn stones with earth still visible between them, laid flush to the route.
			for row in range(2):
				for col in range(2):
					ground.add("path" if rng.randf()>.22 else "worn_path",at+Vector3(-.25+col*.5+rng.randf_range(-.03,.03),.055,-.25+row*.5),Vector3(.43,.055,.43),rng.randf_range(-.08,.08))
