extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.lens
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://lens-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://lens-preview-check.json")); DirAccess.remove_absolute("user://lens-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("sunken-lens-arrival")
	p.position=c.ORIGIN+Vector3(0,.2,-14); p.rotation=Vector3.ZERO
	await capture("sunken-lens-observatory")
	p.character.lens.accepted=true; p.position=c.ORIGIN+c.NODES.dawn+Vector3(0,.1,1.4); c.open_dialog("dawn")
	await capture("sunken-lens-mirror")
	c.close_dialog(); p.set_paused(false); p.character.lens.rotations={"dawn":1,"dusk":3,"crown":0}; p.character.lens.activated=true; p.character._commit()
	p.position=c.ORIGIN+Vector3(0,.2,-33); p.rotation=Vector3.ZERO
	await capture("sunken-lens-active")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("sunken-lens-map")
	world.queue_free(); await process_frame
	print("LENS_RENDERS_COMPLETE"); quit()
