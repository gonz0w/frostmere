extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	assert(not world.player.character.persist and not world.atlas.persist)
	world.player.set_physics_process(false); world.player.set_process_unhandled_input(false)
	world.adventure.open_dialog(); await capture("humor-edda"); world.adventure.close_dialog()
	world.threshold.open_dialog("keeper"); await capture("humor-rook"); world.threshold.close_dialog()
	world.archive_chapter.open_dialog("lantern"); await capture("humor-mereth"); world.archive_chapter.close_dialog()
	print("DIALOGUE_HUMOR_RENDER_COMPLETE"); quit()
