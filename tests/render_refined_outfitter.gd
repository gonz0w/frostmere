extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(8): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/refined-outfitter-"+name+".png")
func run() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): quit(1); return
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	var p=w.player
	assert(not p.character.persist and not w.atlas.persist)
	p.character.unequip("main_hand"); p.character.unequip("off_hand")
	for landmark: Dictionary in w.landmarks: w.discovered[landmark.name]=true
	w.hud.notice_time=0
	p.set_physics_process(false); p.set_process_unhandled_input(false); p.set_third_person(false)
	p.position=Vector3(-6,.3,3); p.rotation.y=.50; p.pivot.rotation.x=.12
	await capture("street")
	p.position=Vector3(-9,.3,-5); p.rotation.y=.18; p.pivot.rotation.x=-.03
	await capture("interior")
	print("REFINED_OUTFITTER_RENDER_COMPLETE"); quit()
