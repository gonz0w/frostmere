extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.lens
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("archive"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.lens.debt_started=true; p.character.lens.debt_instruments=["west_cache","east_cache"]; p.character.lens.defeated=["lens_0","lens_1"]
	p.position=c.ORIGIN+c.NODES.keeper+Vector3(0,.1,1.4); w.interact_nearby()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/astronomer-debt-choice.png")
	print("ASTRONOMER_DEBT_RENDER_COMPLETE"); quit()
