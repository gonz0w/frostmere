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
	for i in range(4): await physics_frame
	var p = world.player; var a = world.adventure
	a.enter(); p.set_physics_process(false); p.set_process(false); p.set_paused(false)
	for e in a.enemies: e.set_physics_process(false)
	p.position = Vector3(0, -29.95, 2); p.rotation = Vector3.ZERO
	var enemy = a.enemies[0]
	enemy.global_position = p.global_position + Vector3.FORWARD * 1.5
	check(not p.activate_finisher(), "Healthy enemies cannot be executed")
	enemy.health = enemy.maximum_health * 0.2
	check(p.nearby_finisher() == enemy, "Twenty percent health exposes nearby target")
	p.rotation.y = PI; check(p.nearby_finisher() == null, "Target behind player is ineligible"); p.rotation.y = 0
	enemy.global_position += Vector3.FORWARD * 5
	check(not p.activate_finisher(), "Distant target is ineligible")
	enemy.global_position = p.global_position + Vector3.FORWARD * 1.5
	p.character.equip(p.character.add_item("iron_bow"), "main_hand")
	check(not p.activate_finisher(), "Finisher requires melee weapon")
	p.character.equip(p.character.add_item("iron_sword"), "main_hand")
	p.set_paused(true); check(not p.activate_finisher(), "Menu blocks finisher"); p.set_paused(false)
	var hp: float = enemy.health
	check(p.activate_finisher() and enemy.execution_locked and enemy.health == hp, "Activation locks target without premature damage")
	check(not p.activate_finisher() and not p.attack() and not p.cast_spell(), "Execution cannot stack with other attacks")
	p.power = 100; check(not p.activate_power(), "Whirlwind cannot interrupt execution")
	p.update_finisher(0.2); check(enemy.health == hp, "Windup does not kill early")
	p.set_paused(true)
	check(not enemy.execution_locked and enemy.health == hp and p.finisher_remaining == 0, "Menu cancellation releases living target safely")
	p.set_paused(false); p.activate_finisher(); enemy.global_position += Vector3.FORWARD * 5; p.update_finisher(0.6)
	check(not enemy.dead and not enemy.execution_locked and p.finisher_remaining == 0, "Range is rechecked at impact")
	enemy.global_position = p.global_position + Vector3.FORWARD * 1.5
	p.activate_finisher(); var rotation: Vector3 = p.pivot.rotation; p.update_finisher(0.55)
	check(enemy.dead and enemy.enemy_id in p.character.adventure.defeated, "Impact kills through normal persistent defeat path")
	check(p.pivot.rotation == rotation, "Execution keeps camera orientation steady")
	var xp: int = p.character.skills.xp.melee
	p.update_finisher(0.1); check(p.character.skills.xp.melee == xp, "Impact and XP cannot repeat")
	p.update_finisher(1)
	check(p.finisher_remaining == 0 and not enemy.execution_locked and not p.activate_finisher(), "Animation releases corpse and cannot reexecute it")
	var other = a.enemies[1]; other.health = 5
	p.global_position = Vector3(5, -29.95, -9); other.global_position = Vector3(5, -29.95, -11)
	check(p.nearby_finisher() == null, "Wall blocks target selection")
	p.global_position = Vector3(0, -29.95, 2); other.global_position = p.global_position + Vector3.FORWARD * 1.5
	p.activate_finisher(); p.respawn()
	check(p.finisher_remaining == 0 and not other.execution_locked and not other.dead, "Respawn releases target without killing it")
	p.character.story_completed.append("archive"); world.lens.enter()
	for e in world.lens.enemies: e.set_physics_process(false)
	var boss = world.lens.enemies[4]
	p.rotation = Vector3.ZERO; boss.global_position = p.global_position + Vector3.FORWARD * 1.5; boss.health = 5
	check(not p.can_finish(boss), "Protected weak boss cannot bypass story barrier")
	p.character.lens.activated = true
	check(p.activate_finisher(), "Unprotected weak boss becomes eligible")
	p.character.lens.activated = false; p.update_finisher(0.6)
	check(not boss.dead and not boss.execution_locked and p.finisher_remaining == 0, "New protection before impact cancels execution")
	world.queue_free(); await process_frame
	print("FINISHERS_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
