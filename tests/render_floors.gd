extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(6): await physics_frame
	var p=w.player; assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false)
	p.position=Vector3(-10,.3,-3); p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.5
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/plank-floor.png")
	print("FLOORS_RENDER_COMPLETE"); quit()
