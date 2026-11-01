extends SceneTree
const State=preload("res://scripts/character_state.gd")
const Rules=preload("res://scripts/road_quest_rules.gd")
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
func travel(area: String) -> void:
	c.close(); p.set_paused(false)
	for id in w.session_save.AREAS:
		if w.get(id).inside: w.get(id).leave()
	if area!="home": check(w.get(area).enter(),"Actual area entry: "+area)
func talk(site: String,id: String) -> void:
	travel(c.catalog.sites[site].area)
	p.position=c.position_for(site)+Vector3(0,.1,1.3)
	w.interact_nearby()
	check(c.panel.visible and c.subject==site,"World interaction reaches "+site)
	check(w.session_save.supported_position(p.position,p),"Supported approach: "+site)
	for b in c.options.get_children():
		if b.text==c.catalog.quests[id].name: b.pressed.emit(); return
	check(false,"Quest selector exists: "+id)
func press(label: String) -> bool:
	for b in c.options.get_children():
		if b.text==label: b.pressed.emit(); return true
	return false
func save(path: String) -> Dictionary:
	check(s.save_to(path),"Save checkpoint")
	return JSON.parse_string(FileAccess.get_file_as_string(path))
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	p=w.player; c=w.road_quests; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Isolated profiles")
	check(c.catalog.quests.size()==7,"Seven remaining quests")
	talk("courier","sable_concord_1")
	check(not c.act("sable_concord_1","accept"),"Story gate blocks actual acceptance")
	s.story_completed.append("stonewake"); s.story_completed.append("archive")
	s.wilderness.defeated.append("wild_11"); s.mountain.defeated.append("pass_2"); s.roots.defeated.append("roots_0"); s.shore.defeated.append("shore_0")
	for manager in [w.wilderness,w.mountain,w.roots,w.shore]:
		for enemy in manager.enemies: enemy.set_physics_process(false)
	for mat in ["wood","iron_ingot","herb","water"]: s.materials[mat]=100
	s.gold=2000
	check(c.locked("sable_concord_2")!="" and c.locked("sable_concord_3")!="","Faction prerequisites")
	var loaded=State.new()
	for id in c.catalog.quests:
		var q: Dictionary=c.catalog.quests[id]
		for i in range(q.steps.size()):
			var step: Dictionary=q.steps[i]
			var o: Dictionary=step.options[0]
			for candidate in step.options:
				if c.allowed_branch(id,candidate): o=candidate; break
			var site: String=c.option_site(step,o)
			talk(site,id)
			check(not c.act(id,"invalid"),"Unknown action rejected")
			var pos: Vector3=p.position; p.position+=Vector3.RIGHT*8
			check(not c.act(id,o.id),"Remote action rejected")
			p.position=pos
			if o.has("guard"):
				var defeated: Array=s.get(o.guard[0]).defeated; defeated.erase(o.guard[1])
				check(not c.act(id,o.id),"Guard proof required")
				defeated.append(o.guard[1]); c.show_quest()
			if o.has("cost"):
				var before: Dictionary=s.materials.duplicate(true); var mat: String=o.cost.keys()[0]; s.materials[mat]=0
				check(not c.act(id,o.id) and c.answers(id).size()==i,"Missing material rejects action")
				for other in o.cost:
					if other!=mat: check(s.materials[other]==before[other],"No partial material spending")
				s.materials=before; c.show_quest()
			if o.has("gold_cost"):
				var gold: int=s.gold; s.gold=0
				check(not c.act(id,o.id) and s.gold==0,"Cannot pay unavailable gold")
				s.gold=gold; c.show_quest()
			if i==q.steps.size()-1:
				var checkpoint: Dictionary=save("user://roads-pending.json")
				for finish: Dictionary in step.options:
					check(s.load_from("user://roads-pending.json"),"Reload pending outcome")
					talk(c.option_site(step,finish),id)
					var gold: int=s.gold; var count: int=s.inventory.size(); var mats: Dictionary=s.materials.duplicate(true)
					check(press(finish.label) and c.complete(id) and c.ending(id)==finish.id,"Actual ending: "+id+" / "+finish.id)
					var r: Dictionary=finish.reward
					check(s.gold==gold+int(r.gold) and s.inventory.size()==count+1,"Exact gold and one item")
					var found:=false
					for uid in s.inventory:
						var item: Dictionary=s.inventory[uid]
						if item.custom_name==r.name: found=item.base_id==r.item and item.quality==r.quality and item.enchant==r.enchant and item.favorite
					check(found,"Exact equipment, enchantment and favorite")
					for mat in r.materials: check(s.materials.get(mat,0)==mats.get(mat,0)+r.materials[mat],"Exact material payout")
					check(not c.act(id,finish.id) and s.inventory.size()==count+1,"No repeated reward")
					save("user://roads-final.json")
					check(loaded.load_from("user://roads-final.json") and Rules.ending(loaded.hunt.roads,id)==finish.id,"Final outcome reloads")
					w.hud.world_map.selected_quest=id; w.hud.world_map._show_quest()
					check("complete" in w.hud.world_map.quest_text.text,"Journal completion")
			else:
				var gold: int=s.gold; var before: Dictionary=s.materials.duplicate(true)
				check(press(o.label) and c.answers(id).size()==i+1,"Actual step: "+id+" / "+str(i))
				check(s.gold==gold-int(o.get("gold_cost",0)),"Exact intermediate gold cost")
				for mat in o.get("cost",{}): check(s.materials[mat]==before[mat]-o.cost[mat],"Exact intermediate material cost")
				save("user://roads-partial.json")
				check(loaded.load_from("user://roads-partial.json") and loaded.hunt.roads[id].answers.size()==i+1,"Partial progress reloads")
		check(c.complete(id),"Quest complete: "+id)
	check(c.rank()=="Concord Hand" and c.compact_blocked(),"Concord rank and hostile consequence")
	check(c.well_water.visible and c.medicine_crates.visible,"Well supply and delivered medicine visible")
	check(c.position_for("traveler")==w.shore.ORIGIN+Vector3(31,0,39),"Rescued traveler moves to guesthouse")
	travel("home"); var angle: float=c.wheel.rotation.z; c._process(1)
	check(c.wheel.rotation.z!=angle,"Repaired mill runs")
	p.set_paused(true); angle=c.wheel.rotation.z; c._process(1); check(c.wheel.rotation.z==angle,"Menu pauses wheel"); p.set_paused(false)
	travel("shore"); angle=c.wheel.rotation.z; c._process(1); check(c.wheel.rotation.z==angle,"Travel pauses wheel")
	var sh=w.shore; p.position=sh.interaction_position("charter")+Vector3(0,.1,1.3); sh.open_dialog("charter")
	check(not sh.act("passage_start") and not sh.act("passage_sign:open") and "closed" in sh.passage_objective(),"Concord war blocks Compact actions and journal")
	sh.close_dialog(); p.set_paused(false)
	var final_data: Dictionary=save("user://roads-all.json")
	for issue in ["type","unknown","answer","overlong","prerequisite","guard","story","rival"]:
		var bad: Dictionary=final_data.duplicate(true)
		if issue=="type": bad.hunt.roads=[]
		elif issue=="unknown": bad.hunt.roads.fake={"answers":["accept"]}
		elif issue=="answer": bad.hunt.roads.side_dunewell.answers[0]="bogus"
		elif issue=="overlong": bad.hunt.roads.side_dunewell.answers.append("shared")
		elif issue=="prerequisite": bad.hunt.roads.erase("sable_concord_1")
		elif issue=="guard": bad.wilderness.defeated.erase("wild_11")
		elif issue=="story": bad.story_completed.erase("stonewake")
		else: bad.shore.passage_choice="open"
		var f=FileAccess.open("user://roads-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(bad)); f.close()
		check(not loaded.load_from("user://roads-invalid.json") and Rules.complete(loaded.hunt.roads,"side_reedhollow"),"Malformed save rejected atomically: "+issue)
	final_data.hunt.erase("roads")
	var f=FileAccess.open("user://roads-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(final_data)); f.close()
	check(loaded.load_from("user://roads-legacy.json") and not loaded.hunt.has("roads"),"Legacy save compatibility")
	w.queue_free(); await process_frame
	print("REMAINING_QUESTS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
