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
	check(not s.persist and not w.atlas.persist,"Isolated Compact fixture")
	s.story_completed.append("archive"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("compact"); check(not c.act("compact_start"),"Black Shore completion required")
	s.shore.accepted=true; s.shore.heard=["harbor","salvager"]; s.shore.relays=["pump","relay"]; s.shore.log=true; s.shore.core=true; s.shore.defeated=["shore_6"]; s.shore.choice="navigation"; s.shore.rewarded=true; s.story_completed.append("tides")
	talk("compact"); check(press("Investigate the missing") and s.shore.compact_stage==1,"Real arbiter accepts")
	check(not c.act("compact_start") and not c.act("compact_oath") and not c.act("compact_hearing"),"Cannot repeat or skip investigation")
	talk("nameplate"); check(not c.act("compact_evidence"),"Coastal raider guards evidence")
	c.close_dialog(); p.set_paused(false); c.enemies[0].receive_damage(10000,p)
	for id in ["registry","nameplate","salvager"]:
		talk(id); check(c.subject==id and w.session_save.supported_position(p.position,p),"Accessible investigation node "+id)
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("compact_witness" if id=="salvager" else "compact_evidence"),"Remote evidence blocked"); p.position=pos
		check(press("Ask Neris" if id=="salvager" else "Record this") and id in s.shore.compact_evidence,"Real evidence action "+id)
		check(not c.act("compact_witness" if id=="salvager" else "compact_evidence"),"Evidence one time")
	check(not c.ship_plate.visible,"Recovered nameplate removed")
	check(s.save_to("user://compact-investigation.json"),"Investigation saves")
	var loaded=State.new(); check(loaded.load_from("user://compact-investigation.json") and loaded.shore.compact_evidence.size()==3,"Evidence reloads")
	talk("compact"); check(press("Convene") and s.shore.compact_stage==2,"Hearing opens")
	var gold: int=s.gold
	check(press("The crew stole") and s.shore.compact_stage==2 and s.gold==gold and "does not account" in c.description.text,"Unsupported claim gives retry without penalty")
	check(press("The fallen") and s.shore.compact_stage==2,"Star wreck cannot substitute for evidence")
	check(press("Relief cargo") and s.shore.compact_stage==3,"Supported finding upheld")
	c.close_dialog(); p.set_paused(false); c.leave(); c.enter(); talk("compact")
	check(s.shore.compact_stage==3 and s.gold==gold,"Membership can be deferred across travel")
	var before: Array=s.inventory.keys()
	check(press("Swear the Decksworn") and s.shore.compact_stage==4,"Explicit oath grants rank")
	var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
	check(rewards.size()==1 and s.inventory[rewards[0]].base_id=="tideglass_saber" and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].enchant=="fleet" and s.inventory[rewards[0]].favorite,"Exact protected Superior reward")
	check(s.gold==gold+140 and "fleet" in s.formulas,"Gold and formula granted")
	check(not c.act("compact_oath"),"No duplicate oath rewards")
	check(s.shore.choice=="navigation" and s.shore.get("silver_stage",0)==0,"Other coastal stories unchanged")
	w.hud.world_map.selected_quest="tide_compact_1"; w.hud.world_map._show_quest(); check("Decksworn" in w.hud.world_map.quest_text.text,"Quest journal rank")
	w.hud.world_map.selected_faction="tide_compact"; w.hud.world_map._show_faction(); check("Decksworn" in w.hud.world_map.faction_text.text and "initiation playable" in w.hud.world_map.faction_text.text,"Faction journal rank")
	s.save_to("user://compact-done.json"); check(loaded.load_from("user://compact-done.json") and loaded.shore.compact_stage==4,"Rank and reward save")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://compact-done.json"))
	for issue in ["negative","fraction","bool","overflow","unknown","duplicate","missing","guard","gate"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"negative": invalid.shore.compact_stage=-1
			"fraction": invalid.shore.compact_stage=1.5
			"bool": invalid.shore.compact_stage=true
			"overflow": invalid.shore.compact_stage=5
			"unknown": invalid.shore.compact_evidence=["other"]
			"duplicate": invalid.shore.compact_evidence=["registry","registry","salvager"]
			"missing": invalid.shore.compact_evidence=[]
			"guard": invalid.shore.defeated=["shore_6"]
			"gate": invalid.shore.rewarded=false
		var f=FileAccess.open("user://compact-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://compact-bad.json") and loaded.shore.compact_stage==4,"Atomic validation "+issue)
	data.shore.erase("compact_stage"); data.shore.erase("compact_evidence")
	var f=FileAccess.open("user://compact-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://compact-legacy.json") and loaded.shore.get("compact_stage",0)==0,"Legacy saves default unstarted")
	w.queue_free(); await process_frame
	print("TIDE_COMPACT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
