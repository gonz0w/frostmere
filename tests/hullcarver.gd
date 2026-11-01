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
	var p=world.player; var c=world.threshold; var e=c.enemies[5]
	p.set_physics_process(false); p.set_process(false)
	for actor in c.enemies: actor.set_physics_process(false)
	c.inside=true; p.set_paused(false); p.position=e.home+Vector3.BACK*7
	check(e.legs.size()==8 and is_equal_approx(e.get_child(0).shape.height,3.6),"Station guardian has eight legs and monster collision")
	check(world.session_save.supported_position(e.position,e),"Large monster fits station deck")
	var hp: float=e.health; e.receive_damage(100,p)
	check(e.health==hp,"Station repair gate still protects monster")
	p.character.threshold.power=true; p.character.threshold.air=true
	e.exposed=0; e.receive_damage(100,p); var armor_damage: float=hp-e.health
	e.health=hp; e.exposed=3; e.receive_damage(100,p)
	check(is_equal_approx(armor_damage,52) and is_equal_approx(hp-e.health,120),"Exposed core rewards timing with increased damage")
	e.health=hp; e.exposed=0; e.cooldown=0; e._physics_process(.02)
	check(e.windup>0 and e.exposed==0,"Spit begins with warning before vulnerability")
	check(e.charge.visible and e.mandibles.size()==2,"Warning has physical charge and articulated mandibles")
	var initial_scale: float=e.charge.scale.x
	e._physics_process(.55)
	check(e.charge.scale.x>initial_scale and absf(e.mandibles[0].rotation.y)>.2 and e.rig.position.y<0,"Charge grows while jaws open and body braces")
	check(e.exposed==0,"Wind-up animation does not expose the core early")
	e._physics_process(.56)
	check(e.exposed==3 and absf(e.plates[0].position.x)>.4,"Attack opens shell plates and exposes core")
	check(not e.charge.visible and e.spit_recoil>0 and e.rig.rotation.x>0,"Shot clears charge and kicks the body back")
	e._physics_process(3.01)
	check(e.exposed==0 and is_equal_approx(absf(e.plates[0].position.x),.4),"Core closes after recovery")
	check(e.spit_recoil==0 and is_zero_approx(e.rig.rotation.x),"Recovery settles back into idle pose")
	e.windup=1; e.exposed=2; p.set_paused(true); e._physics_process(.01)
	check(e.windup==0 and e.exposed==0,"Menu cancels pending attack and core phase")
	check(not e.charge.visible and e.rig.position.y==0,"Menu clears charge and braced pose")
	p.set_paused(false); e.windup=1; c.inside=false; e._physics_process(.01)
	check(e.windup==0 and not e.visible and e.collision_layer==0,"Travel hides monster and cancels attack")
	c.inside=true; e.health=5; p.position=e.position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Armored weak monster remains eligible for finisher")
	p.update_finisher(.6)
	check(e.dead and "threshold_5" in p.character.threshold.defeated,"Finisher penetrates weakened shell and preserves persistent boss identity")
	e.update_shell(); check(not e.charge.visible,"Corpse cannot retain a charging effect")
	check(c.loot("threshold_5") and not c.loot("threshold_5"),"Monster retains single-claim named blade reward")
	p.cancel_finisher(); world.queue_free(); await process_frame
	print("HULLCARVER_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
