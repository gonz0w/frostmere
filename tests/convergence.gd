extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
var world: Node3D
var c: Node3D
var p: CharacterBody3D
var s: RefCounted
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func frames(n: int=3) -> void:
	for i in range(n): await physics_frame
func talk(id: String) -> void:
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); p.velocity=Vector3.ZERO; world.interact_nearby()
func walk(from: Vector3,to: Vector3) -> bool:
	p.position=c.ORIGIN+from; p.velocity=Vector3.ZERO; await frames(4)
	for i in range(65): p.velocity=(c.ORIGIN+to-p.position).normalized()*4; p.move_and_slide(); await physics_frame
	return Vector2(p.position.x-c.ORIGIN.x-to.x,p.position.z-c.ORIGIN.z-to.z).length()<.8
func fixture(data: Dictionary) -> void:
	var f:=FileAccess.open("user://convergence-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.convergence; p=world.player; s=p.character
	for missing in c.REQUIRED:
		s.story_completed=c.REQUIRED.duplicate(); s.story_completed.erase(missing)
		check(not c.enter(),"Every branch is required: "+missing)
	s.story_completed=c.REQUIRED.duplicate(); check(c.enter(),"All four discoveries open expedition without membership")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Arrival deck supports the player")
	check(await walk(Vector3(-16,.2,28),Vector3(-16,.2,24)),"Ilyra's lodge has a traversable entrance")
	check(await walk(Vector3(0,.2,10),Vector3(0,.2,5)),"Southern platform connects to the boardwalk")
	check(await walk(Vector3(0,.2,-25),Vector3(0,.2,-30)),"Boardwalk connects to calibration platform")
	p.position=c.ORIGIN+Vector3(40,-2,-20); p.velocity=Vector3.DOWN*5; c.check_fall()
	check(p.position.distance_to(c.ORIGIN+Vector3(0,.2,40))<.01 and p.velocity==Vector3.ZERO,"Marsh fall returns safely to the dock")
	check(world.combat_enemies().is_empty(),"Dormant sentinels do not trigger combat music or targeting")
	for enemy in c.enemies:
		var hp: float=enemy.health; enemy.receive_damage(10000,p); check(enemy.health==hp,"Survey sentinel is dormant before regulator installation")
	talk("roots"); check(not c.act("evidence"),"Briefing requires acceptance")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Expedition accepts once")
	check(not c.act("reward"),"Cannot claim premature report reward")
	check(not s.craft_recipe("forge_transit_regulator","forge").begins_with("Created"),"Regulator blueprint is initially unknown")
	for id in c.REQUIRED:
		talk(id); p.position+=Vector3(10,0,0); check(not c.act("evidence"),"Remote briefing action rejected: "+id)
		talk(id); check(c.act("evidence") and not c.act("evidence"),"Evidence records once: "+id)
		check(c.lights[id].material_override==world.blocks.materials.mire_glow,"Evidence light updates: "+id)
	check("transit_regulator" in s.blueprints,"All four findings unlock regulator recipe")
	for woodland in ["wild","tended"]:
		for harbor in ["harbor","navigation"]:
			s.roots.choice=woodland; s.shore.choice=harbor
			talk("roots"); var root_text: String=c.description.text
			talk("tides"); check(c.ready_for_expedition() and ("wild grove" in root_text if woodland=="wild" else "tended pact" in root_text) and ("harbor beacon" in c.description.text if harbor=="harbor" else "navigation core" in c.description.text),"Earlier outcomes remain valid and acknowledged: "+woodland+" / "+harbor)
	s.roots.choice=""; s.shore.choice=""
	talk("rig"); check(not c.act("install"),"Live test requires a crafted regulator")
	s.materials.steel_ingot=0; var before: Dictionary=s.materials.duplicate()
	check(not s.craft_recipe("forge_transit_regulator","forge").begins_with("Created") and s.materials==before,"Missing ingredients cause no partial spend")
	talk("supplies"); check(c.act("supplies") and not c.act("supplies"),"Crew supplies claim once")
	before=s.materials.duplicate()
	check(not s.craft_recipe("forge_transit_regulator","alchemy").begins_with("Created") and s.materials==before,"Regulator requires a forge")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES.forge+Vector3(0,.1,1.4)
	var workshop: Control=world.hud.workshop; workshop.open("forge"); workshop.search.text="Transit Regulator"; workshop.refresh()
	check(workshop.ids==["forge_transit_regulator"],"Regulator can be found in the actual forge menu")
	var craft_button: Button=workshop.actions.get_child(0)
	check(not craft_button.disabled,"Prepared regulator recipe has an enabled craft button")
	craft_button.pressed.emit(); workshop.close()
	check(s.materials.steel_ingot==before.steel_ingot-4 and s.materials.crystal==before.crystal-3 and s.materials.rune_dust==before.rune_dust-2 and s.materials.transit_regulator==1,"Forge button consumes exact ingredients and produces one regulator")
	check(s.save_to("user://convergence-ready.json"),"Crafted regulator and briefing save")
	var loaded:=State.new(); check(loaded.load_from("user://convergence-ready.json") and loaded.materials.transit_regulator==1 and loaded.convergence.evidence.size()==4,"Preparation survives reload")
	talk("rig"); check(c.act("install") and s.materials.transit_regulator==0,"Installation consumes exactly one regulator")
	check(not c.act("install") and c.can_damage_enemy("convergence_0") and world.combat_enemies().size()==3,"Installed regulator cannot charge twice and awakens sentinels")
	talk("beacon"); check(not c.act("calibrate"),"Living sentinels prevent calibration")
	c.close_dialog(); p.set_paused(false)
	for enemy in c.enemies: enemy.receive_damage(10000,p)
	check(s.convergence.defeated.size()==3,"Live test uses expedition combat roster")
	check(c.loot("convergence_2") and not c.loot("convergence_2"),"Recovered upgrade supplies claim once")
	talk("beacon"); check(c.act("calibrate") and not c.act("calibrate") and c.beacon.visible,"Cleared test stabilizes visible return beacon once")
	talk("keeper"); var gold: int=s.gold
	check(c.act("reward") and s.gold==gold+180 and "convergence" in s.story_completed,"Report completes convergence and grants gold")
	check(not c.act("reward") and "expedition" in s.blueprints,"Report grants equipment patterns only once")
	for mat: Dictionary in s.crafting.materials: s.materials[mat.id]=100
	for id in ["wayfarer_shield","pathfinder_feet"]:
		check(s.craft_recipe("craft_"+id,"forge").begins_with("Created"),"Expedition pattern creates equipment: "+id)
		var uid: String=s.add_item(id,3)
		check(s.temper_cost(uid)=={"steel_ingot":4,"crystal":4,"ash_glass":1} and s.improve(uid,"forge").begins_with("Improved"),"Equipment tempers using stated rare materials: "+id)
	check(s.save_to("user://convergence-done.json") and loaded.load_from("user://convergence-done.json") and loaded.convergence==s.convergence,"Completed expedition round-trips")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://convergence-done.json"))
	for issue in ["missing_branch","duplicate_evidence","unaccepted","uninstalled","uncleared","unrewarded_route","invalid_loot"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"missing_branch": bad.story_completed.erase("roots")
			"duplicate_evidence": bad.convergence.evidence.append("roots")
			"unaccepted": bad.convergence.accepted=false
			"uninstalled": bad.convergence.installed=false
			"uncleared": bad.convergence.defeated.erase("convergence_0")
			"unrewarded_route": bad.story_completed.erase("convergence")
			"invalid_loot": bad.convergence.looted.append("convergence_9")
		fixture(bad); check(not loaded.load_from("user://convergence-bad.json") and loaded.convergence==s.convergence,"Invalid save rejected atomically: "+issue)
	data.erase("convergence"); fixture(data); check(loaded.load_from("user://convergence-bad.json") and not loaded.convergence.accepted,"Older save starts with an untouched expedition")
	c.close_dialog(); p.set_paused(false); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_convergence() and world.hud.world_map.place_action.disabled,"Mirewatch has a local map and safe dossier")
	for id in ["forge","enchant"]:
		p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); check(world.station_nearby()==id,"Expedition workstation reachable: "+id)
	c.leave(); check(not c.inside and p.position.distance_to(c.TRAIL)<3,"Return road leads home")
	check(c.enter(),"Completed expedition can be revisited")
	s.story_completed.append("council"); check(world.choir.enter() and not c.inside,"Cross-chapter travel clears expedition state")
	check(c.enter() and not world.choir.inside,"Return from Choir restores expedition environment")
	p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Combat death exits and restores vitals")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Preparation does not skip the actual space expedition")
	for name in ["ready","done","bad"]: DirAccess.remove_absolute("user://convergence-"+name+".json")
	world.queue_free(); await process_frame
	print("CONVERGENCE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
