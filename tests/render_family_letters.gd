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
	p.character.mountain.letters_started=true; p.character.mountain.letters_received=["stoneguard","stormweaver"]; p.character.mountain.letters_witness=true
	p.position=c.ORIGIN+c.NODES.council+Vector3(0,.1,1.4); w.interact_nearby()
	await capture("family-letters-choice")
	c.act("letters_public"); c.close_dialog(); p.set_paused(false)
	p.position=c.ORIGIN+c.NODES.memorial+Vector3(0,.1,3); p.rotation=Vector3.ZERO; p.pivot.rotation.x=-.15; p.set_third_person(false); w.hud.notice_time=0
	await capture("family-letters-memorial")
	print("FAMILY_LETTERS_RENDER_COMPLETE"); quit()
