extends SceneTree
const Ground=preload("res://scripts/pinehall_terrain.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p=w.player; var c=w.archive_chapter
	p.set_physics_process(false)
	check(not p.character.persist and not w.atlas.persist,"Isolated terrain fixture")
	p.character.story_completed.append("stonewake"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)
	for at in [Vector2(0,32),Vector2(-14,4),Vector2(14,4),Vector2(-23,26),Vector2(0,-65)]:
		check(Ground.height_at(at.x,at.y)==0,"Existing inhabited/quest ground stays flat: "+str(at))
	for hill in Ground.HILLS:
		var at: Vector3=c.ORIGIN+Vector3(hill.x,0,hill.y)
		var q=PhysicsRayQueryParameters3D.create(at+Vector3.UP*10,at-Vector3.UP,1)
		var hit: Dictionary=p.get_world_3d().direct_space_state.intersect_ray(q)
		check(not hit.is_empty() and absf(hit.position.y-(Ground.height_at(hill.x,hill.y)-.1))<.05,"Hill collision matches its visible summit")
		check(w.footstep_at(at+Vector3.UP*(Ground.height_at(hill.x,hill.y)+.1))=="step_grass","Raised forest ground uses grass footsteps")
	var gentle:=true
	for x in range(-42,43):
		for z in range(-81,46):
			var dx: float=Ground.height_at(x+.5,z)-Ground.height_at(x-.5,z)
			var dz: float=Ground.height_at(x,z+.5)-Ground.height_at(x,z-.5)
			if Vector2(dx,dz).length()>.7: gentle=false
	check(gentle,"All authored slope gradients stay below the walking limit")
	p.position=c.ORIGIN+Vector3(25,.2,-56); p.velocity=Vector3.ZERO
	for i in range(360):
		p.velocity.x=3; p.velocity.z=0; p.velocity.y-=18.0/60
		p.move_and_slide(); await physics_frame
		if p.position.x>=c.ORIGIN.x+35: break
	print("CLIMB position=",p.position-c.ORIGIN," floor=",p.is_on_floor())
	check(p.position.x>c.ORIGIN.x+34 and p.position.y>3 and p.is_on_floor(),"Actual player climbs the eastern rise without jumping")
	var saved: Dictionary=w.session_save.capture()
	check(w.session_save.restore(saved) and p.position.distance_to(w.session_save.vector(saved.position))<.01,"Elevated player position restores on supported terrain")
	saved.position=w.session_save.vec(c.ORIGIN+Vector3(35,.1,-56))
	check(w.session_save.restore(saved) and p.position.distance_to(c.ORIGIN+Vector3(0,.2,32))<.1,"Older flat-ground save under a new hill falls back to camp")
	check(Ground.tree_sites().size()>=30 and Ground.tree_sites().size()<38,"Varied forest retains density and clears western building")
	w.queue_free(); await process_frame
	print("PINEHALL_TERRAIN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
