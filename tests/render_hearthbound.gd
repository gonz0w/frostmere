extends SceneTree
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	var p=w.player; var c=w.hunts
	assert(not p.character.persist and not w.atlas.persist)
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	p.character.adventure.rewarded=true; p.character.hunt.lodge_started=true; p.character.hunt.lodge_repairs=["village","crossing","ridge"]; c.refresh_road()
	p.position=c.POSITION+Vector3(0,.1,1.3); c.selected="lodge"; w.interact_nearby()
	await capture("hearthbound-oath")
	c.close(); p.position=c.road_position("crossing")+Vector3(0,.1,4); p.rotation=Vector3.ZERO; p.pivot.rotation.x=0; p.set_third_person(false); w.hud.notice_time=0
	await capture("hearthbound-road-marker")
	print("HEARTHBOUND_RENDER_COMPLETE"); quit()
