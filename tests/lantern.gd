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
	var p=world.player; var s=p.character; var c=world.archive_chapter
	s.story_completed.append("stonewake"); c.enter(); p.set_physics_process(false)
	for e in c.enemies: e.set_physics_process(false)
	talk(c,p,"lantern"); check(not c.act("trial_accept"),"Missing Atlas completion gates trial")
	s.story_completed.append("archive")
	for recipient in ["lantern","briar"]:
		s.archive={"accepted":true,"heard":["lantern","briar"],"atlas":true,"recipient":recipient,"caches":[],"defeated":["archive_3"],"looted":[],"reputation":{"lantern":25 if recipient=="lantern" else -10,"briar":25 if recipient=="briar" else -10}}
		talk(c,p,"lantern"); check(c.act("trial_accept"),recipient+" custody permits independent membership trial")
		talk(c,p,"trial"); check(not c.act("trial_answer:witness"),"Trial requires studying evidence first")
		talk(c,p,"notes"); check(c.act("trial_study"),"Testimony advances investigation")
		talk(c,p,"trial"); check(not c.act("trial_answer:erase") and s.archive.lantern_trial=="testimony","Wrong answer gives retry without progress")
		check(c.act("trial_answer:witness"),"Correct reading recovers protected testimony")
		check(not c.act("trial_join"),"Oath requires returning to Mereth")
		talk(c,p,"lantern"); var gold: int=s.gold
		check(c.act("trial_join") and s.gold==gold+100 and s.archive.recipient==recipient,"Oath grants reward while preserving custodian choice")
		check(not c.act("trial_join") and "lantern_witness" in s.blueprints,"Membership reward cannot duplicate")
		check(s.save_to("user://lantern-test.json"),"Membership saves")
		var loaded=preload("res://scripts/character_state.gd").new()
		check(loaded.load_from("user://lantern-test.json") and loaded.archive==s.archive,"Membership and custody round-trip")
	for m in s.crafting.materials: s.materials[m.id]=100
	check(s.craft_recipe("craft_witness_pendant","forge").begins_with("Created"),"Witness pattern forges pendant")
	var uid: String=""
	for id in s.inventory:
		if s.inventory[id].base_id=="witness_pendant" and s.inventory[id].favorite: uid=id
	check(uid!="" and s.inventory[uid].quality==1 and s.improve(uid,"forge").begins_with("Improved"),"Fine favorited pendant supports tempering")
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://lantern-test.json")); data.archive.recipient=""
	check(not s._valid_archive(data),"Trial without prior atlas resolution rejected")
	DirAccess.remove_absolute("user://lantern-test.json")
	world.queue_free(); await process_frame
	print("LANTERN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
