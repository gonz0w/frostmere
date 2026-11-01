extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var r=world.realms; var e=r.enemies[5]
	r.enter("crucible",true); p.set_physics_process(false); p.set_process(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3.BACK*7; p.invulnerable=0; p.blocking=false
	check(e.legs.size()==6 and world.session_save.supported_position(e.global_position,e),"Six-legged beast fits the final terrace")
	e.cooldown=0; e._physics_process(.02); var hp: float=p.health; var target: Vector3=e.vent_origin
	check(e.vent.visible and e.windup==1.5 and p.health==hp,"Rupture marks danger before damage")
	e._physics_process(.75)
	check(e.bellows.size()==2 and e.bellows[0].scale.y>1 and e.jaw.rotation.x<0 and e.rig.position.y>0,"Wind-up opens bellows and jaw before rupture")
	check(p.health==hp and e.exposed==0 and e.vent_origin==target,"Animation preserves fixed warning target and damage timing")
	p.position+=Vector3.RIGHT*4; e._physics_process(.76)
	check(e.vent_origin==target and p.health==hp and not e.vent.visible,"Leaving locked circle avoids rupture")
	check(e.impact_time>0 and e.rig.position.y<0 and e.exposed==2.5,"Rupture slams body and opens the existing core window")
	e._physics_process(.41)
	check(e.impact_time==0 and e.rig.position.y==0 and e.jaw.rotation.x<0,"Impact settles while exposed jaw remains open")
	e.begin_vent(); e._physics_process(1.51)
	check(p.health<hp and e.cooldown==6,"Remaining in circle takes damage and starts recovery")
	hp=p.health; p.invulnerable=0; e._physics_process(.1)
	check(p.health==hp,"Rupture cannot hit twice")
	e.health=e.maximum_health*.5; e.begin_vent(); e._physics_process(1.51)
	check(is_equal_approx(hp-p.health,46*100.0/(100+float(p.derived.armor)*1.5)) and e.cooldown==4,"Half health increases exact damage and attack frequency")
	e.begin_vent(); p.set_paused(true); e._physics_process(.02)
	check(not e.vent_pending and not e.vent.visible,"Menu cancels warning safely")
	check(e.impact_time==0 and e.rig.position.y==0 and e.bellows[0].scale.y==1 and e.jaw.rotation.x==0,"Pause restores neutral presentation")
	p.set_paused(false); e.begin_vent(); r.current="aeralis"; e._physics_process(.02)
	check(not e.visible and not e.vent.visible and e.collision_layer==0,"Realm travel clears actor and marker")
	r.current="crucible"; e.begin_vent(); e.execution_locked=true; e._physics_process(.02)
	check(not e.vent_pending,"Finisher lock cancels pending damage"); e.execution_locked=false
	e.health=5; p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Weak monster remains finishable")
	p.update_finisher(.6)
	check(e.dead and "crucible_warden" in p.character.realm_progress.defeated and not e.vent.visible,"Finisher preserves ending guardian identity and removes warning")
	p.cancel_finisher(); world.queue_free(); await process_frame
	print("FURNACE_BEAST_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
