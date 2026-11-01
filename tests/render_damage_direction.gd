extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	for i in range(4): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+path+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var cue=w.hud.damage_direction
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false); cue.set_process(false)
	p.set_third_person(false); w.hud.notice_time=0; p.invulnerable=0
	p.receive_damage(10,p.global_position+p.global_basis.x*5)
	await capture("damage-direction-hit")
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	p.invulnerable=0; p.blocking=true; p.parry_window=.22; p.stamina=100
	p.receive_damage(10,p.global_position-p.global_basis.z*5,w.adventure.enemies[0])
	await capture("damage-direction-parry")
	print("DAMAGE_DIRECTION_RENDER_COMPLETE"); quit()
