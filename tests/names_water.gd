extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func talk(c: Node,p: Node,id: String) -> void:
	c.inside=true; p.position=c.ORIGIN+c.NODES[id]+Vector3.BACK*1.5; c.open_dialog(id)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var s=p.character; var a=world.archive_chapter; var c=world.convergence
	p.set_physics_process(false)
	for e in c.enemies: e.set_physics_process(false)
	s.story_completed=["stonewake","archive","roots","tides","lens","choir"]
	s.archive={"accepted":true,"heard":["lantern","briar"],"atlas":true,"recipient":"lantern","caches":[],"defeated":["archive_3"],"looted":[],"reputation":{"lantern":25,"briar":-10}}
	talk(a,p,"lantern"); check(not a.act("names_accept"),"Witness oath gates next quest")
	s.archive.lantern_trial="member"
	check(a.act("names_accept") and not a.act("names_accept"),"Mereth starts investigation once"); a.close_dialog(); a.inside=false
	for id in ["names_dock","names_roll"]:
		talk(c,p,id); check(c.act("names_collect") and not c.act("names_collect"),id+" recovered once at actual site")
		c.close_dialog()
	talk(c,p,"names_seal"); check(not c.act("names_collect"),"Northern record requires stabilized beacon")
	s.convergence={"accepted":true,"evidence":["roots","tides","lens","choir"],"supplies":true,"installed":true,"calibrated":true,"rewarded":false,"defeated":["convergence_0","convergence_1","convergence_2"],"looted":[]}
	check(c.act("names_collect") and s.archive.names_records.size()==3,"Calibration allows complete testimony recovery"); c.close_dialog(); c.inside=false
	check(not a.act("names_resolve:public"),"Resolution requires physical return to Mereth")
	var pending: Dictionary=s.archive.duplicate(true)
	for choice in ["public","sealed"]:
		s.archive=pending.duplicate(true); s.blueprints.erase("names_public"); s.blueprints.erase("names_sealed")
		talk(a,p,"lantern"); var gold: int=s.gold
		check(a.act("names_resolve:"+choice) and s.gold==gold+140 and not a.act("names_resolve:"+choice),choice+" resolves once")
		check("names_"+choice in s.blueprints and "names_"+("sealed" if choice=="public" else "public") not in s.blueprints,"Only chosen ring pattern unlocks")
		check(s.save_to("user://names-test.json"),"Resolution saves")
		var loaded=preload("res://scripts/character_state.gd").new()
		check(loaded.load_from("user://names-test.json") and loaded.archive==s.archive,"Records and choice survive reload")
		for m in s.crafting.materials: s.materials[m.id]=100
		var item: String="memorial_ring" if choice=="public" else "sealed_memory_ring"
		check(s.craft_recipe("craft_"+item,"forge").begins_with("Created"),"Chosen reward can be forged")
		var uid: String=""
		for id in s.inventory:
			if s.inventory[id].base_id==item and s.inventory[id].favorite: uid=id
		check(uid!="" and s.inventory[uid].quality==2 and s.improve(uid,"forge").begins_with("Improved"),"Superior favorited ring can be tempered")
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://names-test.json")); data.archive.names_records=[]
	check(not s._valid_archive(data),"Choice without all evidence rejected")
	DirAccess.remove_absolute("user://names-test.json")
	world.queue_free(); await process_frame
	print("NAMES_WATER_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
