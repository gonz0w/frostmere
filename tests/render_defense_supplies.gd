extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var s=p.character
	assert(not s.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	s.story_completed.append("returning_light"); s.story_completed.append("winter_siege")
	for area in ["winter","seal"]:
		var c=w.get(area); c.enter(); s.get(area).accepted=true
		for enemy in c.enemies: enemy.set_physics_process(false)
		p.position=c.ORIGIN+c.NODES.supplies+Vector3(0,.1,1.4); c.open_dialog("supplies")
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/"+area+"-combat-reserves.png")
		c.close_dialog(); p.set_paused(false); c.leave()
	print("DEFENSE_SUPPLIES_RENDER_COMPLETE"); quit()
