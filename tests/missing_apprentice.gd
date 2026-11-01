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
	c.close_dialog(); p.set_paused(false); p.position=c.interaction_position(id)+Vector3(0,.1,1.3); w.interact_nearby()
func press(prefix: String) -> bool:
	for b in c.options.get_children():
		if b.text.begins_with(prefix): b.pressed.emit(); return true
	return false
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	p=w.player; c=w.archive_chapter; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Apprentice fixture is isolated")
	check(not c.enter(),"Stonewake still gates Pinehall access")
	s.story_completed.append("stonewake"); check(c.enter(),"Normal road opens")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("apprentice"); check(not c.act("apprentice_rescue"),"Cannot skip research trail")
	talk("apprentice_notice"); check(press("Follow the missing") and s.archive.apprentice_stage==1,"Actual notice accepts investigation")
	check(not c.act("apprentice_accept") and not s.archive.accepted,"Optional acceptance is independent and single use")
	talk("notes"); check(press("Follow Iven") and s.archive.apprentice_stage==2,"Existing testimony offers a separate apprentice trail")
	check(s.save_to("user://apprentice-mid.json"),"Partial investigation saves")
	var loaded=State.new(); check(loaded.load_from("user://apprentice-mid.json") and loaded.archive.apprentice_stage==2,"Partial investigation reloads")
	talk("apprentice"); check(not c.act("apprentice_rescue"),"Living sentinel prevents safe return")
	c.close_dialog(); p.set_paused(false); c.enemies[2].receive_damage(10000,p)
	talk("apprentice"); var pos: Vector3=p.position; p.position+=Vector3.RIGHT*5
	check(not c.act("apprentice_rescue"),"Remote stale rescue rejected")
	p.position=pos; check(press("Help Iven") and s.archive.apprentice_stage==3 and not p.paused and not c.dialog.visible,"Actual rescue closes dialogue and returns control")
	check(c.apprentice.position==c.ORIGIN+Vector3(4,0,24),"Rescued NPC relocates to camp")
	check(c.nearest().get("id","")!="apprentice","Old alcove no longer targets relocated NPC")
	talk("apprentice"); check(c.subject=="apprentice" and "RETURNED" in c.title.text and w.session_save.supported_position(p.position,p),"Relocated camp NPC is interactable on supported ground")
	check(s.archive.recipient=="" and not s.archive.atlas and s.archive.get("lantern_trial","")=="","Rescue preserves atlas custody and faction gates")
	check(s.save_to("user://apprentice-choice.json"),"Pending research decision saves")
	for choice in ["return","protect"]:
		s.load_from("user://apprentice-choice.json"); talk("apprentice")
		var gold: int=s.gold; var before: Array=s.inventory.keys()
		check(press("Return research" if choice=="return" else "Protect authorship") and s.archive.apprentice_choice==choice,"Actual research choice commits: "+choice)
		var formula: String="insight" if choice=="return" else "vigor"
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].base_id==("crystal_staff" if choice=="return" else "cloth_chest") and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant==formula,"Exact protected Superior equipment reward: "+choice)
		check(s.gold==gold+100 and formula in s.formulas,"Gold and reusable enchantment formula granted: "+choice)
		check(not c.act("apprentice_return") and not c.act("apprentice_protect"),"Cannot repeat or switch choice: "+choice)
		check(s.save_to("user://apprentice-complete.json") and loaded.load_from("user://apprentice-complete.json") and loaded.archive.apprentice_choice==choice,"Completed outcome reloads: "+choice)
		w.hud.world_map.selected_quest="side_pinehall"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal records outcome: "+choice)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://apprentice-complete.json"))
	for bad in [-1,4,1.5,true,"safe"]:
		var invalid: Dictionary=data.duplicate(true); invalid.archive.apprentice_stage=bad
		var f=FileAccess.open("user://apprentice-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://apprentice-invalid.json") and loaded.archive.apprentice_choice=="protect","Malformed stage rejected atomically: "+str(bad))
	for issue in ["guard","early","choice"]:
		var invalid: Dictionary=data.duplicate(true)
		if issue=="guard": invalid.archive.defeated=[]
		elif issue=="early": invalid.archive.apprentice_stage=1
		else: invalid.archive.apprentice_choice="both"
		var f=FileAccess.open("user://apprentice-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://apprentice-invalid.json"),"Impossible progress rejected: "+issue)
	data.archive.erase("apprentice_stage"); data.archive.erase("apprentice_choice")
	var f=FileAccess.open("user://apprentice-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://apprentice-legacy.json") and loaded.archive.get("apprentice_stage",0)==0,"Legacy profiles default to unstarted quest")
	w.queue_free(); await process_frame
	print("MISSING_APPRENTICE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
