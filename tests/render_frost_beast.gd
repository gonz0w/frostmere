extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var e=world.wilderness.enemies[12]; var h=world.hunts
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	for actor in world.wilderness.enemies: actor.set_physics_process(false)
	p.set_third_person(false); p.position=e.home+Vector3(0,0,8); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.05
	e.rotation.y=PI; await capture("frost-beast")
	e.charge_cooldown=0; e._physics_process(.02); e._physics_process(.8); await capture("frost-beast-warning")
	e._physics_process(.51); e._physics_process(.12); await capture("frost-beast-charge")
	p.position=h.POSITION; h.selected="frostmaw"; h.open(); await capture("frost-hunt-board")
	print("FROST_BEAST_RENDER_COMPLETE"); quit()
