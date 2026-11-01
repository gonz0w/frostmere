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
	c.close(); p.set_paused(false); p.position=(c.POSITION if id=="board" else c.road_position(id))+Vector3(0,.1,1.3); c.selected="lodge"; w.interact_nearby()
func press(prefix: String) -> bool:
	for b in c.actions.get_children():
		if b.text.begins_with(prefix): b.pressed.emit(); return true
	return false
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	p=w.player; c=w.hunts; s=p.character; p.set_physics_process(false)
	for enemy in w.wilderness.enemies: enemy.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated Lodge fixture")

	talk("board"); c.selected="warden"; c.refresh(); check(not c.warden_act("start"),"Waykeeper required")
	s.adventure.accepted=true; s.adventure.rewarded=true; s.adventure.defeated=["captain"]; s.adventure.looted=["captain"]; s.hunt.lodge_started=true; s.hunt.lodge_joined=true; s.hunt.lodge_repairs=["village","crossing","ridge"]; s.hunt.water_stage=4; s.hunt.water_choice="expose"; s.wilderness.defeated=["wild_9","wild_10"]
	talk("board"); check(press("Decide Who Guards") and press("Accept the north-pass") and s.hunt.watch_started,"Board starts finale")
	check(not c.warden_act("neutral"),"Harvested colossus proof required")
	c.close(); p.set_paused(false); w.wilderness.enemies[11].receive_damage(10000,p)
	s.wilderness.looted.append("wild_11")
	talk("board"); press("Decide Who Guards"); check(not c.warden_act("clan"),"Independent character cannot select clan rule")
	check(s.save_to("user://warden-ready.json"),"Ready finale saves")
	var loaded=State.new(); check(loaded.load_from("user://warden-ready.json"),"Ready finale reloads")
	for choice in ["neutral","clan"]:
		s.load_from("user://warden-ready.json")
		if choice=="clan":
			s.mountain={"accepted":true,"heard":["stoneguard","stormweaver"],"ledger":true,"settlement":"accord","clan":"stoneguard","wards":[],"rank":0,"services":[],"reputation":{"stoneguard":0,"stormweaver":0},"defeated":["pass_0","pass_1","pass_2"],"looted":[]}; s.story_completed.append("stonewake"); s.story_completed.append("council")
		talk("board"); press("Decide Who Guards"); var gold: int=s.gold; var before: Array=s.inventory.keys()
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*12; check(not c.warden_act(choice),"Remote mandate rejected"); p.position=pos
		check(press("Keep the Lodge" if choice=="neutral" else "Place the watch") and s.hunt.watch_choice==choice,"Actual Warden choice "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].quality==4 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].base_id==("wardkeeper_amulet" if choice=="neutral" else "steel_bow") and s.gold==gold+220,"Exact Masterwork reward")
		check(not c.warden_act("neutral") and not c.warden_act("clan"),"Mandate immutable")
		c.close(); p.set_paused(false); c._process(1); var patrol_pos: Vector3=c.watch_patrol.position; c._process(1)
		check(c.watch_patrol.visible and c.watch_patrol.position!=patrol_pos,"Visible patrol moves")
		p.set_paused(true); patrol_pos=c.watch_patrol.position; c._process(1); check(c.watch_patrol.position==patrol_pos,"Menus pause watch")
		talk("watch_cache"); check(w.session_save.supported_position(p.position,p),"Supply cache on supported ground")
		var heal: int=s.consumables.get("healing_draught",0); var steel: int=s.materials.get("steel_ingot",0)
		check(press("Collect road watch") and s.hunt.watch_supplies,"Actual support claim")
		check(s.consumables.get("healing_draught",0)==heal+3 if choice=="neutral" else s.materials.steel_ingot==steel+8,"Policy-specific support")
		check(not c.warden_act("support"),"Support one-time")
		check(s.save_to("user://warden-done.json") and loaded.load_from("user://warden-done.json") and loaded.hunt.watch_choice==choice,"Outcome reloads")
		w.hud.world_map.selected_quest="hearthbound_3"; w.hud.world_map._show_quest(); check("Warden" in w.hud.world_map.quest_text.text and "supplies collected" in w.hud.world_map.quest_text.text,"Journal rank and claimed supply state")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://warden-done.json"))
	for issue in ["start","rank","choice","proof","clan"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"start": invalid.hunt.watch_started=false
			"rank": invalid.hunt.water_choice=""
			"choice": invalid.hunt.watch_choice="both"
			"proof": invalid.wilderness.looted=[]
			"clan": invalid.mountain.clan=""
		var f=FileAccess.open("user://warden-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://warden-bad.json"),"Invalid finale rejected "+issue)
	for key in ["watch_started","watch_choice","watch_supplies"]: data.hunt.erase(key)
	var f=FileAccess.open("user://warden-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://warden-legacy.json") and not loaded.hunt.get("watch_started",false),"Legacy Waykeeper saves compatible")
	w.queue_free(); await process_frame
	print("WARDEN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
