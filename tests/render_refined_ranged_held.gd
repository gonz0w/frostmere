extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): quit(1); return
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	var p=w.player; var s=p.character
	assert(not s.persist and not w.atlas.persist)
	p.position=Vector3(0,.2,12); p.rotation=Vector3.ZERO; p.pivot.rotation=Vector3.ZERO
	p.set_physics_process(false)
	var ids: Array=["iron_axe","steel_battleaxe","iron_mace"] if "--impact" in OS.get_cmdline_user_args() else ["iron_bow","lantern_conductor","cinder_gun"]
	for id in ids:
		s.equip(s.add_item(id,2,"vigor"),"main_hand")
		for third in [true,false]:
			p.set_third_person(third)
			for i in range(5): await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://build/refined-%s-%s.png" % [id,"third" if third else "first"])
	print("REFINED_RANGED_HELD_COMPLETE"); quit()
