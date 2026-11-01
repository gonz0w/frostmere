extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1; push_error("FAIL "+label)
	else: print("PASS "+label)
func clear_of_new_props(w: Node3D,p: Vector3) -> bool:
	var shape=CapsuleShape3D.new(); shape.radius=.32; shape.height=1.7
	var q=PhysicsShapeQueryParameters3D.new(); q.shape=shape; q.transform.origin=p+Vector3.UP*.9; q.collision_mask=1
	for hit in w.get_world_3d().direct_space_state.intersect_shape(q,64):
		if w.get_node("RegionalLandscape").is_ancestor_of(hit.collider): return false
	return true
func run() -> void:
	assert(DisplayServer.get_name()=="headless")
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(5): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false)
	var detail=w.get_node("RegionalLandscape")
	var coverage: Dictionary={}
	for r in detail.get_meta("placements"):
		if not coverage.has(r.region): coverage[r.region]={}
		coverage[r.region][r.kind]=int(coverage[r.region].get(r.kind,0))+1
	for id in coverage:
		check(not coverage[id].is_empty(),"Runtime scenery present: "+id)
	print("LANDSCAPE_COVERAGE "+JSON.stringify(coverage))
	for id in ["mountain","archive_chapter","shore","lens","roots","choir","convergence","winter","threshold"]:
		var chapter=w.get(id)
		var safe:=true
		for p in chapter.NODES.values(): safe=safe and clear_of_new_props(w,chapter.ORIGIN+p)
		check(safe,"All quest/service positions clear of new scenery: "+id)
	for route in [[Vector3.ZERO,preload("res://scripts/town_layout.gd").LANES],[Vector3(800,0,0),preload("res://scripts/wyrmkeep_detail.gd").LANES],[Vector3(-800,0,0),preload("res://scripts/pinehall_detail.gd").LANES]]:
		var safe:=true
		for lane in route[1]:
			for i in range(lane.size()-1):
				var a: Vector2=lane[i]; var b: Vector2=lane[i+1]
				var steps: int=ceili(a.distance_to(b)/.5)
				for j in range(steps+1):
					var p=a.lerp(b,float(j)/maxi(steps,1))
					safe=safe and clear_of_new_props(w,route[0]+Vector3(p.x,.1,p.y))
		check(safe,"Existing settlement walking lanes remain clear: "+str(route[0]))
	var coast_clear:=true
	for z in range(-50,49): coast_clear=coast_clear and clear_of_new_props(w,w.shore.ORIGIN+Vector3(22,0,z))
	check(coast_clear,"Saltbreak main road remains clear")
	var original: Environment
	for node in w.get_children():
		if node is WorldEnvironment: original=node.environment
	for id in w.atlas.quests:
		if id not in w.player.character.story_completed: w.player.character.story_completed.append(id)
	for repeat in range(2):
		for id in ["mountain","archive_chapter","shore","lens","roots","choir","convergence","winter"]:
			var chapter=w.get(id)
			check(chapter.enter(),"Enter regional atmosphere: "+id)
			for node in w.get_children():
				if node is WorldEnvironment: check(node.environment.sky!=original.sky,"Distinct sky: "+id)
			chapter.leave()
			for node in w.get_children():
				if node is WorldEnvironment: check(node.environment==original,"Restore home environment: "+id)
	check(not w.realms.roots.aeralis.visible and not w.realms.roots.crucible.visible,"Inactive realms cannot leak into other regions")
	check(w.realms.enter("aeralis",true) and w.realms.roots.aeralis.visible,"Aeralis geometry becomes visible on entry")
	check(w.realms.enter("crucible",true) and not w.realms.roots.aeralis.visible and w.realms.roots.crucible.visible,"Switching realms scopes all geometry")
	w.realms.leave()
	check(not w.realms.roots.crucible.visible,"Crucible hides on return")
	check(detail.get_meta("cuboids")<65000,"Added regional detail stays within bounded geometry budget")
	print("REGIONAL_LANDSCAPE_COMPLETE checks=%d failures=%d"%[checks,failures]); quit(1 if failures else 0)
