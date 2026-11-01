extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + name + ".png")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done = true; world.audio.enabled = false
	for i in range(5): await physics_frame
	var p = world.player
	assert(not p.character.persist and not world.atlas.persist)
	p.set_physics_process(false); p.set_process(false); p.set_process_unhandled_input(false)
	p.power = 100; await capture("sunder-ready")
	p.activate_power("sunder"); p.update_power(0.35); await capture("sunder-third-person")
	p.update_power(.14); await capture("sunder-impact")
	p.cancel_power(); p.set_third_person(false); p.attack_cooldown = 0; p.power = 100
	p.activate_power("sunder"); p.update_power(0.35); await capture("sunder-first-person")
	p.cancel_power(); assert(Engine.time_scale == 1)
	print("SUNDER_RENDER_COMPLETE"); quit()
