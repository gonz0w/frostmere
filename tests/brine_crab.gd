extends SceneTree
const Projectile=preload("res://scripts/projectile.gd")
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
	var p=world.player; var c=world.shore; var e=c.enemies[6]
	p.set_physics_process(false); p.set_process(false)
	for actor in c.enemies: actor.set_physics_process(false)
	c.inside=true; p.set_paused(false); p.position=e.home+Vector3.BACK*7
	check(e.legs.size()==6 and e.claws.size()==2 and is_equal_approx(e.get_child(0).shape.height,2.8),"Coastal guardian has six legs, claws and monster collision")
	check(world.session_save.supported_position(e.position,e),"Large monster fits wreck floor")
	var hp: float=e.health
	e.exposed=0; e.receive_damage(100,p); var armor_damage: float=hp-e.health
	e.health=hp; e.exposed=2.5; e.receive_damage(100,p)
	check(is_equal_approx(armor_damage,64) and is_equal_approx(hp-e.health,112),"Exposed core rewards timing with increased damage")
	e.health=hp; e.exposed=0; e.cooldown=0; e._physics_process(.02)
	check(world.audio.last_effect=="brine_warning","Distinct brine warning cue plays")
	check(e.windup>0 and e.exposed==0,"Spit begins with warning before vulnerability")
	var aim: Vector3=e.aim; p.position+=Vector3.RIGHT
	e._physics_process(1.41)
	var bolts=[]
	for child in world.adventure.get_children():
		if child is Projectile and child.shooter==e: bolts.append(child)
	check(bolts.size()==3 and bolts[1].direction.is_equal_approx(aim) and bolts[1].tint==Color("8fd4cf"),"Three brine bolts preserve the telegraphed aim")
	check(e.exposed==2.5 and absf(e.plates[0].position.x)>.4,"Attack opens shell plates and exposes core")
	e._physics_process(2.51)
	check(e.exposed==0 and is_equal_approx(absf(e.plates[0].position.x),.4),"Core closes after recovery")
	e.windup=1; e.stagger_time=1; e._physics_process(.01)
	check(e.windup==0,"Stagger cancels volley"); e.stagger_time=0
	e.windup=1; e.execution_locked=true; e._physics_process(.01)
	check(e.windup==0,"Execution lock cancels volley"); e.execution_locked=false
	e.windup=1; e.exposed=2; p.set_paused(true); e._physics_process(.01)
	check(e.windup==0 and e.exposed==0,"Menu cancels pending attack and core phase")
	p.set_paused(false); e.windup=1; c.inside=false; e._physics_process(.01)
	check(e.windup==0 and not e.visible and e.collision_layer==0,"Travel hides monster and cancels attack")
	c.inside=true; e.health=5; p.position=e.position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Armored weak monster remains eligible for finisher")
	p.update_finisher(.6)
	check(e.dead and "shore_6" in p.character.shore.defeated,"Finisher penetrates weakened shell and preserves persistent boss identity")
	check(c.loot("shore_6") and not c.loot("shore_6"),"Monster retains single-claim salvage reward")
	p.cancel_finisher(); world.queue_free(); await process_frame
	print("BRINE_CRAB_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
