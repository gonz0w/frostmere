extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): push_error("Use -- --capture"); quit(1); return
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	var p=w.player; var s=p.character
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.position=Vector3(-4,.15,-11)
	s.train("magic",400); s.learn_perk("kindled_mind"); s.learn_perk("clear_channel")
	s.known_spells.append("starfall"); s.active_spell="starfall"
	s.equip(s.add_item("lantern_conductor",2,"insight"),"main_hand")
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/spell-costs.png")
	s.known_spells.append("soulfire"); s.active_spell="soulfire"
	s.equip(s.add_item("cinder_gun"),"main_hand")
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/spell-costs-rifle.png")
	print("SPELL_COSTS_RENDER_COMPLETE"); quit()
