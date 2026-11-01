extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS " + label)
	else: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(6): await physics_frame
	var w = world.wilderness; var p = world.player; var s = p.character
	p.set_physics_process(false)
	for e in w.enemies: e.set_physics_process(false)
	var supported := true
	for e in w.enemies: supported = world.session_save.supported_position(e.global_position, e) and supported
	check(supported, "All authored creature spawns have clear supported ground")
	check(w.enemies.size()==13 and w.inside and world.combat_enemies()==w.enemies, "Home combat roster contains thirteen wilderness creatures")
	check(w.enemies.filter(func(e): return e.species=="wolf").size()==6 and w.enemies.filter(func(e): return e.species=="boar").size()==5, "Wilderness includes wolf packs and tusked boars")
	var giant = w.enemies[11]
	check(giant.maximum_health==420 and giant.get_child(0).shape.height==4.5, "Colossus has giant collision and health")
	var wolf = w.enemies[0]
	p.position = wolf.home+Vector3(0,0,8); wolf.cooldown=0
	wolf._physics_process(.1)
	check(Vector2(wolf.velocity.x,wolf.velocity.z).length()>0, "Wolf pursues a player within its habitat")
	p.position=Vector3.ZERO; wolf.global_position=wolf.home+Vector3.RIGHT*2; wolf._physics_process(.1)
	check(wolf.windup==0 and wolf.velocity.x<0, "Distant or town player makes creature return home")
	wolf.parried(); wolf._physics_process(.1)
	check(wolf.velocity.x==0 and wolf.velocity.z==0, "Parry staggers creature without movement")
	world.adventure.enter(); wolf._physics_process(.1)
	check(not w.inside and not wolf.visible and wolf.collision_layer==0 and world.combat_enemies()!=w.enemies, "Dungeon entry disables wilderness visibility, collision and targeting")
	world.adventure.leave(); p.set_paused(false); wolf._physics_process(.1)
	check(wolf.visible and wolf.collision_layer==4, "Returning home reactivates living creatures")
	p.position=wolf.global_position+Vector3.BACK; p.invulnerable=0; p.blocking=false; wolf.stagger_time=0; wolf.windup=.01
	var health: float=p.health
	wolf._physics_process(.02)
	check(p.health<health, "Creature windup lands actual melee damage")
	wolf.receive_damage(1000,p,"","melee")
	check(wolf.dead and wolf.enemy_id in s.wilderness.defeated, "Creature uses normal damage and persistent defeat")
	var hide: int=s.materials.get("hide",0); var gold: int=s.gold
	check(w.loot() and s.materials.hide==hide+2 and s.gold==gold+8, "Harvest grants hide, meat and gold")
	check(not w.loot() and s.gold==gold+8, "Harvest is single claim")
	p.position=giant.global_position+Vector3.BACK*2; giant.receive_damage(10000,p,"","marksman")
	var ore: int=s.materials.get("iron_ore",0)
	check(w.loot() and s.materials.iron_ore==ore+8, "Giant awards forging materials")
	check(s.save_to("user://wilderness-test.json"), "Wilderness progress saves")
	var loaded=preload("res://scripts/character_state.gd").new()
	check(loaded.load_from("user://wilderness-test.json") and loaded.wilderness==s.wilderness, "Defeat and harvest survive reload")
	check(not s.valid_wilderness({"defeated":[],"looted":["wild_0"]}) and not s.valid_wilderness({"defeated":["fake"],"looted":[]}), "Invalid and unearned claims rejected")
	var snapshot = world.session_save.capture()
	check(snapshot.area=="home" and snapshot.enemies.size()==11, "Session snapshot includes surviving wilderness creatures")
	p.set_paused(true); check(not w.loot(), "Menus block harvesting")
	DirAccess.remove_absolute("user://wilderness-test.json")
	world.queue_free(); await process_frame
	print("WILDERNESS_COMPLETE checks=%d failures=%d" % [checks,failures]); quit(1 if failures else 0)
