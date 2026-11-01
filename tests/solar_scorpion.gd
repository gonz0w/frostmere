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
	var p=world.player; var r=world.lens; var e=r.enemies[4]
	p.character.story_completed.append("archive"); r.enter(); p.set_physics_process(false); p.set_process(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3.BACK*7; p.invulnerable=0; p.blocking=false
	check(e.legs.size()==8 and world.session_save.supported_position(e.global_position,e),"Scorpion fits the observatory floor")
	e.cooldown=0; e._physics_process(.02)
	check(not e.pending,"Mirror gate prevents early attacks")
	p.character.lens.activated=true
	check(e.maximum_health==360 and e.finisher_surface()=="stone","Health and stone finisher identity preserved")
	e.cooldown=0; e._physics_process(.02); var hp: float=p.health; var target: Vector3=e.target
	check(world.audio.last_effect=="solar_warning","Distinct monster warning cue plays")
	check(e.warning.visible and e.windup==1.4 and p.health==hp,"Beam marks danger before damage")
	p.position+=Vector3.RIGHT*4; e._physics_process(1.41)
	check(e.target==target and p.health==hp and not e.warning.visible,"Sidestepping locked beam avoids damage")
	e.begin_beam(); e._physics_process(1.41)
	check(p.health<hp and e.cooldown==6,"Remaining in beam takes damage and starts recovery")
	hp=p.health; p.invulnerable=0; e._physics_process(.1)
	check(p.health==hp,"Beam cannot hit twice")
	e.health=e.maximum_health*.5; e.begin_beam(); e._physics_process(1.41)
	check(is_equal_approx(hp-p.health,44*100.0/(100+float(p.derived.armor)*1.5)) and e.cooldown==4,"Half health increases exact damage and attack frequency")
	e.cancel_beam(); p.position=e.global_position+Vector3.BACK*7; e.begin_beam()
	p.position=e.global_position-Vector3.BACK*2; hp=p.health; e.resolve_beam()
	check(p.health==hp,"Locked beam cannot hit behind its origin")
	e.cancel_beam(); p.position=e.global_position+Vector3.BACK*7; e.begin_beam()
	p.position=e.global_position+Vector3.BACK*12.1; hp=p.health; e.resolve_beam()
	check(p.health==hp,"Beam cannot hit beyond its marked twelve-meter reach")
	p.position=e.global_position+Vector3.BACK*7
	e.begin_beam(); e.stagger_time=1; e._physics_process(.02)
	check(not e.pending and not e.warning.visible,"Stagger cancels beam"); e.stagger_time=0
	e.begin_beam(); p.set_paused(true); e._physics_process(.02)
	check(not e.pending and not e.warning.visible,"Menu cancels warning safely")
	p.set_paused(false); e.begin_beam(); r.inside=false; e._physics_process(.02)
	check(not e.visible and not e.warning.visible and e.collision_layer==0,"Realm travel clears actor and marker")
	r.inside=true; e.begin_beam(); e.execution_locked=true; e._physics_process(.02)
	check(not e.pending,"Finisher lock cancels pending damage"); e.execution_locked=false
	e.health=5; p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Weak monster remains finishable")
	p.update_finisher(.6)
	check(e.dead and "lens_4" in p.character.lens.defeated and not e.warning.visible,"Finisher preserves solar guardian identity and removes warning")
	p.cancel_finisher(); world.queue_free(); await process_frame
	print("SOLAR_SCORPION_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
