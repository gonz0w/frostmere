extends SceneTree
const State = preload("res://scripts/character_state.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS " + label)
	else: failures += 1; push_error("FAIL " + label)
func run() -> void:
	var s = State.new()
	check(not s.save_loadout(-1, "Bad") and not s.save_loadout(0, " ") and not s.apply_loadout(0), "Invalid index, blank name and empty set rejected")
	var sword = s.add_item("steel_sword", 3); s.equip(sword, "main_hand")
	var gear = s.equipment.duplicate(); var owned = s.inventory.duplicate(true)
	check(s.save_loadout(0, "Warrior"), "Named set saves all slots")
	var bow = s.add_item("iron_bow"); s.equip(bow, "main_hand"); s.save_loadout(1, "Ranger")
	check(s.apply_loadout(0) and s.equipment == gear, "Whole set restores exact item IDs and shield")
	check(s.inventory[sword] == owned[sword], "Improved item data preserved")
	check(s.apply_loadout(1) and s.equipment.main_hand == bow and s.equipment.off_hand == "", "Two-handed set clears off hand atomically")
	s.inventory.erase(sword); var before = s.equipment.duplicate()
	check(s.loadout_missing(0).size() == 1 and not s.apply_loadout(0) and s.equipment == before, "Missing gear blocks entire swap and reports piece")
	check(s.save_to("user://loadout-test.json"), "Set with missing owned item can still save")
	var loaded = State.new()
	check(loaded.load_from("user://loadout-test.json") and loaded.loadouts == s.loadouts, "Missing-item set survives reload")
	s.inventory[sword] = owned[sword]
	check(s.apply_loadout(0), "Recovering original item makes set usable again")
	check(s.delete_loadout(1) and not s.delete_loadout(1) and s.inventory.has(bow), "Deleting set leaves items owned")
	var bad = s.loadouts.duplicate(true); bad[0].equipment.off_hand = sword
	check(not s.valid_loadouts(bad, s.inventory), "Duplicate item references rejected")
	bad = s.loadouts.duplicate(true); bad[0].bases.main_hand = "iron_bow"
	check(not s.valid_loadouts(bad, s.inventory), "Mismatched item identity rejected")
	bad = s.loadouts.duplicate(true); bad[0].equipment.erase("head")
	check(not s.valid_loadouts(bad, s.inventory), "Incomplete slot maps rejected")
	check(not s.valid_loadouts([{}, {}], s.inventory), "Wrong slot count rejected")
	s.save_to("user://loadout-test.json")
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://loadout-test.json")); data.erase("loadouts")
	var f = FileAccess.open("user://loadout-old.json", FileAccess.WRITE); f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://loadout-old.json") and loaded.loadouts == [{}, {}, {}, {}], "Older profiles migrate to four empty sets")
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(4): await physics_frame
	var p = world.player; var menu = world.hud.character_menu
	menu.loadout_name.text = "Live set"
	var actions = menu.loadout_apply.get_parent()
	actions.get_child(0).pressed.emit()
	check(p.character.loadouts[0].name == "Live set", "Actual Save current button saves named set")
	var previous: String = p.character.equipment.main_hand
	p.character.equip(p.character.add_item("iron_bow"), "main_hand")
	menu.loadout_apply.pressed.emit()
	check(p.character.equipment.main_hand == previous and p.derived.damage == p.character.stats().damage, "Actual Equip set button refreshes live stats")
	world.queue_free(); await process_frame
	for path in ["user://loadout-test.json", "user://loadout-old.json"]: DirAccess.remove_absolute(path)
	print("LOADOUTS_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
