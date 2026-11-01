extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.choir
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("council"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.choir.pilgrim_stage=3; p.character.choir.defeated=["choir_1"]
	p.position=c.interaction_position("pilgrim")+Vector3(0,.1,1.3); w.interact_nearby()
	await capture("empty-shoes-choice")
	c.act("pilgrim_depart")
	p.position=c.interaction_position("pilgrim")+Vector3(0,.1,4); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0; p.set_third_person(false); w.hud.notice_time=0
	await capture("empty-shoes-safe-camp")
	print("EMPTY_SHOES_RENDER_COMPLETE"); quit()
