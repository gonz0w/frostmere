extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false)
	for e in world.wilderness.enemies: e.set_physics_process(false)
	var views=[Vector3(0,.15,17),Vector3(-9,.15,20),Vector3(-3,14,36),Vector3(-10,.15,-19)]
	for i in range(views.size()):
		p.position=views[i]; p.rotation=Vector3.ZERO; p.pivot.rotation.x= -.55 if i==2 else 0
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/town-%d.png" % i)
	print("TOWN_RENDER_COMPLETE"); quit()
