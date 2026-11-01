extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(15): await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.capture_done = true
	var p: CharacterBody3D = world.player
	world.realms.enter("aeralis", true)
	world.realms.preview_kit("aeralis")
	world.hud.notice_time = 0
	await capture("res://build/aeralis-preview.png")
	p.map_open = true
	p.set_paused(true)
	world.hud.world_map.set_view(true)
	await capture("res://build/aeralis-map.png")
	world.hud.world_map.close()
	world.realms.enter("crucible", true)
	world.realms.preview_kit("crucible")
	world.hud.notice_time = 0
	p.set_third_person(false)
	await capture("res://build/crucible-first-person.png")
	world.queue_free()
	await process_frame
	print("REALM_RENDERS_COMPLETE")
	quit()
