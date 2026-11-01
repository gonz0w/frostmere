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
	p=w.player; c=w.shore; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated Compact fixture")
	s.story_completed.append("archive"); c.enter()
	for enemy in c.enemies: enemy.set_physics_process(false)

	s.shore.accepted=true; s.shore.heard=["harbor","salvager"]; s.shore.relays=["pump","relay"]; s.shore.log=true; s.shore.core=true; s.shore.defeated=["shore_6"]; s.shore.choice="navigation"; s.shore.rewarded=true; s.story_completed.append("tides")

	talk("compact"); check(not c.act("harbor_start"),"Decksworn prerequisite enforced")
	s.shore.compact_stage=4; s.shore.compact_evidence=["registry","nameplate","salvager"]; s.shore.defeated.append("shore_0")
	talk("compact"); check(press("Investigate the forged") and s.shore.harbor_stage==1,"Vessa starts second chapter")
	check(not c.act("harbor_start") and not c.act("harbor_public"),"Cannot repeat start or skip investigation")
	talk("false_orders"); check(not c.act("harbor_orders"),"Register must be compared first")
	talk("registry"); check(press("Copy the original") and s.shore.harbor_stage==2,"Register comparison advances")
	talk("false_orders"); check(press("Secure the signed") and s.shore.harbor_stage==3,"Signed orders recovered")
	check(s.save_to("user://harbor-mid.json"),"Evidence checkpoint saves")
	var loaded=State.new(); check(loaded.load_from("user://harbor-mid.json") and loaded.shore.harbor_stage==3,"Evidence checkpoint reloads")
	talk("witness"); check(not c.act("harbor_shelter"),"Living relay raider blocks protection")
	c.close_dialog(); p.set_paused(false); c.enemies[2].receive_damage(10000,p)
	talk("witness"); var pos: Vector3=p.position; p.position+=Vector3.RIGHT*10
	check(not c.act("harbor_shelter"),"Stale remote rescue rejected"); p.position=pos
	check(press("Arrange watch") and s.shore.harbor_stage==4 and not p.paused and not c.dialog.visible,"Protection returns player control")
	check(c.witness.position==c.ORIGIN+Vector3(41,0,46) and "sheltered" in c.witness_label.text,"Witness relocates to lodge with updated label")
	check(c.nearest().get("id","")!="witness","Old position no longer targets witness")
	talk("witness"); check(c.subject=="witness" and "soup" in c.description.text and w.session_save.supported_position(p.position,p),"Sheltered witness remains accessible")
	check(s.save_to("user://harbor-choice.json"),"Shelter checkpoint saves")
	for choice in ["public","sealed"]:
		s.load_from("user://harbor-choice.json"); talk("compact")
		var before: Array=s.inventory.keys(); var gold: int=s.gold
		check(press("Public testimony" if choice=="public" else "Seal her identity") and s.shore.harbor_choice==choice and s.shore.harbor_stage==5,"Actual presentation choice "+choice)
		var rewards: Array=s.inventory.keys().filter(func(uid): return uid not in before)
		check(rewards.size()==1 and s.inventory[rewards[0]].base_id==("tideguard_shell" if choice=="public" else "signal_focus") and s.inventory[rewards[0]].quality==2 and s.inventory[rewards[0]].favorite and s.inventory[rewards[0]].enchant==("vigor" if choice=="public" else "insight"),"Exact protected Envoy reward "+choice)
		check(s.gold==gold+160 and s.materials.wreck_alloy>=6 and s.materials.signal_circuit>=4,"Gold and upgrade materials "+choice)
		check(not c.act("harbor_public") and not c.act("harbor_sealed"),"Cannot switch or repeat reward "+choice)
		check(s.save_to("user://harbor-done.json") and loaded.load_from("user://harbor-done.json") and loaded.shore.harbor_choice==choice,"Outcome reloads "+choice)
		w.hud.world_map.selected_quest="tide_compact_2"; w.hud.world_map._show_quest(); check("Envoy" in w.hud.world_map.quest_text.text,"Envoy journal "+choice)
	check(s.shore.compact_stage==4 and s.shore.choice=="navigation" and s.shore.get("silver_stage",0)==0,"Other coastal progress preserved")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://harbor-done.json"))
	for issue in ["negative","fraction","bool","overflow","choice","early","guard","rank"]:
		var invalid: Dictionary=data.duplicate(true)
		match issue:
			"negative": invalid.shore.harbor_stage=-1
			"fraction": invalid.shore.harbor_stage=1.5
			"bool": invalid.shore.harbor_stage=true
			"overflow": invalid.shore.harbor_stage=6
			"choice": invalid.shore.harbor_choice="both"
			"early": invalid.shore.harbor_stage=3
			"guard": invalid.shore.defeated.erase("shore_2")
			"rank": invalid.shore.compact_stage=3
		var f=FileAccess.open("user://harbor-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(invalid)); f.close()
		check(not loaded.load_from("user://harbor-bad.json") and loaded.shore.harbor_choice=="sealed","Atomic validation "+issue)
	data.shore.erase("harbor_stage"); data.shore.erase("harbor_choice")
	var f=FileAccess.open("user://harbor-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://harbor-legacy.json") and loaded.shore.get("harbor_stage",0)==0,"Legacy Compact saves compatible")
	w.queue_free(); await process_frame
	print("HARBOR_LIED_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
