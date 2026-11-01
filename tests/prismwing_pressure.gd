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
	var p=w.player; var r=w.realms; var e=r.enemies[2]
	check(not p.character.persist,"Pressure test uses isolated profile")
	r.enter("aeralis",true); p.set_physics_process(false)
	for actor in r.enemies: actor.set_physics_process(false)
	p.position=e.global_position+Vector3.BACK*3
	e.health=e.maximum_health*.5; e._physics_process(.02)
	check(e.stagger_time>1.5 and e.windup==0,"Wing fracture retains its free counterattack opening")
	e.stagger_time=0; e.cooldown=0; var hp: float=p.health
	e._physics_process(.02)
	check(e.attack_kind=="bite" and is_equal_approx(e.windup,.9) and p.health==hp and "BITE" in e.label.text,"Close second-phase attack warns before damage")
	var aim: Vector3=e.aim; p.position+=Vector3.RIGHT*4
	e._physics_process(.3)
	check(e.aim==aim,"Bite direction stays locked during warning")
	check(e.jaw.rotation.x<-.2 and e.head.position.z> -1.6,"Bite opens jaw and draws head back without changing aim")
	e._physics_process(.61)
	check(p.health==hp and is_equal_approx(e.cooldown,2.4),"Sidestep avoids bite and creates recovery")
	check(e.head.position.z< -1.6 and e.bite_recoil>0,"Bite snap extends the visual head into recoil")
	p.position=e.global_position+Vector3.BACK*3; p.invulnerable=0; p.blocking=false
	e.cooldown=0; e._physics_process(.02); e._physics_process(.91)
	check(is_equal_approx(hp-p.health,32*100.0/(100+float(p.derived.armor)*1.5)),"Remaining in committed bite cone deals exact armored damage")
	hp=p.health; p.invulnerable=0; e._physics_process(.1)
	check(p.health==hp,"Bite cannot repeat during recovery")
	for escape in [Vector3.BACK*4.2,Vector3.FORWARD*3,Vector3(0,3,3)]:
		p.position=e.global_position+Vector3.BACK*3; e.cooldown=0; e._physics_process(.02)
		p.position=e.global_position+escape; e._physics_process(.91)
		check(p.health==hp,"Range, facing or height can evade bite: "+str(escape))
	for reason in ["pause","travel","stagger","execution"]:
		p.position=e.global_position+Vector3.BACK*3; e.cooldown=0; e._physics_process(.02)
		match reason:
			"pause": p.set_paused(true)
			"travel": r.current="crucible"
			"stagger": e.parried()
			"execution": e.execution_locked=true
		e._physics_process(.1)
		check(e.windup==0 and p.health==hp,"Pending bite cancels on "+reason)
		p.set_paused(false); r.current="aeralis"; e.execution_locked=false; e.stagger_time=0
	p.position=e.global_position+Vector3.BACK*8; e.cooldown=0; e._physics_process(.02)
	check(e.attack_kind=="fan" and e.windup>0,"Fractured wyrm still uses ranged fan against distant players")
	e.health=e.maximum_health; e.cooldown=0; p.position=e.global_position+Vector3.BACK*3; e._physics_process(.02)
	check(not e.fractured and e.attack_kind=="fan","Reset restores first-phase attacks")
	w.queue_free(); await process_frame
	print("PRISMWING_PRESSURE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
