extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var c=world.roots; var s=p.character; var e=c.enemies[3]
	assert(not s.persist and not world.atlas.persist)
	s.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for actor in c.enemies: actor.set_physics_process(false)
	s.roots.cleansed=["spring","stone","seed"]; s._commit(); e._physics_process(.016)
	e.position=c.ORIGIN+Vector3(0,.15,-45); e.home=e.global_position
	p.position=e.global_position+Vector3(4,0,9); p.rotation.y=atan2(4,9); p.set_third_person(false); p.pivot.rotation.x=.05; e.rotation.y=PI
	await capture("hollow-warden")
	e.begin_roots(); p.position+=Vector3.BACK*5; p.pivot.rotation.x=-.4
	await capture("hollow-root-warning")
	e.resolve_roots(); await capture("hollow-root-eruption")
	print("HOLLOW_WARDEN_RENDER_COMPLETE"); quit()
