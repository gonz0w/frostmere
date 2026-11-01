extends SceneTree
const State = preload("res://scripts/character_state.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS " + message)
	else:
		failures += 1
		push_error("FAIL " + message)
func frames(n: int = 3) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames()
	var p: CharacterBody3D = world.player
	var a: Node3D = world.adventure
	var s: RefCounted = p.character
	check(a.enemies.size() == 7 and a.chests.size() == 2, "Dungeon contains six sentries, a boss and two hidden chests")
	p.position = a.SMITH + Vector3(1, 0.1, 0)
	world.interact_nearby()
	await frames()
	check(p.dialog_open and p.paused and a.dialog.visible and not world.hud.pause_panel.visible, "Nearby E opens smith dialogue without stacked pause overlay")
	a.dialog_action.pressed.emit()
	check(s.adventure.accepted and s.materials.arrow == 30 and s.consumables.healing_draught == 3, "Smith quest button grants expedition supplies")
	var count: int = s.inventory.size()
	check(not a.accept_quest() and s.inventory.size() == count and s.materials.arrow == 30, "Quest acceptance cannot duplicate supplies")
	check(not a.reward_quest(), "Cannot claim quest reward before recovering ember")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_ESCAPE
	p._unhandled_input(key)
	check(not p.dialog_open and not p.paused, "Escape leaves smith dialogue")
	p.position = a.ENTRANCE + Vector3(0, 0.1, 1)
	world.interact_nearby()
	check(a.inside and p.position.y < -20, "World entrance interaction descends into dungeon")
	key.physical_keycode = KEY_M
	p._unhandled_input(key)
	check(world.hud.world_map.canvas.local_view and p.map_open, "M opens underground map while in barrow")
	key.physical_keycode = KEY_ESCAPE
	p._unhandled_input(key)
	# Isolate combat cases from other active opponents.
	for enemy: CharacterBody3D in a.enemies: enemy.set_physics_process(false)
	await frames(12)
	check(p.is_on_floor() and p.position.y > -31, "Dungeon floor supports player without triggering surface respawn")
	var guard: CharacterBody3D = a.enemies[0]
	p.position = Vector3(0, -29.95, 2)
	p.rotation = Vector3.ZERO
	guard.position = Vector3(0, 0.05, 0)
	await frames()
	var hp: float = guard.health
	check(p.attack() and guard.health < hp, "Melee swing damages an enemy within forward reach")
	hp = guard.health
	check(not p.attack() and guard.health == hp, "Attack cooldown prevents repeated damage from spamming")
	p.attack_cooldown = 0
	p.rotation.y = PI
	p.attack()
	check(guard.health == hp, "Melee does not hit behind the player")
	p.attack_cooldown = 0
	p.rotation.y = 0
	p.position = Vector3(5, -29.95, -9)
	guard.position = Vector3(5, 0.05, -11)
	await frames()
	p.attack()
	check(guard.health == hp, "Partition wall blocks melee damage")
	p.stamina = 0
	p.attack_cooldown = 0
	check(not p.attack(), "Empty stamina blocks melee")
	p.stamina = p.derived.stamina
	p.health = p.derived.health
	p.invulnerable = 0
	p.blocking = false
	p.receive_damage(30, p.position + Vector3.FORWARD)
	var normal: float = p.derived.health - p.health
	p.health = p.derived.health
	p.invulnerable = 0
	p.blocking = true
	p.receive_damage(30, p.position + Vector3.FORWARD)
	check(p.derived.health - p.health < normal and p.stamina < p.derived.stamina, "Facing shield block reduces damage and spends stamina")
	p.health = p.derived.health
	p.invulnerable = 0
	p.receive_damage(30, p.position + Vector3.BACK)
	check(is_equal_approx(p.derived.health - p.health, normal), "Blocking does not protect the player's back")
	p.invulnerable = 0
	p.stamina = 1
	p.receive_damage(30, p.position + Vector3.FORWARD)
	check(not p.blocking and p.stamina == 0, "Insufficient stamina breaks guard")
	p.set_paused(true)
	var health: float = p.health
	p.receive_damage(40, p.position)
	check(p.health == health and not p.attack() and not p.cast_spell(), "Paused menus prevent combat damage and attacks")
	p.set_paused(false)
	p.position = Vector3(0, -29.95, 2)
	guard.position = Vector3(0, 0.05, -4)
	guard.health = guard.maximum_health
	p.set_third_person(false)
	p.pivot.rotation.x = 0
	p.rotation = Vector3.ZERO
	p.attack_cooldown = 0
	p.stamina = p.derived.stamina
	s.equip(s.add_item("iron_bow"), "main_hand")
	await frames()
	var arrows: int = s.materials.arrow
	hp = guard.health
	check(p.attack() and s.materials.arrow == arrows - 1, "Bow attack consumes exactly one owned arrow")
	await frames(30)
	check(guard.health < hp, "Swept arrow projectile hits an enemy")
	p.attack_cooldown = 0
	s.materials.arrow = 0
	check(not p.attack(), "Bow cannot fire without arrows")
	p.magicka = p.derived.magicka
	p.spell_cooldown = 0
	hp = guard.health
	check(p.cast_spell() and p.magicka == p.derived.magicka - 18, "Emberbolt consumes magicka")
	await frames(30)
	check(guard.health < hp, "Emberbolt projectile deals damage")
	p.spell_cooldown = 0
	p.magicka = 0
	check(not p.cast_spell(), "Spell cannot fire without magicka")
	# A hostile bolt must stop at a partition, even at high speed.
	p.position = Vector3(5, -29.95, -9)
	p.invulnerable = 0
	health = p.health
	a.fire(Vector3(5, -28.7, -12), Vector3.BACK, 30, true, guard, true)
	await frames(30)
	check(is_equal_approx(p.health, health), "Stone partition stops hostile projectiles")
	p.position = Vector3(0, -29.95, 2)
	p.invulnerable = 0
	a.fire(Vector3(0, -28.7, -1), Vector3.BACK, 20, true, guard, true)
	await frames(30)
	check(p.health < health, "Hostile projectile damages player in clear line of sight")
	p.health = 20
	var potions: int = s.consumables.healing_draught
	key.physical_keycode = KEY_F
	p._unhandled_input(key)
	check(p.health == 70 and s.consumables.healing_draught == potions - 1, "F consumes a potion and heals the actual player")
	# Verify real enemy AI windups, melee and ranged attacks.
	a.clear_projectiles()
	await frames()
	p.position = Vector3(0, -29.95, 2)
	p.health = p.derived.health
	p.invulnerable = 0
	guard.position = Vector3(0, 0.05, 0.5)
	guard.cooldown = 0
	guard.windup = 0
	guard.set_physics_process(true)
	await frames(3)
	check(guard.windup > 0 and p.health == p.derived.health, "Melee enemy telegraphs before damaging player")
	await frames(50)
	check(p.health < p.derived.health, "Melee enemy AI completes a damaging strike")
	guard.set_physics_process(false)
	guard.position = Vector3(-8, 0.05, 0)
	for index in [1, 2]:
		var ranged: CharacterBody3D = a.enemies[index]
		ranged.position = Vector3(0, 0.05, -4)
		ranged.velocity = Vector3.ZERO
		await frames(3)
		ranged.cooldown = 0
		ranged.windup = 0
		p.invulnerable = 0
		p.health = p.derived.health
		ranged.set_physics_process(true)
		await frames(90)
		check(p.health < p.derived.health, "Ranged enemy AI fires a damaging projectile: " + ranged.role)
		ranged.set_physics_process(false)
		ranged.position = Vector3(-8, 0.05, -20)
		a.clear_projectiles()
	# Restore melee and walk a real route through both doorways.
	s.equip(s.add_item("iron_sword"), "main_hand")
	for enemy: CharacterBody3D in a.enemies:
		enemy.position.x = -8
	p.position = Vector3(0, -29.95, 5)
	p.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	await frames(740)
	Input.action_release("move_forward")
	check(p.position.z < -43 and a.inside, "Player can walk through both chamber doors into boss arena")
	var boss: CharacterBody3D = a.enemies.back()
	boss.position = Vector3(0, 0.05, -46)
	boss.receive_damage(9999)
	check(boss.dead and "captain" in s.adventure.defeated, "Boss defeat is recorded persistently")
	p.position = Vector3(0, -29.95, -45)
	world.interact_nearby()
	check("captain" in s.adventure.looted, "E loots the defeated boss")
	var named := ""
	for uid: String in s.inventory:
		if s.inventory[uid].base_id == "oldwatch_oath": named = uid
	check(named != "" and s.inventory[named].quality == 2 and s.inventory[named].favorite, "Boss awards a Superior enchanted named sword protected as a favorite")
	count = s.inventory.size()
	check(not a.loot_enemy("captain") and s.inventory.size() == count, "Boss loot cannot duplicate")
	p.position = a.chests.alcove.global_position + Vector3(0, 0.1, 1)
	world.interact_nearby()
	check("alcove" in s.adventure.chests and not a.loot_chest("alcove"), "Hidden chest is collectible exactly once")
	p.position = a.EXIT + Vector3(0, 0.1, -1)
	world.interact_nearby()
	check(not a.inside and p.position.y > -1, "Exit interaction returns player to the surface")
	p.position = a.SMITH + Vector3(1, 0.1, 0)
	world.interact_nearby()
	a.dialog_action.pressed.emit()
	check(s.adventure.rewarded and "oldwatch" in s.blueprints, "Returning ember through smith dialogue grants unique forging recipe")
	var mats: Dictionary = s.materials.duplicate()
	check(not a.reward_quest() and s.materials == mats, "Completed quest cannot duplicate rewards")
	a.close_dialog()
	p.set_paused(false)
	for id in ["steel_ingot", "rune_dust", "ember_core", "leather"]: s.materials[id] = 20
	check(s.craft_recipe("craft_oldwatch_oath", "forge").begins_with("Created"), "Reward recipe forges another Oldwatch Oath")
	check(s.improve(named, "forge").begins_with("Improved"), "Named boss weapon participates in existing tempering")
	var path := "res://build/combat-save-test.json"
	check(s.save_to(path), "Adventure and inventory save atomically")
	var restored := State.new()
	check(restored.load_from(path) and restored.adventure == s.adventure and restored.inventory.has(named), "Quest, boss defeat, chest claims and named gear survive reload")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.adventure.looted.append("made_up_enemy")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data)); file.close()
	check(not restored.load_from(path), "Malformed adventure progress rejected")
	DirAccess.remove_absolute(path)
	a.enter()
	p.invulnerable = 0
	p.health = 1
	p.receive_damage(1000, p.position + Vector3.BACK)
	check(not a.inside and p.health == p.derived.health and p.position.distance_to(p.spawn_point) < 0.1 and s.adventure.rewarded, "Death safely returns to trail, restores vitals and preserves earned progress")
	world.queue_free()
	await process_frame
	print("COMBAT_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
