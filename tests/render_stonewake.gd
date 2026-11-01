extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(16): await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.capture_done = true
	assert(not world.player.character.persist and not world.atlas.persist, "Story preview must isolate both saves")
	world.adventure.accept_quest()
	world.adventure.mark_defeated("captain")
	world.adventure.loot_enemy("captain")
	world.adventure.reward_quest()
	var story: Node3D = world.stonewake
	var p: CharacterBody3D = world.player
	p.position = story.KEEPER + Vector3(0, 0.1, 1.5)
	world.interact_nearby()
	await capture("res://build/stonewake-keeper.png")
	story.action.pressed.emit()
	story.close_dialog(); p.set_paused(false)
	var ward: Dictionary = story.WARDS[0]
	p.position = ward.position + Vector3(0, 0.1, 1.5)
	world.interact_nearby()
	await capture("res://build/stonewake-runes.png")
	story.close_dialog(); p.set_paused(false)
	for entry: Dictionary in story.WARDS:
		p.position = entry.position + Vector3(0, 0.1, 1.5)
		world.interact_nearby()
		story.choose_rune(entry.answer)
		story.close_dialog(); p.set_paused(false)
	p.position = story.RELIC + Vector3(0, 0.1, 2)
	world.interact_nearby()
	story.close_dialog(); p.set_paused(false)
	p.position = story.RELIC + Vector3(0, 0.1, 5)
	p.rotation = Vector3.ZERO
	for landmark: Dictionary in world.landmarks: world.discovered[landmark.name] = true
	world.hud.notice_time = 0
	await capture("res://build/stonewake-echoes.png")
	p.map_open = true; p.set_paused(true)
	world.hud.world_map.set_view(true)
	await capture("res://build/stonewake-map.png")
	world.queue_free(); await process_frame
	print("STONEWAKE_RENDERS_COMPLETE")
	quit()
