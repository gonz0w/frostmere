extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(18): await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	world.capture_done=true
	assert(not world.player.character.persist and not world.atlas.persist)
	if "--mountain-preview" in OS.get_cmdline_user_args():
		assert(world.player.character.stonewake.rewarded and world.player.character.adventure.rewarded)
		assert(world.player.character.save_to("user://mountain-preview-check.json"))
		var probe = load("res://scripts/character_state.gd").new()
		assert(probe.load_from("user://mountain-preview-check.json"))
		DirAccess.remove_absolute("user://mountain-preview-check.json")
	world.player.character.story_completed=["stonewake"]
	world.mountain.enter()
	world.hud.notice_time=0
	await capture("res://build/wyrmkeep-arrival.png")
	world.player.position=world.mountain.ORIGIN+world.mountain.NODES.council+Vector3(0,0.1,1.4)
	world.interact_nearby()
	await capture("res://build/wyrmkeep-council.png")
	world.mountain.close_dialog(); world.player.set_paused(false)
	world.player.map_open=true; world.player.set_paused(true); world.hud.world_map.set_view(true)
	await capture("res://build/wyrmkeep-map.png")
	world.hud.world_map.close()
	world.player.position=world.mountain.ORIGIN+Vector3(0,0.3,-48)
	await capture("res://build/wyrmkeep-outpost.png")
	for enemy in world.mountain.enemies: enemy.receive_damage(10000)
	for id in ["council","stoneguard","stormweaver","ledger","council","stoneguard"]:
		world.mountain.close_dialog(); world.player.set_paused(false)
		world.player.position=world.mountain.ORIGIN+world.mountain.NODES[id]+Vector3(0,0.1,1.4)
		world.interact_nearby()
		if id=="council": world.mountain.act("settle:accord" if world.player.character.mountain.ledger else "accept")
		elif id=="ledger": world.mountain.act("ledger")
		else: world.mountain.act("hear")
	await capture("res://build/wyrmkeep-clan-oath.png")
	world.queue_free(); await process_frame
	print("MOUNTAIN_RENDERS_COMPLETE"); quit()
