extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.story_completed.append("stonewake"); w.mountain.enter(); w.hud.notice_time=0
	for enemy in w.mountain.enemies: enemy.set_physics_process(false)
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true
	for shot in [["wyrmkeep-lanes",Vector3(43,38,48),Vector3(0,0,-7)],["wyrmkeep-well",Vector3(17,5,1),Vector3(5,1,-15)]]:
		camera.position=w.mountain.ORIGIN+shot[1]; camera.look_at(w.mountain.ORIGIN+shot[2])
		for i in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/"+shot[0]+".png")
	w.queue_free(); await process_frame; print("WYRMKEEP_DETAIL_RENDER_COMPLETE"); quit()
