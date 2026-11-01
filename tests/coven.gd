extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func talk(c: Node,p: Node,id: String) -> void:
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3.BACK*1.5; c.open_dialog(id)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var s=p.character; var c=world.roots
	check(not s.persist and not world.atlas.persist,"QA persistence disabled")
	s.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false)
	for e in c.enemies: e.set_physics_process(false)
	talk(c,p,"keeper"); check(not c.act("coven_start"),"Woodland reward gates initiation")
	s.story_completed.append("roots")
	for pact in ["wild","tended"]:
		s.roots={"accepted":true,"heard":["keeper","steward"],"cleansed":["spring","stone","seed"],"choice":pact,"record":true,"rewarded":true,"caches":[],"defeated":["roots_0","roots_1","roots_2","roots_3"],"looted":[]}
		s._commit()
		talk(c,p,"bed_west"); check(not c.act("coven_tend") and not c.seedlings.bed_west.visible,"Beds require accepting trial")
		talk(c,p,"keeper"); var herbs: int=s.materials.get("herb",0)
		check(c.act("coven_start") and s.materials.herb==herbs+6,"Initiation grants supplies")
		check(not c.act("coven_start"),"Supplies cannot repeat")
		check(not c.act("coven_oath:shelter"),"Oath requires all beds")
		talk(c,p,"bed_west"); s.materials.herb=0; var before: Dictionary=s.materials.duplicate()
		check(not c.act("coven_tend") and s.materials==before,"Insufficient supplies spend nothing")
		s.materials.herb=6
		for bed in ["bed_west","bed_east","bed_south"]:
			talk(c,p,bed); p.position+=Vector3.BACK*5
			check(not c.act("coven_tend"),"Remote tending rejected")
			talk(c,p,bed); var water: int=s.materials.water
			check(c.act("coven_tend") and s.materials.water==water-2 and c.seedlings[bed].visible,"Tending consumes supplies and reveals shoots")
			check(not c.act("coven_tend"),"Restored bed cannot charge twice")
		check(not c.act("coven_oath:medicine"),"Oath requires Maelin")
		talk(c,p,"keeper"); var gold: int=s.gold
		var oath: String="shelter" if pact=="wild" else "medicine"
		check(c.act("coven_oath:"+oath) and s.gold==gold+100 and s.roots.choice==pact,"Oath rewards and preserves prior pact")
		check(not c.act("coven_oath:"+oath) and "coven_seedkeeper" in s.blueprints,"Reward and pattern are single claim")
		check(s.save_to("user://coven-test.json"),"Coven progress saves")
		var loaded=preload("res://scripts/character_state.gd").new()
		check(loaded.load_from("user://coven-test.json") and loaded.roots==s.roots,"Coven state round trips")
		var data=JSON.parse_string(FileAccess.get_file_as_string("user://coven-test.json"))
		data.roots.coven_beds.pop_back(); check(not s._valid_roots(data),"Oath without completed beds rejected")
		data.roots.coven_beds=["bed_west","bed_west","bed_south"]; check(not s._valid_roots(data),"Duplicate bed proof rejected")
		data.roots.erase("coven_beds"); data.roots.erase("coven_started"); data.roots.erase("coven_oath")
		check(s._valid_roots(data),"Older woodland saves remain valid")
	for m in s.crafting.materials: s.materials[m.id]=100
	check(s.craft_recipe("craft_seedkeeper_charm","forge").begins_with("Created"),"Learned charm pattern forges")
	var uid: String=""
	for id in s.inventory:
		if s.inventory[id].base_id=="seedkeeper_charm" and s.inventory[id].favorite: uid=id
	check(uid!="" and s.inventory[uid].quality==1 and s.improve(uid,"forge").begins_with("Improved"),"Fine favorited charm supports tempering")
	DirAccess.remove_absolute("user://coven-test.json")
	world.queue_free(); await process_frame
	print("COVEN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
