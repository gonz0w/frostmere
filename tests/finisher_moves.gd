extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS " + label)
	else: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p = world.player; var roster = world.wilderness.enemies
	p.set_physics_process(false); p.set_process(false)
	for e in roster: e.set_physics_process(false)
	var index := 0
	for family in p.FinisherMoves.MOVES:
		var e = roster[index]; index += 1
		p.character.equip(p.character.add_item("iron_"+family),"main_hand")
		p.position = Vector3(-28,0,-20); p.rotation = Vector3(0, index*PI/3, 0)
		e.position = p.position - p.global_basis.z*1.5; e.health=5
		var hand_position: Vector3 = p.first_person_hands.position
		var arm: Vector3 = p.right_arm.rotation
		var hands: Vector3 = p.first_person_hands.rotation
		check(p.activate_finisher() and p.finisher_move == p.FinisherMoves.MOVES[family],family+" selects its move")
		var impact: float = p.finisher_move.impact
		p.update_finisher(impact*.5)
		check(not e.dead and p.right_arm.rotation != arm and p.first_person_hands.position != hand_position,family+" animates both camera rigs before impact")
		p.set_paused(true)
		check(not e.execution_locked and p.first_person_hands.position == hand_position and p.right_arm.rotation == arm and p.first_person_hands.rotation == hands,family+" cancellation restores complete pose")
		p.set_paused(false); p.activate_finisher(); p.update_finisher(impact+.01)
		check(e.dead and e.enemy_id in p.character.wilderness.defeated,family+" impacts through normal defeat path")
		var fragments = e.adventure.get_children().filter(func(n): return n.has_meta("finisher_surface"))[-1]
		check((-fragments.global_basis.z).dot(-p.global_basis.z)>.999,family+" fragments follow the actual strike heading")
		var xp: int=p.character.skills.xp.melee
		p.update_finisher(2)
		check(p.character.skills.xp.melee == xp and p.first_person_hands.position == hand_position and not e.execution_locked,family+" recovery restores pose without duplicate XP")
	var giant = roster[11]; giant.health=5
	p.position=giant.position+Vector3.BACK*2; p.rotation=Vector3.ZERO
	check(giant.finisher_surface()=="stone" and roster[6].finisher_surface()=="flesh","Monster anatomy selects stone or flesh fragments")
	check(p.activate_finisher(),"Giant can receive weapon-specific finisher")
	p.update_finisher(p.finisher_move.impact+.01)
	var burst = world.wilderness.get_children().filter(func(n): return n.has_meta("finisher_surface"))[-1]
	check(giant.dead and burst.get_child(0).mesh.material.albedo_color.is_equal_approx(Color("788474")),"Stone giant sheds stone-colored fragments")
	p.update_finisher(2)
	world.queue_free(); await process_frame
	print("FINISHER_MOVES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
