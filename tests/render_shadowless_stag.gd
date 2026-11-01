extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.roots
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	for enemy in c.enemies: enemy.hide(); enemy.set_physics_process(false)
	p.character.roots.rewarded=true; p.character.roots.stag_step=2; c._refresh(); c.stag.position=c.ORIGIN+c.STAG_STOPS[2]
	p.position=c.stag.position+Vector3(2,.1,5); p.rotation.y=.35; p.pivot.rotation.x=0; p.set_third_person(false); w.hud.notice_time=0
	await capture("shadowless-stag")
	p.character.roots.stag_step=4; c._refresh(); p.position=c.interaction_position("hunter")+Vector3(0,.1,1.3); w.interact_nearby()
	await capture("stag-forgiveness")
	print("SHADOWLESS_STAG_RENDER_COMPLETE"); quit()
