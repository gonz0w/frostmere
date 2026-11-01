extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false)
	for e in world.wilderness.enemies: e.set_physics_process(false)
	for index in [0,3,11]:
		var e=world.wilderness.enemies[index]
		p.global_position=e.global_position+Vector3(0,0,3.5 if index<11 else 8); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0; e.rotation.y=PI
		await capture("wilderness-"+e.species)
	print("WILDERNESS_RENDER_COMPLETE"); quit()
