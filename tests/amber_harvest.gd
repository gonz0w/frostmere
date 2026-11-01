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
	p=w.player; c=w.roots; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated profiles")
	check(not c.enter(),"Stonewake gate")
	s.story_completed.append("stonewake"); check(c.enter(),"Woodland access")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("amber_plot"); check(not c.act("amber_sample") and not c.act("amber_test"),"No skipped investigation")
	talk("amber_healer"); check(w.session_save.supported_position(p.position,p),"Healer supported approach")
	check(press("Investigate the amber") and s.roots.amber_stage==1,"Actual acceptance")
	check(not c.act("amber_start") and not c.act("amber_protect"),"No duplicate start or early reward")
	talk("amber_plot"); check(w.session_save.supported_position(p.position,p),"Plot supported approach")
	check(press("Collect bark") and s.roots.amber_stage==2,"Actual sample collection")
	check(s.save_to("user://amber-mid.json"),"Sample saves")
	var loaded=State.new(); check(loaded.load_from("user://amber-mid.json") and loaded.roots.amber_stage==2,"Sample reloads")
	talk("amber_bench"); check(w.session_save.supported_position(p.position,p),"Bench supported approach")
	s.materials.herb=3; s.materials.water=1
	check(not c.act("amber_mix") and s.materials.herb==3,"Missing water spends nothing")
	s.materials.herb=2; s.materials.water=2
	check(not c.act("amber_mix") and s.materials.water==2,"Missing herbs spends nothing")
	s.materials.herb=3
	var pos: Vector3=p.position; p.position+=Vector3.RIGHT*5
	check(not c.act("amber_mix") and s.materials.herb==3,"Stale remote action rejected")
	p.position=pos; c.open_dialog("amber_bench")
	check(press("Prepare the trial") and s.roots.amber_stage==3 and s.materials.herb==0 and s.materials.water==0,"Atomic exact treatment cost")
	check(not c.act("amber_mix"),"No repeated mixing")
	check(s.save_to("user://amber-dose.json") and loaded.load_from("user://amber-dose.json") and loaded.roots.amber_stage==3,"Prepared dose reloads")
	talk("amber_plot"); check(press("Apply the prepared") and s.roots.amber_stage==4,"Actual treatment application")
	check(c.amber_crowns[0].material_override==w.blocks.materials.roots_leaf and c.amber_crowns[1].material_override==w.blocks.materials.roots_blight,"Trial heals only first tree")
	check(s.save_to("user://amber-choice.json"),"Pending decision saves")
	for choice in ["protect","logging"]:
		s.load_from("user://amber-choice.json"); talk("amber_healer")
		var gold: int=s.gold; var count: int=s.inventory.size(); var mats: Dictionary=s.materials.duplicate(true)
		check(press("Treat the grove" if choice=="protect" else "Authorize two") and s.roots.amber_choice==choice,"Actual permanent choice: "+choice)
		check(s.gold==gold+(100 if choice=="protect" else 160) and s.inventory.size()==count+1,"Exact gold and gear")
		var found:=false
		for uid in s.inventory:
			var item: Dictionary=s.inventory[uid]
			if item.get("custom_name","")==("Amber's Tomorrow" if choice=="protect" else "The Lean Season"):
				found=item.quality==2 and item.favorite and item.base_id==("groveheart_chest" if choice=="protect" else "pactkeeper_axe")
		check(found,"Distinct Superior favorite equipment")
		var mat: String="amber_resin" if choice=="protect" else "heartwood"
		check(s.materials.get(mat,0)==mats.get(mat,0)+(6 if choice=="protect" else 10),"Exact material reward")
		check(c.amber_stumps.visible==(choice=="logging") and c.amber_trees[1].visible==(choice=="protect") and c.amber_trees[0].visible,"Visible grove consequence")
		check(not c.act("amber_protect") and not c.act("amber_logging"),"No repeated or alternative reward")
		check(s.save_to("user://amber-final.json") and loaded.load_from("user://amber-final.json") and loaded.roots.amber_choice==choice,"Final outcome reloads")
		w.hud.world_map.selected_quest="side_alderrest"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal outcome")
	check(not s.roots.accepted and s.roots.cleansed.is_empty() and s.roots.choice=="" and not s.roots.get("coven_started",false),"Independent woodland and faction progress")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://amber-final.json"))
	for bad in [-1,5,1.5,"yes",true]:
		var invalid: Dictionary=data.duplicate(true); invalid.roots.amber_stage=bad
		var f=FileAccess.open("user://amber-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://amber-invalid.json") and loaded.roots.amber_choice=="logging","Invalid stage rejected atomically: "+str(bad))
	for issue in ["early","choice","gate"]:
		var invalid: Dictionary=data.duplicate(true)
		if issue=="early": invalid.roots.amber_stage=3
		elif issue=="choice": invalid.roots.amber_choice="both"
		else: invalid.story_completed.erase("stonewake")
		var f=FileAccess.open("user://amber-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://amber-invalid.json"),"Impossible progress rejected: "+issue)
	data.roots.erase("amber_stage"); data.roots.erase("amber_choice")
	var f=FileAccess.open("user://amber-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://amber-legacy.json") and loaded.roots.get("amber_stage",0)==0,"Legacy defaults")
	w.queue_free(); await process_frame
	print("AMBER_HARVEST_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
