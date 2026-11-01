extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(10): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + name + ".png")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done = true; world.audio.enabled = false
	for i in range(5): await physics_frame
	var p = world.player; var s = p.character; var menu = world.hud.character_menu
	assert(not s.persist and not world.atlas.persist)
	p.set_process_unhandled_input(false)
	s.save_loadout(0, "Warrior")
	var bow = s.add_item("steel_bow", 3); s.equip(bow, "main_hand"); s.save_loadout(1, "Ranger")
	p.character_menu_open = true; p.set_paused(true); menu.show(); menu._refresh()
	menu.loadout_picker.select(1); menu._refresh_loadout(true)
	await capture("loadouts-ranger")
	s.apply_loadout(0); s.inventory.erase(bow); menu._refresh()
	await capture("loadouts-missing")
	print("LOADOUTS_RENDER_COMPLETE"); quit()
