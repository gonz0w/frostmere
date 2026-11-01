extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(3): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/" + name + ".png")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world); world.capture_done = true; world.audio.enabled = false
	for i in range(5): await physics_frame
	var p = world.player; world.adventure.enter()
	assert(not p.character.persist and not world.atlas.persist)
	p.set_process(false); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for e in world.adventure.enemies: e.set_physics_process(false)
	p.global_position = Vector3(0, -29.95, 2); p.rotation = Vector3.ZERO; p.set_third_person(false); p.pivot.rotation.x = 0
	var enemy = world.adventure.enemies[0]; enemy.global_position = p.global_position + Vector3.FORWARD * 2.1; enemy.health = 10; enemy._update_label()
	await capture("finisher-ready")
	assert(p.activate_finisher()); p.update_finisher(0.3); await capture("finisher-windup")
	p.update_finisher(0.25); assert(enemy.dead); await capture("finisher-impact")
	p.cancel_finisher(); print("FINISHERS_RENDER_COMPLETE"); quit()
