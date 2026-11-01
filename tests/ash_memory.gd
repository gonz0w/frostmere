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

	talk("keeper"); check(not c.act("memory_start"),"Listener oath required")
	s.choir.listener_started=true; s.choir.listener_vigils=["vigil_south","vigil_middle","vigil_north"]; s.choir.listener_record=true; s.choir.listener_joined=true
	talk("keeper"); check(press("Discuss the sealed") and press("Investigate the sealed") and s.choir.memory_started,"Real archive investigation start")
	talk("memory_archive"); check(not c.act("memory_read"),"Closed cabinet protects evidence")
	talk("memory_lock"); check(press("Release the latch") and s.choir.memory_lock==0,"Wrong first setting resets safely")
	check(press("Mute the signal") and s.choir.memory_lock==1,"First setting correct")
	check(s.save_to("user://memory-mid.json"),"Partial lock saves")
	var loaded=State.new(); check(loaded.load_from("user://memory-mid.json") and loaded.choir.memory_lock==1,"Partial lock reloads")
	var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("memory_lock:vent"),"Remote lock action rejected"); p.position=pos
	check(press("Vent the pressure") and s.choir.memory_lock==2,"Second setting correct")
	check(press("Release the latch") and s.choir.memory_lock==3 and c.memory_door.rotation.y< -1,"Third setting opens visible cabinet")
	check(not c.act("memory_lock:release"),"Opened lock cannot reset")
	talk("memory_archive"); check(w.session_save.supported_position(p.position,p),"Archive accessible on supported ground")
	check(press("Copy the signed") and s.choir.memory_record,"Signed evidence recorded")
	check(not c.act("memory_read"),"Evidence one time")
	check(s.save_to("user://memory-choice.json"),"Pending decision saves")
	for choice in ["publish","conceal"]:
		s.load_from("user://memory-choice.json"); talk("keeper"); press("Discuss the sealed")
		var gold: int=s.gold; var before: Array=s.inventory.keys()
		check(press("Publish the order" if choice=="publish" else "Conceal the elders") and s.choir.memory_choice==choice,"Actual permanent decision "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].quality==3 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].base_id==("cantors_staff" if choice=="publish" else "resonance_blade") and s.inventory[rewards[0]].enchant==("insight" if choice=="publish" else "fleet"),"Exact Exquisite equipment "+choice)
		check(s.gold==gold+180 and s.materials.resonant_ore>=8 and s.materials.ash_glass>=6,"Gold and upgrade materials")
		check(not c.act("memory_publish") and not c.act("memory_conceal"),"Reward and outcome cannot repeat")
		check(c.memory_caption.text==("TESTIMONY MADE PUBLIC" if choice=="publish" else "RESTRICTED CHOIR RECORD"),"Visible outcome caption")
		check(s.save_to("user://memory-done.json") and loaded.load_from("user://memory-done.json") and loaded.choir.memory_choice==choice,"Outcome reloads")
		w.hud.world_map.selected_quest="ashen_choir_2"; w.hud.world_map._show_quest(); check("Cantor" in w.hud.world_map.quest_text.text,"Cantor rank journal")
	check(s.choir.listener_joined and s.choir.record and s.mountain.clan=="","Initiation and main campaign unchanged")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://memory-done.json"))
	for issue in ["negative","fraction","bool","overflow","rank","start","record","choice"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"negative": invalid.choir.memory_lock=-1
			"fraction": invalid.choir.memory_lock=1.5
			"bool": invalid.choir.memory_lock=true
			"overflow": invalid.choir.memory_lock=4
			"rank": invalid.choir.listener_joined=false
			"start": invalid.choir.memory_started=false
			"record": invalid.choir.memory_record=false
			"choice": invalid.choir.memory_choice="both"
		var f=FileAccess.open("user://memory-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://memory-bad.json") and loaded.choir.memory_choice=="conceal","Atomic save validation "+issue)
	for key in ["memory_started","memory_record","memory_lock","memory_choice"]: data.choir.erase(key)
	var f=FileAccess.open("user://memory-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://memory-legacy.json") and not loaded.choir.get("memory_started",false),"Legacy Listener saves compatible")
	w.queue_free(); await process_frame
	print("ASH_MEMORY_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
