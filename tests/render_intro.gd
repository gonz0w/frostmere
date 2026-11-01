extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.intro.start(); w.intro.set_process(false); w.player.set_physics_process(false)
	w.player.set_third_person(false); w.player.position=w.intro.ORIGIN+Vector3(0,.1,-1.5)
	w.player.pivot.rotation.x=.12
	w.intro.interact(); w.intro.advance(3.5)
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/dark-intro.png")
	w.intro.finish()
	w.intro.advance(.375)
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/intro-arrival-fade.png")
	w.intro.advance(1)
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/intro-arrival.png")
	print("INTRO_RENDER_COMPLETE"); quit()
