extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	if "--capture" not in OS.get_cmdline_user_args(): quit(1); return
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(6): await physics_frame
	assert(not w.player.character.persist and not w.atlas.persist)
	w.player.set_physics_process(false); w.player.visible=false
	for e in w.wilderness.enemies: e.set_physics_process(false)
	for layer in w.find_children("*","CanvasLayer",true,false): layer.visible=false
	var camera=Camera3D.new(); w.add_child(camera); camera.current=true
	for close in [false,true]:
		camera.position=Vector3(19.5,1.9,-8) if close else Vector3(10,3,-12)
		camera.look_at(Vector3(23,.5,2) if close else Vector3(21,.7,0))
		for i in range(10): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/refined-riverbank-"+("walk" if close else "overview")+".png")
	print("REFINED_RIVERBANK_RENDER_COMPLETE"); quit()
