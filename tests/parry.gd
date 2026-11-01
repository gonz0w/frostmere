extends SceneTree
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS " + message)
	else: failures += 1; push_error("FAIL " + message)
func ready_guard(p: Node) -> void:
	p.health = p.derived.health; p.stamina = p.derived.stamina; p.invulnerable = 0
	p.attack_animation = 0; p.parry_cooldown = 0; p.guard_recovery = 0
	p.update_guard(0, false); p.update_guard(0, true)
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	for i in range(4): await physics_frame
	var p = world.player
	var a = world.adventure
	a.enter()
	p.set_physics_process(false)
	for enemy in a.enemies: enemy.set_physics_process(false)
	p.set_paused(false); p.rotation = Vector3.ZERO
	var enemy = a.enemies[0]
	ready_guard(p)
	check(p.blocking and p.parry_window > 0, "Fresh guard opens timed parry window")
	var stamina: float = p.stamina
	p.receive_damage(16, p.global_position + Vector3.FORWARD, enemy)
	check(p.health == p.derived.health and p.stamina == stamina - 8, "Frontal melee parry prevents damage for eight stamina")
	check(enemy.stagger_time == 0.7 and enemy.windup == 0, "Parry staggers ordinary attacker and cancels windup")
	check(p.parry_window == 0, "Successful parry consumes window")
	p.update_guard(0.1, false); p.update_guard(0, true)
	check(p.parry_window == 0, "Rapid guard tapping cannot bypass parry cooldown")
	p.update_guard(1, true)
	check(p.blocking and p.parry_window == 0, "Holding guard does not automatically rearm parry")
	p.update_guard(0, false); p.update_guard(0, true)
	check(p.parry_window > 0, "Fresh press after cooldown rearms parry")
	ready_guard(p); p.update_guard(0.23, true); p.receive_damage(16, p.global_position + Vector3.FORWARD, enemy)
	check(p.health < p.derived.health and p.blocking, "Late block retains ordinary damage mitigation")
	ready_guard(p); enemy.stagger_time = 0
	p.receive_damage(16, p.global_position + Vector3.BACK, enemy)
	check(p.health < p.derived.health and enemy.stagger_time == 0, "Rear melee hit cannot be parried")
	ready_guard(p); p.receive_damage(16, p.global_position + Vector3.FORWARD)
	check(p.health < p.derived.health and enemy.stagger_time == 0, "Projectiles use ordinary blocking rather than staggering remote attacker")
	ready_guard(p); p.stamina = 1; p.receive_damage(16, p.global_position + Vector3.FORWARD, enemy)
	check(not p.blocking and p.guard_recovery > 0 and p.stamina == 0, "Exhausted guard breaks without free parry")
	p.stamina = 50; p.update_guard(0.1, true)
	check(not p.blocking, "Guard break prevents immediate reblock even after stamina recovery")
	p.update_guard(0.6, true)
	check(p.blocking and p.parry_window == 0, "Guard returns after recovery without granting held-button parry")
	ready_guard(p); p.set_paused(true)
	var hp: float = p.health
	p.receive_damage(16, p.global_position + Vector3.FORWARD, enemy)
	check(p.parry_window == 0 and p.health == hp, "Opening menu cancels parry and pauses damage")
	p.set_paused(false)
	p.character.equip(p.character.add_item("iron_bow"), "main_hand")
	ready_guard(p)
	check(not p.blocking and p.parry_window == 0, "Bow cannot block or parry")
	p.character.equip(p.character.add_item("iron_sword"), "main_hand")
	ready_guard(p); p.attack_animation = 0.2; p.update_guard(0, true)
	check(not p.blocking and p.parry_window == 0, "Attack animation cannot be cancelled into parry")
	var boss = a.enemies[-1]
	boss.parried()
	check(boss.stagger_time == 0.35, "Bosses recover from parry faster")
	enemy.dead = true; enemy.stagger_time = 0; enemy.parried()
	check(enemy.stagger_time == 0, "Corpses cannot be staggered")
	enemy.dead = false; enemy.parried(); enemy.windup = 0.1
	enemy._physics_process(0.2)
	check(enemy.windup == 0 and enemy.stagger_time > 0 and enemy.velocity.x == 0 and enemy.velocity.z == 0, "Stagger stops enemy attack and pursuit")
	p.global_position = Vector3(0, -29.95, 2); p.rotation = Vector3.ZERO
	enemy.global_position = p.global_position + Vector3.FORWARD * 1.4
	enemy.stagger_time = 0; enemy.windup = 0.01
	ready_guard(p); enemy._physics_process(0.02)
	check(p.health == p.derived.health and enemy.stagger_time > 0, "Actual enemy melee strike routes through parry and staggers its attacker")
	print("PARRY_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
