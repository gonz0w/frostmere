extends SceneTree
## Connected progression plus an explicitly idealized resource model, never a profile playthrough.
const State=preload("res://scripts/character_state.gd")
var world: Node3D
var p: CharacterBody3D
var s: RefCounted
var build_id: String
var chapter: String
var rows: Array=[]
var checks:=0
var failures:=0
var hits:=0
var attempts:=0
var elapsed:=0.0
var waiting:=0.0
var potions:=0
var crafted:=0
var supply_gold:=0
var ammo_start:=0
var weapon_start: String
func _initialize() -> void: call_deferred("run")
func require(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		push_error("CAMPAIGN_ROUTE_FAIL %s / %s: %s" % [build_id,chapter,label])
		failures+=1
func close(c: Node) -> void:
	c.close_dialog(); p.set_paused(false)
func action(c: Node,id: String,verb: String) -> void:
	if failures: return
	close(c); p.position=c.ORIGIN+c.NODES[id]+Vector3(0,.1,1.4)
	c.interact(id)
	require(c.act(verb),id+" -> "+verb)
	close(c)
func begin(id: String) -> void:
	chapter=id; hits=0; attempts=0; elapsed=0; waiting=0; potions=0; crafted=0; supply_gold=0
	ammo_start=s.materials.get("arrow",0)
	weapon_start=s.item_at("main_hand").name
	print("CAMPAIGN_CHAPTER "+build_id+" "+id)
func checkpoint(flag: String="") -> void:
	if failures: return
	if flag!="": require(flag in s.story_completed,"earned completion "+flag)
	rows.append({"build":build_id,"chapter":chapter,"weapon":weapon_start,"hits":hits,"attempts":attempts,"attack_seconds":snappedf(elapsed,.1),"regen_wait_seconds":snappedf(waiting,.1),"magicka_draughts":potions,"arrows_start":ammo_start,"arrows_end":s.materials.get("arrow",0),"fletching_batches":crafted,"supply_gold":supply_gold,"gold":s.gold,"materials":s.materials.duplicate(true),"consumables":s.consumables.duplicate(true),"equipment":s.equipment.duplicate(true),"story_completed":s.story_completed.duplicate()})
	require(s.save_to("user://campaign-route-audit.json"),"write isolated checkpoint")
	var loaded=State.new()
	require(loaded.load_from("user://campaign-route-audit.json"),"checkpoint accepted by real save validator")
	require(loaded.story_completed==s.story_completed and loaded.equipment==s.equipment,"completion and equipment round trip")
	require(JSON.parse_string(JSON.stringify(loaded.materials))==JSON.parse_string(JSON.stringify(s.materials)) and JSON.parse_string(JSON.stringify(loaded.consumables))==JSON.parse_string(JSON.stringify(s.consumables)),"supply checkpoint round trip")
	choose_weapon()
func choose_weapon() -> void:
	var best: String=s.equipment.main_hand
	var score: float=-1
	for uid: String in s.inventory:
		var item: Dictionary=s.describe_item(uid)
		var family: String=item.get("family","")
		if build_id=="ranger" and family!="bow": continue
		if build_id=="mage" and family!="staff": continue
		if build_id=="warrior" and family not in ["sword","axe","mace","dagger","greatsword","battleaxe"]: continue
		var value: float=item.get("damage",0)
		if value>score: best=uid; score=value
	s.equip(best,"main_hand")
func advance(seconds: float) -> void:
	p.magicka=minf(p.derived.magicka,p.magicka+p.derived.magicka_regen*seconds)
	p.stamina=minf(p.derived.stamina,p.stamina+p.derived.stamina_regen*seconds)
	elapsed+=seconds
func resupply_arrows() -> void:
	var trade=preload("res://scripts/trade.gd").new(s)
	for material in ["wood","iron_ingot"]:
		if s.materials.get(material,0)>0: continue
		for shop in s.shop_data.shops:
			var sku: String="material:"+material
			if trade.merchant(shop.id).stock.get(sku,0)<1: continue
			var before: int=s.gold
			if trade.buy(shop.id,sku,1).begins_with("Bought"):
				supply_gold+=before-s.gold; break
	require(s.craft_recipe("craft_arrows","forge").begins_with("Created"),"afford fletching using finite shop stock")
func fight(c: Node,indices: Array=[]) -> void:
	if failures: return
	p.set_paused(false)
	var targets: Array=indices
	if targets.is_empty(): targets=range(c.enemies.size())
	for i in targets:
		var enemy: CharacterBody3D=c.enemies[i]
		if c==world.realms and not enemy.enemy_id.begins_with(c.current): continue
		if enemy.dead: continue
		enemy.set_physics_process(false)
		var count:=0
		while not enemy.dead:
			count+=1
			if count>=1000:
				require(false,"bounded encounter "+enemy.enemy_id); return
			var damage: float=p.derived.damage
			var interval: float=p.melee_interval()
			var skill: String="melee"
			if build_id=="ranger":
				if s.materials.get("arrow",0)==0:
					# Model a return to a forge; travel duration is deliberately unmeasured.
					resupply_arrows()
					if s.materials.get("arrow",0)==0: return
					crafted+=1
				s.materials.arrow-=1; interval=.85; skill="marksman"
			elif build_id=="mage":
				# Fixed starter spell isolates staff/training progression, without assuming fan hits.
				var spell: Dictionary=s.spell_definition("emberbolt")
				var cost: float=s.spell_cost(spell.cost)
				if p.magicka<cost and s.consumables.get("magicka_draught",0)>0:
					require(s.consume("magicka_draught",p).begins_with("Used"),"use owned magicka draught"); potions+=1
				if p.magicka<cost:
					var delay: float=(cost-p.magicka)/p.derived.magicka_regen+.00001
					waiting+=delay; advance(delay)
				p.magicka-=cost; damage=p.derived.spell_power*spell.scale; interval=spell.cooldown; skill="magic"
			else:
				var cost: float=p.melee_stamina_cost()
				if p.stamina<cost:
					var delay: float=(cost-p.stamina)/p.derived.stamina_regen+.00001
					waiting+=delay; advance(delay)
				p.stamina-=cost
			attempts+=1
			# Deterministic 75% ranged accuracy; melee has no modeled positioning misses.
			if build_id=="warrior" or attempts%4!=0:
				var before: float=enemy.health
				enemy.receive_damage(damage,p,s.item_at("main_hand").get("effect","") if build_id=="warrior" else "",skill)
				require(enemy.health<before,"damage accepted "+enemy.enemy_id); hits+=1
			advance(interval)
		if c==world.adventure: require(c.loot_enemy(enemy.enemy_id),"loot "+enemy.enemy_id)
		else: require(c.loot(enemy.enemy_id),"loot "+enemy.enemy_id)
func enter(c: Node) -> void:
	if failures: return
	require(c.enter(),"normal chapter entry")
	for e in c.enemies: e.set_physics_process(false)
func route() -> void:
	var c: Node=world.adventure
	begin("Oldwatch"); require(c.accept_quest(),"accept Oldwatch"); c.enter(); fight(c)
	for id in c.chests: require(c.loot_chest(id),"loot chest "+id)
	c.leave(); require(c.reward_quest(),"Oldwatch return"); checkpoint()
	c=world.stonewake; begin("Stonewake")
	p.position=c.KEEPER+Vector3(0,.1,1.4); c.interact("keeper"); require(c.accept(),"accept Stonewake"); close(c)
	for ward in c.WARDS:
		p.position=ward.position+Vector3(0,.1,1.4); c.interact(ward.id); require(c.choose_rune(ward.answer),"restore ward"); close(c)
	p.position=c.RELIC+Vector3(0,.1,1.4); c.interact("relic"); close(c)
	p.position=c.KEEPER+Vector3(0,.1,1.4); c.interact("keeper"); require(c.reward(),"report watchstone"); close(c); checkpoint("stonewake")
	c=world.mountain; begin("Wyrmkeep council"); enter(c)
	action(c,"council","accept")
	for id in ["stoneguard","stormweaver"]: action(c,id,"hear")
	fight(c); action(c,"ledger","ledger"); action(c,"council","settle:accord"); c.leave(); checkpoint("council")
	c=world.archive_chapter; begin("Pinehall archive"); enter(c)
	action(c,"lantern","accept"); action(c,"lantern","hear"); action(c,"briar","hear"); fight(c)
	for id in ["cache_west","cache_east"]: action(c,id,"cache")
	action(c,"atlas","atlas"); action(c,"lantern","entrust"); c.leave(); checkpoint("archive")
	c=world.roots; begin("Woodland roots"); enter(c)
	action(c,"keeper","accept"); action(c,"keeper","hear"); action(c,"steward","hear")
	for id in ["camp_cache","grove_cache"]: action(c,id,"cache")
	fight(c,[0,1,2])
	for id in ["spring","stone","seed"]: action(c,id,"cleanse")
	fight(c,[3]); action(c,"heart","wild"); action(c,"record","record"); action(c,"keeper","reward"); c.leave(); checkpoint("roots")
	c=world.shore; begin("Saltbreak wreck"); enter(c)
	action(c,"harbor","accept"); action(c,"harbor","hear"); action(c,"salvager","hear")
	action(c,"pump","solve"); action(c,"relay","solve"); fight(c)
	for id in ["coast_cache","cave_cache"]: action(c,id,"cache")
	action(c,"log","log"); action(c,"core","core"); action(c,"navigation","choose_navigation"); action(c,"harbor","reward"); c.leave(); checkpoint("tides")
	c=world.lens; begin("Sunken Lens"); enter(c); action(c,"keeper","accept")
	for id in ["west_cache","east_cache"]: action(c,id,"cache")
	for id in c.SOLUTIONS:
		while not failures and s.lens.rotations[id]!=c.SOLUTIONS[id]: action(c,id,"rotate")
	action(c,"lens","activate"); fight(c); action(c,"chart","chart"); action(c,"keeper","reward"); c.leave(); checkpoint("lens")
	c=world.choir; begin("Ember Choir"); enter(c); action(c,"keeper","accept")
	for id in ["camp_cache","vault_cache"]: action(c,id,"cache")
	for id in c.SONG: action(c,id,"ring")
	action(c,"receiver","activate"); fight(c); action(c,"record","record"); action(c,"keeper","reward"); c.leave(); checkpoint("choir")
	c=world.convergence; begin("Mirewatch expedition"); enter(c); action(c,"keeper","accept")
	for id in c.REQUIRED: action(c,id,"evidence")
	action(c,"supplies","supplies"); require(s.craft_recipe("forge_transit_regulator","forge").begins_with("Created"),"forge regulator from earned supplies")
	action(c,"rig","install"); fight(c); action(c,"beacon","calibrate"); action(c,"keeper","reward"); c.leave(); checkpoint("convergence")
	c=world.threshold; begin("Space station"); enter(c); action(c,"keeper","accept"); action(c,"locker","locker")
	fight(c,[0,1,2]); action(c,"cargo","cargo"); action(c,"power","power"); action(c,"air","air"); fight(c,[3,4,5])
	action(c,"record","record"); p.position=c.ORIGIN+c.NODES["return"]+Vector3(0,.1,-1); c.interact("return"); checkpoint("threshold")
	realm("aeralis","returning_light")
	c=world.winter; begin("Winter Siege"); enter(c); action(c,"keeper","accept"); action(c,"supplies","supplies")
	fight(c,[0,1,2]); action(c,"ward","repair"); action(c,"ballista","repair"); action(c,"keeper","assault"); fight(c,[3,4,5])
	action(c,"orders","orders"); action(c,"keeper","reward"); c.leave(); checkpoint("winter_siege")
	c=world.seal; begin("Broken Seal"); enter(c); action(c,"keeper","accept"); action(c,"supplies","supplies")
	fight(c,[0,1]); action(c,"intake","valve"); action(c,"exhaust","valve"); fight(c,[2,3]); action(c,"plans","plans")
	require(s.craft_recipe("craft_cinder_ward","forge").begins_with("Created"),"forge ward from earned supplies")
	fight(c,[4]); action(c,"seal","bind"); action(c,"keeper","reward"); c.leave(); checkpoint("broken_seal")
	realm("crucible","last_furnace")
	begin("Homecoming")
	var ending: Node=world.realms.ending
	p.position=ending.HOME+Vector3(0,.1,1)
	require(ending.open_chronicle(),"open earned homecoming")
	require(ending.claim({"warrior":"blade","ranger":"bow","mage":"staff"}[build_id]),"claim chosen heirloom")
	ending.close_dialog(); p.set_paused(false); checkpoint("last_furnace")
func realm(id: String,flag: String) -> void:
	begin(id); var c: Node=world.realms
	require(c.enter(id,false),"normal realm gate "+id)
	require(c.attune(id),"claim arrival kit"); choose_weapon(); weapon_start=s.item_at("main_hand").name; fight(c)
	if id=="crucible":
		p.position=c.vector(c.definitions[id].origin)+c.ending.CONTROL+Vector3(0,.1,1.4)
		require(c.ending.shutdown(),"stop invasion engine")
	p.position=c.vector(c.definitions[id].origin)+Vector3(0,.1,19)
	require(c.finish_chapter(),"return with guardian relic"); c.leave(); checkpoint(flag)
func run() -> void:
	if DisplayServer.get_name()!="headless":
		push_error("Campaign audit requires --headless"); quit(1); return
	for archetype in ["warrior","ranger","mage"]:
		build_id=archetype
		world=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await process_frame
		p=world.player; s=p.character
		if s.persist or world.atlas.persist:
			push_error("Campaign audit refuses persistent profiles"); quit(1); return
		var input_count: int=InputMap.action_get_events("attack").size()
		world._inputs()
		require(InputMap.action_get_events("attack").size()==input_count,"reinitializing controls preserves bindings without duplicates")
		p.set_physics_process(false); p.set_process_unhandled_input(false)
		# Replace only the new-character starting kit; campaign flags, resources and rewards remain untouched.
		s.inventory.clear(); s.next_id=1
		for slot in s.equipment: s.equipment[slot]=""
		s.set_identity("Campaign audit","frostkin",archetype,"balanced")
		for slot in s.archetypes[archetype].loadout:
			var base: String=s.archetypes[archetype].loadout[slot]
			if base!="": s.equip(s.add_item(base),slot)
		p.health=p.derived.health; p.magicka=p.derived.magicka; p.stamina=p.derived.stamina
		route()
		if failures:
			world.queue_free(); await process_frame; quit(1); return
		world.queue_free(); await process_frame
	DirAccess.remove_absolute("user://campaign-route-audit.json")
	var f=FileAccess.open("res://build/campaign-route-audit.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"schema":1,"generated_utc":Time.get_datetime_string_from_system(true),"checks":checks,"rows":rows},"\t")); f.close()
	print("CAMPAIGN_ROUTE_COMPLETE builds=3 checkpoints=%d checks=%d" % [rows.size(),checks]); quit()
