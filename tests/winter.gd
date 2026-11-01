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
	var f:=FileAccess.open("user://winter-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.winter; p=world.player; s=p.character
	check(not c.enter(),"Siege requires the return from Aeralis")
	p.position=c.TRAIL+Vector3(0,.1,1.4); check(world.nearest_interaction().get("kind")=="winter","Home-world supply road is interactable")
	world.interact_nearby(); check(not c.inside,"Travel interaction respects story gate")
	s.story_completed.append("returning_light"); world.interact_nearby()
	check(c.inside and not p.character.persist,"Supply road enters isolated test fort")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Arrival has a physical floor")
	check(await walk(Vector3(0,.2,-5),Vector3(0,.2,-11)),"Fort gate lane is physically traversable")
	check(world.combat_enemies().is_empty(),"No active invaders before accepting defense")
	check(not c.enemies[5].visible and c.enemies[5].collision_layer==0,"Later assault is hidden and noncolliding")
	c.enemies[5].receive_damage(10000,p); check(not c.enemies[5].dead,"Dormant commander cannot be killed early")
	talk("ward"); check(not c.act("repair"),"Cannot repair before clearing scouts")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Defense accepts once")
	check(world.combat_enemies().size()==3,"Acceptance activates exactly three scouts")
	check(not c.act("assault"),"Main assault cannot begin early")
	talk("supplies"); var steel: int=s.materials.get("steel_ingot",0)
	check(c.act("supplies") and not c.act("supplies") and s.materials.steel_ingot==steel+8,"Reserved repair stock grants once")
	c.close_dialog(); p.set_paused(false)
	for i in range(3): c.enemies[i].receive_damage(10000,p)
	check(c.first_wave_done() and s.winter.defeated.size()==3,"Actual combat clears the scouting phase")
	check(c.loot("winter_0") and not c.loot("winter_0"),"Invader loot is single claim")
	talk("ward"); s.materials.crystal=0; var dust: int=s.materials.rune_dust
	check(not c.act("repair") and s.materials.rune_dust==dust,"Insufficient repair stock spends nothing")
	s.materials.crystal=6
	check(c.act("repair") and not c.act("repair") and s.materials.crystal==4 and s.materials.rune_dust==dust-2,"Ward consumes exact repair materials once")
	talk("keeper"); check(not c.act("assault"),"Both defenses are required")
	talk("ballista"); steel=s.materials.steel_ingot
	check(c.act("repair") and s.materials.steel_ingot==steel-3,"Ballista consumes three steel")
	check(s.save_to("user://winter-mid.json"),"Intermission progress saves")
	var loaded:=State.new(); check(loaded.load_from("user://winter-mid.json") and loaded.winter==s.winter,"Repair and defeat progress round-trips")
	talk("keeper"); p.health=1; p.magicka=1
	check(c.act("assault") and not c.act("assault"),"Captain begins main assault only once")
	check(p.health==p.derived.health and p.magicka==p.derived.magicka,"Watchstone restores combat resources")
	check(c.enemies[5].health==340 and c.enemies[5].visible,"Ballista weakens the now-visible marshal by 100")
	c.close_dialog(); p.set_paused(false); c.leave(); check(c.enter(),"Fort can be revisited during assault")
	check(c.enemies[5].health==340,"Ballista weakening survives leaving and returning")
	for i in range(3,6): c.enemies[i].receive_damage(10000,p)
	check(s.winter.defeated.size()==6,"Main assault clears through real enemy defeat callbacks")
	talk("keeper"); check(not c.act("reward"),"Victory requires recovering the orders")
	talk("orders"); check(c.act("orders") and not c.act("orders"),"Command satchel recovered once")
	talk("keeper"); var gold: int=s.gold
	check(c.act("reward") and not c.act("reward") and s.gold==gold+240,"Garrison reward is single claim")
	check("winter_siege" in s.story_completed and not world.realms.can_enter("crucible"),"Siege completion leaves Broken Seal gate intact")
	check("northwatch" in s.blueprints,"Victory teaches garrison patterns")
	for id in ["northwatch_head","northwatch_greatsword"]:
		var found:=false
		for uid: String in s.inventory:
			if s.inventory[uid].base_id==id: found=true; check(s.inventory[uid].favorite,"Quest equipment is protected as a favorite")
		check(found,"Earned equipment: "+id)
		s.materials.steel_ingot=20; s.materials.crystal=20; s.materials.rune_dust=20
		check(s.craft_recipe("craft_"+id,"forge").begins_with("Created"),"Reward pattern can be forged: "+id)
		var temper_uid: String=s.add_item(id,3)
		check(s.temper_cost(temper_uid)=={"steel_ingot":4,"crystal":4,"rune_dust":1} and s.improve(temper_uid,"forge").begins_with("Improved"),"Northwatch gear supports high-rank tempering: "+id)
	check(s.save_to("user://winter-done.json") and loaded.load_from("user://winter-done.json") and loaded.winter==s.winter,"Completed chapter and rewards round-trip")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://winter-done.json"))
	for issue in ["requirement","phase","repairs","orders","reward","duplicate","loot","type"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"requirement": bad.story_completed.erase("returning_light")
			"phase": bad.winter.assault=false
			"repairs": bad.winter.repairs=["ward"]
			"orders": bad.winter.defeated.erase("winter_4")
			"reward": bad.story_completed.erase("winter_siege")
			"duplicate": bad.winter.defeated.append("winter_0")
			"loot": bad.winter.looted.append("unknown")
			"type": bad.winter.assault="yes"
		fixture(bad); check(not loaded.load_from("user://winter-bad.json") and loaded.winter==s.winter,"Invalid save rejected atomically: "+issue)
	data.erase("winter"); fixture(data); check(loaded.load_from("user://winter-bad.json") and not loaded.winter.accepted,"Older saves receive fresh siege progress")
	c.close_dialog(); p.set_paused(false); s.story_completed.append("archive")
	check(world.lens.enter() and not c.inside,"Travel to another chapter clears siege state")
	check(c.enter() and not world.lens.inside,"Returning to the fort clears previous chapter state")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_winter() and world.hud.world_map.status.text==c.objective(),"Local map reports current siege progress")
	p.map_open=false; p.set_paused(false); p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Combat death returns safely home")
	for name in ["mid","done","bad"]: DirAccess.remove_absolute("user://winter-"+name+".json")
	world.queue_free(); await process_frame
	print("WINTER_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
