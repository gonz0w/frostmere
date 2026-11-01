extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	var p=w.player; var a=w.audio
	check(not p.character.persist and not w.atlas.persist,"QA persistence disabled")
	for id in ["step_grass","step_snow","step_stone","step_wood","step_metal"]:
		check(a.streams.has(id) and a.streams[id].get_length()>0,"Footstep WAV loads: "+id)
	var snow: Rect2=w.step_snow.values()[0][0]; var point:=snow.get_center()
	var snow_at:=Vector3(point.x,.1,point.y)
	check(w.terrain_step_at(snow_at)=="snow" and w.footstep_at(snow_at)=="step_snow","Visible snow patch selects snow through floor ray")
	var cell:=Vector2i(floori(point.x),floori(point.y))
	var edge:=Vector3(cell.x+.02,.1,cell.y+.02)
	check(w.terrain_step_at(edge)=="grass" and w.footstep_at(edge)=="step_grass","Outside the small snow patch stays grass")
	check(w.footstep_at(Vector3(0,.1,5))=="step_stone","Town cobbles select stone")
	check(w.footstep_at(Vector3(-10,.3,-6))=="step_wood","House interior planks select wood")
	check(w.footstep_at(w.threshold.ORIGIN+Vector3(0,.2,40))=="step_metal","Station deck selects metal")
	check(w.footstep_at(Vector3(0,20,5))=="step","No floor returns neutral fallback")
	p.set_physics_process(false); p.position=Vector3(0,10,5); p.velocity=Vector3(3,0,0); p.move_and_slide()
	a.step_time=0; a.last_effect=""; a._process(.1)
	check(not a.last_effect.begins_with("step"),"Airborne movement does not emit footsteps")
	p.position=Vector3(0,.05,5)
	for i in range(8):
		p.velocity=Vector3(0,-3,0); p.move_and_slide(); await physics_frame
	p.velocity=Vector3(3,0,0); a.cooldowns.clear(); a.step_time=0; a._process(.1)
	check(a.last_effect=="step_stone" and a.step_time==.48,"Grounded walking uses selected surface and cadence")
	p.set_paused(true); var count: int=a.effect_count; a.step_time=0; a._process(.1)
	check(a.effect_count==count,"Menus suppress footfalls")
	w.queue_free(); await process_frame
	print("FOOTSTEPS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
