extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var c=world.lens; var e=c.enemies[4]
	assert(not p.character.persist and not world.atlas.persist)
	p.character.story_completed.append("archive"); c.enter(); p.character.lens.activated=true; p.character._commit()
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	for actor in c.enemies: actor.set_physics_process(false)
	p.position=e.home+Vector3(2,0,9); p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.05; p.set_third_person(false); world.hud.notice_time=0
	e.visible=true; e.rotation.y=PI; await capture("solar-scorpion")
	e.begin_beam(); p.position+=Vector3.LEFT*4; p.pivot.rotation.x=-.25; await capture("solar-warning")
	e.resolve_beam(); await capture("solar-beam")
	print("SOLAR_SCORPION_RENDER_COMPLETE"); quit()
