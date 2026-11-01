extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
var w: Node3D
var c: Node3D
var p: CharacterBody3D
var s: RefCounted
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func talk(id: String) -> void:
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); w.interact_nearby()
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	p=w.player; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated reserves fixture")
	s.story_completed.append("returning_light"); s.story_completed.append("winter_siege")
	for area in ["winter","seal"]:
		c=w.get(area); check(c.enter(),"Qualified chapter entry")
		for enemy in c.enemies: enemy.set_physics_process(false)
		talk("supplies"); check(not c.act("supplies"),"Acceptance still required")
		talk("keeper"); check(c.act("accept"),"Accept chapter")
		var mats: Dictionary=s.materials.duplicate(true); var pots: int=s.consumables.get("magicka_draught",0)
		talk("supplies"); var pos: Vector3=p.position; p.position+=Vector3.RIGHT*7
		check(not c.act("supplies") and s.materials==mats,"Remote claim spends or grants nothing")
		p.position=pos; var pressed:=false
		for b in c.options.get_children():
			if b.text.begins_with("Collect"): b.pressed.emit(); pressed=true; break
		var expected_pots:=2 if area=="winter" else 3
		check(pressed and s.materials.arrow==mats.get("arrow",0)+60 and s.materials.station_round==mats.get("station_round",0)+120 and s.consumables.magicka_draught==pots+expected_pots,"Exact combat reserve via real button")
		var original: Dictionary={"steel_ingot":8,"crystal":6,"rune_dust":4} if area=="winter" else {"steel_ingot":8,"crystal":8,"rune_dust":4,"ash_glass":4}
		for mat in original: check(s.materials[mat]==mats.get(mat,0)+original[mat],"Required component stock preserved: "+mat)
		check(not c.act("supplies") and s.materials.arrow==mats.get("arrow",0)+60,"Duplicate claim rejected")
		c.close_dialog(); p.set_paused(false); s.equip(s.add_item("station_rifle",1),"main_hand"); p.attack_cooldown=0; p.blocking=false
		check(p.attack() and s.materials.station_round==mats.get("station_round",0)+119,"Reserve round fires through rifle")
		w.adventure.clear_projectiles(); s.equip(s.add_item("steel_bow",2),"main_hand"); p.attack_cooldown=0
		check(p.attack() and s.materials.arrow==mats.get("arrow",0)+59,"Reserve arrow fires through bow")
		w.adventure.clear_projectiles(); p.magicka=0
		check(s.consume("magicka_draught",p).begins_with("Used") and p.magicka==50,"Reserve draught restores real magicka")
		check(s.save_to("user://defense-supplies.json"),"Consumed reserves save")
		var expected_materials: Dictionary=s.materials.duplicate(); var expected_consumables: Dictionary=s.consumables.duplicate()
		for mat in expected_materials: expected_materials[mat]=int(expected_materials[mat])
		for item in expected_consumables: expected_consumables[item]=int(expected_consumables[item])
		var loaded=State.new(); check(loaded.load_from("user://defense-supplies.json") and loaded.materials==expected_materials and loaded.consumables==expected_consumables,"Supplies and consumption reload exactly after integer normalization")
		check(s.load_from("user://defense-supplies.json"),"Live save resumes")
		talk("supplies"); check(not c.act("supplies"),"Reload cannot refill stores")
		c.close_dialog(); p.set_paused(false); c.leave(); check(c.enter(),"Revisit chapter")
		talk("supplies"); check(not c.act("supplies"),"Revisit cannot refill stores")
		# Earlier collected saves have no entitlement to the newly added reserve.
		s.materials.erase("arrow"); s.materials.erase("station_round"); s.consumables.erase("magicka_draught")
		check(s.save_to("user://defense-old-claim.json") and s.load_from("user://defense-old-claim.json"),"Earlier claimed profile without ammunition loads")
		talk("supplies"); check(not c.act("supplies") and s.materials.get("arrow",0)==0 and s.materials.get("station_round",0)==0,"No retroactive free refill")
		c.close_dialog(); p.set_paused(false); c.leave()
	w.queue_free(); await process_frame
	print("DEFENSE_SUPPLIES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
