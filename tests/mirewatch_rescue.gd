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
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); p.velocity=Vector3.ZERO; w.interact_nearby()
func press(text: String) -> bool:
	for b in c.options.get_children():
		if b.text.begins_with(text): b.pressed.emit(); return true
	return false
func write_data(data: Dictionary) -> void:
	var f=FileAccess.open("user://rescue-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(6): await physics_frame
	c=w.convergence; p=w.player; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Side quest fixture cannot modify normal saves")
	check(not c.enter(),"Mirewatch travel prerequisites remain required")
	s.story_completed=c.REQUIRED.duplicate(); check(c.enter(),"Normal road opens after required discoveries")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("rescue_cache"); check(not c.act("rescue_reward"),"Cache cannot be claimed before rescue")
	talk("keeper"); check(press("Ask about") and s.convergence.rescue_stage==1,"Actual keeper button accepts side quest")
	check(not s.convergence.accepted and not s.convergence.installed,"Side quest does not accept or advance main expedition")
	check(not c.act("rescue_accept") and not c.act("rescue_free"),"Acceptance cannot repeat or skip subjects")
	talk("rescue_light"); check(c.dialog.visible and press("Answer the signal") and s.convergence.rescue_stage==2,"Physical light interaction advances investigation")
	check(s.save_to("user://rescue-mid.json"),"Investigation progress saves")
	var loaded=State.new(); check(loaded.load_from("user://rescue-mid.json") and loaded.convergence.rescue_stage==2,"Investigation survives reload")
	talk("rescue_winch"); var position: Vector3=p.position; p.position+=Vector3.RIGHT*5
	check(not c.act("rescue_free") and s.convergence.rescue_stage==2,"Stale rescue action rejects remote use")
	p.position=position
	check(press("Release the catch") and s.convergence.rescue_stage==3 and c.rescue_npc.visible and not c.rescue_glow.visible,"Actual winch rescue reveals living scavenger and stops signals")
	check(not c.act("rescue_free"),"Rescue cannot repeat")
	var gold: int=s.gold; var crystal: int=s.materials.get("crystal",0); var dust: int=s.materials.get("rune_dust",0); var potions: int=s.consumables.get("healing_draught",0)
	talk("rescue_cache"); check(press("Open the salvage") and s.convergence.rescue_stage==4,"Actual cache button completes quest")
	check(s.gold==gold+90 and s.materials.crystal==crystal+6 and s.materials.rune_dust==dust+4 and s.consumables.healing_draught==potions+2,"Reward pays exact gold, upgrade supplies and healing")
	check(not c.act("rescue_reward") and s.gold==gold+90 and c.rescue_lid.rotation.x<0,"Cache opens visually and cannot pay twice")
	check(s.save_to("user://rescue-complete.json") and loaded.load_from("user://rescue-complete.json") and loaded.convergence.rescue_stage==4,"Completed rescue survives save/load")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://rescue-complete.json"))
	for bad in [-1,5,1.5,"rescued",true]:
		var invalid: Dictionary=data.duplicate(true); invalid.convergence.rescue_stage=bad; write_data(invalid)
		check(not loaded.load_from("user://rescue-invalid.json") and loaded.convergence.rescue_stage==4,"Malformed rescue stage rejected atomically: "+str(bad))
	var legacy: Dictionary=data.duplicate(true); legacy.convergence.erase("rescue_stage"); write_data(legacy)
	check(loaded.load_from("user://rescue-invalid.json") and loaded.convergence.get("rescue_stage",0)==0,"Older save defaults to unstarted quest")
	var invalid: Dictionary=data.duplicate(true); invalid.story_completed=[]; write_data(invalid)
	check(not loaded.load_from("user://rescue-invalid.json"),"Rescue progress requires access prerequisites in saved data")
	w.hud.world_map.selected_quest="side_mirewatch"; w.hud.world_map._show_quest()
	check("Tovin rescued" in w.hud.world_map.quest_text.text,"Journal displays actual completed progress")
	c.close_dialog(); p.set_paused(false); c.leave(); c.enter()
	check(c.rescue_npc.visible and not c.rescue_glow.visible and s.convergence.rescue_stage==4,"Returning to Mirewatch retains rescue outcome")
	for id in ["rescue_light","rescue_winch","rescue_cache"]:
		p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4)
		check(w.session_save.supported_position(p.position,p) and c.nearest().get("id")==id,"Quest station is on a supported reachable deck: "+id)
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+Vector3(-25,.1,33.4)
	for i in range(4): await physics_frame
	for i in range(270):
		p.velocity=Vector3(0,-2,-5); p.move_and_slide(); await physics_frame
		if p.position.z<c.ORIGIN.z+13.6: break
	check(p.position.z<c.ORIGIN.z+13.6 and p.position.y>c.ORIGIN.y-.5,"Western deck route is physically walkable between quest stations")
	w.queue_free(); await process_frame
	print("MIREWATCH_RESCUE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
