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
	var p=world.player; var c=world.choir; var e=c.enemies[4]
	p.set_physics_process(false); p.set_process(false)
	for actor in c.enemies: actor.set_physics_process(false)
	c.inside=true; p.set_paused(false); p.position=e.home+Vector3.BACK*5
	check(not p.character.persist and not world.atlas.persist,"Test persistence disabled")
	check(e.legs.size()==6 and e.wings.size()==2 and world.session_save.supported_position(e.position,e),"Winged creature fits volcanic floor")
	e.cooldown=0; e._physics_process(.02); check(e.windup==0,"Bell gate prevents early song")
	p.character.choir.activated=true
	e.cooldown=0; e._physics_process(.02); var hp: float=p.health
	check(world.audio.last_effect=="ash_warning","Distinct ash inhale cue plays")
	check(e.windup==1.5 and e.wave.visible and p.health==hp,"Outer warning precedes damage")
	e._physics_process(1.51); check(e.ringing and e.radius==0,"Warning begins expanding ring")
	p.position.y=e.home.y+1.2; e._physics_process(.8)
	check(p.health==hp,"Jumping above the low wave avoids damage")
	e.cancel_song(); p.position=e.home+Vector3.BACK*8.1; e.begin_song(); e._physics_process(1.51); e._physics_process(1.2)
	check(p.health==hp and not e.ringing,"Retreating beyond eight meters avoids wave")
	p.position=e.home+Vector3.BACK*5; p.invulnerable=0; p.blocking=false
	e.begin_song(); e._physics_process(1.51); e._physics_process(.8)
	check(p.health<hp and e.hit,"Grounded target takes crossing hit")
	hp=p.health; p.invulnerable=0; e._physics_process(.2)
	check(p.health==hp,"Wave hits at most once")
	e.cancel_song(); e.health=e.maximum_health*.5; p.invulnerable=0
	e.begin_song(); e._physics_process(1.51); e._physics_process(1.2)
	check(is_equal_approx(hp-p.health,40*100.0/(100+float(p.derived.armor)*1.5)) and e.cooldown==4,"Half health increases damage and shortens recovery")
	e.begin_song(); e.stagger_time=1; e._physics_process(.01)
	check(e.windup==0 and not e.wave.visible,"Stagger cancels song"); e.stagger_time=0
	e.begin_song(); p.set_paused(true); e._physics_process(.01)
	check(e.windup==0 and not e.wave.visible,"Menu cancels song"); p.set_paused(false)
	e.begin_song(); e.execution_locked=true; e._physics_process(.01)
	check(e.windup==0,"Execution lock cancels song"); e.execution_locked=false
	e.begin_song(); c.inside=false; e._physics_process(.01)
	check(not e.visible and not e.wave.visible and e.collision_layer==0,"Travel clears actor and warning")
	c.inside=true; e.health=5; p.position=e.position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Weak Cantor remains finishable"); p.update_finisher(.6)
	check(e.dead and "choir_4" in p.character.choir.defeated and not e.wave.visible,"Finisher preserves guardian identity")
	check(c.loot("choir_4") and not c.loot("choir_4"),"Guardian loot remains single claim")
	p.cancel_finisher(); world.queue_free(); await process_frame
	print("ASH_CANTOR_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
