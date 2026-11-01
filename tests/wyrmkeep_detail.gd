extends SceneTree
const Detail = preload("res://scripts/wyrmkeep_detail.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p=w.player; var c=w.mountain
	p.set_physics_process(false)
	check(not p.character.persist and not w.atlas.persist,"Isolated town fixture")
	p.character.story_completed.append("stonewake"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)
	var capsule=CapsuleShape3D.new(); capsule.radius=.3; capsule.height=1.6
	var query=PhysicsShapeQueryParameters3D.new(); query.shape=capsule; query.collision_mask=1
	for lane_index in range(Detail.LANES.size()):
		var lane=Detail.LANES[lane_index]; var clear:=true; var supported:=true
		for j in range(lane.size()-1):
			var count: int=ceili(lane[j].distance_to(lane[j+1])/.5)
			for i in range(count+1):
				var at: Vector2=lane[j].lerp(lane[j+1],float(i)/count)
				var point: Vector3=c.ORIGIN+Vector3(at.x,.1,at.y)
				query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*1.1)
				if not p.get_world_3d().direct_space_state.intersect_shape(query).is_empty():
					if clear: print("BLOCKED lane=%d at=%s" % [lane_index,at])
					clear=false
				if not w.session_save.supported_position(point,p):
					if supported: print("UNSUPPORTED lane=%d at=%s" % [lane_index,at])
					supported=false
		check(clear,"Player-width lane avoids solid props and walls: "+str(lane_index))
		check(supported,"Lane stays on supported ground: "+str(lane_index))
	for id in ["council","stoneguard","stormweaver","forge","enchant","supply_west","supply_east","hearth","memorial"]:
		p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4)
		check(w.session_save.supported_position(p.position,p),"Existing interaction approach supported: "+id)
	query.transform=Transform3D(Basis.IDENTITY,c.ORIGIN+Detail.WELL+Vector3.UP*.9)
	check(not p.get_world_3d().direct_space_state.intersect_shape(query).is_empty(),"Well has physical collision")
	check(w.footstep_at(c.ORIGIN+Vector3(0,0,35))=="step_stone","Paved arrival lane uses stone footsteps")
	check(w.footstep_at(c.ORIGIN+Vector3(-40,0,35))=="step_snow","Unpaved winter ground uses snow footsteps")
	check(w.footstep_at(c.ORIGIN+Vector3(-22,.3,-14))=="step_wood","Clan hall retains wooden interior footsteps")
	w.queue_free(); await process_frame
	print("WYRMKEEP_DETAIL_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
