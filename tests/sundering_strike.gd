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
	for i in range(4): await physics_frame
	var p=world.player; var a=world.adventure
	a.enter(); p.set_physics_process(false); p.set_process(false); p.set_paused(false)
	for e in a.enemies: e.set_physics_process(false)
	p.position=Vector3(0,-29.95,2); p.rotation=Vector3.ZERO
	var front=a.enemies[0]; var rear=a.enemies[1]; var side=a.enemies[2]
	for i in range(a.enemies.size()):
		a.enemies[i].global_position=p.position+Vector3.RIGHT*(20+i); a.enemies[i].health=500; a.enemies[i].dead=false
	front.global_position=p.position+Vector3.FORWARD*4.5; rear.global_position=p.position+Vector3.BACK*2; side.global_position=p.position+Vector3.RIGHT*2
	check(not p.activate_power("sunder"),"Sunder requires full meter")
	p.power=100; check(not p.activate_power("unknown") and p.power==100,"Invalid move preserves meter")
	var damage: float=p.derived.damage
	var camera: Vector3=p.pivot.rotation; var arm: Vector3=p.right_arm.rotation; var yaw: float=p.avatar.rotation.y
	check(p.activate_power("sunder"),"Full meter activates Sunder")
	check(front.health==500,"Sunder windup is harmless")
	p.update_power(.49)
	check(is_equal_approx(front.health,500-damage*3) and front.stagger_time>=1.5,"Extended forward reach deals triple damage and staggers")
	check(rear.health==500 and side.health==500,"Rear and side targets excluded")
	check(p.power==0 and Engine.time_scale==.35 and not p.activate_power(),"Moves share meter and cannot overlap")
	p.gain_power(100); check(p.power==0,"Sunder cannot recharge itself")
	p.update_power(.4); check(p.avatar.rotation.y==yaw and p.pivot.rotation==camera and p.right_arm.rotation!=arm,"Overhead pose keeps body and camera facing steady")
	p.update_power(1); check(Engine.time_scale==1 and p.right_arm.rotation==arm,"Expiry restores speed and arm pose")
	p.attack_cooldown=0; p.power=100; front.global_position=p.position+Vector3.FORWARD*5.1; front.health=500
	p.activate_power("sunder"); p.update_power(.49); check(front.health==500,"Beyond five meters is excluded"); p.cancel_power()
	p.attack_cooldown=0; p.power=100; p.position=Vector3(5,-29.95,-9); front.global_position=Vector3(5,-29.95,-11)
	p.activate_power("sunder"); p.update_power(.49); check(front.health==500,"Partition blocks Sunder"); p.cancel_power()
	p.attack_cooldown=0; p.power=100; p.activate_power("sunder"); p.set_paused(true)
	check(Engine.time_scale==1 and p.power_remaining==0,"Menus cancel Sunder safely"); p.set_paused(false)
	p.attack_cooldown=0; p.power=100; p.character.equip(p.character.add_item("iron_bow"),"main_hand")
	check(not p.activate_power("sunder") and p.power==100,"Ranged weapons preserve meter")
	p.character.equip(p.character.add_item("iron_sword"),"main_hand")
	a.leave(); p.character.story_completed.append("archive"); world.lens.enter()
	var boss=world.lens.enemies[4]; boss.set_physics_process(false); boss.stagger_time=0
	p.position=boss.position+Vector3.BACK*2; p.rotation=Vector3.ZERO; p.attack_cooldown=0; p.power=100
	var hp: float=boss.health; p.activate_power("sunder"); p.update_power(.49)
	check(boss.health==hp and boss.stagger_time==0,"Unsolved mirror shield prevents damage and stagger")
	p.cancel_power(); p.attack_cooldown=0; p.power=100
	var event:=InputEventKey.new(); event.physical_keycode=KEY_G; event.pressed=true; event.shift_pressed=true
	p._unhandled_input(event); check(p.power_move=="sunder" and p.power_remaining>0,"Shift G selects Sunder")
	p.cancel_power(); world.queue_free(); await process_frame
	check(Engine.time_scale==1,"Cleanup leaves normal time scale")
	print("SUNDERING_STRIKE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
