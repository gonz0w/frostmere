extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL " + message)
	else:
		print("PASS " + message)

func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await process_frame
	var player: CharacterBody3D = world.player
	var menu: Control = world.hud.character_menu
	var state: RefCounted = player.character
	var owned := {}
	state.inventory.clear()
	for slot: String in state.equipment:
		state.equipment[slot] = ""
	for item: Dictionary in state.catalog.items:
		owned[item.id] = state.add_item(item.id)
	state.apply_starter()
	check(not state.persist, "Automated scene does not write user character saves")
	check(menu.item_list.item_count == 20, "Empty search shows all twenty compatible chest items")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_C
	key.pressed = true
	player._unhandled_input(key)
	await process_frame
	check(menu.visible and player.paused and not world.hud.pause_panel.visible, "C opens character menu and pauses world without pause overlay")
	menu.search.text = "crystal"
	menu.search.text_changed.emit("crystal")
	check(menu.item_list.item_count == 1 and menu.selected_item == owned["crystal_chest"], "Search filters compatible items")
	menu.equip_button.pressed.emit()
	await process_frame
	check(state.equipment.chest == owned["crystal_chest"] and player.avatar.b.materials.chest.albedo_color.is_equal_approx(Color("73bfc7")), "Equip button updates state and visible body material")
	var old_points: int = state.points_left()
	menu.plus_buttons.strength.pressed.emit()
	check(state.points_left() == old_points - 1 and state.allocated.strength == 1, "Attribute button edits the correct attribute")
	menu.class_picker.select(4)
	menu.class_picker.item_selected.emit(4)
	check(state.archetype_id == "mage" and state.equipment.chest == owned["crystal_chest"], "Playstyle picker preserves chosen equipment")
	menu.origin_picker.select(6)
	menu.origin_picker.item_selected.emit(6)
	check(state.origin_id == "wildcat", "Ancestry picker updates player identity")
	menu.frame_picker.select(2)
	menu.frame_picker.item_selected.emit(2)
	check(state.frame_id == "broad" and player.avatar.scale.x > 1, "Body frame updates the live rig")
	menu.search.text = ""
	menu.slot_list.item_selected.emit(5)
	check(menu.item_list.item_count == 58, "Main-hand slot lists all 58 weapons")
	menu.selected_item = owned["steel_greatsword"]
	menu._show_item()
	menu.equip_button.pressed.emit()
	check(state.equipment.main_hand == owned["steel_greatsword"] and state.equipment.off_hand == "", "Equipping two-handed weapon through UI clears off hand")
	menu.slot_list.item_selected.emit(6)
	check(menu.item_list.item_count > 4 and menu.equip_button.disabled, "Off-hand UI exposes compatible items but blocks conflicting equip")
	state.unequip("main_hand")
	check(not menu.equip_button.disabled, "Removing two-handed weapon enables off hand")
	menu.search.text = "nothingmatches"
	menu.search.text_changed.emit(menu.search.text)
	check(menu.item_list.item_count == 0 and menu.equip_button.disabled, "Empty filter result cannot equip stale selection")
	player.set_third_person(false)
	state.equip(owned["crystal_staff"], "main_hand")
	await process_frame
	check(not player.avatar.visible and player.first_person_hands.visible and player.first_person_hands.get_child_count() == 2, "Gear changes rebuild first-person visuals without revealing third-person avatar")
	key.physical_keycode = KEY_ESCAPE
	player._unhandled_input(key)
	await process_frame
	check(not menu.visible and not player.paused, "Escape closes character menu and resumes movement")
	player._unhandled_input(key)
	await process_frame
	check(player.paused and world.hud.pause_panel.visible, "Escape still opens the normal pause menu")
	world.queue_free()
	await process_frame
	print("CHARACTER_UI_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
