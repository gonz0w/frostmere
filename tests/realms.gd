extends SceneTree
const State = preload("res://scripts/character_state.gd")
const Projectile = preload("res://scripts/projectile.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS " + message)
	else:
		failures += 1
		push_error("FAIL " + message)
func frames(n: int = 3) -> void:
	for i in range(n): await physics_frame
func bolts(a: Node) -> int:
	var count := 0
	for node in a.get_children():
		if node is Projectile and not node.is_queued_for_deletion(): count += 1
	return count
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames()
	var p: CharacterBody3D = world.player
	var r: Node3D = world.realms
	var s: RefCounted = p.character
	check(not s.persist and not world.atlas.persist, "Automated fixture cannot modify character or atlas saves")
	check(r.enemies.size() == 6, "Both realms contain distinct sentries and a guardian")
	check(not r.enter("aeralis") and not r.enter("crucible"), "New characters cannot skip into later chapters")
	s.story_completed.append("threshold")
	check(r.can_enter("aeralis") and not r.can_enter("crucible"), "Space chapter unlocks only the crystal realm")
	s.persist = true
	check(not r.enter("aeralis", true), "Preview bypass refuses a persistent profile")
	s.persist = false
	check(r.enter("aeralis"), "Story-qualified character enters Aeralis")
	for enemy in r.enemies: enemy.set_physics_process(false)
	await frames(10)
	check(p.is_on_floor() and p.position.y > 159, "Floating terrace has a solid floor")
	check(not r.finish_chapter(), "Returning without the guardian relic cannot complete the chapter")
	check(r.attune("aeralis") and "starfall" in s.known_spells and "aether" in s.blueprints and "aether_attunement" in s.formulas, "Attunement learns realm magic, forging and enchanting")
	var size: int = s.inventory.size()
	check(not r.attune("aeralis") and s.inventory.size() == size, "Attunement supplies cannot be duplicated")
	p.magicka = 100
	p.spell_cooldown = 0
	world.adventure.clear_projectiles()
	check(p.cast_spell() and p.magicka == 72 and bolts(world.adventure) == 3, "Starfall spends 28 magicka and creates three crystal bolts")
	check(not p.cast_spell(), "Spell cooldown prevents rapid repeat casting")
	s.cycle_spell()
	check(s.active_spell == "emberbolt", "Spell cycle wraps to the original spell")
	p.set_paused(true)
	p.spell_cooldown = 0
	check(not p.cast_spell(), "Paused menus cannot cast spells")
	p.set_paused(false)
	p.position = r.vector(r.definitions.aeralis.origin) + Vector3(5, 0.1, 16)
	check(r.nearest().id == "forge" and world.station_nearby() == "forge", "Realm forge prompt and crafting proximity agree")
	p.position = r.vector(r.definitions.aeralis.origin) + Vector3(6, 0.1, 10)
	check(r.nearest().id == "enchant" and world.station_nearby() == "enchant", "Separate enchantment altar has matching proximity")
	var supported := true
	for z in [4, 2, 0, -17, -20, -23]:
		p.position = r.vector(r.definitions.aeralis.origin) + Vector3(0, 0.12, z)
		p.velocity = Vector3.ZERO
		await frames(6)
		supported = supported and p.is_on_floor()
	check(supported, "Both bridges and their joins support traversal")
	var key := InputEventKey.new()
	key.pressed = true; key.physical_keycode = KEY_M
	p._unhandled_input(key)
	check(p.map_open and world.hud.world_map.canvas.local_view and world.hud.world_map.canvas.in_realm(), "M selects a dedicated realm map")
	check(world.hud.world_map.place_action.disabled and not world.hud.world_map.survey_action.visible and world.hud.world_map.place_text.text.contains("Aeralis"), "Realm map describes its own story and hides home-survey actions")
	key.physical_keycode = KEY_ESCAPE
	p._unhandled_input(key)
	var boss: CharacterBody3D = r.enemies[2]
	boss.receive_damage(10000)
	check(boss.dead and "aeralis_regent" in s.realm_progress.defeated and s.adventure.defeated.is_empty(), "Realm guardian defeat is separate from Oldwatch progress")
	check(r.loot("aeralis_regent") and not r.loot("aeralis_regent"), "Guardian loot is collectible once")
	p.position=r.vector(r.definitions.aeralis.origin)+Vector3(0,.1,19)
	check(r.finish_chapter() and "returning_light" in s.story_completed and not r.finish_chapter(), "Relic completes the Aeralis chapter once")
	r.leave()
	check(not r.inside and "starfall" in s.known_spells and s.inventory.size() > size, "Returning home retains realm gear and learned magic")
	check(not r.can_enter("crucible"), "Aeralis completion alone does not unlock Hell")
	s.story_completed.append("winter_siege")
	check(not r.can_enter("crucible"), "Homeworld siege still requires the broken seal chapter")
	s.story_completed.append("broken_seal")
	check(r.enter("crucible"), "Late campaign prerequisites unlock the Crucible")
	r.attune("crucible")
	s.equip(s.add_item("cinder_gun", 1, "infernal_resolve"), "main_hand")
	p.magicka = 100; p.spell_cooldown = 0
	world.adventure.clear_projectiles()
	check(p.cast_spell() and p.magicka == 68 and bolts(world.adventure) == 1, "Soulfire spends 32 magicka for one powerful lance")
	p.attack_cooldown = 0
	var ammo: int = s.materials.hell_round
	check(p.attack() and s.materials.hell_round == ammo - 1 and not p.attack(), "Machine gun spends real ammo and enforces its firing interval")
	p.attack_cooldown = 0
	Input.action_press("attack")
	await frames(25)
	Input.action_release("attack")
	check(s.materials.hell_round < ammo - 2, "Holding the trigger fires automatically")
	r.leave()
	p.attack_cooldown = 0
	check(p.attack() and s.item_at("main_hand").family == "machine_gun", "Machine gun remains usable in Frostmere")
	s.materials.hell_round = 0; p.attack_cooldown = 0
	check(not p.attack(), "Empty machine gun cannot fire")
	s.materials.cinder_alloy = 5; s.materials.charcoal = 5
	check(s.craft_recipe("craft_hell_rounds", "forge").begins_with("Created") and s.materials.hell_round == 40, "Learned realm recipe replenishes ammunition at a home forge")
	check(s.save_to("user://realm-test.json"), "Realm progression and inventory save atomically")
	var loaded := State.new()
	check(loaded.load_from("user://realm-test.json") and loaded.realm_progress == s.realm_progress and loaded.known_spells == s.known_spells and loaded.item_at("main_hand").family == "machine_gun", "Realm progress, spells and portable gun survive reload")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://realm-test.json"))
	data.active_spell = "fake_spell"
	var f := FileAccess.open("user://realm-invalid.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data)); f.close()
	check(not loaded.load_from("user://realm-invalid.json"), "Invalid spell save is rejected without applying it")
	for field in ["realm_progress", "story_completed", "known_spells", "active_spell"]: data.erase(field)
	f = FileAccess.open("user://realm-legacy.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://realm-legacy.json") and loaded.active_spell == "emberbolt" and loaded.realm_progress.completed.is_empty(), "Earlier saves without realm fields load with safe defaults")
	r.enter("crucible")
	p.health = p.derived.health
	p.position.y = -10
	r.check_fall()
	check(r.inside and p.position.y > 0 and p.health < p.derived.health, "Falling into lava recovers the player with damage")
	p.invulnerable = 0; p.receive_damage(10000, p.position + Vector3.BACK)
	check(not r.inside and p.position.x < 100, "Death exits the realm and returns to Frostmere")
	for path in ["user://realm-test.json", "user://realm-invalid.json", "user://realm-legacy.json"]: DirAccess.remove_absolute(path)
	world.queue_free()
	await process_frame
	print("REALMS_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
