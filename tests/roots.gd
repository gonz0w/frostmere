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
	var f:=FileAccess.open("user://roots-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.roots; p=world.player; s=p.character
	check(not c.enter(),"Woodland trail requires Stonewake")
	s.story_completed.append("stonewake"); check(c.enter(),"Stonewake opens the grove independently of atlas choice")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Grove arrival has a physical floor")
	for x in [-12,12]: check(await walk(Vector3(x,.2,28),Vector3(x,.2,24)),"Lodge doorway admits player: "+str(x))
	check(await walk(Vector3(0,.2,-58),Vector3(0,.2,-63)),"Hollow tree leaves an open shrine route")
	var boss: CharacterBody3D=c.enemies[3]; var hp: float=boss.health; boss.receive_damage(1000,p)
	check(boss.health==hp and "Hollow Warden" in c.feedback,"Linked roots protect boss with correct feedback")
	talk("spring"); check(not c.act("cleanse"),"Cannot cleanse before accepting")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Quest accepts once")
	check(c.act("hear") and not c.act("hear"),"Keeper proposal records once")
	check(not c.act("reward"),"Premature reward rejected")
	talk("record"); check(not c.act("record"),"Memory unavailable before a pact")
	talk("heart"); check(not c.act("wild"),"Premature pact rejected")
	talk("spring"); check(not c.act("cleanse"),"Root must lose its defender")
	for i in range(3):
		c.close_dialog(); p.set_paused(false); c.enemies[i].receive_damage(10000,p)
		check(c.loot("roots_"+str(i)) and not c.loot("roots_"+str(i)),"Keeper loot is one-time: "+str(i))
	talk("spring"); s.materials.herb=0; var before: Dictionary=s.materials.duplicate()
	check(not c.act("cleanse") and s.materials==before,"Missing materials do not partially spend inventory")
	for id in ["camp_cache","grove_cache"]:
		talk(id); check(c.act("cache") and not c.act("cache"),"Supply cache only claims once: "+id)
	for id in ["spring","stone","seed"]:
		talk(id); p.position+=Vector3(10,0,0); check(not c.act("cleanse"),"Remote cleansing rejected: "+id)
		talk(id); var herbs: int=s.materials.herb; var water: int=s.materials.water
		check(c.act("cleanse") and s.materials.herb==herbs-2 and s.materials.water==water-2,"Exact cleansing cost: "+id)
		check(not c.act("cleanse"),"Cleansed root cannot charge again: "+id)
		check(c.root_lights[id].material_override==world.blocks.materials.roots_glow,"Cleansed root changes visually: "+id)
	check(not c.ward.visible and c.can_damage_enemy("roots_3"),"All roots remove Warden's protection")
	c.close_dialog(); p.set_paused(false); boss.receive_damage(10000,p)
	check(boss.dead and c.loot("roots_3") and not c.loot("roots_3"),"Warden yields named bow once")
	talk("heart"); check(not c.act("wild"),"Both proposals required before choosing")
	talk("steward"); check(c.act("hear"),"Hear the settlement proposal")
	check(s.save_to("user://roots-ready.json"),"Ready-to-choose state saves")
	var ready: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://roots-ready.json"))
	for choice in ["wild","tended"]:
		check(s.load_from("user://roots-ready.json"),"Reload unfinished pact: "+choice)
		talk("heart"); check(c.act(choice),"Commit restoration pact: "+choice)
		check(not c.act("tended" if choice=="wild" else "wild"),"Other pact locked permanently: "+choice)
		check(c.wild_growth.visible==(choice=="wild") and c.tended_growth.visible==(choice=="tended"),"Pact changes grove dressing: "+choice)
		talk("record"); check(c.act("record") and not c.act("record") and not c.record_mesh.visible,"Memory records once: "+choice)
		talk("keeper"); var gold: int=s.gold
		check(c.act("reward") and s.gold==gold+140 and "roots" in s.story_completed,"Report advances campaign: "+choice)
		check(not c.act("reward"),"Duplicate report rejected: "+choice)
		check("roots_"+choice in s.blueprints and "woodland" in s.blueprints and "roots_"+("wild" if choice=="tended" else "tended") not in s.blueprints,"Only chosen pattern is unlocked: "+choice)
		for mat: Dictionary in s.crafting.materials: s.materials[mat.id]=100
		var gear: String="groveheart_chest" if choice=="wild" else "pactkeeper_axe"
		check(s.craft_recipe("craft_"+gear,"forge").begins_with("Created") and s.craft_recipe("craft_amberbough_bow","forge").begins_with("Created"),"Pact and common patterns forge: "+choice)
		var other: String="pactkeeper_axe" if choice=="wild" else "groveheart_chest"
		check(not s.craft_recipe("craft_"+other,"forge").begins_with("Created"),"Opposite pattern cannot forge: "+choice)
		check(s.save_to("user://roots-done.json"),"Completed pact saves: "+choice)
		var loaded:=State.new(); check(loaded.load_from("user://roots-done.json") and loaded.roots==s.roots,"Pact state survives reload: "+choice)
	for item_id in ["amberbough_bow","groveheart_chest","pactkeeper_axe"]:
		var uid: String=s.add_item(item_id,3)
		check(s.temper_cost(uid)=={"leather":4,"heartwood":4,"amber_resin":1},"High-rank temper uses woodland materials: "+item_id)
		check(s.improve(uid,"forge").begins_with("Improved") and s.inventory[uid].quality==4,"Woodland gear improves: "+item_id)
	var vest: String=s.add_item("groveheart_chest"); s.equip(vest,"chest"); p.health=1; s.consumables.healing_draught=2
	var restored: float=float(s.definition("consumables","healing_draught").restore)
	s.consume("healing_draught",p); check(is_equal_approx(p.health,1+restored*1.25),"Groveheart Vest boosts real potion healing by 25 percent")
	c.close_dialog(); p.set_paused(false)
	var axe: String=s.add_item("pactkeeper_axe"); s.equip(axe,"main_hand")
	var target: CharacterBody3D=c.enemies[0]; target.dead=false; target.health=1; p.stamina=0
	target.receive_damage(10000,p,s.item_at("main_hand").effect)
	check(p.stamina==18,"Pactkeeper's melee-kill effect restores 18 stamina")
	# Corruption is rejected without mutating the loaded character.
	var loaded:=State.new()
	for change in ["duplicate","guardian","unheard","unpaid","record","loot"]:
		var data: Dictionary=ready.duplicate(true)
		match change:
			"duplicate": data.roots.cleansed.append("spring")
			"guardian": data.roots.cleansed=[]
			"unheard": data.roots.choice="wild"; data.roots.heard=[]
			"unpaid": data.roots.accepted=false
			"record": data.roots.record=true
			"loot": data.roots.defeated.erase("roots_0")
		fixture(data); check(not loaded.load_from("user://roots-bad.json") and not loaded.roots.accepted,"Reject invalid progress atomically: "+change)
	ready.erase("roots"); fixture(ready)
	check(loaded.load_from("user://roots-bad.json") and not loaded.roots.accepted,"Older save gains untouched woodland state")
	c.close_dialog(); p.set_paused(false); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_roots() and world.hud.world_map.place_action.disabled,"Grove has local map and safe dossier action")
	for id in ["forge","enchant","alchemy"]:
		p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); check(world.station_nearby()==id,"Woodland station reachable: "+id)
	c.leave(); check(not c.inside and p.position.distance_to(c.TRAIL)<3,"Return road leads home")
	check(c.enter(),"Completed grove can be revisited")
	check(world.mountain.enter() and not c.inside,"Travel into another chapter clears woodland state")
	world.mountain.leave(); p.set_paused(false); c.enter()
	p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Combat death exits grove and restores vitals")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Woodland memory does not bypass later realm gates")
	for name in ["ready","done","bad"]: DirAccess.remove_absolute("user://roots-"+name+".json")
	world.queue_free(); await process_frame
	print("ROOTS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
