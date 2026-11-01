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
	var f:=FileAccess.open("user://threshold-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.threshold; p=world.player; s=p.character
	check(not c.enter(),"Space crossing requires expedition preparation")
	s.story_completed.append("archive"); world.lens.enter()
	for enemy in world.lens.enemies: enemy.set_physics_process(false)
	check(await walk(c.TRAIL-c.ORIGIN+Vector3(0,.2,4),c.TRAIL-c.ORIGIN+Vector3(0,.2,0)),"Crossing approach stays inside the observatory vault walls")
	p.position=c.TRAIL+Vector3(0,.1,1.4)
	check(world.nearest_interaction().kind=="threshold","Crossing is reachable from the Sunken Lens vault")
	world.interact_nearby(); check(not c.inside,"Physical crossing respects convergence gate")
	s.story_completed.append("convergence"); world.interact_nearby()
	check(c.inside and not world.lens.inside,"Actual crossing leaves observatory and enters station")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Airlock arrival has a physical floor")
	check(world.audio.zone()=="station" and world.audio.choose_track("station",false)=="station" and world.audio.choose_track("station",true)=="station_battle","Station selects its exploration and battle scores")
	check(await walk(Vector3(0,.2,11),Vector3(0,.2,5)),"Airlock doorway is traversable")
	check(not await walk(Vector3(0,.2,-40),Vector3(0,.2,-46)),"Command shutter blocks the unrepaired station")
	var boss: CharacterBody3D=c.enemies[5]; var hp: float=boss.health; boss.receive_damage(10000,p)
	check(boss.health==hp and world.combat_enemies().size()==3,"Sealed command security stays protected and outside targeting roster")
	talk("air"); check(not c.act("air"),"Life support requires power first")
	talk("power"); check(not c.act("power"),"Repairs require acceptance")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Engineer quest accepts once")
	var arrows_before: int=s.materials.get("arrow",0); var draughts_before: int=s.consumables.get("magicka_draught",0)
	talk("locker"); check(c.act("locker") and not c.act("locker") and "station" in s.blueprints,"Locker grants rifle, ammunition and patterns once")
	check(s.materials.arrow==arrows_before+36 and s.consumables.magicka_draught==draughts_before+2,"Locker adds exact one-time archer and caster reserves")
	var rifle: String=""
	for uid: String in s.inventory:
		if s.inventory[uid].base_id=="station_rifle": rifle=uid
	check(rifle!="" and s.materials.station_round==120,"Emergency rifle is owned and has usable ammunition")
	c.close_dialog(); p.set_paused(false); s.equip(rifle,"main_hand")
	p.position=c.ORIGIN+Vector3(0,.2,1); p.rotation=Vector3.ZERO; p.set_third_person(false); p.pivot.rotation=Vector3.ZERO; p.pivot.position.y=1.35
	c.enemies[0].position=c.ORIGIN+Vector3(0,.2,-4); await frames(8)
	s.materials.hell_round=11; p.attack_cooldown=0; var rounds: int=s.materials.station_round; hp=c.enemies[0].health
	check(p.attack() and s.materials.station_round==rounds-1 and s.materials.hell_round==11 and is_equal_approx(p.attack_cooldown,.18),"Rifle spends only station ammunition and uses its fire rate")
	check(not p.attack(),"Rifle respects cooldown")
	await frames(40); check(c.enemies[0].health<hp,"Station rifle projectile hits a real station enemy")
	s.materials.station_round=0; p.attack_cooldown=0; check(not p.attack() and s.materials.hell_round==11,"Infernal rounds cannot substitute for station ammunition")
	s.materials.steel_ingot=2; s.materials.charcoal=2
	check(s.craft_recipe("press_station_rounds","forge").begins_with("Created") and s.materials.station_round==40 and s.materials.steel_ingot==1 and s.materials.charcoal==1,"Forty station rounds forge from ordinary materials at exact cost")
	talk("cargo"); var cargo_position: Vector3=p.position; p.position+=Vector3.RIGHT*8
	check(not c.act("cargo") and s.materials.arrow==arrows_before+36 and s.consumables.magicka_draught==draughts_before+2,"Remote cargo action cannot grant reserves")
	p.position=cargo_position
	talk("cargo"); check(c.act("cargo") and not c.act("cargo"),"Cargo salvage claims once")
	check(s.materials.arrow==arrows_before+60 and s.consumables.magicka_draught==draughts_before+3,"Both caches provide 60 arrows and three draughts without duplicates")
	talk("power"); p.position+=Vector3(10,0,0); check(not c.act("power"),"Remote repair rejected")
	talk("power"); check(c.act("power") and not c.act("power"),"Reactor isolation records once")
	check(s.save_to("user://threshold-mid.json"),"Partial station repair saves")
	var loaded:=State.new(); check(loaded.load_from("user://threshold-mid.json") and loaded.threshold.power and not loaded.threshold.air,"Partial repair survives reload")
	check(loaded.materials.arrow==arrows_before+60 and loaded.consumables.magicka_draught==draughts_before+3,"Support supplies and claimed caches survive reload")
	check(s.load_from("user://threshold-mid.json"),"Reload live support-supply checkpoint")
	talk("locker"); check(not c.act("locker"),"Loaded locker cannot refill")
	talk("cargo"); check(not c.act("cargo") and s.materials.arrow==arrows_before+60,"Loaded cargo cannot refill")
	c.close_dialog(); p.set_paused(false); p.magicka=0
	check(s.consume("magicka_draught",p).begins_with("Used") and p.magicka==50 and s.consumables.magicka_draught==draughts_before+2,"Reserve draught actually restores 50 magicka and consumes one")
	talk("air"); check(c.act("air") and not c.act("air") and c.gate.collision_layer==0,"Life-support restart opens command shutter once")
	c.close_dialog(); p.set_paused(false); check(await walk(Vector3(0,.2,-40),Vector3(0,.2,-46)),"Repaired command deck is physically accessible")
	check(world.combat_enemies().size()==6,"All security activates after repair")
	for enemy in c.enemies: enemy.receive_damage(10000,p)
	check(c.loot("threshold_5") and not c.loot("threshold_5"),"Broodmother drops its named blade once")
	talk("record"); check(c.act("record") and not c.act("record") and not c.record_mesh.visible,"Archive becomes protected evidence once")
	check(not c.reward() and not world.realms.can_enter("aeralis"),"Archive alone does not unlock Aeralis before returning")
	for mat: Dictionary in s.crafting.materials: s.materials[mat.id]=100
	for id in ["station_rifle","station_chest","void_cutter"]:
		check(s.craft_recipe("craft_"+id,"forge").begins_with("Created"),"Station pattern creates gear: "+id)
		var uid: String=s.add_item(id,3)
		check(s.temper_cost(uid)=={"steel_ingot":4,"station_alloy":4,"navigation_cell":1} and s.improve(uid,"forge").begins_with("Improved"),"Navigation cells support high-tier tempering: "+id)
	c.close_dialog(); p.set_paused(false); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_threshold() and world.hud.world_map.place_action.disabled,"Station has a local map and safe dossier")
	for id in ["forge","enchant"]:
		p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); check(world.station_nearby()==id,"Station bench reachable: "+id)
	var gold: int=s.gold; p.position=c.ORIGIN+c.NODES["return"]+Vector3(0,.1,-1); world.interact_nearby()
	check(not c.inside and p.position.distance_to(c.HOME)<.01 and s.threshold.rewarded and s.gold==gold+200,"Physical return completes expedition and grants rewards")
	check(world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Successful expedition unlocks only Aeralis")
	check(not c.reward(),"Returned reward cannot duplicate")
	s.equip(rifle,"main_hand"); p.attack_cooldown=0; rounds=s.materials.station_round
	check(p.attack() and s.materials.station_round==rounds-1,"Station rifle remains usable at home")
	world.adventure.clear_projectiles()
	check(s.save_to("user://threshold-done.json") and loaded.load_from("user://threshold-done.json") and loaded.threshold==s.threshold,"Return progress and portable equipment survive reload")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://threshold-done.json"))
	for issue in ["prerequisite","power","air","archive","return","duplicate","loot"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"prerequisite": bad.story_completed.erase("convergence")
			"power": bad.threshold.accepted=false
			"air": bad.threshold.power=false
			"archive": bad.threshold.defeated.erase("threshold_5")
			"return": bad.story_completed.erase("threshold")
			"duplicate": bad.threshold.defeated.append("threshold_0")
			"loot": bad.threshold.looted.append("unknown")
		fixture(bad); check(not loaded.load_from("user://threshold-bad.json") and loaded.threshold==s.threshold,"Invalid save rejected atomically: "+issue)
	data.erase("threshold"); fixture(data); check(loaded.load_from("user://threshold-bad.json") and not loaded.threshold.accepted,"Older saves gain untouched station progress")
	check(world.realms.enter("aeralis",false) and not world.realms.preview,"Aeralis admits normal campaign entry without preview bypass")
	check(world.realms.attune("aeralis") and "starfall" in s.known_spells,"Normal Aeralis grants its own magic and patterns")
	for enemy in world.realms.enemies:
		if enemy.enemy_id.begins_with("aeralis"):
			enemy.set_physics_process(false); enemy.receive_damage(10000,p); world.realms.loot(enemy.enemy_id)
	p.position=world.realms.vector(world.realms.definitions.aeralis.origin)+Vector3(0,.1,19); world.realms.interact("leave")
	check(not world.realms.inside and "returning_light" in s.story_completed,"Aeralis guardian and return complete the next chapter in normal progression")
	check(not world.realms.can_enter("crucible"),"Aeralis completion preserves the later Hell prerequisites")
	check(s.save_to("user://threshold-chain.json") and loaded.load_from("user://threshold-chain.json") and "returning_light" in loaded.story_completed,"Station-to-Aeralis campaign progress round-trips")
	check(c.enter(),"Station remains revisitable")
	p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Station combat death returns safely home")
	for name in ["mid","done","bad","chain"]: DirAccess.remove_absolute("user://threshold-"+name+".json")
	world.queue_free(); await process_frame
	print("THRESHOLD_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
