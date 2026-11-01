extends "res://tests/render_building_review.gd"
func run() -> void:
	assert("--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless")
	root.size=Vector2i(1280,800)
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.process_mode=Node.PROCESS_MODE_DISABLED
	hide_labels(w); w.player.hide()
	camera=Camera3D.new(); root.add_child(camera); camera.current=true; camera.fov=68; camera.far=450
	var original: Environment
	for node in w.get_children():
		if node is WorldEnvironment: original=node.environment
	for id in ["aeralis","crucible"]:
		assert(w.realms.enter(id,true)); hide_labels(w)
		assert(w.realms.atmospheres[id].visible)
		var origin: Vector3=w.realms.roots[id].global_position
		await capture(id+"-arrival",id,"Landmarks",origin+Vector3(0,2,20),origin+Vector3(7,3,9))
		await capture(id+"-terrace",id,"Landmarks",origin+Vector3(0,2,-3),origin+Vector3(-8,4,-12))
		await capture(id+"-sanctum",id,"Landmarks",origin+Vector3(2,3,-25),origin+Vector3(0,7,-39))
		await capture(id+"-atmosphere",id,"Landmarks",origin+Vector3(0,2,16),origin+Vector3(-8,16,-20))
		w.realms.leave()
		assert(not w.realms.atmospheres[id].visible)
		for node in w.get_children():
			if node is WorldEnvironment: assert(node.environment == original)
	print("REALM_ATMOSPHERE_REVIEW_COMPLETE 8 captures; realm visibility and environment restoration verified")
	quit()
