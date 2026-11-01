extends SceneTree
const State = preload("res://scripts/character_state.gd")
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL " + text)
	else:
		print("PASS " + text)
func run() -> void:
	var s := State.new()
	var all_recipes := State.new()
	for recipe: Dictionary in all_recipes.crafting.recipes:
		if recipe.unlock not in all_recipes.blueprints:
			all_recipes.blueprints.append(recipe.unlock)
		for material: Dictionary in all_recipes.crafting.materials:
			all_recipes.materials[material.id] = 1000
		check(all_recipes.craft_recipe(recipe.id, recipe.station).begins_with("Created"), "Recipe creates output: " + recipe.id)
	check(all_recipes.items.keys().all(func(id): return id in all_recipes.discovered), "All catalog designs are obtainable through crafting")
	var start := s.inventory.size()
	s.apply_starter()
	check(s.inventory.size() == start, "Starter outfit cannot grant duplicate free gear")
	check(not s.equip("crystal_sword", "main_hand"), "Catalog entries cannot be equipped without ownership")
	var old := s.materials.duplicate()
	check(s.craft_recipe("smelt_iron", "enchant").contains("correct") and s.materials == old, "Wrong station spends nothing")
	check(s.craft_recipe("craft_crystal_sword", "forge").contains("blueprint") and s.materials == old, "Unknown blueprint spends nothing")
	s.materials = {}
	check(s.craft_recipe("smelt_iron", "forge").contains("enough") and s.inventory.size() == start, "Missing ingredients never create items")
	s.materials = s.crafting.starting_materials.duplicate()
	s.craft_recipe("smelt_iron", "forge")
	s.craft_recipe("smelt_iron", "forge")
	check(s.materials.iron_ore == 4 and s.materials.iron_ingot == 2, "Refining consumes exact input and grants exact output")
	s.craft_recipe("craft_iron_sword", "forge")
	check(s.inventory.size() == start + 1 and s.materials.iron_ingot == 0, "Forging creates a unique owned weapon")
	var sword: String = s.inventory.keys().back()
	var duplicate := s.add_item("iron_sword")
	for entry: Dictionary in s.crafting.materials:
		s.materials[entry.id] = 100
	s.equip(sword, "main_hand")
	var damage: int = s.stats().damage
	s.improve(sword, "forge")
	s.improve(sword, "forge")
	check(s.inventory[sword].quality == 2 and s.inventory[duplicate].quality == 0 and s.stats().damage > damage, "Tempering affects only the selected copy and actual derived damage")
	var stamina: int = s.stats().stamina
	s.enchant_item(sword, "vigor", "enchant")
	check(s.stats().stamina == stamina + 12, "Vigor changes the equipped character resource limit")
	var strength: int = s.attributes().strength
	s.socket_gem(sword, "ruby", "enchant")
	check(s.attributes().strength == strength + 2 and s.materials.ruby == 99, "Socketed gem consumes owned gem and adds attributes")
	old = s.materials.duplicate()
	s.socket_gem(sword, "sapphire", "enchant")
	check(s.materials == old and s.inventory[sword].gem == "ruby", "Filled socket cannot silently destroy the previous gem")
	s.extract_gem(sword, "enchant")
	check(s.materials.ruby == 100 and s.inventory[sword].gem == "" and s.attributes().strength == strength, "Gem extraction returns the gem and removes its bonus")
	s.socket_gem(duplicate, "ruby", "enchant")
	check(s.inventory[duplicate].gem == "", "Standard items cannot socket gems")
	s.dismantle(sword, false, "forge")
	check(s.inventory.has(sword), "Equipped gear is protected from salvage")
	s.personalize(duplicate, "Keepsake", true)
	s.dismantle(duplicate, false, "forge")
	check(s.inventory.has(duplicate), "Favorite gear is protected from salvage")
	s.personalize(duplicate, "Keepsake", false)
	var count: int = s.materials.iron_ingot
	s.dismantle(duplicate, false, "forge")
	check(not s.inventory.has(duplicate) and s.materials.iron_ingot > count and "iron_sword" in s.discovered, "Salvage yields materials and preserves collection discovery")
	s.gather("smith_cache", 1000)
	var inventory_size := s.inventory.size()
	old = s.materials.duplicate()
	s.gather("smith_cache", 9999)
	check(s.inventory.size() == inventory_size and s.materials == old and "steel" in s.blueprints, "Chest grants gear/blueprints only once")
	var enchanted: String = s.inventory.keys().back()
	s.dismantle(enchanted, true, "enchant")
	check("insight" in s.formulas and not s.inventory.has(enchanted), "Disenchanting consumes unknown enchanted loot and teaches formula")
	s.gather("iron_bank", 1000)
	old = s.materials.duplicate()
	s.gather("iron_bank", 1050)
	check(s.materials == old, "Gathering cooldown prevents repeated claims")
	s.gather("iron_bank", 1090)
	check(s.materials.iron_ore == old.iron_ore + 5, "Renewable materials replenish after cooldown")
	for i in range(4):
		s.improve(sword, "forge")
	check(s.inventory[sword].quality == 5, "Quality stops at Legendary")
	var path := "res://build/crafting-test.json"
	check(s.save_to(path), "Crafting progress saves atomically")
	var restored := State.new()
	check(restored.load_from(path) and restored.inventory == s.inventory and restored.materials == s.materials and restored.claims == s.claims and restored.formulas == s.formulas and restored.stats() == s.stats(), "Gear, upgrades, materials, claims and learned formulas survive reload")
	old = restored.materials.duplicate()
	restored.gather("smith_cache", 50000)
	check(restored.materials == old, "Reload does not reset chest claims")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.materials.iron_ore = -1
	write_json(path, data)
	check(not restored.load_from(path) and restored.materials == old, "Invalid crafting save rejected without partial changes")
	write_json(path, {"version":1,"name":"Legacy","origin":"frostkin","archetype":"warrior","frame":"balanced","allocated":{},"equipment":{"main_hand":"iron_sword","off_hand":"iron_sword"}})
	check(restored.load_from(path) and restored.equipment.main_hand != restored.equipment.off_hand and restored.item_at("main_hand").base_id == "iron_sword", "Legacy saves migrate dual-wield copies into distinct owned instances")
	DirAccess.remove_absolute(path)
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player: CharacterBody3D = world.player
	var ui: Control = world.hud.workshop
	player.position = Vector3(-4, 0.1, -11)
	world.interact_nearby()
	await process_frame
	check(ui.visible and player.paused and not world.hud.pause_panel.visible and ui.mode == "Forge", "E at forge opens crafting and pauses without extra overlay")
	ui.selected = "smelt_iron"
	ui.show_detail()
	ui.actions.get_child(0).pressed.emit()
	check(player.character.materials.get("iron_ingot", 0) == 1, "Actual craft button produces an ingot")
	player.position = Vector3(0, 0.1, 17)
	ui.refresh()
	check(ui.actions.get_child(0).disabled, "Moving away disables workstation crafting")
	ui.close()
	player.position = Vector3(3, 0.1, 13)
	world.interact_nearby()
	check(player.character.claims.has("smith_cache"), "World E gathering grants nearby cache")
	player.position = Vector3(-3.8, 0.1, 4.5)
	world.interact_nearby()
	check(ui.mode == "Alchemy", "Herbalist station opens alchemy recipes")
	player.character.gather("bluecaps", 1000)
	player.character.craft_recipe("make_stamina_draught", "alchemy")
	player.stamina = player.derived.stamina - 70
	player.character.consume("stamina_draught", player)
	check(is_equal_approx(player.stamina, player.derived.stamina - 5), "Consumable restores real player resource")
	player.character.craft_recipe("make_healing_draught", "alchemy")
	player.character.consume("healing_draught", player)
	check(player.character.consumables.get("healing_draught", 0) == 1, "Full health does not waste a potion")
	ui.close()
	player.position = Vector3(6, 0.1, -27.5)
	world.interact_nearby()
	check(ui.mode == "Enchant", "Runewright table opens enchanting")
	ui.selected = player.character.equipment.main_hand
	ui.show_detail()
	ui.actions.get_child(1).pressed.emit()
	check(player.character.inventory[player.character.equipment.main_hand].enchant == "vigor", "Enchant button applies selected learned formula to actual gear")
	ui.close()
	var key := InputEventKey.new()
	key.physical_keycode = KEY_I
	key.pressed = true
	player._unhandled_input(key)
	check(player.workshop_open and player.paused, "I opens bag")
	key.physical_keycode = KEY_M
	player._unhandled_input(key)
	check(not player.workshop_open and player.map_open, "M switches bag to map without stacking")
	key.physical_keycode = KEY_I
	player._unhandled_input(key)
	key.physical_keycode = KEY_ESCAPE
	player._unhandled_input(key)
	check(not player.paused and not player.workshop_open, "Escape closes bag and resumes")
	world.queue_free()
	await process_frame
	print("CRAFTING_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
func write_json(path: String, value: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify(value))
	f.close()
