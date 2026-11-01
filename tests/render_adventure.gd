extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.capture_done = true
	var p: CharacterBody3D = world.player
	var a: Node3D = world.adventure
	p.position = a.SMITH + Vector3(1.5, 0.15, 0)
	a.open_dialog()
	await capture("res://build/edda-quest.png")
	a.close_dialog()
	p.set_paused(false)
	a.accept_quest()
	a.enter()
	for enemy: CharacterBody3D in a.enemies: enemy.set_physics_process(false)
	p.position = Vector3(0, -29.95, -33)
	world.hud.notice_time = 0
	await capture("res://build/oldwatch-arena.png")
	p.map_open = true
	p.set_paused(true)
	world.hud.world_map.set_view(true)
	world.hud.world_map.tabs.current_tab = 2
	world.hud.world_map.selected_quest = "side_frostmere"
	world.hud.world_map._refresh()
	await capture("res://build/oldwatch-map.png")
	world.queue_free()
	await process_frame
	quit()
