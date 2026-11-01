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
	p=w.player; c=w.mountain; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated shelter fixture")
	s.story_completed.append("stonewake"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("hearth"); check(not c.act("shelter_heat"),"Cannot skip travelers")
	talk("shelter_notice"); check(press("Look for") and s.mountain.shelter_stage==1,"Notice starts rescue")
	talk("travelers"); check(press("Help the group") and s.mountain.shelter_stage==2,"Group found")
	talk("hearth"); s.materials.wood=3; check(not c.act("shelter_heat") and s.materials.wood==3,"Missing wood spends nothing")
	s.materials.wood=4; var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10; check(not c.act("shelter_heat"),"Remote repair rejected"); p.position=pos
	check(press("Light the watch") and s.materials.wood==0 and s.mountain.shelter_stage==3 and not p.paused,"Exact hearth cost and control restored")
	check(c.shelter_flame.visible and c.shelter_people.position==c.ORIGIN+Vector3(30,0,-54),"Fire lights and group relocates")
	talk("travelers"); check(c.subject=="travelers" and "SHELTERED" in c.title.text and w.session_save.supported_position(p.position,p),"Sheltered group reachable")
	check(not c.act("shelter_road"),"Raided road unavailable")
	check(s.save_to("user://shelter-ready.json"),"Warm shelter saves")
	var loaded=State.new(); check(loaded.load_from("user://shelter-ready.json") and loaded.mountain.shelter_stage==3,"Shelter reloads")
	for choice in ["ridge","road"]:
		s.load_from("user://shelter-ready.json")
		if choice=="road":
			c.close_dialog(); p.set_paused(false)
			for e in c.enemies: e.receive_damage(10000,p)
		talk("travelers"); var gold: int=s.gold; var before: Array=s.inventory.keys()
		check(press("Arrange a ridge" if choice=="ridge" else "Arrange the cleared") and s.mountain.shelter_choice==choice,"Actual route choice "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].base_id=="fur_feet" and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant=="fleet" and s.gold==gold+120,"Exact protected reward")
		check(not c.act("shelter_road") and not c.act("shelter_ridge") and not c.act("shelter_heat"),"No repeat rewards or heating")
		check(s.save_to("user://shelter-done.json") and loaded.load_from("user://shelter-done.json") and loaded.mountain.shelter_choice==choice,"Outcome reloads")
		w.hud.world_map.selected_quest="side_rimegate"; w.hud.world_map._show_quest(); check("complete" in w.hud.world_map.quest_text.text,"Journal outcome")
	check(s.mountain.clan=="" and not s.mountain.accepted,"Council and clans independent")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://shelter-done.json"))
	for issue in ["fraction","bool","overflow","choice","guard","early"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"fraction": invalid.mountain.shelter_stage=1.5
			"bool": invalid.mountain.shelter_stage=true
			"overflow": invalid.mountain.shelter_stage=4
			"choice": invalid.mountain.shelter_choice="both"
			"guard": invalid.mountain.defeated=[]
			"early": invalid.mountain.shelter_stage=1
		var f=FileAccess.open("user://shelter-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://shelter-bad.json") and loaded.mountain.shelter_choice=="road","Invalid save rejected "+issue)
	data.mountain.erase("shelter_stage"); data.mountain.erase("shelter_choice")
	var f=FileAccess.open("user://shelter-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://shelter-legacy.json") and loaded.mountain.get("shelter_stage",0)==0,"Legacy save compatibility")
	w.queue_free(); await process_frame
	print("WARM_SHELTER_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
