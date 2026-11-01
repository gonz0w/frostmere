extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true; world.audio.enabled=false
	var p: CharacterBody3D=world.player; var r: Node3D=world.realms; var e: Node=r.ending
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://ending-preview.json")); var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://ending-preview.json")); DirAccess.remove_absolute("user://ending-preview.json")
	world.hud.notice_time=0
	for enemy in r.enemies: enemy.set_physics_process(false)
	var origin: Vector3=r.vector(r.definitions.crucible.origin)
	p.position=origin+Vector3(0,.2,-27); p.set_third_person(false); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0
	await capture("ending-engine-active")
	for enemy in r.enemies:
		if enemy.enemy_id.begins_with("crucible"): enemy.receive_damage(10000,p); r.loot(enemy.enemy_id)
	p.position=origin+e.CONTROL+Vector3(0,.1,1.4); assert(e.shutdown())
	p.position=origin+Vector3(0,.2,-29); await capture("ending-engine-stopped")
	p.position=origin+Vector3(0,.1,19); r.interact("leave"); assert(e.dialog.visible)
	await capture("ending-homecoming")
	p.character.roots.choice="wild"; p.character.shore.choice="harbor"; p.character.mountain.clan="stoneguard"; e.open_chronicle(); await capture("ending-choices")
	e.options.get_child(1).pressed.emit(); assert(p.character.finale.reward=="bow")
	await capture("ending-heirloom")
	world.hud.notice_time=0; world.adventure.feedback_time=0
	e.close_dialog(); p.set_paused(false); p.position=e.HOME+Vector3(0,.2,4); p.rotation=Vector3.ZERO
	await capture("ending-chronicle")
	world.queue_free(); await process_frame; print("ENDING_RENDERS_COMPLETE"); quit()
