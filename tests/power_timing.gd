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
	for i in range(4): await physics_frame
	var p=w.player; var a=w.adventure; var e=a.enemies[0]
	a.enter(); p.set_physics_process(false); p.set_process(false); p.set_paused(false)
	for actor in a.enemies: actor.set_physics_process(false); actor.global_position=Vector3(30,-30,0)
	p.position=Vector3(0,-29.95,2); p.rotation=Vector3.ZERO
	for move in ["whirlwind","sunder"]:
		w.audio.cooldowns.clear()
		p.power=100; p.attack_cooldown=0; e.dead=false; e.health=500; e.global_position=p.position+Vector3.FORWARD*2
		var damage: float=p.derived.damage*(3 if move=="sunder" else 2)
		p.activate_power(move); p.update_power(.1)
		check(e.health==500,"No hit during early windup")
		e.global_position+=Vector3.RIGHT*10; p.update_power(.5)
		check(w.audio.last_effect=="power_impact","Power impact cue occurs on strike")
		check(e.health==500 and p.power_hit,"Moving outside attack avoids impact")
		e.global_position=p.position+Vector3.FORWARD*2; p.update_power(.1)
		check(e.health==500,"Missed strike cannot hit later"); p.cancel_power()
		p.power=100; p.attack_cooldown=0; p.activate_power(move); p.set_paused(true); p.update_power(2)
		check(e.health==500 and Engine.time_scale==1,"Menu before impact cancels pending damage"); p.set_paused(false)
		p.power=100; p.attack_cooldown=0; p.activate_power(move); damage=p.power_damage
		p.update_power(2)
		check(is_equal_approx(e.health,500-damage),"Large frame step applies exactly one impact")
		check(p.power==0 and Engine.time_scale==1 and p.power_remaining==0,"Impact at expiry cannot recharge meter or strand slow motion")
		var hp: float=e.health; p.update_power(2); check(e.health==hp,"Expired attack cannot hit again")
	w.queue_free(); await process_frame
	print("POWER_TIMING_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
