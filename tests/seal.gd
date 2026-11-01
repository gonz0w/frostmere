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
	var f:=FileAccess.open("user://seal-bad.json",FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
func run() -> void:
	world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames()
	c=world.seal; p=world.player; s=p.character
	check(not c.enter(),"Underworks requires Winter Siege completion")
	p.position=c.TRAIL+Vector3(0,.1,1.4); check(world.nearest_interaction().get("kind")=="seal","Service lift is interactable from Frostmere")
	world.interact_nearby(); check(not c.inside,"Physical lift respects story gate")
	s.story_completed.append_array(["returning_light","winter_siege"]); world.interact_nearby()
	check(c.inside and not s.persist,"Service lift enters isolated test underworks")
	for enemy in c.enemies: enemy.set_physics_process(false)
	await frames(15); check(p.is_on_floor(),"Arrival has a physical floor")
	check(await walk(Vector3(0,.2,13),Vector3(0,.2,7)),"Entry arch has a clear walking route")
	check(await walk(Vector3(0,.2,-24),Vector3(0,.2,-30)),"Inner arch has a clear walking route")
	check(world.combat_enemies().is_empty(),"Defenders stay inactive until investigation begins")
	check(not c.enemies[4].visible and c.enemies[4].collision_layer==0,"Sealbreaker is hidden and noncolliding before ledger")
	c.enemies[4].receive_damage(10000,p); check(not c.enemies[4].dead,"Dormant boss cannot be killed early")
	talk("intake"); check(not c.act("valve"),"Valve cannot be used before defeating its guard")
	talk("keeper"); check(c.act("accept") and not c.act("accept"),"Investigation accepts once")
	check(world.combat_enemies().size()==2,"Acceptance activates only outer enforcers")
	talk("supplies"); var steel: int=s.materials.get("steel_ingot",0)
	check(c.act("supplies") and not c.act("supplies") and s.materials.steel_ingot==steel+8,"Supplies grant once")
	check(not s.craft_recipe("craft_cinder_ward","forge").begins_with("Created"),"Ward requires recovered design")
	c.close_dialog(); p.set_paused(false); c.enemies[0].receive_damage(10000,p)
	talk("exhaust"); check(not c.act("valve"),"Each valve requires its assigned enforcer")
	talk("intake"); check(c.act("valve") and not c.act("valve"),"Intake isolates once")
	check(world.combat_enemies().size()==2,"One isolated line does not activate inner defenders")
	c.close_dialog(); p.set_paused(false); c.enemies[1].receive_damage(10000,p)
	talk("exhaust"); check(c.act("valve") and s.seal.valves.size()==2,"Both lines isolate through interactions")
	check(world.combat_enemies().size()==4 and not c.enemies[4].visible,"Inner enforcers activate while boss stays dormant")
	talk("plans"); check(not c.act("plans"),"Ledger requires clearing inner enforcers")
	c.close_dialog(); p.set_paused(false)
	for i in [2,3]: c.enemies[i].receive_damage(10000,p)
	check(c.loot("seal_2") and not c.loot("seal_2"),"Furnace salvage claims once")
	talk("plans"); check(c.act("plans") and not c.act("plans") and "cinder_ward" in s.blueprints,"Ledger teaches actual ward recipe once")
	check(c.enemies[4].visible and world.combat_enemies().size()==5,"Ledger activates the Sealbreaker")
	check(s.save_to("user://seal-mid.json"),"Investigation progress saves")
	var loaded:=State.new(); check(loaded.load_from("user://seal-mid.json") and loaded.seal==s.seal,"Valve and ledger progress round-trips")
	talk("seal"); check(not c.act("bind"),"Living Sealbreaker prevents binding")
	c.close_dialog(); p.set_paused(false); c.enemies[4].receive_damage(10000,p)
	talk("seal"); check(not c.act("bind"),"Defeating the boss does not substitute for crafting the ward")
	s.materials.steel_ingot=4; s.materials.crystal=4; s.materials.rune_dust=2; s.materials.ash_glass=1
	check(not s.craft_recipe("craft_cinder_ward","forge").begins_with("Created") and s.materials.steel_ingot==4,"Insufficient ward ingredients spend nothing")
	s.materials.ash_glass=2
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES.forge+Vector3(0,.1,1.4); world.interact_nearby()
	var workshop=world.hud.workshop; workshop.search.text="Cinder Ward"; workshop.refresh()
	check(p.workshop_open and workshop.ids==["craft_cinder_ward"],"Actual forge filters to the learned Cinder Ward")
	workshop.actions.get_child(0).pressed.emit()
	check(s.materials.get("cinder_ward",0)==1 and s.materials.steel_ingot==0 and s.materials.crystal==0 and s.materials.rune_dust==0 and s.materials.ash_glass==0,"Forge button spends exact ingredients and creates a real ward")
	workshop.close(); talk("seal")
	check(c.act("bind") and not c.act("bind") and s.materials.cinder_ward==0,"Binding consumes exactly one ward once")
	check(not world.realms.can_enter("crucible"),"Binding alone still requires reporting to Tovan")
	talk("keeper"); var gold: int=s.gold
	check(c.act("reward") and not c.act("reward") and s.gold==gold+220,"Containment report rewards once")
	check("broken_seal" in s.story_completed and world.realms.can_enter("crucible"),"Report unlocks normal Crucible access")
	check("wardkeeper" in s.blueprints and c.lights.crossing.visible,"Report grants amulet pattern and illuminates crossing")
	var found:=false
	for uid: String in s.inventory:
		if s.inventory[uid].base_id=="wardkeeper_amulet": found=true; check(s.inventory[uid].favorite,"Wardkeeper reward is protected as a favorite")
	check(found,"Wardkeeper amulet is actually owned")
	for material in ["steel_ingot","crystal","rune_dust","ash_glass"]: s.materials[material]=30
	check(s.craft_recipe("craft_wardkeeper_amulet","forge").begins_with("Created"),"Wardkeeper pattern can be forged")
	var temper_uid: String=s.add_item("wardkeeper_amulet",3)
	check(s.temper_cost(temper_uid)=={"steel_ingot":4,"crystal":4,"ash_glass":1} and s.improve(temper_uid,"forge").begins_with("Improved"),"Amulet supports high-rank tempering")
	check(s.save_to("user://seal-done.json") and loaded.load_from("user://seal-done.json") and loaded.seal==s.seal,"Completed chapter round-trips")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://seal-done.json"))
	for issue in ["requirement","valve","guard","plans","bound","reward","duplicate","loot","type"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"requirement": bad.story_completed.erase("winter_siege")
			"valve": bad.seal.valves=["intake"]
			"guard": bad.seal.defeated.erase("seal_0")
			"plans": bad.seal.plans=false
			"bound": bad.seal.bound=false
			"reward": bad.story_completed.erase("broken_seal")
			"duplicate": bad.seal.defeated.append("seal_0")
			"loot": bad.seal.looted.append("unknown")
			"type": bad.seal.bound="yes"
		fixture(bad); check(not loaded.load_from("user://seal-bad.json") and loaded.seal==s.seal,"Invalid save rejected atomically: "+issue)
	data.erase("seal"); fixture(data); check(loaded.load_from("user://seal-bad.json") and not loaded.seal.accepted,"Older saves gain fresh underworks progress")
	c.close_dialog(); p.set_paused(false); p.position=c.ORIGIN+c.NODES.crossing+Vector3(0,.1,1.4); world.interact_nearby()
	check(world.realms.inside and world.realms.current=="crucible" and not world.realms.preview and not c.inside,"Northern crossing enters Crucible in normal progression")
	check(world.realms.attune("crucible"),"Normal descent grants infernal equipment and magic")
	for enemy in world.realms.enemies:
		if enemy.enemy_id.begins_with("crucible"):
			enemy.set_physics_process(false); enemy.receive_damage(10000,p); world.realms.loot(enemy.enemy_id)
	p.position=world.realms.vector(world.realms.definitions.crucible.origin)+world.realms.ending.CONTROL+Vector3(0,.1,1.4); world.realms.interact("shutdown")
	p.position=world.realms.vector(world.realms.definitions.crucible.origin)+Vector3(0,.1,19); world.realms.interact("leave")
	check(not world.realms.inside and "last_furnace" in s.story_completed,"Defeat, loot and return finish the Crucible in normal progression")
	check(s.save_to("user://seal-chain.json") and loaded.load_from("user://seal-chain.json") and "last_furnace" in loaded.story_completed,"End-to-end descent and return round-trip")
	world.realms.ending.close_dialog(); p.set_paused(false)
	check(c.enter(),"Underworks remains revisitable after the descent")
	p.map_open=true; p.set_paused(true); world.hud.world_map.set_view(true)
	check(world.hud.world_map.canvas.in_seal(),"Local map selects underworks")
	p.map_open=false; p.set_paused(false); p.health=1; p.invulnerable=0; p.blocking=false; p.receive_damage(10000,p.position+Vector3.FORWARD)
	check(not c.inside and p.position.x<100 and p.health==p.derived.health,"Combat death returns safely home")
	for name in ["mid","done","bad","chain"]: DirAccess.remove_absolute("user://seal-"+name+".json")
	world.queue_free(); await process_frame
	print("SEAL_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
