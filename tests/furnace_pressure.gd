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
	var p=w.player; var r=w.realms; var e=r.enemies[5]
	check(not p.character.persist,"Pressure fixture is isolated")
	r.enter("crucible",true); p.set_physics_process(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3.BACK*7
	for skill in ["melee","marksman","magic"]:
		e.health=e.maximum_health; e.exposed=0
		e.receive_damage(20,p,"",skill)
		check(is_equal_approx(e.maximum_health-e.health,9.6),"Closed shutters mitigate actual "+skill+" hits")
	e.health=e.maximum_health; e.begin_vent(); var hp: float=p.health
	p.position+=Vector3.RIGHT*4; e._physics_process(1.51)
	check(p.health==hp and e.exposed==2.5 and not e.vent_pending,"Dodging rupture opens a full retaliation window")
	check(is_equal_approx(absf(e.shutters[0].position.x),.95) and "CORE EXPOSED" in e.label.text,"Open core is visible and labeled")
	e.receive_damage(20,p,"","marksman")
	check(is_equal_approx(e.maximum_health-e.health,21.6),"Exposed core rewards shots with exact bonus damage")
	e._physics_process(2.4)
	check(e.exposed>0,"Exposure lasts through its intended window")
	e._physics_process(.11)
	check(e.exposed==0 and is_equal_approx(absf(e.shutters[0].position.x),.36),"Shutters close after recovery window")
	for reason in ["pause","travel","execution","death"]:
		e.exposed=2.5; e.update_shutters(); e.begin_vent(); e.exposed=2.5
		match reason:
			"pause": p.set_paused(true)
			"travel": r.current="aeralis"
			"execution": e.execution_locked=true
			"death": e.dead=true
		e._physics_process(.01)
		check(e.exposed==0 and not e.vent.visible and not e.vent_pending,"Interrupt clears exposure and warning: "+reason)
		p.set_paused(false); r.current="crucible"; e.execution_locked=false; e.dead=false
	e.health=5; e.exposed=0
	p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Closed shutters do not block an eligible execution")
	p.update_finisher(.6)
	check(e.dead and "crucible_warden" in p.character.realm_progress.defeated,"Actual finisher remains lethal through closed shutters")
	p.cancel_finisher()
	check(r.loot("crucible_warden") and not r.loot("crucible_warden"),"Guardian reward still grants exactly once")
	w.queue_free(); await process_frame
	print("FURNACE_PRESSURE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
