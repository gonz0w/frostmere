extends SceneTree
const Terrain = preload("res://scripts/terrain_profile.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS " + label)
	else: failures += 1; push_error("FAIL " + label)
func run() -> void:
	check(is_equal_approx(Terrain.height_at(-28,-42),3.2) and is_equal_approx(Terrain.height_at(33,-52),2.8), "Western and eastern summits have distinct elevations")
	check(Terrain.height_at(0,0)==0 and Terrain.height_at(14,-16)==0 and Terrain.height_at(35,-35)==0, "Village, bridge and barrow approaches retain elevation")
	var safe := true
	var vertices=Terrain.collision_vertices()
	for i in range(0,vertices.size(),3):
		var normal=(vertices[i+1]-vertices[i]).cross(vertices[i+2]-vertices[i]).normalized()
		safe = safe and normal.y < -0.707
	check(safe, "All terrain triangles use Godot clockwise winding and stay within walkable slope limits")
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(5): await physics_frame
	var p=world.player; p.set_physics_process(false); p.collision_mask=1 # Isolate terrain from stationary test creatures.
	for e in world.wilderness.enemies: e.set_physics_process(false)
	p.invulnerable=1000
	for hill: Vector4 in Terrain.HILLS:
		p.position=Vector3(hill.x,0.15,hill.y+hill.w+1); p.velocity=Vector3.ZERO
		var peak := 0.0
		for step in range(500):
			var z: float=maxf(hill.y-hill.w-1,p.position.z-1)
			var target=Vector3(hill.x+sin((z-hill.y)*.25)*1.8,p.position.y,z)
			var direction=(target-p.position).normalized()
			p.velocity.x=direction.x*4; p.velocity.z=direction.z*4; p.velocity.y-=18.0/60.0
			p.move_and_slide(); peak=maxf(peak,p.position.y)
			await physics_frame
			if p.position.z<hill.y-hill.w-.5: break
		print("ROUTE ",hill.x," peak=",peak," finish=",p.position)
		check(peak>1.8, "Player climbs raised route at x="+str(hill.x))
		check(p.position.z<hill.y-hill.w-.5 and p.position.y<.5, "Player descends opposite side without jumping at x="+str(hill.x))
	p.position=Vector3(-28,Terrain.height_at(-28,-42)+.05,-42)
	var saved=world.session_save.capture()
	p.position=Vector3.ZERO
	check(world.session_save.restore(saved) and p.position.y>3, "Session resumes on elevated ground")
	var trees_supported := true
	for site in world.tree_sites:
		# Probe the finished ground: the refined riverbank has its own height profile.
		# Starting within the trunk ignores that collider and checks the soil beneath it.
		var q=PhysicsRayQueryParameters3D.create(site.position+Vector3.UP*.2,site.position-Vector3.UP*.35,1)
		var hit: Dictionary=p.get_world_3d().direct_space_state.intersect_ray(q)
		trees_supported=trees_supported and not hit.is_empty() and absf(hit.position.y-site.position.y)<.16
	check(trees_supported, "Tree roots meet actual terrain and refined riverbank collision")
	world.queue_free(); await process_frame
	print("TERRAIN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
