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

	talk("board"); c.selected="watershed"; c.refresh(); check(not c.water_act("start"),"Outrider required")
	s.adventure.accepted=true; s.adventure.rewarded=true; s.adventure.defeated=["captain"]; s.adventure.looted=["captain"]; s.hunt.lodge_started=true; s.hunt.lodge_joined=true; s.hunt.lodge_repairs=["village","crossing","ridge"]; s.wilderness.defeated=["wild_9","wild_10"]
	talk("board"); check(press("Investigate A Winter") and press("Investigate the silent") and s.hunt.water_stage==1,"Board starts watershed investigation")
	for id in ["den","runoff","grovekeeper"]:
		talk(id); check(c.selected=="watershed" and c.lodge_subject==id and w.session_save.supported_position(p.position,p),"Actual accessible investigation site "+id)
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*8; check(not c.water_act("trace"),"Remote trace rejected"); p.position=pos
		check(press({"den":"Follow the stained","runoff":"Collect residue","grovekeeper":"Record Senna"}[id]),"Evidence action "+id)
		check(not c.water_act("trace"),"Cannot repeat evidence")
	check(s.save_to("user://water-ready.json"),"Pending repair saves")
	var loaded=State.new(); check(loaded.load_from("user://water-ready.json") and loaded.hunt.water_stage==4,"Evidence reloads")
	for choice in ["expose","patron"]:
		s.load_from("user://water-ready.json"); talk("sluice")
		s.materials.wood=1; s.materials.herb=2; check(not c.water_act(choice) and s.materials.herb==2 and s.hunt.get("water_choice","")=="","Missing wood does not partially spend")
		s.materials.wood=2; var gold: int=s.gold; var before: Array=s.inventory.keys(); c.refresh()
		check(press("Repair and expose" if choice=="expose" else "Repair but conceal") and s.hunt.water_choice==choice,"Permanent outcome "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].base_id==("leather_chest" if choice=="expose" else "steel_bow") and s.inventory[rewards[0]].quality==3 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant==("vigor" if choice=="expose" else "fleet"),"Exact Exquisite reward")
		check(s.materials.wood==0 and s.materials.herb==0 and s.gold==gold+(160 if choice=="expose" else 220) and c.clean_sluice.visible,"Repair cost, gold and visible filter")
		check(not c.water_act("expose") and not c.water_act("patron"),"No duplicate or switched rewards")
		check(s.save_to("user://water-done.json") and loaded.load_from("user://water-done.json") and loaded.hunt.water_choice==choice,"Outcome reloads")
		w.hud.world_map.selected_quest="hearthbound_2"; w.hud.world_map._show_quest(); check("Waykeeper" in w.hud.world_map.quest_text.text,"Journal rank")
	check(not s.hunt.accepted and s.wilderness.defeated==["wild_9","wild_10"],"Existing wolf packs and hunts unchanged")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://water-done.json"))
	for issue in ["fraction","bool","overflow","choice","rank","early"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"fraction": invalid.hunt.water_stage=1.5
			"bool": invalid.hunt.water_stage=true
			"overflow": invalid.hunt.water_stage=5
			"choice": invalid.hunt.water_choice="both"
			"rank": invalid.hunt.lodge_joined=false
			"early": invalid.hunt.water_stage=1
		var f=FileAccess.open("user://water-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://water-bad.json") and loaded.hunt.water_choice=="patron","Atomic save rejection "+issue)
	data.hunt.erase("water_stage"); data.hunt.erase("water_choice")
	var f=FileAccess.open("user://water-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://water-legacy.json") and loaded.hunt.get("water_stage",0)==0,"Legacy Outrider saves compatible")
	w.queue_free(); await process_frame
	print("WATERSHED_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
