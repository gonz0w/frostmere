extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.mountain
	assert(not p.character.persist and not w.atlas.persist)
	p.character.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.mountain.shelter_stage=3; c._refresh()
	p.position=c.interaction_position("travelers")+Vector3(0,.1,1.3); w.interact_nearby()
	await capture("warm-shelter-choice")
	c.close_dialog(); p.set_paused(false)
	p.position=c.ORIGIN+Vector3(30,.1,-49); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0; p.set_third_person(false); w.hud.notice_time=0
	await capture("warm-shelter-hut")
	print("WARM_SHELTER_RENDER_COMPLETE"); quit()
