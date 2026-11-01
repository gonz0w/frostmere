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
	var p=w.player; var s=p.character
	p.set_physics_process(false)
	check(not s.persist,"Pacing fixture is isolated")
	s.equip(s.add_item("iron_dagger"),"main_hand")
	p.stamina=6; p.attack_cooldown=0
	check(p.attack() and p.stamina==0 and is_equal_approx(p.attack_cooldown,.38),"Actual dagger attack spends six stamina with faster cadence")
	p.stamina=100; var before: float=p.stamina
	check(not p.attack() and p.stamina==before,"Dagger cooldown still rejects repeated input")
	p.attack_cooldown=0; p.stamina=5
	check(not p.attack() and p.stamina==5,"Dagger cannot swing below its stamina cost")
	s.skills.xp.melee=400; s.skills.perks.append("measured_swing")
	p.stamina=4
	check(p.attack() and p.stamina==0,"Measured Swing reduces dagger cost to four")
	s.skills.perks.clear()
	for pair in [["iron_sword",.62],["iron_battleaxe",.85]]:
		s.equip(s.add_item(pair[0]),"main_hand"); p.attack_cooldown=0; p.stamina=100
		check(p.attack() and p.stamina==91 and is_equal_approx(p.attack_cooldown,pair[1]),"Existing weapon timing and stamina preserved: "+pair[0])
	s.skills.perks.append("measured_swing"); p.attack_cooldown=0; p.stamina=100
	check(p.attack() and p.stamina==94,"Measured Swing retains six-stamina cost for other melee weapons")
	s.skills.perks.clear(); s.equip(s.add_item("iron_dagger"),"main_hand")
	w.adventure.enter()
	for enemy in w.adventure.enemies: enemy.set_physics_process(false)
	var target=w.adventure.enemies[0]
	p.position=target.global_position+Vector3(0,0,2); p.rotation=Vector3.ZERO
	for i in range(3): await physics_frame
	p.derived.critical=0; p.stamina=100; p.attack_cooldown=0
	var hp: float=target.health; var damage: float=p.derived.damage
	check(p.attack() and is_equal_approx(target.health,hp-damage),"Faster dagger strike still applies ordinary weapon damage exactly once")
	hp=target.health
	check(not p.attack() and target.health==hp,"Cooldown prevents a second damage application")
	w.queue_free(); await process_frame
	print("MELEE_PACING_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
