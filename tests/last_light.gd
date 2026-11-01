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
	p=w.player; c=w.shore; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated profiles")
	check(not c.enter(),"Archive gate remains")
	s.story_completed.append("archive"); check(c.enter(),"Normal coast entry")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("light_control"); check(not c.act("light_repair") and not c.act("light_signal"),"Cannot skip investigation")
	talk("light_keeper"); check(w.session_save.supported_position(p.position,p),"Pilot supported approach")
	check(press("Help the Hallowcliff") and s.shore.light_stage==1,"Actual pilot acceptance")
	check(not c.act("light_start") and not c.act("light_public"),"No repeat or early reward")
	talk("light_record"); check(w.session_save.supported_position(p.position,p),"Log supported approach")
	check(press("Take the log") and s.shore.light_stage==2,"Actual keeper evidence")
	check(s.save_to("user://last-light-mid.json"),"Investigation saves")
	var loaded=State.new(); check(loaded.load_from("user://last-light-mid.json") and loaded.shore.light_stage==2,"Investigation reloads")
	talk("light_control"); check(w.session_save.supported_position(p.position,p),"Controls supported approach")
	s.materials.iron_ingot=2; s.materials.crystal=0
	check(not c.act("light_repair") and s.materials.iron_ingot==2 and s.shore.light_stage==2,"Missing crystal spends nothing")
	s.materials.iron_ingot=1; s.materials.crystal=1
	check(not c.act("light_repair") and s.materials.crystal==1,"Missing iron spends nothing")
	s.materials.iron_ingot=2
	var pos: Vector3=p.position; p.position+=Vector3.RIGHT*5
	check(not c.act("light_repair") and s.materials.iron_ingot==2,"Remote stale repair rejected")
	p.position=pos; c.open_dialog("light_control")
	check(press("Repair the frame") and s.shore.light_stage==3 and s.materials.iron_ingot==0 and s.materials.crystal==0,"Exact atomic repair cost")
	check(c.last_light.visible and c.last_lamp.visible and not c.beacon.visible,"Independent visible signal light")
	check(not c.act("light_repair"),"No duplicate repair")
	check(s.save_to("user://last-light-repaired.json") and loaded.load_from("user://last-light-repaired.json") and loaded.shore.light_stage==3,"Repaired but unsignaled save")
	var ship_before: Vector3=c.last_ship.position
	check(press("Signal the safe") and s.shore.light_stage==4 and not c.dialog.visible and not p.paused,"Actual signal returns to gameplay")
	check(c.last_ship.position!=ship_before and c.last_caption.text=="SHIP AT SAFE ANCHOR","Ship visibly reaches safe anchor")
	check(not c.act("light_signal"),"Closed dialogue rejects repeat")
	check(s.save_to("user://last-light-choice.json"),"Unresolved report saves")
	for choice in ["public","family"]:
		s.load_from("user://last-light-choice.json"); talk("light_keeper")
		var gold: int=s.gold; var count: int=s.inventory.size()
		check(press("Publish the log" if choice=="public" else "Report the route") and s.shore.light_choice==choice,"Actual reporting choice: "+choice)
		check(s.gold==gold+120 and s.inventory.size()==count+1,"Exact gold and one item")
		var found:=false
		for uid in s.inventory:
			var item: Dictionary=s.inventory[uid]
			if item.get("custom_name","")==("Keeper's Witness" if choice=="public" else "The Quiet Passage"):
				found=item.quality==2 and item.favorite and item.base_id==("starsignal_staff" if choice=="public" else "tideglass_saber")
		check(found,"Distinct Superior protected reward")
		check(not c.act("light_public") and not c.act("light_family") and s.gold==gold+120,"Permanent one-time reward")
		check(s.save_to("user://last-light-final.json") and loaded.load_from("user://last-light-final.json") and loaded.shore.light_choice==choice,"Final outcome reloads")
		w.hud.world_map.selected_quest="side_hallowcliff"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal completed outcome")
	check(not s.shore.accepted and not s.shore.core and s.shore.choice=="" and s.shore.get("compact_stage",0)==0,"Main shore and faction progress independent")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://last-light-final.json"))
	for bad in [-1,5,2.5,"yes",true]:
		var invalid: Dictionary=data.duplicate(true); invalid.shore.light_stage=bad
		var f=FileAccess.open("user://last-light-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://last-light-invalid.json") and loaded.shore.light_choice=="family","Malformed stage rejected atomically: "+str(bad))
	for issue in ["early","choice","gate"]:
		var invalid: Dictionary=data.duplicate(true)
		if issue=="early": invalid.shore.light_stage=3
		elif issue=="choice": invalid.shore.light_choice="both"
		else: invalid.story_completed.erase("archive")
		var f=FileAccess.open("user://last-light-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://last-light-invalid.json"),"Impossible progress rejected: "+issue)
	data.shore.erase("light_stage"); data.shore.erase("light_choice")
	var f=FileAccess.open("user://last-light-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://last-light-legacy.json") and loaded.shore.get("light_stage",0)==0,"Legacy defaults")
	w.queue_free(); await process_frame
	print("LAST_LIGHT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
