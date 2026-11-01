extends SceneTree
const Detail=preload("res://scripts/pinehall_detail.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p=w.player; var c=w.archive_chapter; p.set_physics_process(false)
	check(not p.character.persist and not w.atlas.persist,"Isolated camp fixture")
	var shape=CapsuleShape3D.new(); shape.radius=.3; shape.height=1.6
	var q=PhysicsShapeQueryParameters3D.new(); q.shape=shape; q.collision_mask=1
	for lane in Detail.LANES:
		var clear:=true; var supported:=true
		for j in range(lane.size()-1):
			var count: int=ceili(lane[j].distance_to(lane[j+1])/.5)
			for i in range(count+1):
				var at: Vector2=lane[j].lerp(lane[j+1],float(i)/count)
				var point: Vector3=c.ORIGIN+Vector3(at.x,.1,at.y)
				q.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*1.1)
				if not p.get_world_3d().direct_space_state.intersect_shape(q).is_empty():
					if clear: print("BLOCKED ",at)
					clear=false
				if not w.session_save.supported_position(point,p): supported=false
		check(clear,"Camp lane has player-width clearance")
		check(supported,"Camp lane has continuous ground support")
	for entry in [[Vector3(0,0,35),"stone"],[Vector3(16,0,33),"grass"],[Vector3(-14,.3,4),"wood"],[Vector3(4,0,-32),"stone"]]:
		check(w.footstep_at(c.ORIGIN+entry[0])=="step_"+entry[1],"Actual camp floor surface: "+entry[1])
	for id in ["lantern","briar","forge","enchant","apprentice_notice","trial","notes"]:
		check(w.session_save.supported_position(c.ORIGIN+c.NODES[id]+Vector3(0,.2,1.4),p),"Existing quest approach: "+id)
	q.transform=Transform3D(Basis.IDENTITY,c.ORIGIN+Vector3(4,1.2,24))
	check(p.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"Rescued apprentice location remains clear")
	w.queue_free(); await process_frame
	print("PINEHALL_DETAIL_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
