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
	check(not s.persist and not w.atlas.persist,"Fixture isolated")
	s.story_completed.append("stonewake"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("hunter"); check(not c.act("stag_start"),"Restoration required")
	s.roots.accepted=true; s.roots.heard=["keeper","steward"]; s.roots.cleansed=["spring","stone","seed"]; s.roots.defeated=["roots_0","roots_1","roots_2","roots_3"]; s.roots.choice="wild"; s.roots.record=true; s.roots.rewarded=true; s.story_completed.append("roots")
	talk("hunter"); check(press("Follow the pale") and s.roots.stag_step==1 and not p.paused,"Start through real dialogue")
	check(c.stag.visible and not c.stag.has_method("receive_damage"),"Spectral stag cannot be attacked")
	for mesh in c.stag.get_children(): check(mesh.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"No shadow on spectral part")
	var start: Vector3=c.stag.position
	p.set_paused(true); c._process(1); check(c.stag.position==start,"Menu freezes trail")
	p.set_paused(false); p.position=start+Vector3.RIGHT*30; c._process(1); check(c.stag.position==start,"Stag waits for distant player")
	p.position=start+Vector3.BACK*2; c._process(1); check(c.stag.position.distance_to(start)>2 and not c.stag_arrived(),"Stag walks gradually")
	check(c.nearest().get("id","")!="stag_echo","Cannot skip a moving leg")
	for step in [1,2,3]:
		for tick in range(150):
			p.position=c.stag.position+Vector3.BACK*2; c._process(.1)
		check(c.stag_arrived(),"Trail reaches stop "+str(step))
		check(w.session_save.supported_position(c.stag.position+Vector3.UP*.2,p),"Stop has supported ground "+str(step))
		talk("stag_echo"); check(c.subject=="stag_echo","Actual moving target interaction "+str(step))
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("stag_follow"),"Remote interaction rejected"); p.position=pos
		check(press("Listen" if step<3 else "Carry") and s.roots.stag_step==step+1,"Listen advances once "+str(step))
		check(not c.act("stag_follow"),"Closed dialogue cannot repeat")
		check(s.save_to("user://stag-mid.json"),"Checkpoint saves")
		var loaded=State.new(); check(loaded.load_from("user://stag-mid.json") and loaded.roots.stag_step==step+1,"Checkpoint reloads")
	check(not c.stag.visible,"Stag departs after invitation")
	c.close_dialog(); p.set_paused(false); s.roots.stag_step=2; c.leave(); c.enter(); c._refresh()
	check(c.stag.position==c.ORIGIN+c.STAG_STOPS[1] and c.stag.visible,"Reenter resumes unfinished leg at previous checkpoint")
	var resumed: Vector3=c.stag.position; c.leave(); p.position=resumed; c._process(1)
	check(c.stag.position==resumed,"Travel away freezes trail")
	c.enter(); s.roots.stag_step=4; c._refresh()
	talk("hunter"); var gold: int=s.gold; var wood: int=s.materials.get("heartwood",0)
	check(press("Offer forgiveness") and s.roots.stag_step==5 and s.gold==gold+100 and s.materials.heartwood==wood+6,"Forgiveness grants reward")
	check(not c.act("stag_forgive"),"Reward cannot repeat")
	check(s.roots.choice=="wild" and not s.roots.get("coven_started",false),"Main pact and Coven unchanged")
	w.hud.world_map.selected_quest="side_stag_shrine"; w.hud.world_map._show_quest(); check("Quest complete" in w.hud.world_map.quest_text.text,"Journal completion")
	s.save_to("user://stag-complete.json"); var loaded=State.new(); check(loaded.load_from("user://stag-complete.json"),"Completion reloads")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://stag-complete.json"))
	for bad in [-1,6,1.5,true,"done"]:
		var invalid: Dictionary=data.duplicate(true); invalid.roots.stag_step=bad
		var f=FileAccess.open("user://stag-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://stag-invalid.json") and loaded.roots.stag_step==5,"Invalid stage rejected atomically "+str(bad))
	var locked: Dictionary=data.duplicate(true); locked.roots.rewarded=false; locked.story_completed.erase("roots")
	var blocked=FileAccess.open("user://stag-invalid.json",FileAccess.WRITE); blocked.store_string(JSON.stringify(locked)); blocked.close()
	check(not loaded.load_from("user://stag-invalid.json"),"Save cannot bypass woodland restoration")
	data.roots.erase("stag_step"); var f=FileAccess.open("user://stag-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://stag-legacy.json") and loaded.roots.get("stag_step",0)==0,"Legacy progress defaults safely")
	w.queue_free(); await process_frame
	print("SHADOWLESS_STAG_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
