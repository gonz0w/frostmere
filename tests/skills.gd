extends SceneTree
const State=preload("res://scripts/character_state.gd")
var checks:=0
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS "+label)
	else: failures+=1; push_error("FAIL "+label)
func frames(n: int=4) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	var s:=State.new()
	check(s.skill_level("melee")==1 and s.perk_points()==0,"Fresh characters start without free perks")
	check(not s.learn_perk("heavy_hand") and not s.learn_perk("fake"),"Locked and unknown perks cannot be learned")
	s.train("melee",99); check(s.skill_level("melee")==1,"Partial XP does not level early")
	check(s.train("melee",1) and s.skill_level("melee")==2 and s.perk_points()==1,"100 XP earns a level and one point")
	var damage: int=s.stats().damage
	check(s.learn_perk("heavy_hand") and s.perk_points()==0 and not s.learn_perk("heavy_hand"),"Perk consumes points once")
	check(s.stats().damage==roundi(damage*1.1),"Heavy Hand increases melee damage")
	s.train("melee",5000); check(s.skill_level("melee")==10 and s.skills.xp.melee==900,"Skill XP caps at level ten")
	check(not s.train("fake",10) and not s.train("magic",-1),"Invalid training is ignored")
	for skill in ["marksman","magic","crafting"]: s.train(skill,400)
	for id: String in s.Skills.PERKS:
		if id!="heavy_hand": check(s.learn_perk(id),"Eligible perk can be learned: "+id)
	check(s.Skills.valid(s.skills) and s.spell_cost(20)==16,"Learned build validates and reduces spell cost")
	s.equip(s.add_item("steel_bow"),"main_hand"); var ranged: int=s.stats().damage
	var comparison:=State.new(); comparison.equip(comparison.add_item("steel_bow"),"main_hand")
	check(ranged==roundi(comparison.stats().damage*1.1),"Steady Aim increases bow damage")
	check(s.stats().spell_power==roundi(comparison.stats().spell_power*1.1),"Kindled Mind increases spell power")
	for material: Dictionary in s.crafting.materials: s.materials[material.id]=100
	var recipe: Dictionary=s.crafting.recipes.filter(func(x): return x.output_kind=="gear")[0]
	s.blueprints.append(recipe.unlock)
	check(s.craft_recipe(recipe.id,recipe.station).begins_with("Created"),"Crafting succeeds with Artisan")
	var uid: String="gear_"+str(s.next_id-1)
	# Locate the actual newly created item using its base and quality.
	var fine:=false
	for owned: Dictionary in s.inventory.values():
		if owned.base_id==recipe.output and owned.quality==1: fine=true
	check(fine,"Artisan creates Fine equipment")
	uid=s.add_item("steel_sword",3)
	var discounted: Dictionary=s.temper_cost(uid)
	var base_uid: String=comparison.add_item("steel_sword",3); var full: Dictionary=comparison.temper_cost(base_uid)
	var exact:=true
	for key: String in full: exact=exact and discounted[key]==maxi(1,full[key]-1)
	check(exact,"Careful Tempering discounts the displayed material costs")
	check(s.save_to("user://skills-test.json"),"Skills save with the character")
	var loaded:=State.new(); check(loaded.load_from("user://skills-test.json") and loaded.skills==s.skills,"Skills and learned perks round-trip")
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://skills-test.json"))
	for issue in ["xp","fraction","perk","duplicate","level","points"]:
		var bad: Dictionary=data.duplicate(true)
		match issue:
			"xp": bad.skills.xp.melee=901
			"fraction": bad.skills.xp.magic=2.5
			"perk": bad.skills.perks.append("fake")
			"duplicate": bad.skills.perks.append("heavy_hand")
			"level": bad.skills.xp.magic=0
			"points": bad.skills.xp={"melee":100,"marksman":100,"magic":100,"crafting":100}; bad.skills.perks=["heavy_hand","steady_aim","kindled_mind","artisan","measured_swing"]
		var file:=FileAccess.open("user://skills-invalid.json",FileAccess.WRITE); file.store_string(JSON.stringify(bad)); file.close()
		check(not loaded.load_from("user://skills-invalid.json") and loaded.skills==s.skills,"Invalid skill build rejected atomically: "+issue)
	data.erase("skills"); data.craft_xp=230
	var file:=FileAccess.open("user://skills-invalid.json",FileAccess.WRITE); file.store_string(JSON.stringify(data)); file.close()
	check(loaded.load_from("user://skills-invalid.json") and loaded.skill_level("crafting")==3 and loaded.skills.perks.is_empty(),"Legacy crafting XP converts without selecting perks")
	var world: Node3D=load("res://scenes/main.tscn").instantiate(); root.add_child(world); await frames(5)
	var p: CharacterBody3D=world.player; var a: Node3D=world.adventure; var live: RefCounted=p.character
	a.enter()
	for enemy in a.enemies: enemy.set_physics_process(false)
	var guard: CharacterBody3D=a.enemies[0]
	p.position=Vector3(0,-29.95,2); p.rotation=Vector3.ZERO; guard.position=Vector3(0,.05,0); await frames()
	check(p.attack() and live.skills.xp.melee>0,"Actual melee hits train Melee")
	var xp: int=live.skills.xp.melee
	p.attack_cooldown=0; p.rotation.y=PI; p.attack()
	check(live.skills.xp.melee==xp,"Missed swings do not train")
	var before: int=live.skills.xp.magic
	a.fire(guard.global_position+Vector3(0,1,2),Vector3.FORWARD,5,false,p,true)
	await frames(12)
	check(live.skills.xp.magic>before,"Actual spell projectile hit trains Magic")
	before=live.skills.xp.marksman
	a.fire(guard.global_position+Vector3(0,1,2),Vector3.FORWARD,5,false,p,false)
	await frames(12)
	check(live.skills.xp.marksman>before,"Actual ranged projectile hit trains Marksmanship")
	guard.receive_damage(10000,p,"","melee"); xp=live.skills.xp.melee
	guard.receive_damage(10000,p,"","melee"); check(live.skills.xp.melee==xp,"Corpses cannot be trained against")
	for skill in ["melee","marksman","magic","crafting"]: live.train(skill,400)
	for id in ["measured_swing","quick_release","clear_channel"]: live.learn_perk(id)
	p.attack_cooldown=0; p.stamina=30; p.attack()
	check(p.stamina==24,"Measured Swing changes real stamina consumption")
	live.equip(live.add_item("steel_bow"),"main_hand"); live.materials.arrow=10; p.attack_cooldown=0; p.attack()
	check(is_equal_approx(p.attack_cooldown,.85*.85),"Quick Release changes real bow cooldown")
	p.magicka=100; p.spell_cooldown=0; p.cast_spell("emberbolt")
	check(is_equal_approx(p.magicka,100-live.spell_cost(18)),"Clear Channel changes real spell consumption")
	var key:=InputEventKey.new(); key.pressed=true; key.physical_keycode=KEY_K; p._unhandled_input(key)
	check(world.skills_menu.visible and p.paused and p.dialog_open,"K opens the live skills screen")
	world.skills_menu.selected="crafting"; world.skills_menu.refresh()
	world.skills_menu.rows.get_child(2).pressed.emit()
	check(live.has_perk("artisan"),"Actual skills button purchases a perk")
	key.physical_keycode=KEY_I; p._unhandled_input(key)
	check(not world.skills_menu.visible and p.workshop_open,"Inventory cleanly replaces skills screen")
	world.hud.workshop.close(); key.physical_keycode=KEY_K; p._unhandled_input(key); key.physical_keycode=KEY_ESCAPE; p._unhandled_input(key)
	check(not world.skills_menu.visible and not p.paused,"Escape resumes exploration")
	for path in ["user://skills-test.json","user://skills-invalid.json"]: DirAccess.remove_absolute(path)
	world.queue_free(); await process_frame
	print("SKILLS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
