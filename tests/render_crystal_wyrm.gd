extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var r=world.realms; var e=r.enemies[2]
	assert(not p.character.persist and not world.atlas.persist)
	r.enter("aeralis",true); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3(0,0,8); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.03; p.set_third_person(false); world.hud.notice_time=0
	e.visible=true; e.rotation.y=PI; await capture("prismwing")
	e.cooldown=0; e._physics_process(.02); e._physics_process(.8); await capture("prismwing-fan-charge")
	e.windup=0
	e.health=e.maximum_health*.5; e._physics_process(.02); await capture("prismwing-fractured")
	p.position=e.global_position+Vector3(0,0,3.5); e.cooldown=0; e.stagger_time=0; e._physics_process(.02)
	e._physics_process(.5)
	p.position=e.global_position+Vector3(0,0,7); await capture("prismwing-bite")
	print("CRYSTAL_WYRM_RENDER_COMPLETE"); quit()
