extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.shore
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("archive"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.shore.silver_stage=3; p.character.shore.defeated=["shore_1"]
	p.position=c.ORIGIN+c.NODES.harbor+Vector3(0,.1,1.3); w.interact_nearby()
	await capture("silver-nets-choice")
	c.act("silver_protect"); c.close_dialog(); p.set_paused(false)
	var uid: String=""
	for id in p.character.inventory:
		if p.character.inventory[id].base_id=="netmender_ring": uid=id
	var menu=w.hud.workshop; menu.open(); menu.selected=uid; menu.refresh()
	await capture("netmender-band")
	print("SILVER_NETS_RENDER_COMPLETE"); quit()
