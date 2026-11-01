extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(8): await physics_frame
	var p=w.player
	assert(not p.character.persist and not w.atlas.persist)
	p.set_process(false); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for e in w.wilderness.enemies: e.set_physics_process(false)
	p.avatar.hide(); p.first_person_hands.hide()
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true
	for e in [w.wilderness.enemies[0],w.wilderness.enemies[3]]:
		p.position=e.home+Vector3.BACK*1.5; e.cooldown=0
		e._physics_process(.01); e._physics_process(.5)
		camera.position=e.global_position+Vector3(2,1.4,3); camera.look_at(e.global_position+Vector3.UP)
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/bite-"+e.species+".png")
	print("WILD_BITES_RENDER_COMPLETE"); quit()
