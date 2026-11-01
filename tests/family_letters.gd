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
	p=w.player; c=w.mountain; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Letters fixture is isolated")
	check(not c.enter(),"Existing Stonewake gate remains")
	s.story_completed.append("stonewake"); check(c.enter(),"Normal Wyrmkeep entry opens")
	for enemy in c.enemies: enemy.set_physics_process(false)
	talk("memorial"); check(not c.act("letters_verify"),"Memorial cannot skip both accounts")
	talk("council"); check(press("Ask about the families") and s.mountain.letters_started,"Actual Runa button accepts investigation")
	check(not s.mountain.accepted and not c.act("letters_accept"),"Side investigation is independent and single-use")
	talk("stoneguard"); check(press("Carry this family") and s.mountain.letters_received==["stoneguard"],"First family's account collected through dialogue")
	check(not c.act("letters_read"),"Account cannot duplicate")
	talk("memorial"); check(not c.act("letters_verify"),"One family cannot establish shared truth")
	check(s.save_to("user://letters-mid.json"),"Partial letters save")
	var loaded=State.new(); check(loaded.load_from("user://letters-mid.json") and loaded.mountain.letters_received==["stoneguard"],"Partial letters reload")
	talk("stormweaver"); check(press("Carry this family") and s.mountain.letters_received.size()==2,"Rival family speaks without requiring membership")
	talk("memorial"); var pos: Vector3=p.position; p.position+=Vector3.RIGHT*4
	check(not c.act("letters_verify"),"Remote stale memorial action rejected")
	p.position=pos; check(press("Copy the final") and s.mountain.letters_witness,"Physical memorial resolves contradictory accounts")
	check(w.session_save.supported_position(p.position,p),"Memorial can be read from supported ground")
	check(s.mountain.clan=="" and s.mountain.settlement=="" and s.mountain.heard.is_empty(),"Investigation does not choose clan or council policy")
	check(s.save_to("user://letters-choice.json"),"Unresolved delivery decision saves")
	for choice in ["public","private"]:
		s.load_from("user://letters-choice.json"); talk("council")
		var gold: int=s.gold; var rep: Dictionary=s.mountain.reputation.duplicate(); var mats: Dictionary=s.materials.duplicate()
		check(press("Publish their" if choice=="public" else "Return private") and s.mountain.letters_choice==choice,"Actual delivery choice commits: "+choice)
		var gain: int=10 if choice=="public" else 5
		check(s.mountain.reputation.stoneguard==rep.stoneguard+gain and s.mountain.reputation.stormweaver==rep.stormweaver+gain,"Both clans receive promised regard change: "+choice)
		var material: String="steel_ingot" if choice=="public" else "silver_ingot"
		check(s.gold==gold+(150 if choice=="public" else 120) and s.materials[material]==int(mats.get(material,0))+4,"Exact gold and materials awarded: "+choice)
		check(not c.act("letters_public") and not c.act("letters_private"),"Decision cannot repeat or switch: "+choice)
		check(("MARA & OREN" in c.memorial_caption.text)==(choice=="public"),"Memorial inscription respects public/private outcome: "+choice)
		check(s.save_to("user://letters-complete.json") and loaded.load_from("user://letters-complete.json") and loaded.mountain.letters_choice==choice,"Resolution persists: "+choice)
		w.hud.world_map.selected_quest="side_wyrmkeep"; w.hud.world_map._show_quest()
		check("complete" in w.hud.world_map.quest_text.text,"Journal records outcome: "+choice)
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://letters-complete.json"))
	for issue in ["type","duplicate","unknown","witness","early","unstarted"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"type": invalid.mountain.letters_started="yes"
			"duplicate": invalid.mountain.letters_received=["stoneguard","stoneguard"]
			"unknown": invalid.mountain.letters_choice="both"
			"witness": invalid.mountain.letters_witness=false
			"early": invalid.mountain.letters_received=[]
			"unstarted": invalid.mountain.letters_started=false
		var f=FileAccess.open("user://letters-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://letters-invalid.json") and loaded.mountain.letters_choice=="private","Malformed progress rejected atomically: "+issue)
	for key in ["letters_started","letters_received","letters_witness","letters_choice"]: data.mountain.erase(key)
	var f=FileAccess.open("user://letters-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://letters-legacy.json") and not loaded.mountain.get("letters_started",false),"Legacy profiles default to unstarted letters")
	w.queue_free(); await process_frame
	print("FAMILY_LETTERS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
