extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
var world: Node3D
var c: Node3D
var p: CharacterBody3D
var s: RefCounted
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func frames(n: int=3) -> void:
	for i in range(n): await physics_frame
func talk(id: String) -> void:
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); p.velocity=Vector3.ZERO; world.interact_nearby()
func walk(from: Vector3,to: Vector3) -> bool:
	p.position=c.ORIGIN+from; p.velocity=Vector3.ZERO; await frames(4)
	for i in range(65): p.velocity=(c.ORIGIN+to-p.position).normalized()*4; p.move_and_slide(); await physics_frame
	return Vector2(p.position.x-c.ORIGIN.x-to.x,p.position.z-c.ORIGIN.z-to.z).length()<.8
func fixture(data: Dictionary) -> void:
	var f:=FileAccess.open("user://ending-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	p=world.player; s=p.character
	var r: Node3D=world.realms; var ending: Node=r.ending
	check(not ending.open_chronicle() and not ending.claim("blade"),"Chronicle and rewards are locked before completion")
	s.story_completed.append_array(["returning_light","winter_siege","broken_seal"])
	check(r.enter("crucible"),"Campaign prerequisites permit final descent")
	for enemy in r.enemies: enemy.set_physics_process(false)
	var origin: Vector3=r.vector(r.definitions.crucible.origin)
	p.position=origin+ending.CONTROL+Vector3(0,.1,1.4)
	check(world.nearest_interaction().get("id")=="shutdown","Engine console has a physical interaction")
	check(not ending.shutdown() and ending.core.visible,"Active defenders prevent shutdown")
	r.enemies[5].receive_damage(10000,p)
	check(not ending.shutdown(),"Warden defeat alone does not recover its relic")
	r.loot("crucible_warden")
	check(not ending.shutdown(),"Remaining sentries prevent engine shutdown")
	for i in [3,4]: r.enemies[i].receive_damage(10000,p)
	p.position=origin+Vector3(0,.1,19)
	check(not r.finish_chapter(),"Returning with relic cannot bypass engine shutdown")
	check(not ending.shutdown(),"Shutdown requires standing at console")
	p.position=origin+ending.CONTROL+Vector3(0,.1,1.4); world.interact_nearby()
	check(s.finale.shutdown and not ending.core.visible,"Actual E interaction stops the visible invasion engine")
	check(not ending.shutdown(),"Shutdown is single use")
	check(not r.finish_chapter(),"Chapter cannot finish remotely from final terrace")
	check(s.save_to("user://ending-mid.json"),"Shutdown progress saves before return")
	var loaded:=State.new(); check(loaded.load_from("user://ending-mid.json") and loaded.finale.shutdown,"Engine state round-trips")
	r.leave(); check(r.enter("crucible") and not ending.core.visible,"Engine remains off when revisiting")
	p.position=origin+Vector3(0,.1,19); world.interact_nearby()
	check(not r.inside and "last_furnace" in s.story_completed,"Actual return completes Last Furnace")
	check(ending.dialog.visible and p.paused and p.dialog_open,"Return opens a readable ending and pauses play")
	check(ending.options.get_child_count()==3,"Finale offers three heirloom choices")
	check(ending.options.get_child(1).text.contains("30 base damage / +4 Agility"),"Final bow offer shows rebalanced catalog damage")
	check(ending.options.get_child(2).text.contains("32 base damage / +4 Intellect"),"Final staff offer shows rebalanced catalog damage")
	check(s.save_to("user://ending-choice.json"),"Unclaimed ending can be saved")
	for choice in ["blade","bow","staff"]:
		check(s.load_from("user://ending-choice.json"),"Restore unclaimed fixture for "+choice)
		ending.open_chronicle(); var gold: int=s.gold
		check(ending.claim(choice) and s.finale.reward==choice and s.gold==gold+350,"Claim chosen heirloom once: "+choice)
		check(not ending.claim(choice) and not ending.claim("blade"),"Cannot claim another heirloom: "+choice)
		check("dawnforged" in s.blueprints,"All three patterns learned: "+choice)
		var found:=false
		for uid: String in s.inventory:
			if s.inventory[uid].base_id==ending.REWARDS[choice]: found=true; check(s.inventory[uid].quality==3 and s.inventory[uid].favorite,"Heirloom is Exquisite and protected: "+choice)
		check(found,"Selected heirloom is owned: "+choice)
	for material in ["steel_ingot","crystal","cinder_alloy","soul_ember"]: s.materials[material]=100
	for id in ending.REWARDS.values():
		check(s.craft_recipe("craft_"+id,"forge").begins_with("Created"),"Learned collection pattern forges: "+id)
		var uid: String=s.add_item(id,3)
		check(s.temper_cost(uid)=={"steel_ingot":4,"cinder_alloy":4,"soul_ember":1} and s.improve(uid,"forge").begins_with("Improved"),"Heirloom tempers with infernal materials: "+id)
	check(s.save_to("user://ending-done.json") and loaded.load_from("user://ending-done.json") and loaded.finale==s.finale,"Final reward and equipment round-trip")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://ending-done.json"))
	for issue in ["type","choice","shutdown","completion","loot"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"type": bad.finale.shutdown="yes"
			"choice": bad.finale.reward="all"
			"shutdown": bad.finale.shutdown=false
			"completion": bad.story_completed.erase("last_furnace")
			"loot": bad.realm_progress.looted.erase("crucible_warden")
		fixture(bad); check(not loaded.load_from("user://ending-bad.json") and loaded.finale==s.finale,"Invalid ending rejected atomically: "+issue)
	data.erase("finale"); fixture(data)
	check(loaded.load_from("user://ending-bad.json") and loaded.finale.shutdown and loaded.finale.reward=="","Existing completed saves migrate with heirloom unclaimed")
	data.story_completed.erase("last_furnace"); data.realm_progress.completed.erase("crucible"); fixture(data)
	check(loaded.load_from("user://ending-bad.json") and not loaded.finale.shutdown,"Old unfinished saves retain shutdown objective")
	s.roots.choice="wild"; s.shore.choice="harbor"; s.mountain.clan="stoneguard"
	check(ending.chronicle_text().contains("wild grove") and ending.chronicle_text().contains("harbor beacon") and ending.chronicle_text().contains("Stoneguard"),"Chronicle reflects prior choices and membership")
	s.roots.choice="tended"; s.shore.choice="navigation"
	check(ending.chronicle_text().contains("tended woodland") and ending.chronicle_text().contains("navigation core"),"Alternate decisions receive their own epilogue")
	var key:=InputEventKey.new(); key.physical_keycode=KEY_ESCAPE; key.pressed=true; p._unhandled_input(key)
	check(not ending.dialog.visible and not p.paused and not p.dialog_open,"Escape returns from ending to active exploration")
	p.position=ending.HOME+Vector3(0,.1,1.4); world.interact_nearby()
	check(ending.dialog.visible and ending.options.get_child_count()==0,"Chronicle can be revisited without duplicate reward options")
	ending.close_dialog(); p.set_paused(false)
	check(r.enter("crucible") and not ending.core.visible,"Postgame travel remains available with stopped engine")
	p.position=origin+Vector3(0,.1,19); world.interact_nearby()
	check(not ending.dialog.visible and not p.paused,"Completed return does not interrupt exploration with another reward screen")
	for name in ["mid","choice","done","bad"]: DirAccess.remove_absolute("user://ending-"+name+".json")
	world.queue_free(); await process_frame
	print("ENDING_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
