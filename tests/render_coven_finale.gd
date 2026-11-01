extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var c=world.roots; var s=p.character
	assert(not s.persist and not world.atlas.persist)
	s.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for e in c.enemies: e.set_physics_process(false)
	s.roots.choice="wild"; s.roots.rewarded=true; s.roots.coven_started=true; s.roots.coven_beds=["bed_west","bed_east","bed_south"]; s._commit()
	s.roots.coven_oath="shelter"; s.roots.debt_started=true; s.roots.debt_evidence=["foundation","spring","steward"]
	s.roots.debt_choice="cistern"; s.roots.promise_started=true; s.roots.promise_heard=["keeper","steward","record"]
	p.position=c.ORIGIN+c.NODES.heart+Vector3.BACK*1.5; c.open_dialog("heart"); await capture("coven-finale-choice")
	c.act("promise_choose:shared"); await capture("coven-finale-shared")
	print("COVEN_FINALE_RENDER_COMPLETE"); quit()
