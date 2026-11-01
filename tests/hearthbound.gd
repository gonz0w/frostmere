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
	c.close(); p.set_paused(false); p.position=(c.POSITION if id=="board" else c.road_position(id))+Vector3(0,.1,1.3); c.selected="lodge"; w.interact_nearby()
func press(prefix: String) -> bool:
	for b in c.actions.get_children():
		if b.text.begins_with(prefix): b.pressed.emit(); return true
	return false
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	p=w.player; c=w.hunts; s=p.character; p.set_physics_process(false)
	for enemy in w.wilderness.enemies: enemy.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated Lodge fixture")
	talk("board"); check(not c.lodge_act("start"),"Forge ember restoration required")
	s.adventure.accepted=true; s.adventure.rewarded=true; s.adventure.defeated=["captain"]; s.adventure.looted=["captain"]
	talk("board"); check(press("Accept the road") and s.hunt.lodge_started,"Board accepts and supplies repairs")
	check(not c.lodge_act("start") and not c.lodge_act("oath"),"Cannot repeat supplies or skip repairs")
	talk("ridge"); check(not c.lodge_act("repair"),"Both ridge beasts must fall")
	c.close(); p.set_paused(false)
	for i in [9,10]: w.wilderness.enemies[i].receive_damage(10000,p)
	for id in ["village","crossing","ridge"]:
		talk(id); check(c.lodge_subject==id and w.session_save.supported_position(p.position,p),"Actual marker on supported ground "+id)
		var wood: int=s.materials.wood; var iron: int=s.materials.iron_ingot
		s.materials.wood=1; check(not c.lodge_act("repair") and s.materials.iron_ingot==iron,"Missing materials spend nothing"); s.materials.wood=wood
		var pos: Vector3=p.position; p.position+=Vector3.RIGHT*8; check(not c.lodge_act("repair"),"Remote repair rejected"); p.position=pos; c.refresh()
		check(press("Repair marker") and s.materials.wood==wood-2 and s.materials.iron_ingot==iron-1,"Exact repair cost "+id)
		check(c.road_glows[id].visible and not c.lodge_act("repair"),"Visible permanent repair")
	check(s.save_to("user://lodge-ready.json"),"Repaired road saves")
	var loaded=State.new(); check(loaded.load_from("user://lodge-ready.json") and loaded.hunt.lodge_repairs.size()==3,"Repairs reload")
	talk("board"); var gold: int=s.gold; var before: Array=s.inventory.keys()
	check(press("Take the Outrider") and s.hunt.lodge_joined,"Optional oath grants rank")
	var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
	check(rewards.size()==1 and s.inventory[rewards[0]].base_id=="wardkeeper_amulet" and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant=="vigor" and s.gold==gold+120,"Exact Outrider reward")
	check(not c.lodge_act("oath") and not s.hunt.accepted and not s.frost_hunt.accepted,"Oath one-time and separate from monster hunts")
	w.hud.world_map.selected_quest="hearthbound_1"; w.hud.world_map._show_quest(); check("Outrider" in w.hud.world_map.quest_text.text,"Journal rank")
	s.save_to("user://lodge-done.json"); check(loaded.load_from("user://lodge-done.json") and loaded.hunt.lodge_joined,"Rank reloads")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://lodge-done.json"))
	for issue in ["start","gate","duplicate","missing","guard"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"start": invalid.hunt.lodge_started=false
			"gate": invalid.adventure.rewarded=false
			"duplicate": invalid.hunt.lodge_repairs=["village","village","ridge"]
			"missing": invalid.hunt.lodge_repairs=[]
			"guard": invalid.wilderness.defeated=[]
		var f=FileAccess.open("user://lodge-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://lodge-bad.json") and loaded.hunt.lodge_joined,"Atomic validation "+issue)
	for key in ["lodge_started","lodge_repairs","lodge_joined"]: data.hunt.erase(key)
	var f=FileAccess.open("user://lodge-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://lodge-legacy.json") and not loaded.hunt.get("lodge_started",false),"Legacy hunts compatible")
	w.queue_free(); await process_frame
	print("HEARTHBOUND_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
