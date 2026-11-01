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
	check(not c.enter(),"Archive travel gate")
	s.story_completed.append("archive"); check(c.enter(),"Coast entry")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("ash_hull"); check(not c.act("ash_inspect") and not c.act("ash_workers"),"Cannot skip acceptance or evidence")
	talk("ash_factor"); check(press("Investigate the Ashport") and s.shore.ash_started,"Accept actual Brann dialogue")
	check(not c.act("ash_start") and not c.act("ash_hear"),"No repeat acceptance or premature claim")
	for id in ["ash_hull","ash_manifest"]:
		talk(id); check(w.session_save.supported_position(p.position,p),"Supported evidence approach: "+id)
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*5
		check(not c.act("ash_inspect"),"Stale remote evidence rejected")
		p.position=pos; check(press("Inspect and record") and not c.act("ash_inspect"),"Unique actual evidence: "+id)
	check(s.save_to("user://ash-boat-mid.json"),"Partial progress saves")
	var loaded=State.new(); check(loaded.load_from("user://ash-boat-mid.json") and loaded.shore.ash_evidence.size()==2,"Evidence reloads")
	for id in ["ash_factor","ash_reader"]:
		talk(id); check(w.session_save.supported_position(p.position,p),"Supported claimant approach: "+id)
		check(press("Record the") and not c.act("ash_hear"),"Unique actual claim: "+id)
	check(s.save_to("user://ash-boat-choice.json"),"Pending choice saves")
	for choice in ["workers","choir"]:
		s.load_from("user://ash-boat-choice.json"); talk("ash_hull")
		var gold: int=s.gold; var count: int=s.inventory.size(); var before: Dictionary=s.materials.duplicate(true)
		check(press("Return the plates" if choice=="workers" else "Entrust the originals") and s.shore.ash_choice==choice,"Actual cargo choice: "+choice)
		check(s.gold==gold+140 and s.inventory.size()==count+1,"One gold and gear reward: "+choice)
		var found:=false
		for uid in s.inventory:
			var item: Dictionary=s.inventory[uid]
			if item.get("custom_name","")==("Ashport's Shelter" if choice=="workers" else "Fireproof Memory"):
				found=item.quality==2 and item.favorite and item.base_id==("breakwater_mantle" if choice=="workers" else "signal_focus")
		check(found,"Superior favorite equipment: "+choice)
		for mat in ({"steel_ingot":6} if choice=="workers" else {"resonant_ore":6,"ash_glass":4}):
			check(s.materials.get(mat,0)==before.get(mat,0)+(4 if mat=="ash_glass" else 6),"Exact materials: "+mat)
		check(not c.act("ash_workers") and not c.act("ash_choir") and not c.ash_cargo.visible,"Cargo removed; permanent award")
		check(s.save_to("user://ash-boat-final.json") and loaded.load_from("user://ash-boat-final.json") and loaded.shore.ash_choice==choice,"Outcome reloads")
		w.hud.world_map.selected_quest="side_ashport"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal outcome")
	check(not s.shore.accepted and not s.shore.core and s.shore.get("compact_stage",0)==0 and not s.choir.get("listener_joined",false),"Independent campaign and faction progress")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://ash-boat-final.json"))
	for patch in [{"ash_started":"yes"},{"ash_started":false},{"ash_evidence":[]},{"ash_evidence":["ash_hull","ash_hull"]},{"ash_claims":["ash_factor"]},{"ash_claims":{}},{"ash_choice":"both"}]:
		var invalid: Dictionary=data.duplicate(true); invalid.shore.merge(patch,true)
		var f=FileAccess.open("user://ash-boat-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://ash-boat-invalid.json") and loaded.shore.ash_choice=="choir","Malformed progress rejected atomically: "+str(patch))
	for key in ["ash_started","ash_evidence","ash_claims","ash_choice"]: data.shore.erase(key)
	var f=FileAccess.open("user://ash-boat-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://ash-boat-legacy.json") and not loaded.shore.get("ash_started",false),"Legacy defaults")
	w.queue_free(); await process_frame
	print("ASH_BOAT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
