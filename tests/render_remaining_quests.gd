extends "res://tests/remaining_quests.gd"
func capture(name: String) -> void:
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/"+name+".png")
func view_site(area: String,from: Vector3,target: Vector3,name: String) -> void:
	travel(area); p.position=from
	var delta: Vector3=target-from; p.rotation=Vector3(0,atan2(-delta.x,-delta.z),0); p.pivot.rotation.x=0; p.set_third_person(false); w.hud.notice_time=0
	await capture(name)
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w); w.capture_done=true
	for i in range(8): await physics_frame
	p=w.player; c=w.road_quests; s=p.character; p.set_physics_process(false); p.set_process_unhandled_input(false)
	assert(not s.persist and not w.atlas.persist)
	s.story_completed.append("stonewake"); s.story_completed.append("archive")
	s.wilderness.defeated=["wild_11"]; s.mountain.defeated=["pass_2"]; s.roots.defeated=["roots_0"]; s.shore.defeated=["shore_0"]
	s.hunt.roads={}
	for manager in [w.wilderness,w.mountain,w.roots,w.shore]:
		for enemy in manager.enemies: enemy.set_physics_process(false)
	for id in c.catalog.quests:
		var q: Dictionary=c.catalog.quests[id]; s.hunt.roads[id]={"answers":[]}
		for i in range(q.steps.size()-1):
			for o in q.steps[i].options:
				if c.allowed_branch(id,o): s.hunt.roads[id].answers.append(o.id); break
		var step: Dictionary=q.steps.back(); talk(step.site,id)
		await capture("road-"+id)
		c.act(id,step.options[0].id)
	c.refresh()
	await view_site("home",Vector3(21,.1,42),c.position_for("courier")+Vector3(2,0,3),"road-caravan")
	await view_site("home",Vector3(-14,.1,40),c.wheel.position,"road-mill")
	await view_site("mountain",w.mountain.ORIGIN+Vector3(39,.1,2),c.position_for("well_channel"),"road-well")
	await view_site("roots",w.roots.ORIGIN+Vector3(-8,.1,42),c.position_for("refugees")+Vector3(-3,0,-4),"road-refugees")
	await view_site("shore",w.shore.ORIGIN+Vector3(30,.1,45),c.position_for("traveler"),"road-rescued-traveler")
	print("REMAINING_QUESTS_RENDER_COMPLETE"); quit()
