extends SceneTree
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func run() -> void:
	var world=load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var p=world.player; var e=world.wilderness.enemies[12]; var h=world.hunts; var s=p.character
	p.set_physics_process(false); p.set_process(false)
	for actor in world.wilderness.enemies: actor.set_physics_process(false)
	check(e.maximum_health==540 and is_equal_approx(e.rig.scale.x,2.4) and world.session_save.supported_position(e.position,e),"Giant quadruped has supported spawn and boss health")
	p.position=e.home+Vector3.BACK*7; e.charge_cooldown=0; e._physics_process(.02)
	check(e.charge_warning>0 and e.charge_remaining==0,"Charge telegraphs before moving")
	e._physics_process(.5)
	check(e.charge_head.rotation.x<0 and e.rig.position.y<0,"Charge preparation lowers head and braces body")
	var direction: Vector3=e.charge_direction; var hp: float=p.health
	p.position+=Vector3.RIGHT*5; e._physics_process(1.31)
	check(e.charge_direction==direction and p.health==hp,"Sidestep does not redirect committed charge")
	e._physics_process(1.0/60.0)
	check(e.charge_head.rotation.x<0 and absf(e.legs[0].rotation.x)>0,"Running charge keeps head down and animates stride")
	for i in range(70): e._physics_process(1.0/60.0)
	check(p.health==hp and e.charge_remaining==0 and e.stagger_time>0,"Dodged charge misses and exposes recovery window")
	e.position=e.home; e.stagger_time=0; e.charge_cooldown=0; p.position=e.home+Vector3.BACK*5; p.invulnerable=0; p.blocking=false
	e._physics_process(.02); e._physics_process(1.31)
	for i in range(30): e._physics_process(1.0/60.0)
	check(p.health<hp and e.charge_hit,"Charge lands real damage")
	hp=p.health; p.invulnerable=0
	for i in range(10): e._physics_process(1.0/60.0)
	check(p.health==hp,"Single charge cannot damage repeatedly")
	p.set_paused(true); e._physics_process(.02)
	check(e.charge_remaining==0 and e.charge_warning==0,"Menu safely cancels charge")
	check(e.charge_head.rotation.x==0 and e.rig.position.y==0,"Canceled charge restores head and body pose")
	p.set_paused(false); e.charge_warning=1; e.execution_locked=true; e._physics_process(.02)
	check(e.charge_warning==0,"Finisher lock cancels charge"); e.execution_locked=false
	check(not h.accept_frost() and not h.claim_frost(),"Remote hunt operations rejected")
	p.position=h.POSITION; h.selected="frostmaw"; h.open(); h.actions.get_child(0).pressed.emit()
	check(s.frost_hunt.accepted and not h.claim_frost(),"Board accepts hunt and blocks unearned reward"); h.close()
	p.position=e.position+Vector3.BACK; e.charge_warning=1; e.receive_damage(10000,p,"","melee")
	check(e.dead and e.charge_warning==0 and world.wilderness.loot(),"Monster death cancels attack and provides real harvest proof")
	check(not h.claim_frost(),"Harvest must be returned to board")
	p.position=h.POSITION; h.open(); var gold: int=s.gold; h.actions.get_child(0).pressed.emit()
	check(s.frost_hunt.rewarded and s.gold==gold+180 and "frostmaw" in s.blueprints and not h.claim_frost(),"Board grants unique reward and both patterns once")
	var uid: String=""
	for id in s.inventory:
		if s.inventory[id].base_id=="rimefang_maul": uid=id
	check(uid!="" and s.inventory[uid].quality==1 and s.inventory[uid].favorite,"Maul reward is Fine and favorited")
	for m in s.crafting.materials: s.materials[m.id]=100
	check(s.craft_recipe("craft_frostmaw_chest","forge").begins_with("Created") and s.improve(uid,"forge").begins_with("Improved"),"Hunt armor can be forged and maul tempered")
	check(s.save_to("user://frost-beast-test.json"),"Hunt and creature progress save")
	var loaded=preload("res://scripts/character_state.gd").new()
	check(loaded.load_from("user://frost-beast-test.json") and loaded.frost_hunt==s.frost_hunt and "wild_12" in loaded.wilderness.looted,"Reward and proof survive reload")
	check(not s.valid_frost_hunt({"frost_hunt":{"accepted":true,"rewarded":true},"wilderness":{"defeated":[],"looted":[]}}),"Forged reward without proof rejected")
	check(s.valid_frost_hunt({}),"Older profiles default to unaccepted hunt")
	DirAccess.remove_absolute("user://frost-beast-test.json")
	world.queue_free(); await process_frame
	print("FROST_BEAST_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
