extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
var world: Node3D
var chapter: Node3D
var p: CharacterBody3D
var s: RefCounted
func _initialize() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok: print("PASS "+message)
	else: failures+=1; push_error("FAIL "+message)
func frames(n: int=3) -> void:
	for i in range(n): await physics_frame
func talk(id: String) -> void:
	chapter.close_dialog(); p.set_paused(false); p.position=chapter.ORIGIN+chapter.NODES[id]+Vector3(0,0.1,1.4); world.interact_nearby()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	chapter=world.archive_chapter; p=world.player; s=p.character
	check(not chapter.enter(),"Pinehall requires Stonewake")
	s.story_completed.append("stonewake")
	check(chapter.enter(),"Forest branch opens independently of council completion")
	for enemy in chapter.enemies: enemy.set_physics_process(false)
	await frames(30)
	check(p.is_on_floor() and p.position.x< -700,"Forest floor supports the player")
	for h in [[-814,10],[-786,10],[-823,30.5]]:
		p.position=Vector3(h[0],0.3,h[1]+3); p.rotation=Vector3.ZERO; p.velocity=Vector3.ZERO
		Input.action_press("move_forward"); await frames(110); Input.action_release("move_forward")
		check(p.position.z<h[1] and p.is_on_floor(),"Pinehall building entrance is walkable: "+str(h))
	for z in [-28,-46]:
		p.position=chapter.ORIGIN+Vector3(0,0.2,z+3); p.rotation=Vector3.ZERO; p.velocity=Vector3.ZERO
		Input.action_press("move_forward"); await frames(100); Input.action_release("move_forward")
		check(p.position.z<z and p.is_on_floor(),"Archive chamber doorway is traversable: "+str(z))
	talk("lantern")
	check(chapter.dialog.visible and p.paused,"Representative dialogue pauses combat")
	check(chapter.act("accept") and not chapter.act("accept"),"Expedition accepts once")
	check(chapter.act("hear") and not chapter.act("entrust"),"Lantern testimony cannot turn in missing evidence")
	talk("briar"); check(chapter.act("hear") and s.archive.heard.size()==2,"Both perspectives can be investigated without membership")
	talk("atlas"); check(not chapter.act("atlas"),"Living guardian prevents atlas recovery")
	chapter.close_dialog(); p.set_paused(false)
	# Fire the actual staff projectile through a line of separate, visible enemies.
	s.equip(s.add_item("lantern_conductor"),"main_hand"); p.position=chapter.ORIGIN+Vector3(0,0.2,-32); p.rotation=Vector3.ZERO; p.set_third_person(false)
	for i in range(4): chapter.enemies[i].position=chapter.ORIGIN+Vector3(i*2,0.1,-35 if i<3 else -64)
	await frames(8)
	var hp: Array=[]
	for enemy in chapter.enemies: hp.append(enemy.health)
	p.magicka=100; p.attack_cooldown=0; p.spell_cooldown=0
	check(p.attack() and p.magicka==76,"Conductor primary casts for exactly 24 magicka")
	check(not p.attack(),"Lightning respects its cooldown")
	await frames(40)
	check(chapter.enemies[0].health<hp[0] and chapter.enemies[1].health<hp[1] and chapter.enemies[2].health<hp[2] and chapter.enemies[3].health==hp[3],"Projectile strikes its target and chains to two enemies only")
	check(hp[1]-chapter.enemies[1].health < hp[0]-chapter.enemies[0].health and hp[2]-chapter.enemies[2].health < hp[1]-chapter.enemies[1].health,"Lightning damage diminishes at each jump")
	for i in range(4): chapter.enemies[i].position=chapter.ORIGIN+Vector3(6,0.1,-44 if i==0 else -48-i*2)
	await frames(8)
	hp.clear()
	for enemy in chapter.enemies: hp.append(enemy.health)
	p.chain_lightning(chapter.enemies[0],40,2)
	check(chapter.enemies[1].health==hp[1],"Lightning cannot jump through archive walls")
	for i in range(4): chapter.enemies[i].position=chapter.ORIGIN+Vector3(i*6,0.1,-35)
	await frames(8)
	p.chain_lightning(chapter.enemies[0],40,2)
	check(chapter.enemies[1].health==hp[1],"Lightning cannot jump beyond five meters")
	s.equip(s.add_item("iron_sword"),"main_hand"); p.spell_cooldown=0
	check(not p.cast_spell("chain_lightning"),"Removing the staff removes its unlearned primary spell")
	s.equip(s.add_item("echo_blade"),"main_hand")
	p.position=chapter.ORIGIN+Vector3(0,0.1,-32); chapter.enemies[0].position=chapter.ORIGIN+Vector3(0,0.1,-34); chapter.enemies[0].health=1
	await frames(8); p.stamina=50; p.attack_cooldown=0
	check(p.attack() and chapter.enemies[0].dead and p.stamina==59,"Echoharvest melee kill restores 18 stamina after the attack's 9-point cost")
	chapter.enemies[0].receive_damage(100,p,"stamina_on_kill")
	check(p.stamina==59,"Corpse damage cannot farm stamina")
	chapter.enemies[1].health=1; chapter.enemies[1].receive_damage(100,p)
	check(p.stamina==59,"Spell-style kills do not trigger the blade effect")
	s.equip(s.add_item("briar_vestment"),"chest"); s.consumables.healing_draught=4; p.health=10
	var restore: float=s.definition("consumables","healing_draught").restore
	s.consume("healing_draught",p)
	check(p.health==minf(p.derived.health,10+restore*1.25),"Vestment increases potion healing by 25 percent")
	p.health=p.derived.health; var potions: int=s.consumables.healing_draught; s.consume("healing_draught",p)
	check(s.consumables.healing_draught==potions,"Healing armor preserves full-health no-waste behavior")
	s.equip(s.add_item("leather_chest"),"chest"); p.health=10; s.consume("healing_draught",p)
	check(p.health==minf(p.derived.health,10+restore),"Removing the armor removes its healing bonus")
	for enemy in chapter.enemies: enemy.receive_damage(10000)
	check(chapter.loot("archive_3") and not chapter.loot("archive_3") and "archive_relic" in s.blueprints,"Guardian loot grants Echoharvest and its pattern once")
	for id in ["cache_west","cache_east"]:
		talk(id); check(chapter.act("cache") and not chapter.act("cache"),"Rare component cache claims once: "+id)
	talk("atlas"); check(chapter.act("atlas") and not chapter.relic.visible,"Atlas becomes protected evidence and leaves its pedestal")
	check(s.save_to("user://archive-ready.json"),"Pre-choice quest state saves")
	for faction in ["lantern","briar"]:
		if faction=="briar": s.load_from("user://archive-ready.json")
		talk(faction); p.position+=Vector3(0,0,10)
		check(not chapter.act("entrust"),"Recipient selection rechecks proximity")
		p.position=chapter.ORIGIN+chapter.NODES[faction]+Vector3(0,0.1,1.4)
		check(chapter.act("entrust") and s.archive.recipient==faction and "archive" in s.story_completed,"Either recipient advances the main story: "+faction)
		check(faction+"_relic" in s.blueprints and ("briar_relic" if faction=="lantern" else "lantern_relic") not in s.blueprints,"Only chosen faction's pattern unlocks")
		check(s.archive.reputation[faction]==25 and s.archive.reputation["briar" if faction=="lantern" else "lantern"]== -10,"Recipient choice changes both standings")
		check(not chapter.act("entrust"),"Atlas turn-in reward cannot duplicate")
		for material: Dictionary in s.crafting.materials: s.materials[material.id]=100
		check(s.craft_recipe("craft_"+("lantern_conductor" if faction=="lantern" else "briar_vestment"),"forge").begins_with("Created"),"Chosen relic pattern consumes rare components to forge gear")
		check(s.save_to("user://archive-done.json"),"Recipient, inventory and effects save together")
		var loaded:=State.new()
		check(loaded.load_from("user://archive-done.json") and loaded.archive==s.archive and loaded.items.echo_blade.effect=="stamina_on_kill","Completed choice and effect-bearing gear survive reload")
	chapter.close_dialog(); p.set_paused(false)
	world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_archive() and world.hud.world_map.place_action.disabled,"Forest map shows its own dossier")
	chapter.leave()
	check(not chapter.inside and p.position.x> -100 and s.archive.recipient=="briar","Return home preserves the story choice")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"),"Archive branch does not skip later worlds")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://archive-done.json")); data.archive.recipient="both"
	var f:=FileAccess.open("user://archive-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	var loaded:=State.new(); check(not loaded.load_from("user://archive-bad.json"),"Invalid recipient is rejected")
	data.erase("archive"); f=FileAccess.open("user://archive-old.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://archive-old.json") and loaded.archive.recipient=="","Older saves gain empty archive progress")
	for file in ["ready","done","bad","old"]: DirAccess.remove_absolute("user://archive-"+file+".json")
	world.queue_free(); await process_frame
	print("ARCHIVE_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
