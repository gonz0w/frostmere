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
	talk("keeper"); check(press("Discuss the ash") and press("Begin the three") and s.choir.listener_started,"Real initiation dialogue")
	check(not c.act("listener_start") and not c.act("listener_oath"),"No duplicate start or skipped oath")
	talk("roll"); check(not c.act("listener_roll"),"Vigils required before testimony")
	for id in c.PILGRIM_SHRINES:
		c.vigil_time=fposmod(-c.PILGRIM_SHRINES.find(id)*2.0,6.0)
		talk(id); check(not c.vigil_cool(id) and not c.act("listener_wait"),"Hot vent rejects listening "+id)
		var t: float=c.vigil_time; c._process(1); check(c.vigil_time==t,"Menus pause vent cycle")
		c.close_dialog(); p.set_paused(false); c._process(2.1)
		check(c.vigil_cool(id) and "COOL" in c.vigil_labels[id].text,"Cool vent has readable cue")
		talk(id); check(w.session_save.supported_position(p.position,p),"Shrine has supported terrain")
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("listener_wait"),"Remote listening rejected"); p.position=pos
		check(press("Listen during") and id in s.choir.listener_vigils,"Actual listening action "+id)
		check(not c.act("listener_wait"),"Vigil one time")
		check(s.save_to("user://listener-mid.json"),"Vigil checkpoint saves")
		var copy=State.new(); check(copy.load_from("user://listener-mid.json") and id in copy.choir.listener_vigils,"Vigil reloads")
	talk("roll"); check(press("Copy every name") and s.choir.listener_record,"Testimony copied")
	c.close_dialog(); p.set_paused(false); c.leave(); c.enter(); talk("keeper"); press("Discuss the ash")
	check(not s.choir.get("listener_joined",false),"Membership remains optional across travel")
	var gold: int=s.gold; var before: Array=s.inventory.keys()
	check(press("Swear to preserve") and s.choir.listener_joined,"Oath grants Listener rank")
	var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
	check(rewards.size()==1 and s.inventory[rewards[0]].base_id=="cloth_chest" and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant=="vigor","Exact protected Superior robes")
	check(s.gold==gold+140 and "vigor" in s.formulas,"Gold and reusable formula")
	check(not c.act("listener_oath"),"Oath reward one time")
	check(s.choir.song==["ember","ash","stone"] and s.choir.record and s.mountain.clan=="","Main signal and clan remain unchanged")
	w.hud.world_map.selected_quest="ashen_choir_1"; w.hud.world_map._show_quest(); check("Listener" in w.hud.world_map.quest_text.text,"Journal rank")
	s.save_to("user://listener-done.json"); var loaded=State.new(); check(loaded.load_from("user://listener-done.json") and loaded.choir.listener_joined,"Completed oath reloads")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://listener-done.json"))
	for issue in ["type","start","gate","duplicate","missing","unknown","record"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"type": invalid.choir.listener_started=1
			"start": invalid.choir.listener_started=false
			"gate": invalid.choir.rewarded=false
			"duplicate": invalid.choir.listener_vigils=["vigil_south","vigil_south","vigil_north"]
			"missing": invalid.choir.listener_vigils=[]
			"unknown": invalid.choir.listener_vigils=["vigil_south","vigil_middle","other"]
			"record": invalid.choir.listener_record=false
		var f=FileAccess.open("user://listener-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://listener-bad.json") and loaded.choir.listener_joined,"Atomic validation "+issue)
	for key in ["listener_started","listener_record","listener_joined","listener_vigils"]: data.choir.erase(key)
	var f=FileAccess.open("user://listener-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://listener-legacy.json") and not loaded.choir.get("listener_started",false),"Legacy Choir save compatible")
	w.queue_free(); await process_frame
	print("CHOIR_LISTENER_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
