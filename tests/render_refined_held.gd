extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): quit(1); return
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	var p=w.player; var s=p.character
	assert(not s.persist and not w.atlas.persist)
	p.position=Vector3(0,.2,12); p.rotation=Vector3.ZERO; p.pivot.rotation=Vector3.ZERO
	var uid: String=s.add_item("oldwatch_oath",2,"vigor"); s.inventory[uid].gem="sapphire"
	s.equip(uid,"main_hand"); s.equip(s.add_item("iron_shield"),"off_hand")
	for slot in ["head","chest","hands","legs","feet"]:
		s.equip(s.add_item("steel_"+slot),slot)
	p.set_physics_process(false)
	for third in [true,false]:
		p.set_third_person(third)
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/refined-held-%s.png" % ("third" if third else "first"))
	print("REFINED_HELD_RENDER_COMPLETE"); quit()
