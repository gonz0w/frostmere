extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false); w.player.position=Vector3(-4,.15,-11)
	var uid: String=w.player.character.add_item("iron_staff",2)
	var menu=w.hud.workshop; menu.open("forge"); menu.tabs.select(menu.MODES.find("Improve")); menu.tabs.item_selected.emit(menu.MODES.find("Improve")); menu.selected=uid; menu.refresh()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/staff-scaling.png")
	print("STAFF_SCALING_RENDER_COMPLETE"); quit()
