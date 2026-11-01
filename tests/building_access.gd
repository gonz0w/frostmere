extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	assert(DisplayServer.get_name()=="headless")
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(5): await physics_frame
	var p=w.player; assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.collision_mask=1
	check(w.building_records.size()==25,"All 25 existing buildings have authored profiles")
	var names: Array=[]; var identities: Array=[]; var count:=0
	for r in w.building_records:
		names.append(r.name); identities.append(r.id); count+=r.cuboids
		var origin: Vector3=r.origin
		p.position=origin+Vector3(0,.3,r.depth/2+2.5); p.velocity=Vector3.ZERO
		for step in range(130):
			p.velocity=Vector3(0,-1,-3); p.move_and_slide(); await physics_frame
			if p.position.z<origin.z+r.depth/2-1.1: break
		check(p.position.z<origin.z+r.depth/2-1.1 and p.position.y>.1,"Walk through porch and doorway: "+r.id)
		for step in range(130):
			p.velocity=Vector3(0,-1,3); p.move_and_slide(); await physics_frame
			if p.position.z>origin.z+r.depth/2+1.8: break
		check(p.position.z>origin.z+r.depth/2+1.8,"Walk back outside: "+r.id)
		# Stand in the old entry aisle and cast a body-height capsule sideways.
		p.position=origin+Vector3(0,.3,r.depth/2-1.2)
		check(w.session_save.supported_position(p.position,p),"Saved entry aisle stays supported: "+r.id)
	var unique_names: Dictionary={}; var unique_ids: Dictionary={}
	for n in names: unique_names[n]=true
	for n in identities: unique_ids[n]=true
	check(unique_names.size()==25 and unique_ids.size()==25,"No duplicate building identities or shop signs")
	# Floor and roof probes exercise actual finished collision, not only metadata.
	for r in w.building_records:
		var at: Vector3=r.origin+Vector3(.5,1,r.depth*.2)
		var query=PhysicsRayQueryParameters3D.create(at,at-Vector3.UP*2,1)
		var hit=p.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty() and hit.position.y>r.origin.y+.1,"Room floor supports player: "+r.id)
	print("BUILDING_GEOMETRY cuboids=%d world=%d"%[count,w.block_count])
	w.queue_free(); await process_frame
	print("BUILDING_ACCESS_COMPLETE checks=%d failures=%d"%[checks,failures]); quit(1 if failures else 0)
