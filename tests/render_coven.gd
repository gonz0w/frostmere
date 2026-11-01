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
	p.position=c.ORIGIN+c.NODES.bed_south+Vector3(0,0,4); p.rotation.y=0; p.set_third_person(false); p.pivot.rotation.x=-.35
	await capture("coven-seedbed")
	p.position=c.ORIGIN+c.NODES.keeper+Vector3.BACK*1.5; c.open_dialog("keeper"); await capture("coven-oath")
	print("COVEN_RENDER_COMPLETE"); quit()
