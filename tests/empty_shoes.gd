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
	p=w.player; c=w.choir; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated Listener fixture")
	s.story_completed.append("council"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)

	talk("pilgrim"); check(not c.act("pilgrim_depart"),"Cannot skip investigation")
	talk("pilgrim_notice"); check(press("Investigate the missing") and s.choir.pilgrim_stage==1,"Notice starts quest")
	talk("empty_shoes"); check(press("Follow the bootprints") and s.choir.pilgrim_stage==2,"Bootprints reveal staged disappearance")
	talk("escape_note"); check(not c.act("pilgrim_letter"),"Sentinel guards evidence")
	c.close_dialog(); p.set_paused(false); c.enemies[1].receive_damage(10000,p)
	talk("escape_note"); check(press("Recover Leth") and s.choir.pilgrim_stage==3,"Letter secured")
	check(s.save_to("user://pilgrim-ready.json"),"Investigation saves")
	var loaded=State.new(); check(loaded.load_from("user://pilgrim-ready.json") and loaded.choir.pilgrim_stage==3,"Investigation reloads")
	for choice in ["shelter","depart"]:
		s.load_from("user://pilgrim-ready.json"); talk("pilgrim")
		var gold: int=s.gold; var before: Array=s.inventory.keys(); var pos: Vector3=p.position
		p.position+=Vector3.RIGHT*10; check(not c.act("pilgrim_"+choice),"Remote help rejected"); p.position=pos
		check(press("Arrange shelter" if choice=="shelter" else "Supply a free") and s.choir.pilgrim_choice==choice and not p.paused and not c.dialog.visible,"Actual help returns control "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].base_id=="swift_ring" and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant=="fleet" and s.gold==gold+100,"Exact protected reward")
		check(c.pilgrim.position==c.ORIGIN+Vector3(-7,0,29) and "safe" in c.pilgrim_label.text,"NPC relocates safely")
		check(c.nearest().get("id","")!="pilgrim","Old hiding place no longer targets NPC")
		talk("pilgrim"); check(w.session_save.supported_position(p.position,p) and "Thank you" in c.description.text and "SAFE AT CAMP" in c.title.text,"Camp NPC remains interactable")
		check(not c.act("pilgrim_shelter") and not c.act("pilgrim_depart"),"Outcome immutable")
		check(s.save_to("user://pilgrim-done.json") and loaded.load_from("user://pilgrim-done.json") and loaded.choir.pilgrim_choice==choice,"Outcome reloads")
		w.hud.world_map.selected_quest="side_ember_caldera"; w.hud.world_map._show_quest(); check("complete" in w.hud.world_map.quest_text.text,"Journal records outcome")
	check(not s.choir.accepted and not s.choir.get("listener_joined",false),"Independent of campaign and faction acceptance")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://pilgrim-done.json"))
	for issue in ["fraction","overflow","choice","guard","early"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"fraction": invalid.choir.pilgrim_stage=1.5
			"overflow": invalid.choir.pilgrim_stage=4
			"choice": invalid.choir.pilgrim_choice="both"
			"guard": invalid.choir.defeated=[]
			"early": invalid.choir.pilgrim_stage=1
		var f=FileAccess.open("user://pilgrim-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://pilgrim-bad.json") and loaded.choir.pilgrim_choice=="depart","Invalid save rejected atomically "+issue)
	data.choir.erase("pilgrim_stage"); data.choir.erase("pilgrim_choice")
	var f=FileAccess.open("user://pilgrim-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://pilgrim-legacy.json") and loaded.choir.get("pilgrim_stage",0)==0,"Legacy save compatibility")
	w.queue_free(); await process_frame
	print("EMPTY_SHOES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
