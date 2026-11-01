extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.shore
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.story_completed.append("archive"); c.enter(); w.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true; camera.environment=p.camera.environment
	for shot in [["saltbreak-waterfront",Vector3(9,9,44),Vector3(-9,0,26)],["saltbreak-pier",Vector3(4,3,26),Vector3(-20,1,26)]]:
		camera.position=c.ORIGIN+shot[1]; camera.look_at(c.ORIGIN+shot[2])
		for i in range(6): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/"+shot[0]+".png")
	w.queue_free(); await process_frame; print("SALTBREAK_DETAIL_RENDER_COMPLETE"); quit()
