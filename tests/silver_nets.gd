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
	check(not s.persist and not w.atlas.persist,"Silver quest uses isolated profiles")
	check(not c.enter(),"Existing coastal travel gate remains")
	s.story_completed.append("archive"); check(c.enter(),"Normal coastal entry after archive")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("cave_cache"); check(not c.act("silver_ledger"),"Ledger cannot skip investigation")
	talk("harbor"); check(press("Ask about") and s.shore.silver_stage==1,"Actual Sella button accepts contract")
	check(not s.shore.accepted and not c.act("silver_accept"),"Optional acceptance is separate and cannot repeat")
	talk("silver_net"); check(w.session_save.supported_position(p.position,p),"Net interaction stands on the existing dock")
	check(press("Record the coin") and s.shore.silver_stage==2 and not c.silver_coins.visible,"Actual net investigation secures coin evidence")
	check(not c.act("silver_trace"),"Net evidence cannot repeat")
	check(s.save_to("user://silver-mid.json"),"Investigation saves")
	var loaded=State.new(); check(loaded.load_from("user://silver-mid.json") and loaded.shore.silver_stage==2,"Investigation resumes from saved evidence")
	talk("cave_cache"); check(not c.act("silver_ledger"),"Guard defeat required for ledger")
	c.close_dialog(); p.set_paused(false); c.enemies[1].receive_damage(10000,p)
	talk("cave_cache"); var pos: Vector3=p.position; p.position+=Vector3.RIGHT*5
	check(not c.act("silver_ledger"),"Remote stale ledger action rejected")
	p.position=pos; check(press("Recover the ledger") and s.shore.silver_stage==3 and not c.silver_ledger.visible,"Defeated guard permits actual ledger recovery")
	check(s.shore.caches.is_empty() and s.shore.relays.is_empty() and not s.shore.core,"Investigation preserves main relic and power systems")
	check(s.save_to("user://silver-choice.json"),"Unresolved reporting choice saves")
	for choice in ["public","protect"]:
		s.load_from("user://silver-choice.json"); talk("harbor")
		var gold: int=s.gold; var silver: int=s.materials.get("silver_ingot",0); var count: int=s.inventory.size()
		check(press("Publish the full" if choice=="public" else "Protect crew") and s.shore.silver_choice==choice,"Actual report choice commits: "+choice)
		check(s.gold==gold+(120 if choice=="public" else 60) and int(s.materials.get("silver_ingot",0))==silver+(6 if choice=="protect" else 0),"Exact differentiated payment: "+choice)
		var ring: String=""
		for uid in s.inventory:
			if s.inventory[uid].base_id=="netmender_ring": ring=uid
		check(ring!="" and s.inventory.size()==count+1 and s.inventory[ring].quality==1 and s.inventory[ring].favorite and "saltbreak_silver" in s.blueprints,"Fine protected ring and forge pattern awarded: "+choice)
		check(not c.act("silver_public") and not c.act("silver_protect") and s.inventory.size()==count+1,"Neither duplicate nor alternative claim is allowed: "+choice)
		check(s.save_to("user://silver-complete.json") and loaded.load_from("user://silver-complete.json") and loaded.shore.silver_choice==choice,"Final story and new equipment reload: "+choice)
		w.hud.world_map.selected_quest="side_saltbreak"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal records outcome: "+choice)
		for mat in ["silver_ingot","leather","crystal"]: s.materials[mat]=100
		check(s.craft_recipe("craft_netmender_ring","forge").begins_with("Created"),"Earned pattern forges a second owned ring: "+choice)
		check(s.improve(ring,"forge").begins_with("Improved") and s.describe_item(ring).armor==6,"Reward ring tempers to Superior: "+choice)
		check(s.equip(ring,"ring") and s.item_at("ring").bonuses.endurance==2 and s.item_at("ring").bonuses.presence==2,"Ring equips with promised attributes: "+choice)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://silver-complete.json"))
	for bad in [-1,4,1.5,"yes",true]:
		var invalid: Dictionary=data.duplicate(true); invalid.shore.silver_stage=bad
		var f=FileAccess.open("user://silver-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://silver-invalid.json") and loaded.shore.silver_choice=="protect","Invalid stage rejected atomically: "+str(bad))
	for issue in ["early","guard","choice"]:
		var invalid: Dictionary=data.duplicate(true)
		if issue=="early": invalid.shore.silver_stage=1
		elif issue=="guard": invalid.shore.defeated=[]
		else: invalid.shore.silver_choice="both"
		var f=FileAccess.open("user://silver-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://silver-invalid.json"),"Impossible silver progress rejected: "+issue)
	data.shore.erase("silver_stage"); data.shore.erase("silver_choice")
	var f=FileAccess.open("user://silver-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://silver-legacy.json") and loaded.shore.get("silver_stage",0)==0,"Legacy save defaults to unstarted investigation")
	w.queue_free(); await process_frame
	print("SILVER_NETS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
