extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.choir
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://choir-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://choir-preview-check.json")); DirAccess.remove_absolute("user://choir-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("ember-caldera-arrival")
	p.position=c.ORIGIN+Vector3(0,.2,-15); p.rotation=Vector3.ZERO
	await capture("ember-caldera-sanctuary")
	p.character.choir.accepted=true; p.position=c.ORIGIN+c.NODES.ember+Vector3(0,.1,1.4); c.open_dialog("ember")
	await capture("ember-caldera-resonator")
	c.close_dialog(); p.set_paused(false); p.character.choir.song=["ember","ash","stone"]; p.character.choir.activated=true; p.character._commit()
	p.position=c.ORIGIN+Vector3(0,.2,-48); p.rotation=Vector3.ZERO
	await capture("ember-caldera-vault")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("ember-caldera-map")
	world.queue_free(); await process_frame
	print("CHOIR_RENDERS_COMPLETE"); quit()
