extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.convergence
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed=c.REQUIRED.duplicate(); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.position=c.ORIGIN+Vector3(-25,.2,17); p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.5; p.set_third_person(false); w.hud.notice_time=0
	c.set_process(false); c.rescue_glow.visible=true
	await capture("mirewatch-signal")
	p.character.convergence.rescue_stage=2; c._refresh(); p.position=c.ORIGIN+c.NODES.rescue_winch+Vector3(0,.1,1.4); w.interact_nearby()
	await capture("mirewatch-rescue-dialogue")
	c.act("rescue_free"); c.close_dialog(); p.set_paused(false)
	p.position=c.ORIGIN+Vector3(-25,.2,28); p.rotation=Vector3.ZERO; p.pivot.rotation.x=.05
	await capture("mirewatch-tovin-rescued")
	print("MIREWATCH_RESCUE_RENDER_COMPLETE"); quit()
