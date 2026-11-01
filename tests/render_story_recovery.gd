extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false)
	var s=w.player.character; var c=w.convergence
	s.story_completed=c.REQUIRED.duplicate(); c.enter()
	s.convergence.accepted=true; s.convergence.supplies=true; s.convergence.evidence=c.REQUIRED.duplicate()
	s.blueprints.append("transit_regulator"); s.materials.clear()
	w.player.position=c.ORIGIN+c.NODES.supplies+Vector3(0,.1,1.4); c.open_dialog("supplies")
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/story-recovery.png")
	print("STORY_RECOVERY_RENDER_COMPLETE"); quit()
