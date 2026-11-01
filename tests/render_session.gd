extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	for i in range(6): await physics_frame
	var p: CharacterBody3D=world.player; var session: Node=world.session_save
	assert(not p.character.persist and not world.atlas.persist)
	for enemy in world.winter.enemies: enemy.set_physics_process(false)
	p.position=world.winter.ORIGIN+Vector3(3,.2,14); p.rotation.y=.3; p.set_third_person(false); p.health=47; p.magicka=35; p.stamina=26
	for i in range(12): await physics_frame
	assert(p.character.save_to("user://session-render.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://session-render.json"))
	world.winter.leave(); assert(session.restore(loaded.session)); world.hud.notice_time=0
	await capture("session-resumed")
	p.set_paused(true); await capture("session-pause")
	DirAccess.remove_absolute("user://session-render.json")
	world.queue_free(); await process_frame; print("SESSION_RENDERS_COMPLETE"); quit()
