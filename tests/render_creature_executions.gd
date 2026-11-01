extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var r=world.realms; var t=world.threshold
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process(false); p.set_process_unhandled_input(false)
	for actor in r.enemies+t.enemies: actor.set_physics_process(false)
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	p.character.threshold.power=true; p.character.threshold.air=true
	for e in [t.enemies[5],r.enemies[2],r.enemies[5]]:
		if e.adventure==r:
			t.inside=false
			r.enter("aeralis" if e==r.enemies[2] else "crucible",true)
		else: t.inside=true
		e.rotation.y=PI; e.visible=true; e.health=5
		p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
		assert(p.activate_finisher()); p.update_finisher(.4); assert(not e.dead)
		p.position=e.global_position+Vector3(5,0,7); p.look_at(Vector3(e.global_position.x,p.position.y,e.global_position.z)); p.pivot.rotation.x=-.05; p.set_third_person(false)
		world.hud.notice_time=0
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/execution-"+e.finisher_surface()+".png")
		p.cancel_finisher()
	print("CREATURE_EXECUTIONS_RENDER_COMPLETE"); quit()
