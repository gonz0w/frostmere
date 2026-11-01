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
	p.character.choir.rewarded=true; p.character.choir.listener_started=true; p.character.choir.listener_vigils=["vigil_south","vigil_middle","vigil_north"]; p.character.choir.listener_record=true; p.character.choir.listener_joined=true; p.character.choir.memory_started=true; p.character.choir.memory_lock=3; p.character.choir.memory_record=true; p.character.choir.memory_choice="publish"; p.character.choir.fire_started=true; p.character.choir.fire_seals=["fire_west","fire_east"]; c._refresh()
	p.position=c.ORIGIN+c.NODES.fire_cradle+Vector3(0,.1,1.3); w.interact_nearby()
	await capture("fire-invite-choice")
	c.act("fire_choose:contain"); c.close_dialog(); p.set_paused(false); p.character.choir.listener_vigils=[]; c.vigil_time=3
	p.position=c.ORIGIN+c.NODES.fire_cradle+Vector3(0,.1,4); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0; p.set_third_person(false); w.hud.notice_time=0
	await capture("fire-invite-contained")
	print("FIRE_INVITE_RENDER_COMPLETE"); quit()
