extends SceneTree
var failures:=0
var checks:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+message)
	else: print("PASS "+message)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; p.set_physics_process(false); p.collision_mask=1
	for e in w.wilderness.enemies: e.set_physics_process(false)
	p.position=Vector3(21,1,-9); p.velocity=Vector3.ZERO
	var low:=100.0; var high:=-100.0; var supported:=true
	for i in range(330):
		p.velocity=Vector3(0,-3,3); p.move_and_slide(); await physics_frame
		if i>35:
			low=minf(low,p.position.y); high=maxf(high,p.position.y)
			if absf(p.position.y-preload("res://scripts/refined_riverbank.gd").height_at(p.position.x,p.position.z))>.22: supported=false
	check(p.position.z>6,"Player crosses the new bank without snagging")
	check(supported and high-low>.12,"Walking collision follows the bank's elevation changes")
	p.position=Vector3(6,.3,-16)
	for i in range(340):
		p.velocity=Vector3(3,-2,0); p.move_and_slide(); await physics_frame
	check(p.position.x>21,"Existing bridge remains traversable from village to east bank")
	check(w.footstep_at(Vector3(21,.3,0))!="water","Raised bank retains a land footstep surface")
	for z in [-6.0,1.0,6.0]:
		var edge: float=preload("res://scripts/refined_riverbank.gd").shore_x(z)
		var x: float=lerpf(edge,18,.70)
		var query=PhysicsRayQueryParameters3D.create(Vector3(x,2,z),Vector3(x,-2,z),1)
		var hit: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.y-preload("res://scripts/refined_riverbank.gd").shelf_height(.70))<.04 and hit.normal.y>.6,"Scalloped shelf has matching upward collision at z="+str(z))
	for z in [-6.0,1.0,6.0]:
		var edge: float=preload("res://scripts/refined_riverbank.gd").west_edge(z)
		var x: float=lerpf(10,edge,.70)
		var query=PhysicsRayQueryParameters3D.create(Vector3(x,2,z),Vector3(x,-2,z),1)
		var hit: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and absf(hit.position.y-preload("res://scripts/refined_riverbank.gd").shelf_height(.30))<.04 and hit.normal.y>.6,"Western shelf joins land with correct collision at z="+str(z))
	var channel=PhysicsRayQueryParameters3D.create(Vector3(14,1,0),Vector3(14,-3,0),1)
	var bed: Dictionary=w.get_world_3d().direct_space_state.intersect_ray(channel)
	check(not bed.is_empty() and bed.position.y< -1,"New shelves leave the central river channel open")
	w.queue_free(); await process_frame
	print("RIVERBANK_COMPLETE checks=%d failures=%d"%[checks,failures]); quit(1 if failures else 0)
