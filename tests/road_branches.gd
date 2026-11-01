extends "res://tests/remaining_quests.gd"
func run() -> void:
	w=load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	for i in range(8): await physics_frame
	p=w.player; c=w.road_quests; s=p.character; p.set_physics_process(false)
	check(not s.persist and not w.atlas.persist,"Branch fixture isolated")
	s.story_completed.append("stonewake"); s.story_completed.append("archive")
	for manager in [w.wilderness,w.mountain,w.roots,w.shore]:
		for enemy in manager.enemies: enemy.set_physics_process(false)
	s.wilderness.defeated=["wild_11"]; s.mountain.defeated=["pass_2"]
	s.hunt.roads={"sable_concord_1":{"answers":["accept"]}}
	talk("canyon","sable_concord_1")
	check(press("Inspect the contents before carrying them onward") and c.answers("sable_concord_1")[1]=="opened","Alternate opened cargo")
	talk("broker","sable_concord_1"); check("You tell Sal you inspected" in c.description.text,"Opened cargo acknowledged")
	check(c.act("sable_concord_1","oath") and c.rank()=="Runner","Opened cargo can earn Runner through honesty")
	s.hunt.roads.side_larksbridge={"answers":["accept","inspect"]}
	talk("mill_worker","side_larksbridge"); s.gold=59
	check(not c.act("side_larksbridge","pay") and s.gold==59,"Wage arrears cannot overdraft")
	s.gold=60; check(c.act("side_larksbridge","pay") and s.gold==0,"Alternate paid wages exact cost")
	check(not c.act("side_larksbridge","lien"),"Cannot reverse wage agreement")
	s.hunt.roads.side_reedhollow={"answers":["accept","mix"]}
	talk("toll","side_reedhollow"); check(c.act("side_reedhollow","marsh"),"Alternate marsh route")
	talk("marsh","side_reedhollow")
	check(not c.act("side_reedhollow","cache"),"Marsh requires actual hostile approach defeat")
	s.roots.defeated=["roots_0"]
	check(not c.act("side_reedhollow","receipt"),"Cannot use unpaid road receipt")
	check(c.act("side_reedhollow","cache"),"Cleared marsh supplies secured")
	var data: Dictionary=save("user://roads-branches.json")
	var loaded=State.new(); check(loaded.load_from("user://roads-branches.json"),"Alternate branches reload")
	data.hunt.roads.side_reedhollow.answers[2]="road"
	check(not Rules.valid(data),"Impossible mixed route rejected")
	# Build a valid Envoy fixture ready to sign; the final charters must work in either order.
	s.shore.accepted=true; s.shore.heard=["harbor","salvager"]; s.shore.relays=["pump","relay"]; s.shore.log=true; s.shore.core=true; s.shore.defeated=["shore_0","shore_2","shore_6"]; s.shore.choice="navigation"; s.shore.rewarded=true; s.story_completed.append("tides")
	s.shore.compact_stage=4; s.shore.compact_evidence=["registry","nameplate","salvager"]; s.shore.harbor_stage=5; s.shore.harbor_choice="sealed"; s.shore.passage_started=true; s.shore.passage_heard=["harbor","salvager","witness"]
	s.hunt.roads.sable_concord_2={"answers":["accept","trade","copy","commons"]}
	s.hunt.roads.sable_concord_3={"answers":["accept","hear","hear"]}
	save("user://roads-both-ready.json")
	for charter in ["open","house","outlaw"]:
		check(s.load_from("user://roads-both-ready.json"),"Reload both pending charters")
		travel("shore"); var sh=w.shore
		p.position=sh.interaction_position("charter")+Vector3(0,.1,1.3); sh.open_dialog("charter")
		check(sh.act("passage_sign:"+charter),"Compact first: "+charter)
		sh.close_dialog(); p.set_paused(false); talk("route_table","sable_concord_3")
		check(not c.act("sable_concord_3","war"),"Completed Compact cannot be retroactively invalidated")
		if charter=="outlaw":
			check(not c.act("sable_concord_3","open") and not c.act("sable_concord_3","monopoly") and "closed" in c.objective("sable_concord_3"),"Compact ban blocks every Concord final outcome")
		else:
			check(c.act("sable_concord_3","open"),"Peaceful Concord finish after Compact")
			save("user://roads-coexist.json"); check(loaded.load_from("user://roads-coexist.json"),"Both peaceful capstones reload")
			var invalid: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://roads-coexist.json")); invalid.shore.passage_choice="outlaw"
			check(not Rules.valid(invalid),"Completed Concord plus ban rejected")
	for ending_id in ["open","monopoly","war"]:
		s.load_from("user://roads-both-ready.json"); talk("route_table","sable_concord_3")
		check(c.act("sable_concord_3",ending_id),"Concord first: "+ending_id)
		travel("shore"); var sh=w.shore
		p.position=sh.interaction_position("charter")+Vector3(0,.1,1.3); sh.open_dialog("charter")
		check(not sh.act("passage_sign:outlaw"),"No retroactive Concord ban")
		check(sh.act("passage_sign:open")==(ending_id!="war"),"Reciprocal Compact completion gate")
		sh.close_dialog(); p.set_paused(false)
		save("user://roads-order.json"); check(loaded.load_from("user://roads-order.json"),"Charter order reloads")
	# Real Escape input must close the new panel without leaving paused controls.
	talk("courier","sable_concord_1")
	var key:=InputEventKey.new(); key.physical_keycode=KEY_ESCAPE; key.pressed=true; p._unhandled_input(key)
	check(not c.panel.visible and not p.paused and not p.dialog_open,"Escape closes road quest dialogue")
	w.queue_free(); await process_frame
	print("ROAD_BRANCHES_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
