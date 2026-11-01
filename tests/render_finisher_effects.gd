extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var r=world.realms
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process(false); p.set_process_unhandled_input(false)
	for actor in r.enemies: actor.set_physics_process(false)
	for entry in [["aeralis",2,"sword"],["crucible",5,"mace"]]:
		r.enter(entry[0],true); world.hud.notice_time=0
		var e=r.enemies[entry[1]]; e.visible=true; e.health=5
		p.character.equip(p.character.add_item("iron_"+entry[2]),"main_hand")
		p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO; p.set_third_person(false)
		assert(p.activate_finisher()); p.update_finisher(p.finisher_move.impact+.01); assert(e.dead)
		var burst=r.get_children().filter(func(n): return n.has_meta("finisher_surface"))[-1]
		burst.set_process(false); burst._process(.22)
		p.cancel_finisher(); p.position=e.global_position+Vector3(0,0,7); p.pivot.rotation.x=.02
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/finisher-"+entry[0]+"-breakup.png")
	print("FINISHER_EFFECTS_RENDER_COMPLETE"); quit()
