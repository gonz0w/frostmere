extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true; w.audio.enabled=false
	for i in range(5): await physics_frame
	var p=w.player; p.set_physics_process(false); p.set_process_unhandled_input(false)
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("threshold")
	for id in ["outfitter","apothecary","mountain_smith"]:
		var data: Dictionary=w.shops.trade.shop(id); var at: Array=data.position
		p.position=Vector3(at[0],at[1],at[2]); w.shops.open(id)
		for i in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/merchant-"+id+".png")
		w.shops.close()
	print("MERCHANT_VOICE_RENDER_COMPLETE"); quit()
