extends SceneTree
const State = preload("res://scripts/character_state.gd")
const Visual = preload("res://scripts/character_visual.gd")
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)
	else:
		print("PASS " + message)

func _run() -> void:
	var state := State.new()
	check(not state.items.is_empty() and state.items.size() == state.catalog.items.size(), "Every catalog item has a unique ID")
	check(state.origins.size() == 8 and state.archetypes.size() == 8, "Eight ancestries and eight playstyles")
	check(state.equipment.size() == 9, "Nine equipment slots")
	var owned := {}
	for item: Dictionary in state.catalog.items:
		owned[item.id] = state.add_item(item.id)
	var stats := state.stats()
	check(stats.health > 100 and stats.armor > 0, "Starting bonuses and gear contribute to derived stats")
	check(not state.equip(owned["iron_sword"],  "head"), "Reject weapon in armor slot")
	check(not state.equip("unknown", "main_hand"), "Reject unknown item")
	check(state.equip(owned["iron_greatsword"],  "main_hand") and state.equipment.off_hand == "", "Two-handed weapon removes off-hand gear")
	check(not state.equip(owned["iron_shield"],  "off_hand"), "Two-handed weapon blocks a shield")
	state.equip(owned["steel_sword"],  "main_hand")
	check(state.equip(owned["iron_dagger"],  "off_hand") and state.stats().offhand_damage > 0, "One-handed weapons support dual wielding")
	state.unequip("off_hand")
	check(state.stats().offhand_damage == 0, "Unequipping removes off-hand damage")
	check(state.equip(owned["spell_focus"],  "off_hand"), "One-handed weapon pairs with magical focus")
	var before: int = state.attributes().strength
	state.equip(owned["might_ring"],  "ring")
	check(state.attributes().strength == before + 2, "Jewelry contributes attribute bonus")
	state.unequip("ring")
	check(state.attributes().strength == before, "Removing jewelry removes its bonus")
	for i in range(10):
		check(state.allocate("agility", 1), "Allocate available attribute point %d" % i)
	check(state.points_left() == 0 and not state.allocate("strength", 1), "Cannot overspend points")
	check(not state.allocate("strength", -1), "Cannot refund unassigned points")
	state.reset_points()
	check(state.points_left() == 10, "Reset refunds allocated points")
	state.set_identity("Aster", "grove_elf", "mage", "lean")
	state.apply_starter()
	var light_stats := state.stats()
	for slot in ["head", "chest", "hands", "legs", "feet"]:
		state.equip(owned["obsidian_" + slot], slot)
	check(state.stats().speed < light_stats.speed and state.stats().sprint_cost > light_stats.sprint_cost, "Heavy armor slows movement and increases sprint cost")
	var before_class: Dictionary = state.equipment.duplicate()
	state.set_identity("Aster", "grove_elf", "rogue", "lean")
	check(state.equipment == before_class, "Changing playstyle preserves mixed equipment")
	state.allocate("agility", 1)
	# A fresh source checkout does not contain ignored test output.
	var output_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	if output_error != OK:
		push_error("Cannot create character test output directory: " + str(output_error))
		quit(1)
		return
	var path := ProjectSettings.globalize_path("res://build/character-test.json")
	check(state.save_to(path), "Character saves atomically")
	var restored := State.new()
	check(restored.load_from(path), "Character save loads")
	check(restored.character_name == "Aster" and restored.frame_id == "lean" and restored.equipment == state.equipment and restored.allocated == state.allocated and restored.stats() == state.stats(), "Identity, equipment, allocation and stats survive round trip")
	var previous := restored.equipment.duplicate()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"version":1,"origin":"grove_elf","archetype":"rogue","name":"Broken","allocated":{"agility":999},"equipment":{}}')
	file.close()
	check(not restored.load_from(path) and restored.equipment == previous, "Invalid save rejected without partially replacing state")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('not json')
	file.close()
	check(not restored.load_from(path), "Malformed save rejected safely")
	DirAccess.remove_absolute(path)
	var all_valid := true
	for origin: String in state.origins:
		for archetype: String in state.archetypes:
			state.set_identity("Tester", origin, archetype, "balanced")
			state.apply_starter()
			for slot: String in state.equipment:
				if state.equipment[slot] != "" and not state.accepts(state.equipment[slot], slot):
					all_valid = false
			if state.stats().stamina <= 0 or state.stats().health <= 0:
				all_valid = false
	check(all_valid, "All 64 ancestry/playstyle starter combinations are valid")
	var visual := Visual.new()
	root.add_child(visual)
	for origin: String in state.origins:
		state.set_identity("Tester", origin, "warrior", "balanced")
		visual.build(state)
		await process_frame
	check(visual.get_child_count() > 4, "Every ancestry builds a modular character rig")
	var weapon_root := Node3D.new()
	root.add_child(weapon_root)
	for item: Dictionary in state.catalog.items:
		if item.category in ["weapon", "shield", "focus"]:
			Visual.make_weapon(weapon_root, item)
	check(weapon_root.get_child_count() > 0, "All weapon and off-hand visuals build")
	visual.queue_free()
	weapon_root.queue_free()
	await process_frame
	print("CHARACTERS_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
