extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false)
	for e in world.wilderness.enemies: e.set_physics_process(false)
	for i in range(3):
		var hill: Vector4=world.Terrain.HILLS[i]
		p.position=Vector3(hill.x,world.Terrain.height_at(hill.x,hill.y+hill.w*.5)+.15,hill.y+hill.w*.5)
		p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.1
		for frame in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/terrain-%d.png" % i)
	print("TERRAIN_RENDER_COMPLETE"); quit()
