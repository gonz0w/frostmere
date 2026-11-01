extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	var s: RefCounted = world.player.character
	var ui: Control = world.hud.workshop
	world.player.position = Vector3(6, 0.1, -27.5)
	var uid: String = s.equipment.main_hand
	for entry: Dictionary in s.crafting.materials:
		s.materials[entry.id] = 20
	s.improve(uid, "forge")
	s.improve(uid, "forge")
	s.enchant_item(uid, "vigor", "enchant")
	s.socket_gem(uid, "ruby", "enchant")
	ui.open("enchant")
	ui.selected = uid
	ui.refresh()
	for i in range(15):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://build/enchanting.png")
	ui.close()
	world.player.respawn()
	for i in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("res://build/crafting-world.png")
	world.queue_free()
	await process_frame
	quit()
