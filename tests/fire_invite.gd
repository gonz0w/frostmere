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
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.3); w.interact_nearby()
func press(prefix: String) -> bool:
	for b in c.options.get_children():
		if b.text.begins_with(prefix): b.pressed.emit(); return true
	return false
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	p=w.player; c=w.choir; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated Listener fixture")
	s.story_completed.append("council"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("keeper"); check(not c.act("listener_start"),"Main signal quest required")
	s.choir.accepted=true; s.choir.song=["ember","ash","stone"]; s.choir.activated=true; s.choir.defeated=["choir_4"]; s.choir.record=true; s.choir.rewarded=true; s.story_completed.append("choir"); s._commit()


	talk("keeper"); check(not c.act("fire_start"),"Cantor prerequisite")
	s.choir.listener_started=true; s.choir.listener_vigils=["vigil_south","vigil_middle","vigil_north"]; s.choir.listener_record=true; s.choir.listener_joined=true; s.choir.memory_started=true; s.choir.memory_lock=3; s.choir.memory_record=true; s.choir.memory_choice="publish"
	talk("keeper"); check(press("Discuss the bound") and press("Secure the ember") and s.choir.fire_started,"Real finale acceptance")
	talk("fire_cradle"); check(not c.act("fire_choose:contain"),"Governors required")
	for id in ["fire_west","fire_east"]:
		talk(id); check(not c.act("fire_secure"),"Living sentinel blocks governor")
		c.close_dialog(); p.set_paused(false); c.enemies[2 if id=="fire_west" else 3].receive_damage(10000,p)
		talk(id); var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("fire_secure"),"Remote action rejected"); p.position=pos
		check(press("Isolate and secure") and id in s.choir.fire_seals,"Governor secured")
		check(not c.act("fire_secure"),"Governor one time")
	check(s.save_to("user://fire-ready.json"),"Ready decision saves")
	var loaded=State.new(); check(loaded.load_from("user://fire-ready.json") and loaded.choir.fire_seals.size()==2,"Governors reload")
	for choice in ["awaken","contain","silence"]:
		s.load_from("user://fire-ready.json"); talk("fire_cradle")
		check(w.session_save.supported_position(p.position,p),"Cradle has supported ground")
		check("permanently closes" in c.description.text,"Consequence disclosed")
		var gold: int=s.gold; var before: Array=s.inventory.keys()
		check(press({"awaken":"Awaken for conquest","contain":"Contain under guard","silence":"Silence the ember"}[choice]) and s.choir.fire_choice==choice,"Actual finale choice "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].quality==4 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].base_id=={"awaken":"resonance_blade","contain":"cantors_staff","silence":"resolve_amulet"}[choice],"Exact Masterwork reward "+choice)
		check(s.gold==gold+250 and not c.act("fire_choose:contain") and not c.act("fire_choose:awaken"),"Rewards cannot repeat")
		check(s.save_to("user://fire-done.json") and loaded.load_from("user://fire-done.json") and loaded.choir.fire_choice==choice,"Finale reloads")
		w.hud.world_map.selected_quest="ashen_choir_3"; w.hud.world_map._show_quest(); check("Ember Voice" in w.hud.world_map.quest_text.text,"Final rank in journal")
	# A completed mandate prevents conquest but leaves peaceful outcomes open.
	s.load_from("user://fire-ready.json"); s.mountain.rank=3; talk("fire_cradle")
	check(not c.act("fire_choose:awaken") and not press("Awaken for conquest"),"Completed Clan Voice oath excludes conquest")
	check(press("Silence the ember"),"Completed Clan Voice keeps peaceful choice")
	s.load_from("user://fire-ready.json"); talk("fire_cradle"); c.act("fire_choose:awaken")
	c.close_dialog(); p.set_paused(false); c.leave()
	var m=w.mountain; s.story_completed.append("stonewake"); m.enter()
	s.mountain.clan="stoneguard"; s.mountain.rank=2
	p.position=m.ORIGIN+m.NODES.stoneguard+Vector3.BACK; m.open_dialog("stoneguard")
	check(not m.act("expedition"),"Conquest blocks actual commission action")
	s.mountain.expedition=true; s.wilderness={"defeated":["wild_11","wild_12"],"looted":["wild_11","wild_12"]}
	check(not m.act("mandate:holds") and not m.act("mandate:leader"),"Conquest blocks pending mandate despite monster proofs")
	w.hud.world_map.selected_quest="iron_pact_3"; w.hud.world_map._show_quest(); check("Permanently closed" in w.hud.world_map.quest_text.text,"Rival closure in journal")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://fire-done.json"))
	var conflict: Dictionary=data.duplicate(true); conflict.choir.fire_choice="awaken"; conflict.mountain.rank=3
	check(not loaded._valid_choir(conflict),"Save validation forbids simultaneous conquest and Clan Voice")
	for issue in ["rank","start","duplicate","missing","guard","choice"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"rank": invalid.choir.memory_choice=""
			"start": invalid.choir.fire_started=false
			"duplicate": invalid.choir.fire_seals=["fire_west","fire_west"]
			"missing": invalid.choir.fire_seals=[]
			"guard": invalid.choir.defeated.erase("choir_2")
			"choice": invalid.choir.fire_choice="both"
		var f=FileAccess.open("user://fire-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://fire-bad.json"),"Malformed finale rejected "+issue)
	for key in ["fire_started","fire_seals","fire_choice"]: data.choir.erase(key)
	var f=FileAccess.open("user://fire-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://fire-legacy.json") and not loaded.choir.get("fire_started",false),"Legacy Cantor saves compatible")
	w.queue_free(); await process_frame
	print("FIRE_INVITE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
