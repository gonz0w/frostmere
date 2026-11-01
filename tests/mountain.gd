extends SceneTree
const State = preload("res://scripts/character_state.gd")
var checks := 0
var failures := 0
var world: Node3D
var town: Node3D
var p: CharacterBody3D
var s: RefCounted
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks+=1
	if ok: print("PASS "+message)
	else: failures+=1; push_error("FAIL "+message)
func frames(n: int=3) -> void:
	for i in range(n): await physics_frame
func talk(id: String) -> void:
	town.close_dialog(); p.set_paused(false)
	p.position=town.ORIGIN+town.NODES[id]+Vector3(0,0.1,1.4)
	world.interact_nearby()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	town=world.mountain; p=world.player; s=p.character
	check(not town.enter(),"North pass enforces Stonewake completion")
	s.story_completed.append("stonewake")
	check(town.enter() and town.inside,"Completed first chapter opens Wyrmkeep")
	for enemy in town.enemies: enemy.set_physics_process(false)
	await frames(30)
	check(p.is_on_floor() and p.position.x>700,"Town floor supports player without surface reset")
	for house in [[782,19],[818,19],[778,-8],[822,-8],[800,-25]]:
		p.position=Vector3(house[0],0.3,house[1]+3); p.velocity=Vector3.ZERO; p.rotation=Vector3.ZERO
		Input.action_press("move_forward"); await frames(110); Input.action_release("move_forward")
		check(p.position.z<house[1] and p.is_on_floor(),"Walkable building entrance at "+str(house))
	talk("council")
	check(p.paused and p.dialog_open and town.dialog.visible,"Council dialogue pauses the game")
	check(town.act("accept") and not town.act("accept"),"Council investigation accepts once")
	check(not town.act("settle:accord"),"Cannot settle without evidence and testimony")
	for clan in ["stoneguard","stormweaver"]:
		talk(clan); check(town.act("hear") and not town.act("join"),"Testimony does not enroll player: "+clan)
	talk("ledger")
	check(not town.act("ledger"),"Reavers guard access to the ledger")
	town.close_dialog(); p.set_paused(false)
	p.position=town.ORIGIN+Vector3(0,0.1,-46); p.rotation=Vector3.ZERO
	town.enemies[0].position=town.ORIGIN+Vector3(0,0.1,-48)
	await frames(8)
	var hp: float=town.enemies[0].health
	p.attack_cooldown=0
	check(p.attack() and town.enemies[0].health<hp,"Player melee reaches the town combat roster")
	for enemy in town.enemies: enemy.receive_damage(10000)
	check(s.mountain.defeated.size()==3 and s.adventure.defeated.is_empty(),"Reaver combat uses independent saved progress")
	check(town.loot("pass_0") and not town.loot("pass_0"),"Reaver loot is claimed once")
	talk("ledger"); check(town.act("ledger"),"Cleared outpost yields protected quest evidence")
	s.save_to("user://mountain-evidence.json")
	for policy in ["stoneguard","stormweaver"]:
		talk("council")
		check(town.act("settle:"+policy) and s.mountain.reputation[policy]==20 and s.mountain.clan=="","Policy endorsement affects reputation without enrollment: "+policy)
		s.load_from("user://mountain-evidence.json")
	talk("council")
	var gold: int=s.gold
	p.position+=Vector3(0,0,10)
	check(not town.act("settle:accord"),"Council choice rechecks physical proximity")
	p.position=town.ORIGIN+town.NODES.council+Vector3(0,0.1,1.4)
	check(town.act("settle:accord") and "council" in s.story_completed and s.gold==gold+120,"Council settlement completes main chapter with a reward")
	check(s.mountain.clan=="" and s.mountain.reputation.stoneguard==10 and s.mountain.reputation.stormweaver==10,"Neutral resolution raises both reputations without membership")
	check(not town.act("settle:accord"),"Council reward cannot repeat")
	check(s.save_to("user://mountain-neutral.json"),"Independent council completion saves")
	for clan in ["stoneguard","stormweaver"]:
		if clan=="stormweaver": check(s.load_from("user://mountain-neutral.json"),"Can restore independent fixture for the rival branch")
		talk(clan); check(town.act("join") and s.mountain.clan==clan,"Explicit oath joins "+clan)
		talk("stormweaver" if clan=="stoneguard" else "stoneguard")
		check(not town.act("join") and s.mountain.clan==clan,"Rival membership remains closed after oath")
		talk(clan); check(not town.act("initiate") and not town.act("promote"),"Ranks cannot skip their tasks")
		for id in ["west","south","east"]:
			talk(id)
			if clan=="stormweaver":
				p.magicka=0; check(not town.act("ward"),"Magic initiation enforces resource cost"); p.magicka=100
			check(town.act("ward") and not town.act("ward"),"Ward service is one-time: "+clan+" "+id)
		talk(clan); check(town.act("initiate") and s.mountain.rank==1 and clan in s.blueprints and town.CLANS[clan].formula in s.formulas,"Initiation grants rank, pattern, formula and enchanted weapon")
		check(not town.act("initiate"),"Initiation rewards cannot duplicate")
		for id in ["supply_west","supply_east"]:
			talk(id)
			var material: String="steel_ingot" if clan=="stoneguard" else "crystal"
			s.materials[material]=0
			check(not town.act("service"),"Supply delivery requires owned materials")
			s.materials[material]=10
			check(town.act("service") and not town.act("service"),"Supply delivery consumes items once")
		talk(clan); check(town.act("promote") and s.mountain.rank==2 and clan+"_veteran" in s.blueprints,"First promotion unlocks advanced patterns")
		check(not town.act("promote"),"Promotion reward is one-time")
		for material: Dictionary in s.crafting.materials: s.materials[material.id]=100
		check(s.craft_recipe("craft_"+clan+"_chest","forge").begins_with("Created"),"Earned advanced clan design can be forged")
		check(s.save_to("user://mountain-branch.json"),"Clan progression saves")
		var loaded:=State.new()
		check(loaded.load_from("user://mountain-branch.json") and loaded.mountain==s.mountain,"Membership, ranks and reputation reload together")
	town.close_dialog(); p.set_paused(false)
	p.position=Vector3(782,0.3,16)
	check(world.shops.nearby()=="mountain_smith","Mountain merchant is physically reachable")
	world.interact_nearby()
	check(p.shop_open,"E opens native town trading UI")
	world.shops.close()
	s.gold=1000
	check(world.shops.trade.buy("mountain_smith","material:steel_ingot",1).begins_with("Bought"),"Mountain shop transacts real stock and gold")
	for id in ["forge","enchant"]:
		p.position=town.ORIGIN+town.NODES[id]+Vector3(0,0.1,1.5)
		check(world.station_nearby()==id,"Town workstation proximity: "+id)
	world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_mountain() and world.hud.world_map.place_action.disabled,"Town map displays its own settlement dossier")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://mountain-branch.json"))
	data.mountain.rank=3
	var f:=FileAccess.open("user://mountain-invalid.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	var loaded:=State.new()
	check(not loaded.load_from("user://mountain-invalid.json"),"Invalid clan rank is rejected")
	data.erase("mountain"); f=FileAccess.open("user://mountain-legacy.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://mountain-legacy.json") and loaded.mountain.clan=="","Earlier saves receive independent clan defaults")
	town.leave()
	check(not town.inside and p.position.x<100 and s.mountain.rank==2,"Returning home preserves membership and earned gear")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Council chapter never skips later realm requirements")
	p.set_paused(false); town.enter(); p.invulnerable=0; p.receive_damage(10000,p.position+Vector3.BACK)
	check(not town.inside and p.position.x<100,"Death in the mountain town returns home")
	for file in ["neutral","branch","invalid","legacy","evidence"]: DirAccess.remove_absolute("user://mountain-"+file+".json")
	world.queue_free(); await process_frame
	print("MOUNTAIN_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
