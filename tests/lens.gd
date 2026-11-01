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
	return Vector2(p.position.x-c.ORIGIN.x-to.x,p.position.z-to.z).length()<.8
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.lens; p=world.player; s=p.character
	check(not c.enter(),"Sunken Lens requires the atlas")
	s.story_completed.append("archive"); check(c.enter(),"Atlas opens the observatory without requiring a particular shore choice")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Expedition arrival has a physical floor")
	check(await walk(Vector3(-16,.2,28),Vector3(-16,.2,24)),"Veyra's house is enterable")
	check(await walk(Vector3(0,.2,-20),Vector3(0,.2,-25)),"Circular observatory entrance is traversable")
	check(not await walk(Vector3(0,.2,-52),Vector3(0,.2,-58)),"Solar barrier physically closes the rear vault")
	var boss: CharacterBody3D=c.enemies[4]; var hp: float=boss.health; boss.receive_damage(1000,p)
	check(boss.health==hp,"Unrestored lens protects the guardian against damage")
	talk("dawn"); check(not c.act("rotate"),"Mirror controls require quest acceptance")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Expedition accepts only once")
	check(not c.act("reward"),"Cannot claim rewards without the star chart")
	talk("lens"); check(not c.act("activate"),"Wrong mirror orientations cannot activate the lens")
	for id in ["dawn","dusk","crown"]:
		talk(id); var before: int=int(s.lens.rotations[id]); p.position+=Vector3(10,0,0)
		check(not c.act("rotate") and s.lens.rotations[id]==before,"Remote mirror input is rejected: "+id)
		talk(id)
		while s.lens.rotations[id]!=c.SOLUTIONS[id]: check(c.act("rotate"),"Quarter turn: "+id)
		check(c.beams[id].position.distance_to((c.ORIGIN+c.NODES[id]+Vector3.UP*3.2+c.ORIGIN+c.NODES.lens+Vector3.UP*2.6)/2)<.01,"Aligned beam meets the central lens: "+id)
	talk("lens"); s.materials.optic_glass=0; var materials: Dictionary=s.materials.duplicate()
	check(not c.act("activate") and s.materials==materials,"Missing restoration materials cannot partially spend inventory")
	for id in ["west_cache","east_cache"]:
		talk(id); check(c.act("cache") and not c.act("cache"),"Excavation cache claims once: "+id)
	talk("lens"); var glass: int=s.materials.optic_glass; var crystals: int=s.materials.crystal
	check(c.act("activate") and s.materials.optic_glass==glass-3 and s.materials.crystal==crystals-2,"Lens restoration spends exact materials")
	check(not c.act("activate") and c.gate.collision_layer==0 and c.prism.visible,"Activated lens cannot charge twice and lowers barrier")
	talk("dawn"); check(not c.act("rotate"),"Active lens locks solved mirrors")
	c.close_dialog(); p.set_paused(false)
	check(await walk(Vector3(0,.2,-52),Vector3(0,.2,-58)),"Restored vault admits the player")
	boss.receive_damage(10,p); check(boss.health<hp,"Restoration makes guardian vulnerable")
	check(not p.cast_spell("sunlance"),"Unlearned Sunlance cannot be cast")
	# Isolate the new projectile's real collision path in the open hall.
	s.known_spells.append("sunlance"); p.position=c.ORIGIN+Vector3(-8,.2,-29); p.rotation=Vector3.ZERO; p.set_third_person(false); p.pivot.rotation=Vector3.ZERO; p.pivot.position.y=1.35
	for i in range(3): c.enemies[i].position=c.ORIGIN+Vector3(-8,.2,-33-i*4)
	await frames(8)
	var healths=[]
	for i in range(3): healths.append(c.enemies[i].health)
	p.magicka=100; p.spell_cooldown=0
	check(p.cast_spell("sunlance") and p.magicka==70,"Sunlance spends exactly 30 magicka")
	check(not p.cast_spell("sunlance"),"Sunlance respects cooldown")
	await frames(60)
	var first: float=healths[0]-c.enemies[0].health; var second: float=healths[1]-c.enemies[1].health
	check(first>0 and second>0 and c.enemies[2].health==healths[2],"Sunlance hits two distinct enemies and stops before a third")
	check(is_equal_approx(second,first*.7),"Pierced target receives 70 percent of initial damage")
	var wall:=StaticBody3D.new(); wall.position=c.ORIGIN+Vector3(-8,1.5,-35); world.add_child(wall)
	var collider:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(3,3,.4); collider.shape=shape; wall.add_child(collider); await frames()
	hp=c.enemies[1].health; p.magicka=100; p.spell_cooldown=0; p.cast_spell("sunlance"); await frames(55)
	check(c.enemies[1].health==hp,"Piercing sunlight cannot pass through a solid wall")
	wall.queue_free(); await frames()
	hp=c.enemies[1].health; p.magicka=100; p.spell_cooldown=0; p.cast_spell("emberbolt"); await frames(55)
	check(c.enemies[1].health==hp,"Ordinary projectiles retain single-target behavior")
	p.spell_cooldown=0; p.magicka=0; check(not p.cast_spell("sunlance"),"No magicka means no Sunlance")
	s.known_spells.erase("sunlance")
	for enemy in c.enemies: enemy.receive_damage(10000,p)
	check(c.loot("lens_4") and not c.loot("lens_4"),"Guardian's named solar blade drops once")
	talk("chart"); check(c.act("chart") and not c.chart_mesh.visible,"Star chart becomes protected evidence")
	check(s.save_to("user://lens-ready.json"),"Mid-chapter state saves")
	talk("keeper"); var gold: int=s.gold
	check(c.act("reward") and s.gold==gold+160 and "lens" in s.story_completed,"Return report advances the campaign and awards gold")
	check("sunlance" in s.known_spells and s.active_spell=="sunlance" and "sunken_lens" in s.blueprints,"Return unlocks Sunlance and solar-forging patterns")
	check(not c.act("reward"),"Reward cannot duplicate")
	for mat: Dictionary in s.crafting.materials: s.materials[mat.id]=100
	for id in ["sunsteel_saber","lenswarden_chest","horizon_staff"]: check(s.craft_recipe("craft_"+id,"forge").begins_with("Created"),"Solar pattern forges: "+id)
	check(s.save_to("user://lens-done.json"),"Completed observatory saves")
	var loaded:=State.new(); check(loaded.load_from("user://lens-done.json") and loaded.lens==s.lens and "sunlance" in loaded.known_spells,"Puzzle, gear and spell survive reload")
	c.close_dialog(); p.set_paused(false); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_lens() and world.hud.world_map.place_action.disabled,"Observatory has a local map and chapter dossier")
	p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Combat death safely exits and restores vitals")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Star chart does not bypass the remaining campaign branches")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://lens-done.json")); data.lens.rotations.dawn=2
	var f:=FileAccess.open("user://lens-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(not loaded.load_from("user://lens-bad.json"),"Activated lens with wrong alignment is rejected")
	data.erase("lens"); f=FileAccess.open("user://lens-old.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://lens-old.json") and not loaded.lens.accepted,"Older saves gain untouched observatory progress")
	for name in ["ready","done","bad","old"]: DirAccess.remove_absolute("user://lens-"+name+".json")
	world.queue_free(); await process_frame
	print("LENS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
