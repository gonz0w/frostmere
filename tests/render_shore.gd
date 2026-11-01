extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done=true
	var p: CharacterBody3D=world.player
	var c: Node3D=world.shore
	world.audio.enabled=false
	assert(not p.character.persist and not world.atlas.persist)
	assert(p.character.save_to("user://shore-preview-check.json"))
	var loaded=preload("res://scripts/character_state.gd").new(); assert(loaded.load_from("user://shore-preview-check.json")); DirAccess.remove_absolute("user://shore-preview-check.json")
	world.hud.notice_time=0
	for enemy in c.enemies: enemy.set_physics_process(false)
	await capture("black-shore-arrival")
	p.position=c.ORIGIN+Vector3(-2,.2,28); p.rotation.y=PI/2
	await capture("black-shore-dock")
	p.position=c.ORIGIN+Vector3(0,.2,-18); p.rotation=Vector3.ZERO
	await capture("black-shore-cave")
	p.position=c.ORIGIN+Vector3(21,.2,-45); p.rotation=Vector3.ZERO
	await capture("black-shore-wreck")
	p.character.shore.accepted=true; p.character.shore.heard=["harbor","salvager"]; p.character.shore.relays=["pump","relay"]; p.character.shore.log=true
	for enemy in c.enemies: enemy.receive_damage(10000)
	p.character.shore.core=true; p.character._commit()
	p.position=c.ORIGIN+c.NODES.navigation+Vector3(0,.1,1.4); c.open_dialog("navigation")
	await capture("black-shore-choice")
	assert(c.act("choose_navigation"))
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+Vector3(17,.2,-88); p.rotation=Vector3.ZERO
	await capture("black-shore-navigation")
	p.character.shore.choice="harbor"; p.character._commit(); world.adventure.feedback_time=0; c.feedback_time=0
	p.position=c.ORIGIN+Vector3(44,.2,18); p.rotation.y=0; p.pivot.rotation.x=.12
	await capture("black-shore-beacon")
	p.character.shore.identified=["blade","armor","focus"]
	p.position=c.ORIGIN+c.NODES.salvager+Vector3(0,.1,1.4); c.open_dialog("salvager")
	await capture("black-shore-identification")
	c.close_dialog(); p.set_paused(false); p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	await capture("black-shore-map")
	world.queue_free(); await process_frame
	print("SHORE_RENDERS_COMPLETE"); quit()
