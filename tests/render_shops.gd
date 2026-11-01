extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	world.capture_done = true
	world.hud.notice_time = 0
	for landmark: Dictionary in world.landmarks: world.discovered[landmark.name] = true
	var p: CharacterBody3D = world.player
	p.position = Vector3(-1, 0.3, 5.0)
	p.rotation.y = 0.5
	p.pivot.rotation.x = -0.1
	await capture("res://build/village-shops.png")
	p.position = Vector3(-10, 0.3, -4.8)
	p.rotation = Vector3.ZERO
	p.set_third_person(false)
	p.pivot.rotation.x = -0.10
	await capture("res://build/outfitter-interior.png")
	p.position = Vector3(-10, 0.3, -6)
	world.shops.open("outfitter")
	await capture("res://build/shop-trading.png")
	world.queue_free()
	await process_frame
	quit()
