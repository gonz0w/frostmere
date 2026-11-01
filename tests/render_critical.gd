extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world); world.capture_done = true; world.audio.enabled = false
	for i in range(5): await physics_frame
	var p = world.player
	assert(not p.character.persist and not world.atlas.persist)
	world.adventure.enter()
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	for enemy in world.adventure.enemies: enemy.set_physics_process(false)
	p.global_position = Vector3(0, -29.95, 2); p.rotation = Vector3.ZERO
	p.set_third_person(false); p.pivot.rotation.x = 0
	p.character.equip(p.character.add_item("iron_sword"), "main_hand")
	var enemy = world.adventure.enemies[0]
	enemy.global_position = p.global_position + Vector3.FORWARD * 1.4
	p.invulnerable = 0; p.attack_animation = 0; p.stamina = p.derived.stamina
	p.blocking = false; p.attack_cooldown = 0
	for value in range(1000):
		p.combat_rng.seed = value
		if p.roll_weapon_critical():
			p.combat_rng.seed = value
			break
	p.attack()
	assert(world.adventure.feedback.begins_with("Critical!"))
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/critical-combat.png")
	print("CRITICAL_RENDER_COMPLETE"); quit()
