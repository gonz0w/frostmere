extends SceneTree
const Projectile=preload("res://scripts/projectile.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func bolts(world: Node) -> int:
	return world.adventure.get_children().filter(func(n): return n is Projectile and not n.is_queued_for_deletion()).size()
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var r=world.realms; var e=r.enemies[2]
	r.enter("aeralis",true); p.set_physics_process(false); p.set_process(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3.BACK*8
	check(e.wings.size()==2 and e.shards.size()==10 and world.session_save.supported_position(e.global_position,e),"Crystal monster fits the guardian terrace")
	e.cooldown=0; e._physics_process(.02)
	check(e.windup>0 and bolts(world)==0,"Fan attack warns before firing")
	var aim: Vector3=e.aim; p.position+=Vector3.RIGHT*3; e._physics_process(.1)
	check(e.aim==aim,"Volley aim stays committed during sidestep")
	check(absf(e.shards[4].rotation.y)>0 and e.rig.position.y<0,"Fan wind-up spreads crystal feathers and braces the body")
	e._physics_process(1.2)
	check(bolts(world)==5,"Intact wings fire five real crystal projectiles")
	check(e.fan_recoil>0 and e.rig.position.y==0,"Volley releases the brace into wing recoil")
	world.adventure.clear_projectiles(); e.health=e.maximum_health*.5; e._physics_process(.02)
	check(e.fractured and e.stagger_time>0 and not e.shards[4].visible and not e.shards[9].visible,"Half health fractures outer wings and opens recovery")
	e.stagger_time=0; e.cooldown=0; e._physics_process(.02); e._physics_process(1.21)
	check(bolts(world)==3,"Broken wings reduce volley to three projectiles")
	e.health=e.maximum_health; e._physics_process(.02)
	check(not e.fractured and e.shards[4].visible,"Encounter health reset restores intact wing phase")
	e.windup=1; p.set_paused(true); e._physics_process(.02)
	check(e.windup==0,"Menus cancel pending fan")
	check(e.fan_recoil==0 and e.jaw.rotation.x==0 and e.shards[4].rotation.y==0,"Menu clears attack-specific poses")
	p.set_paused(false); r.current="crucible"; e._physics_process(.02)
	check(not e.visible and e.collision_layer==0,"Other realm disables crystal monster")
	r.current="aeralis"; e.health=5; p.position=e.global_position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	check(p.activate_finisher(),"Weakened wyrm accepts melee finisher")
	p.update_finisher(.6)
	check(e.dead and "aeralis_regent" in p.character.realm_progress.defeated,"Monster keeps existing persistent guardian identity")
	p.cancel_finisher(); world.queue_free(); await process_frame
	print("CRYSTAL_WYRM_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
