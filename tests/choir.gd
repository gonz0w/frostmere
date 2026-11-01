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
	var f:=FileAccess.open("user://choir-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.choir; p=world.player; s=p.character
	check(not c.enter(),"Pilgrimage requires council resolution")
	s.story_completed.append("council"); check(c.enter() and s.mountain.clan=="","Council opens sanctuary without clan or cult membership")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Pilgrim arrival has a physical floor")
	check(await walk(Vector3(-13,.2,28),Vector3(-13,.2,24)),"Sereth's lodge is enterable")
	check(await walk(Vector3(0,.2,-18),Vector3(0,.2,-23)),"Sanctuary aisle is traversable")
	check(not await walk(Vector3(25,.2,-10),Vector3(30,.2,-10)),"Basalt parapet blocks access to decorative lava")
	check(not await walk(Vector3(34,.2,26),Vector3(34,.2,20)),"Channel end cap blocks the southern lava approach")
	check(not await walk(Vector3(0,.2,-54),Vector3(0,.2,-60)),"Receiver barrier physically closes vault")
	var boss: CharacterBody3D=c.enemies[4]; var hp: float=boss.health; boss.receive_damage(1000,p)
	check(boss.health==hp and "receiver" in c.feedback,"Receiver protects dormant guardian with accurate feedback")
	talk("ember"); check(not c.act("ring"),"Ringing requires acceptance")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Quest accepts once")
	check(not c.act("reward"),"Cannot receive premature reward")
	talk("receiver"); check(not c.act("activate"),"Unsolved song cannot repair receiver")
	talk("record"); check(not c.act("record"),"Cannot retrieve guarded signal")
	talk("ash"); var mats: Dictionary=s.materials.duplicate(); check(c.act("ring") and s.choir.song.is_empty() and s.materials==mats,"Wrong starting note resets without material cost")
	talk("ember"); check(c.act("ring") and s.choir.song==["ember"],"First note lights the ember resonator")
	check(c.lights.ember.material_override==world.blocks.materials.choir_signal,"Correct note has visible feedback")
	check(s.save_to("user://choir-partial.json"),"Partial song saves")
	var partial:=State.new(); check(partial.load_from("user://choir-partial.json") and partial.choir.song==["ember"],"Partial song survives reload")
	talk("stone"); check(c.act("ring") and s.choir.song.is_empty(),"Out-of-order note clears partial sequence")
	for id in c.SONG:
		talk(id); p.position+=Vector3(10,0,0); check(not c.act("ring"),"Remote resonator action rejected: "+id)
		talk(id); check(c.act("ring"),"Correct note: "+id)
		check(is_equal_approx(c.bell.pitch_scale,[.75,1.0,1.25][c.SONG.find(id)]) and c.bell.stream!=null,"Resonator has its distinct pitch and sound: "+id)
	check(s.choir.song==c.SONG,"All three notes solve the sequence")
	talk("receiver"); s.materials.resonant_ore=0; mats=s.materials.duplicate()
	check(not c.act("activate") and s.materials==mats,"Missing ore does not partially spend inventory")
	for id in ["camp_cache","vault_cache"]:
		talk(id); check(c.act("cache") and not c.act("cache"),"Repair cache claims once: "+id)
	talk("receiver"); var ore: int=s.materials.resonant_ore; var crystals: int=s.materials.crystal
	check(c.act("activate") and s.materials.resonant_ore==ore-3 and s.materials.crystal==crystals-2,"Repair spends exact ore and crystal cost")
	check(not c.act("activate") and c.gate.collision_layer==0,"Repair cannot charge twice and removes barrier")
	talk("ember"); check(not c.act("ring") and s.choir.song==c.SONG,"Repaired receiver locks the sequence")
	c.close_dialog(); p.set_paused(false)
	check(await walk(Vector3(0,.2,-54),Vector3(0,.2,-60)),"Repaired vault admits the player")
	boss.receive_damage(10,p); check(boss.health<hp,"Repair makes guardian vulnerable")
	for enemy in c.enemies: enemy.receive_damage(10000,p)
	check(c.loot("choir_4") and not c.loot("choir_4"),"Named guardian blade drops once")
	talk("record"); check(c.act("record") and not c.act("record") and not c.record_mesh.visible,"Signal becomes protected one-time evidence")
	talk("keeper"); var gold: int=s.gold
	check(c.act("reward") and s.gold==gold+160 and "choir" in s.story_completed,"Report advances campaign and rewards gold")
	check(not c.act("reward") and "resonance" in s.blueprints,"Report grants patterns only once")
	for mat: Dictionary in s.crafting.materials: s.materials[mat.id]=100
	for id in ["resonance_blade","cantors_chest","cantors_staff"]:
		check(s.craft_recipe("craft_"+id,"forge").begins_with("Created"),"Resonance pattern forges: "+id)
		var uid: String=s.add_item(id,3)
		check(s.temper_cost(uid)=={"steel_ingot":4,"resonant_ore":4,"ash_glass":1},"High-tier temper uses ash glass: "+id)
		check(s.improve(uid,"forge").begins_with("Improved") and s.inventory[uid].quality==4,"Resonance equipment improves: "+id)
	check(s.save_to("user://choir-done.json"),"Completed chapter saves")
	var loaded:=State.new(); check(loaded.load_from("user://choir-done.json") and loaded.choir==s.choir,"Chapter state and rewards survive reload")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://choir-done.json"))
	for problem in ["order","duplicates","unaccepted","guardian","record","looted","prerequisite"]:
		var bad: Dictionary=data.duplicate(true)
		match problem:
			"order": bad.choir.song=["ash","ember","stone"]
			"duplicates": bad.choir.caches.append("camp_cache")
			"unaccepted": bad.choir.accepted=false
			"guardian": bad.choir.activated=false
			"record": bad.choir.defeated.erase("choir_4")
			"looted": bad.choir.looted.append("choir_99")
			"prerequisite": bad.story_completed.erase("council")
		fixture(bad); check(not loaded.load_from("user://choir-bad.json") and loaded.choir==s.choir,"Invalid save rejected atomically: "+problem)
	data.erase("choir"); fixture(data); check(loaded.load_from("user://choir-bad.json") and not loaded.choir.accepted,"Legacy save gains untouched chapter")
	c.close_dialog(); p.set_paused(false); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_choir() and world.hud.world_map.place_action.disabled,"Caldera has a local map and safe dossier")
	for id in ["forge","enchant"]:
		p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4); check(world.station_nearby()==id,"Station reachable: "+id)
	c.leave(); check(not c.inside and p.position.distance_to(c.TRAIL)<3,"Return road leads home")
	check(c.enter(),"Completed sanctuary can be revisited")
	s.story_completed.append("archive"); check(world.lens.enter() and not c.inside,"Entering observatory clears choir state")
	check(c.enter() and not world.lens.inside,"Entering choir clears observatory state")
	p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Combat death exits and restores vitals")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Signal does not bypass convergence or later realm gates")
	for name in ["partial","done","bad"]: DirAccess.remove_absolute("user://choir-"+name+".json")
	world.queue_free(); await process_frame
	print("CHOIR_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
