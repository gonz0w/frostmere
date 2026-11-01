extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func talk(t: Node,p: Node,clan: String) -> void:
	t.close_dialog(); p.set_paused(false); p.position=t.ORIGIN+t.NODES[clan]+Vector3.BACK; t.open_dialog(clan)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var s=p.character; var t=world.mountain
	p.set_physics_process(false)
	s.story_completed.append("stonewake"); s.story_completed.append("council"); t.enter()
	for e in t.enemies: e.set_physics_process(false)
	for clan in ["stoneguard","stormweaver"]:
		s.mountain={"accepted":true,"heard":["stoneguard","stormweaver"],"ledger":true,"settlement":"accord","clan":clan,"wards":["west","south","east"],"rank":1,"services":["supply_west","supply_east"],"reputation":{"stoneguard":50,"stormweaver":50},"defeated":["pass_0","pass_1","pass_2"],"looted":[]}
		talk(t,p,clan)
		check(not t.act("expedition"),clan+" commission requires Shieldbearer")
		s.mountain.rank=2; talk(t,p,clan)
		check(t.act("expedition") and not t.act("expedition"),clan+" sponsor accepts commission once")
		s.wilderness={"defeated":[],"looted":[]}
		check(not t.act("mandate:holds"),clan+" requires both monster harvests")
		s.wilderness={"defeated":["wild_11","wild_12"],"looted":["wild_11","wild_12"]}
		p.position+=Vector3.RIGHT*10
		check(not t.act("mandate:holds"),clan+" cannot claim remotely")
		talk(t,p,clan); var gold: int=s.gold
		var choice: String="holds" if clan=="stoneguard" else "leader"
		check(t.act("mandate:"+choice) and s.mountain.rank==3 and t.rank_name()=="Clan Voice" and s.gold==gold+160,clan+" mandate awards rank and gold")
		check(not t.act("mandate:"+choice) and "clan_voice" in s.blueprints,clan+" reward cannot duplicate")
		var rival: String="stormweaver" if clan=="stoneguard" else "stoneguard"
		check(s.mountain.reputation[rival]==(60 if choice=="holds" else 40),choice+" has its stated rival reputation consequence")
		check(s.save_to("user://clan-voice-test.json"),clan+" completion saves")
		var loaded=preload("res://scripts/character_state.gd").new()
		check(loaded.load_from("user://clan-voice-test.json") and loaded.mountain==s.mountain,clan+" rank and mandate survive reload")
	var data=JSON.parse_string(FileAccess.get_file_as_string("user://clan-voice-test.json")); data.wilderness.looted=[]
	check(not s._valid_mountain(data),"Invalid capstone without monster proof rejected")
	for m in s.crafting.materials: s.materials[m.id]=100
	check(s.craft_recipe("craft_clan_voice_signet","forge").begins_with("Created"),"Clan Voice pattern forges signet")
	var uid: String=""
	for id in s.inventory:
		if s.inventory[id].base_id=="clan_voice_signet" and s.inventory[id].favorite: uid=id
	check(uid!="" and s.inventory[uid].quality==2 and s.improve(uid,"forge").begins_with("Improved"),"Superior favorited reward supports tempering")
	DirAccess.remove_absolute("user://clan-voice-test.json")
	world.queue_free(); await process_frame
	print("CLAN_VOICE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
