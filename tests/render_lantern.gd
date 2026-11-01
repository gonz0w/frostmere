extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var c=world.archive_chapter; var s=p.character
	assert(not s.persist and not world.atlas.persist)
	s.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for e in c.enemies: e.set_physics_process(false)
	s.archive.accepted=true; s.archive.heard=["lantern","briar"]; s.archive.atlas=true; s.archive.recipient="lantern"; s.archive.lantern_trial="testimony"
	p.position=c.ORIGIN+c.NODES.trial+Vector3.BACK*1.5; c.open_dialog("trial"); await capture("lantern-trial")
	c.act("trial_answer:witness"); c.close_dialog(); p.position=c.ORIGIN+c.NODES.lantern+Vector3.BACK*1.5; c.open_dialog("lantern"); await capture("lantern-oath")
	print("LANTERN_RENDER_COMPLETE"); quit()
