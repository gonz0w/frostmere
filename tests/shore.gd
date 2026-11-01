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
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); p.velocity=Vector3.ZERO
	world.interact_nearby()
func walk(from: Vector3,to: Vector3) -> bool:
	p.position=c.ORIGIN+from; p.velocity=Vector3.ZERO
	await frames(4)
	for i in range(60):
		p.velocity=(c.ORIGIN+to-p.position).normalized()*4
		p.move_and_slide(); await physics_frame
	return Vector2(p.position.x-c.ORIGIN.x-to.x,p.position.z-to.z).length()<.8
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.shore; p=world.player; s=p.character
	check(not c.enter(),"Coastal chapter requires the atlas")
	s.story_completed.append("archive")
	var original_environment: Environment
	for child in world.get_children():
		if child is WorldEnvironment: original_environment=child.environment
	check(c.enter() and c.inside,"Atlas unlocks the coast independently of other branches")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15)
	check(p.is_on_floor() and absf(p.position.x-c.ORIGIN.x)<55,"Arrival has physical ground and region bounds")
	for h in [[34,28,24],[10,14,10],[41,49,44]]:
		check(await walk(Vector3(h[0],.2,h[1]),Vector3(h[0],.2,h[2])),"Enter coastal house at x=%d" % h[0])
	check(await walk(Vector3(0,.2,-19),Vector3(0,.2,-23)),"Sea-cave mouth is traversable")
	check(await walk(Vector3(0,.2,-53),Vector3(0,.2,-58)),"Sea-cave exit reaches the relay path")
	check(not await walk(Vector3(21,.2,-59),Vector3(21,.2,-65)),"Unrestored physical bulkhead blocks entry")
	talk("relay"); check(not c.act("solve"),"Cannot repair before accepting the investigation")
	talk("harbor"); check(c.dialog.visible and p.paused and c.act("accept"),"Harbor conversation accepts the expedition")
	check(not c.act("accept"),"Acceptance cannot duplicate")
	check(c.act("hear"),"Hear Saltbreak's claim")
	talk("salvager"); check(c.act("hear"),"Hear rival salvage crew's claim")
	check(not c.act("identify_blade"),"Unrecovered equipment cannot be identified")
	talk("relay"); check(not c.act("solve"),"Relay requires upstream pressure to be vented")
	talk("pump"); var mats: Dictionary=s.materials.duplicate(); check(not c.act("wrong") and s.materials==mats,"Incorrect pump setting preserves materials")
	p.position+=Vector3(0,0,8); check(not c.act("solve"),"Remote repair input is rejected")
	talk("pump"); check(c.act("solve") and not c.act("solve"),"Pressure pump restores only once")
	talk("relay"); check(c.act("solve") and c.bulkhead.collision_layer==0 and not c.bulkhead.visible,"Second repair opens the physical hull")
	c.close_dialog(); p.set_paused(false)
	check(await walk(Vector3(21,.2,-59),Vector3(21,.2,-65)),"Opened bulkhead admits the player")
	check(await walk(Vector3(21,.2,-80),Vector3(21,.2,-84)),"Internal hull doorway is traversable")
	for id in ["coast_cache","cave_cache"]:
		talk(id); check(c.act("cache") and not c.act("cache"),"Damaged relic cache claims once: "+id)
	talk("salvager")
	for key in ["blade","armor"]: check(c.act("identify_"+key) and not c.act("identify_"+key),"Identifies a unique restoration pattern: "+key)
	for mat: Dictionary in s.crafting.materials:
		if mat.id not in ["fractured_hilt","pressure_shell","clouded_lens"]: s.materials[mat.id]=60
	for id in ["tideglass_saber","tideguard_shell"]:
		var part: String="fractured_hilt" if id=="tideglass_saber" else "pressure_shell"
		check(s.craft_recipe("craft_"+id,"forge").begins_with("Created") and s.materials[part]==0,"Restoration consumes the damaged part: "+id)
		var uid: String=""
		for owned: String in s.inventory:
			if s.inventory[owned].base_id==id: uid=owned
		check(not s.temper_cost(uid).has(part) and s.improve(uid,"forge").begins_with("Improved"),"Restored gear tempers without another damaged relic")
		s.inventory[uid].quality=3
		check(s.temper_cost(uid).has("signal_circuit"),"High tempering consumes rare ship circuitry")
	talk("core"); check(not c.act("core"),"Guardian and recorder protect the quest core")
	talk("log"); check(c.act("log") and not c.act("log"),"Flight recorder copies exactly once")
	c.close_dialog(); p.set_paused(false)
	var guard: CharacterBody3D=c.enemies[0]
	p.position=c.ORIGIN+Vector3(1,.2,-11); guard.position=c.ORIGIN+Vector3(1,.2,-13); p.rotation=Vector3.ZERO
	await frames(); var hp: float=guard.health; p.attack_cooldown=0; p.stamina=p.derived.stamina
	check(p.attack() and guard.health<hp,"Player melee damages coastal raiders")
	for enemy in c.enemies: enemy.receive_damage(10000)
	check(c.loot("shore_6") and not c.loot("shore_6") and s.materials.clouded_lens==1,"Hull guardian drops its damaged signal lens once")
	talk("salvager"); check(c.act("identify_focus"),"Guardian lens identification unlocks final restoration")
	check(s.craft_recipe("craft_signal_focus","forge").begins_with("Created"),"Identified focus can be restored")
	talk("core"); check(c.act("core") and not c.core_mesh.visible,"Protected core leaves its cradle")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES.forge+Vector3(0,.1,1.4); world.interact_nearby()
	check(p.workshop_open and world.hud.workshop.station()=="forge" and world.hud.workshop.mode=="Forge","Coastal forge opens the restoration interface")
	world.hud.workshop.close()
	check(s.save_to("user://shore-ready.json"),"Pre-choice expedition saves")
	for choice in ["harbor","navigation"]:
		if choice=="navigation": check(s.load_from("user://shore-ready.json"),"Reload the alternate pre-choice branch")
		talk("harbor" if choice=="harbor" else "navigation")
		check(c.act("choose_"+choice) and not c.act("choose_"+choice),"One permanent core destination: "+choice)
		check(c.beacon.visible==(choice=="harbor") and c.nav_light.visible==(choice=="navigation"),"Core visibly powers only the chosen destination")
		check(not s.shore.rewarded and "tides" not in s.story_completed,"Final report remains required")
		talk("harbor"); var gold: int=s.gold
		check(c.act("reward") and s.gold==gold+150 and "tides" in s.story_completed,"Return report advances the main timeline")
		check(not c.act("reward"),"Final reward cannot duplicate")
		check("shore_"+choice in s.blueprints and ("shore_navigation" if choice=="harbor" else "shore_harbor") not in s.blueprints,"Only chosen reward pattern unlocks")
		check(s.save_to("user://shore-done.json"),"Completed coast saves")
		var loaded:=State.new(); check(loaded.load_from("user://shore-done.json") and loaded.shore==s.shore,"Core outcome and restoration progress survive reload")
	c.close_dialog(); p.set_paused(false)
	world.hud.world_map.set_view(true); world.hud.world_map._show_quest()
	check(world.hud.world_map.canvas.in_shore() and world.hud.world_map.quest_action.disabled,"Coast has its own map and quest dossier")
	p.position=c.ORIGIN+Vector3(-30,-4,0); c.check_fall()
	check(c.inside and p.position.distance_to(c.ORIGIN+Vector3(22,.2,42))<1,"Dangerous surf returns player with progress intact")
	p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x> -100 and p.health==p.derived.health,"Combat death restores vitals and exits coastal coordinates safely")
	for child in world.get_children():
		if child is WorldEnvironment: check(child.environment==original_environment,"Leaving restores the original world environment")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Coastal story does not bypass later realm gates")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://shore-done.json")); data.shore.choice="both"
	var f:=FileAccess.open("user://shore-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	var loaded:=State.new(); check(not loaded.load_from("user://shore-bad.json"),"Impossible dual-core save is rejected")
	data.erase("shore"); f=FileAccess.open("user://shore-old.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://shore-old.json") and not loaded.shore.accepted,"Older saves gain an untouched coast")
	for name in ["ready","done","bad","old"]: DirAccess.remove_absolute("user://shore-"+name+".json")
	world.queue_free(); await process_frame
	print("SHORE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
