extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(6): await physics_frame
	var p=world.player
	assert(not p.character.persist and not world.atlas.persist)
	p.set_process(false); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for e in world.wilderness.enemies: e.set_physics_process(false)
	var e=world.wilderness.enemies[0]
	p.position=e.position+Vector3.BACK*2; p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.2; e.health=5; e._update_label()
	for family in ["dagger","sword","mace"]:
		p.character.equip(p.character.add_item("iron_"+family),"main_hand")
		p.set_third_person(false); assert(p.activate_finisher()); p.update_finisher(p.finisher_move.impact*.6)
		await capture("finisher-"+family+"-first")
		p.set_third_person(true); await capture("finisher-"+family+"-third")
		p.cancel_finisher()
	var giant=world.wilderness.enemies[11]; giant.health=5
	p.position=giant.position+Vector3.BACK*2; p.rotation=Vector3.ZERO; p.pivot.rotation.x=.3; p.set_third_person(false)
	assert(p.activate_finisher()); p.update_finisher(p.finisher_move.impact+.01)
	await capture("finisher-stone-impact")
	p.cancel_finisher(); print("FINISHER_MOVES_RENDER_COMPLETE"); quit()
