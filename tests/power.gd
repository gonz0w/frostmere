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
	check(p.power == 0 and not p.activate_power(), "Fresh meter cannot activate")
	var front = a.enemies[0]; var rear = a.enemies[1]
	front.global_position = p.global_position + Vector3.FORWARD * 1.5
	rear.global_position = p.global_position + Vector3.BACK * 1.5
	for i in range(2, a.enemies.size()): a.enemies[i].global_position = p.global_position + Vector3.RIGHT * (20 + i)
	front.receive_damage(20, p, "", "magic")
	check(p.power == 5, "Actual spell damage charges quarter-point per health removed")
	p.gain_power(-50); check(p.power == 5, "Negative charge ignored")
	p.set_paused(true); p.gain_power(20); check(p.power == 5, "Paused character cannot gain charge")
	p.set_paused(false); p.gain_power(1000); check(p.power == 100, "Meter caps at 100")
	var hp: float = front.health; var rear_hp: float = rear.health
	var camera_rotation: Vector3 = p.pivot.rotation
	check(p.activate_power(), "Full meter activates melee Whirlwind")
	check(front.health==hp and rear.health==rear_hp,"Windup does not deal damage")
	p.update_power(.31)
	check(is_equal_approx(front.health, maxf(0, hp - p.derived.damage * 2)) and is_equal_approx(rear.health, maxf(0, rear_hp - p.derived.damage * 2)), "Sweep deals double weapon damage in front and behind")
	check(p.power == 0 and is_equal_approx(Engine.time_scale, 0.35), "Power is consumed once and slow motion starts")
	check(not p.activate_power() and not p.attack() and not p.cast_spell(), "Active spin rejects repeat activation and normal attacks")
	p.gain_power(100); check(p.power == 0, "Power attack cannot charge itself")
	p.update_power(0.4)
	check(absf(p.avatar.rotation.y) > 0.1 and p.pivot.rotation == camera_rotation, "Avatar spins without rotating camera")
	p.update_power(1)
	check(p.power_remaining == 0 and Engine.time_scale == 1 and is_zero_approx(p.avatar.rotation.y), "Real-time expiry restores speed and pose")
	p.power = 100; p.attack_cooldown = 0; p.activate_power(); p.set_paused(true)
	check(Engine.time_scale == 1 and p.power_remaining == 0, "Opening menus cancels slow motion safely")
	p.set_paused(false); p.character.equip(p.character.add_item("iron_bow"), "main_hand")
	p.power = 100; p.attack_cooldown = 0
	check(not p.activate_power() and p.power == 100, "Ranged weapon cannot consume melee power")
	p.character.equip(p.character.add_item("iron_sword"), "main_hand")
	p.blocking = true; check(not p.activate_power() and p.power == 100, "Blocking prevents power activation")
	p.blocking = false
	p.global_position = Vector3(5, -29.95, -9); front.global_position = Vector3(5, -29.95, -11)
	front.health = 65; front.dead = false; hp = front.health
	p.activate_power(); p.update_power(.31); check(front.health == hp, "Partition wall blocks Whirlwind damage")
	p.cancel_power(); p.attack_cooldown = 0; p.power = 100
	Engine.time_scale = 0.8; p.activate_power(); p.cancel_power()
	check(is_equal_approx(Engine.time_scale, 0.8), "Cleanup restores prior time scale")
	Engine.time_scale = 1
	p.attack_cooldown = 0; p.power = 100; p.activate_power(); p.respawn()
	check(Engine.time_scale == 1 and p.power == 0 and p.power_remaining == 0, "Respawn clears transient power and restores speed")
	p.attack_cooldown = 0; p.power = 100; p.activate_power()
	world.queue_free(); await process_frame
	check(Engine.time_scale == 1, "Scene removal cannot leave engine slowed")
	print("POWER_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
