extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var c: Node3D=world.threshold
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://threshold-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://threshold-preview-check.json")); DirAccess.remove_absolute("user://threshold-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("threshold-airlock")
	p.position=c.ORIGIN+c.NODES.keeper+Vector3(0,.1,1.4); c.open_dialog("keeper")
	await capture("threshold-engineer")
	c.close_dialog(); p.set_paused(false); p.character.equip(p.character.add_item("station_rifle",1),"main_hand")
	p.position=c.ORIGIN+Vector3(0,.2,-20); p.rotation=Vector3.ZERO
	await capture("threshold-security")
	p.character.threshold.accepted=true; p.character.threshold.power=true; p.character.threshold.air=true; p.character._commit()
	p.position=c.ORIGIN+Vector3(3,.2,-77); p.rotation=Vector3.ZERO; p.set_third_person(false); p.pivot.rotation.x=.1
	await capture("threshold-observation")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("threshold-map")
	p.map_open=false; p.set_paused(false); c.leave(); world.lens.enter()
	assert(world.lens.enemies[4].dead)
	for enemy in world.lens.enemies: enemy.set_physics_process(false)
	p.position=c.TRAIL+Vector3(0,.2,4); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0
	await capture("threshold-departure-gate")
	world.queue_free(); await process_frame
	print("THRESHOLD_RENDERS_COMPLETE"); quit()
