extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p=w.player; var c=w.shore; p.set_physics_process(false)
	check(not p.character.persist and not w.atlas.persist,"Isolated coast fixture")
	var shape=CapsuleShape3D.new(); shape.radius=.3; shape.height=1.6
	var q=PhysicsShapeQueryParameters3D.new(); q.shape=shape; q.collision_mask=1
	for z in [25.3,26.0,26.7]:
		var clear:=true; var supported:=true
		for i in range(59):
			var at: Vector3=c.ORIGIN+Vector3(-24+i*.5,.2,z)
			q.transform=Transform3D(Basis.IDENTITY,at+Vector3.UP*1.1)
			if not p.get_world_3d().direct_space_state.intersect_shape(q).is_empty(): clear=false
			if not w.session_save.supported_position(at,p): supported=false
		check(clear,"Player-width passage along pier: "+str(z))
		check(supported,"Supported pier and shore approach: "+str(z))
	for x in [-23.85,-19.3,-9.55,-3.7,2.15,4.2]:
		check(w.footstep_at(c.ORIGIN+Vector3(x,.2,26))=="step_wood","Plank footstep at "+str(x))
	check(w.footstep_at(c.ORIGIN+Vector3(22,0,36))=="step_stone","Existing coastal road keeps stone footsteps")
	check(not w.session_save.supported_position(c.ORIGIN+Vector3(-23,.2,30),p),"New scenery adds no invisible floor beside seaward pier")
	for id in ["silver_net","charter","ash_factor","light_keeper","harbor","salvager"]:
		var at: Vector3=c.ORIGIN+c.NODES[id]+Vector3(0,.2,1)
		check(w.session_save.supported_position(at,p),"Existing quest approach supported: "+id)
	w.queue_free(); await process_frame
	print("SALTBREAK_DETAIL_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
