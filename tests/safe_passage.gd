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
	p=w.player; c=w.shore; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated Compact fixture")
	s.story_completed.append("archive"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)

	s.shore.accepted=true; s.shore.heard=["harbor","salvager"]; s.shore.relays=["pump","relay"]; s.shore.log=true; s.shore.core=true; s.shore.defeated=["shore_6"]; s.shore.choice="navigation"; s.shore.rewarded=true; s.story_completed.append("tides")


	talk("compact"); check(not c.act("passage_start"),"Envoy required")
	s.shore.compact_stage=4; s.shore.compact_evidence=["registry","nameplate","salvager"]; s.shore.defeated.append("shore_0"); s.shore.defeated.append("shore_2"); s.shore.harbor_stage=5; s.shore.harbor_choice="sealed"; s._commit()
	talk("compact"); check(press("Draft the new") and s.shore.passage_started,"Vessa opens charter")
	talk("charter"); check(not c.act("passage_sign:open"),"All proposals required")
	for id in ["harbor","salvager","witness"]:
		talk(id); check(press("Discuss the passage"),"Optional charter discussion "+id)
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("passage_hear"),"Remote proposal rejected"); p.position=pos
		check(press("Record this proposal") and id in s.shore.passage_heard,"Proposal recorded "+id)
		check(not c.act("passage_hear"),"Proposal cannot repeat")
	talk("harbor"); check(press("Ask about the missing"),"Silver crew quest stays accessible during charter")
	talk("salvager"); check("NERIS" in c.description.text,"Salvage dialogue stays accessible")
	check(s.save_to("user://passage-ready.json"),"Unsigned charter saves")
	var loaded=State.new(); check(loaded.load_from("user://passage-ready.json") and loaded.shore.passage_heard.size()==3,"Unsigned charter reloads")
	for choice in ["open","house","outlaw"]:
		s.load_from("user://passage-ready.json"); talk("charter")
		check(w.session_save.supported_position(p.position,p),"Charter table supported")
		check("permanently closes" in c.description.text,"Explicit rival consequence before signing")
		check(not c.act("passage_sign:unknown"),"Unknown charter rejected")
		var gold: int=s.gold; var before: Array=s.inventory.keys()
		check(press({"open":"Sign open","house":"Sign Merrow charter ·","outlaw":"Sign Merrow charter AND"}[choice]) and s.shore.passage_choice==choice,"Actual charter signing "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].base_id=="voice_amulet" and s.inventory[rewards[0]].quality==4 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant==("vigor" if choice=="open" else "insight"),"Exact Masterwork reward "+choice)
		check(s.gold==gold+(200 if choice=="open" else 300),"Exact gold reward "+choice)
		check(c.concord_capstone_blocked()==(choice=="outlaw"),"Only ban closes rival capstone "+choice)
		check(s.shore.harbor_choice=="sealed" and s.shore.choice=="navigation","Earlier choices preserved")
		check(not c.act("passage_sign:open") and not c.act("passage_sign:house"),"Charter and reward immutable")
		check(c.charter_label.text!="CHARTER AWAITING SEALS","Visible charter changes")
		check(s.save_to("user://passage-done.json") and loaded.load_from("user://passage-done.json") and loaded.shore.passage_choice==choice,"Outcome reloads "+choice)
		w.hud.world_map.selected_quest="tide_compact_3"; w.hud.world_map._show_quest(); check("Harbor Speaker" in w.hud.world_map.quest_text.text,"Final rank in journal")
		w.hud.world_map.selected_quest="sable_concord_3"; w.hud.world_map._show_quest(); check(("Permanently closed" in w.hud.world_map.quest_text.text)==(choice=="outlaw"),"Rival journal reflects ban")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://passage-done.json"))
	for issue in ["started","rank","missing","duplicate","unknown","choice"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"started": invalid.shore.passage_started=false
			"rank": invalid.shore.harbor_stage=4; invalid.shore.harbor_choice=""
			"missing": invalid.shore.passage_heard=[]
			"duplicate": invalid.shore.passage_heard=["harbor","harbor","witness"]
			"unknown": invalid.shore.passage_heard=["harbor","salvager","other"]
			"choice": invalid.shore.passage_choice="both"
		var f=FileAccess.open("user://passage-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://passage-bad.json") and loaded.shore.passage_choice=="outlaw","Atomic save validation "+issue)
	for key in ["passage_started","passage_heard","passage_choice"]: data.shore.erase(key)
	var f=FileAccess.open("user://passage-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://passage-legacy.json") and not loaded.shore.get("passage_started",false),"Legacy Envoy saves compatible")
	w.queue_free(); await process_frame
	print("SAFE_PASSAGE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
