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
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); w.interact_nearby()
func press(prefix: String) -> bool:
	for b in c.options.get_children():
		if b.text.begins_with(prefix): b.pressed.emit(); return true
	return false
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	p=w.player; c=w.lens; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Debt fixture uses isolated profiles")
	check(not c.enter(),"Archive completion still gates observatory travel")
	s.story_completed.append("archive"); check(c.enter(),"Normal travel opens after archive")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("west_cache"); check(not c.act("debt_collect"),"Unaccepted instruments cannot be taken")
	talk("keeper"); check(press("Ask about") and s.lens.debt_started,"Keeper's actual button accepts debt quest")
	check(not c.act("debt_accept") and not s.lens.accepted,"Acceptance is single-use and independent of main quest")
	talk("west_cache"); check(not c.act("debt_collect"),"Guard must be defeated before recovery")
	c.close_dialog(); p.set_paused(false); c.enemies[0].receive_damage(10000,p)
	talk("west_cache"); check(press("Recover Veyra") and s.lens.debt_instruments==["west_cache"] and not c.debt_props.west_cache.visible,"Actual sentinel defeat and cache button recover first instrument")
	check(not c.act("debt_collect"),"Instrument cannot be duplicated")
	check(s.save_to("user://debt-mid.json"),"Mid-investigation saves")
	var loaded=State.new(); check(loaded.load_from("user://debt-mid.json") and loaded.lens.debt_instruments==["west_cache"],"Partial recovery survives reload")
	talk("keeper"); check(not c.act("debt_public"),"One instrument cannot unlock resolution")
	c.close_dialog(); p.set_paused(false); c.enemies[1].receive_damage(10000,p)
	talk("east_cache"); var before: Vector3=p.position; p.position+=Vector3.RIGHT*4
	check(not c.act("debt_collect"),"Remote stale instrument action is rejected")
	p.position=before; check(press("Recover Veyra") and s.lens.debt_instruments.size()==2,"Second guarded instrument recovered")
	check(s.lens.caches.is_empty() and not s.lens.activated,"Instrument recovery preserves main supplies and puzzle state")
	check(s.save_to("user://debt-choice.json"),"Pending choice saves")
	for choice in ["creditor","public"]:
		check(s.load_from("user://debt-choice.json"),"Restore pending choice: "+choice)
		talk("keeper"); var gold: int=s.gold; var mats: Dictionary=s.materials.duplicate(true)
		check(press("Sell to settle" if choice=="creditor" else "Keep for public") and s.lens.debt_choice==choice,"Actual resolution button commits: "+choice)
		var exact: bool=s.gold==gold+(250 if choice=="creditor" else 80)
		for key in ["solar_alloy","optic_glass","rune_dust"]:
			var gain: int=6 if choice=="creditor" and key=="solar_alloy" else 10 if choice=="public" and key=="optic_glass" else 8 if choice=="public" and key=="rune_dust" else 0
			exact=exact and int(s.materials.get(key,0))==int(mats.get(key,0))+gain
		check(exact,"Choice-specific reward is exact: "+choice)
		check(not c.act("debt_public") and not c.act("debt_creditor"),"Cannot claim again or switch after payment: "+choice)
		check(s.save_to("user://debt-complete.json") and loaded.load_from("user://debt-complete.json") and loaded.lens.debt_choice==choice,"Resolution persists: "+choice)
		w.hud.world_map.selected_quest="side_sunken_lens"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal records resolved debt: "+choice)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://debt-complete.json"))
	for issue in ["type","duplicate","unknown","choice","unaccepted","unguarded","missing"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"type": invalid.lens.debt_started="yes"
			"duplicate": invalid.lens.debt_instruments=["west_cache","west_cache"]
			"unknown": invalid.lens.debt_instruments=["fake"]
			"choice": invalid.lens.debt_choice="both"
			"unaccepted": invalid.lens.debt_started=false
			"unguarded": invalid.lens.defeated=[]
			"missing": invalid.lens.debt_instruments=[]
		var f=FileAccess.open("user://debt-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://debt-invalid.json") and loaded.lens.debt_choice=="public","Malformed debt rejected atomically: "+issue)
	for key in ["debt_started","debt_instruments","debt_choice"]: data.lens.erase(key)
	var f=FileAccess.open("user://debt-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://debt-legacy.json") and not loaded.lens.get("debt_started",false),"Older profiles default to unstarted debt quest")
	w.queue_free(); await process_frame
	print("ASTRONOMER_DEBT_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
