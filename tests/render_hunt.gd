extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(5): await physics_frame
	var p=world.player; var h=world.hunts
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.position=h.POSITION+Vector3.BACK; h.open(); await capture("hunt-board")
	h.accept()
	for id in h.TARGETS:
		p.character.wilderness.defeated.append(id); p.character.wilderness.looted.append(id)
	h.refresh(); await capture("hunt-rewards")
	h.claim("mossfang_blade"); await capture("hunt-complete")
	assert(p.character.save_to("user://hunt-preview.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://hunt-preview.json")); DirAccess.remove_absolute("user://hunt-preview.json")
	print("HUNT_RENDER_COMPLETE"); quit()
