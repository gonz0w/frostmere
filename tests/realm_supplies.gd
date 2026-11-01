extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	var p=w.player; var r=w.realms; var s=p.character
	p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated supply fixture")
	check(not r.enter("aeralis") and not r.enter("crucible"),"Existing realm travel gates")
	s.story_completed.append("threshold")
	for enemy in r.enemies: enemy.set_physics_process(false)
	for realm in ["aeralis","crucible"]:
		if realm=="crucible":
			for id in ["returning_light","winter_siege","broken_seal"]: s.story_completed.append(id)
		check(r.enter(realm),"Actual realm entry: "+realm)
		var arrows: int=s.materials.get("arrow",0); var potions: int=s.consumables.get("magicka_draught",0); var rounds: int=s.materials.get("hell_round",0)
		var expected_arrows:=36 if realm=="aeralis" else 48
		var expected_potions:=2 if realm=="aeralis" else 3
		p.position=r.vector(r.definitions[realm].origin)+Vector3(-6,.1,17.3)
		check(w.nearest_interaction().get("id","")=="attune","Actual supply-crystal prompt")
		check(w.session_save.supported_position(p.position,p),"Arrival crystal approach supported")
		w.interact_nearby()
		check(realm in s.realm_progress.attuned and s.materials.arrow==arrows+expected_arrows and s.consumables.magicka_draught==potions+expected_potions,"Exact support kit through E interaction")
		check(s.materials.get("hell_round",0)==rounds+(160 if realm=="crucible" else 0),"Existing infernal ammo preserved")
		w.interact_nearby(); check(s.materials.arrow==arrows+expected_arrows and s.consumables.magicka_draught==potions+expected_potions,"Repeated E cannot duplicate supplies")
		s.equip(s.add_item("steel_bow",2),"main_hand"); p.attack_cooldown=0; p.spell_cooldown=0; p.blocking=false
		check(p.attack() and s.materials.arrow==arrows+expected_arrows-1,"Supply arrow fires through real bow attack")
		w.adventure.clear_projectiles(); p.magicka=10
		check(s.consume("magicka_draught",p).begins_with("Used") and p.magicka==60 and s.consumables.magicka_draught==potions+expected_potions-1,"Reserve potion restores real magicka")
		check(s.save_to("user://realm-supply.json"),"Used supplies save")
		var loaded=State.new(); check(loaded.load_from("user://realm-supply.json") and loaded.materials.arrow==s.materials.arrow and loaded.consumables.magicka_draught==s.consumables.magicka_draught,"Used supplies reload exactly")
		check(s.load_from("user://realm-supply.json") and not r.attune(realm),"Loaded attunement stays claimed")
		r.leave(); check(r.enter(realm) and not r.attune(realm),"Travel cannot refill the kit")
		# Older claimed saves have no new supply marker or catch-up reward.
		s.materials.erase("arrow"); s.consumables.erase("magicka_draught")
		check(s.save_to("user://realm-supply-old.json") and s.load_from("user://realm-supply-old.json"),"Claimed save without reserve inventory loads")
		check(not r.attune(realm) and s.materials.get("arrow",0)==0 and s.consumables.get("magicka_draught",0)==0,"No retroactive refill for earlier claimed attunement")
		r.leave()
	w.queue_free(); await process_frame
	print("REALM_SUPPLIES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
