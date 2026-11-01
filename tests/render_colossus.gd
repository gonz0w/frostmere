extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(8): await physics_frame
	var p=world.player; var e=world.wilderness.enemies[11]
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false)
	for actor in world.wilderness.enemies: actor.set_physics_process(false)
	p.global_position=e.global_position+Vector3(0,2,6); p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.2
	e.rotation.y=PI; e.start_slam(); e._physics_process(1.1)
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/colossus-slam.png")
	e._physics_process(.41)
	var debris=world.wilderness.get_node("GroundSlamDebris"); debris.set_process(false); debris._process(.24)
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/colossus-impact.png")
	print("COLOSSUS_RENDER_COMPLETE"); quit()
