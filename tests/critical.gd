extends SceneTree
const Projectile = preload("res://scripts/projectile.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS " + message)
	else: failures += 1; push_error("FAIL " + message)
func critical_seed(p: Node) -> void:
	for value in range(100):
		p.combat_rng.seed = value
		if p.roll_weapon_critical():
			p.combat_rng.seed = value
			return
	assert(false)
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(4): await physics_frame
	var p = world.player; var a = world.adventure
	a.enter(); p.set_physics_process(false); p.set_paused(false)
	for enemy in a.enemies: enemy.set_physics_process(false)
	var enemy = a.enemies[0]
	var expected = RandomNumberGenerator.new()
	p.combat_rng.seed = 975; expected.seed = 975; p.derived.critical = 12.0
	var matches := true
	for i in range(100): matches = (p.roll_weapon_critical() == (expected.randf() < 0.12)) and matches
	check(matches, "Seeded rolls use displayed percentage")
	p.derived.critical = 0
	var none := true
	for i in range(100): none = not p.roll_weapon_critical() and none
	check(none, "Zero chance never produces a critical")
	p.derived.critical = 100; p.combat_rng.seed = 43; expected.seed = 43; matches = true
	for i in range(100): matches = (p.roll_weapon_critical() == (expected.randf() < 0.35)) and matches
	check(matches, "Critical probability respects 35 percent cap")
	var hp: float = enemy.health
	enemy.receive_damage(10, p, "", "melee", true)
	check(enemy.health == hp - 15 and a.feedback.begins_with("Critical!"), "Weapon critical deals 150 percent damage and reports it")
	hp = enemy.health; enemy.receive_damage(10, p, "", "melee")
	check(enemy.health == hp - 10, "Ordinary weapon hit retains base damage")
	hp = enemy.health; enemy.receive_damage(10, p, "", "magic", true)
	check(enemy.health == hp - 10 and a.feedback.begins_with("Hit"), "Magic cannot gain weapon critical multiplier")
	var boss = a.enemies[-1]; hp = boss.health
	boss.receive_damage(10, p, "", "marksman", true)
	check(is_equal_approx(boss.health, hp - 12), "Boss mitigation applies after critical multiplier")
	p.set_paused(true); hp = enemy.health; enemy.receive_damage(10, p, "", "melee", true)
	check(enemy.health == hp, "Critical cannot bypass paused combat")
	p.set_paused(false); enemy.dead = true; enemy.receive_damage(10, p, "", "melee", true)
	check(enemy.health == hp, "Critical cannot damage corpses")
	enemy.dead = false; enemy.health = 10
	var xp: int = p.character.skills.xp.melee
	enemy.receive_damage(100, p, "", "melee", true)
	check(p.character.skills.xp.melee == xp + 2, "Overkill critical training uses actual health removed")
	enemy.dead = false; enemy.health = 65; enemy.collision_layer = 4
	p.global_position = Vector3(0, -29.95, 2); p.rotation = Vector3.ZERO
	enemy.global_position = p.global_position + Vector3.FORWARD * 1.5
	p.character.equip(p.character.add_item("iron_sword"), "main_hand")
	p.attack_cooldown = 0; p.blocking = false; p.stamina = p.derived.stamina
	critical_seed(p); hp = enemy.health
	check(p.attack() and is_equal_approx(enemy.health, hp - p.derived.damage * 1.5), "Real melee swing propagates critical roll")
	p.character.equip(p.character.add_item("iron_bow"), "main_hand")
	p.character.materials.arrow = 20; p.attack_cooldown = 0; p.set_third_person(false); p.pivot.rotation.x = 0
	enemy.health = 65; enemy.global_position = p.global_position + Vector3.FORWARD * 4
	critical_seed(p); check(p.attack(), "Actual bow attack launches")
	var bolt: Node
	for child in a.get_children():
		if child is Projectile and not child.hostile: bolt = child
	check(is_instance_valid(bolt) and bolt.critical, "Bow projectile snapshots launch critical")
	p.derived.critical = 0
	check(bolt.critical, "Changing gear stats in flight cannot remove rolled critical")
	for i in range(20): await physics_frame
	check(enemy.health < 65 and a.feedback.begins_with("Critical!"), "Swept arrow collision applies critical and feedback")
	p.character.equip(p.character.add_item("station_rifle"), "main_hand")
	p.character.materials.station_round = 10; p.attack_cooldown = 0
	critical_seed(p); check(p.attack(), "Actual firearm attack launches")
	bolt = a.get_child(a.get_child_count() - 1)
	check(bolt is Projectile and bolt.critical and p.character.materials.station_round == 9, "Firearm rolls critical and spends exactly one round")
	critical_seed(p)
	a.fire(p.global_position + Vector3.UP * 3, Vector3.FORWARD, 10, false, p, true)
	bolt = a.get_child(a.get_child_count() - 1)
	check(not bolt.critical and bolt.training_skill == "magic", "Spell projectile never rolls weapon critical")
	a.fire(p.global_position + Vector3.UP * 3, Vector3.FORWARD, 10, true, enemy, false)
	bolt = a.get_child(a.get_child_count() - 1)
	check(not bolt.critical, "Hostile projectile does not use player critical stats")
	world.queue_free(); await process_frame
	print("CRITICAL_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
