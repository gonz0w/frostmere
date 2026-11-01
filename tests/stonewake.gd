extends SceneTree
const State = preload("res://scripts/character_state.gd")
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
func escape(p: Node) -> void:
	var key := InputEventKey.new(); key.pressed = true; key.physical_keycode = KEY_ESCAPE
	p._unhandled_input(key)
func run() -> void:
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames()
	var story: Node3D = world.stonewake
	var p: CharacterBody3D = world.player
	var s: RefCounted = p.character
	check(not story.accept() and not story.reward(), "Main chapter cannot start or reward before Oldwatch")
	p.position = story.KEEPER + Vector3(0, 0.1, 1.5)
	world.interact_nearby()
	check(story.dialog.visible and p.dialog_open and p.paused and story.action.disabled, "Keeper explains prerequisite in a paused dialogue")
	escape(p)
	check(not story.dialog.visible and not p.paused and not p.dialog_open, "Escape closes the keeper dialogue and resumes")
	world.adventure.accept_quest()
	world.adventure.mark_defeated("captain")
	world.adventure.loot_enemy("captain")
	world.adventure.reward_quest()
	world.interact_nearby()
	check(not story.action.disabled and story.text.text.contains("STONEWAKE"), "Returning the ember unlocks the keeper invitation")
	story.action.pressed.emit()
	check(s.stonewake.accepted and not story.accept(), "Actual dialogue accepts Stonewake only once")
	check(not story.reward(), "Reward remains locked until all wards and revelation")
	escape(p)
	p.position = story.RELIC + Vector3(0, 0.1, 1.5)
	world.interact_nearby()
	check(not s.stonewake.awakened and story.dialog.visible, "Relic cannot awaken before the wards are restored")
	escape(p)
	var mats: Dictionary = s.materials.duplicate()
	for ward: Dictionary in story.WARDS:
		p.position = ward.position + Vector3(0, 0.1, 1.5)
		p.velocity = Vector3.ZERO
		await frames(24)
		check(p.is_on_floor() and world.nearest_interaction().get("id") == ward.id, "Ward has an accessible interaction approach: " + ward.id)
		world.interact_nearby()
		check(not story.choose_rune("Sky" if ward.answer != "Sky" else "Hearth") and ward.id not in s.stonewake.wards and s.materials == mats, "Incorrect rune consumes nothing: " + ward.id)
		var saved_position: Vector3 = p.position
		p.position += Vector3(0, 0, 10)
		check(not story.choose_rune(ward.answer), "Ward choice rechecks proximity: " + ward.id)
		p.position = saved_position
		check(story.choose_rune(ward.answer) and story.lights[ward.id + "_rune"].visible and not story.choose_rune(ward.answer), "Correct rune restores a ward once: " + ward.id)
		escape(p)
	check(s.stonewake.wards.size() == 3 and not s.stonewake.awakened, "Three wards lead to a separate watchstone objective")
	check(s.save_to("user://stonewake-mid.json"), "Mid-chapter progress saves")
	var loaded := State.new()
	check(loaded.load_from("user://stonewake-mid.json") and loaded.stonewake == s.stonewake, "Ward progress survives save/reload")
	world.atlas.start_quest("oldwatch_survey")
	world.atlas.record_event("inspect_forge")
	world.atlas.record_event("reach_crossing")
	p.position = story.RELIC + Vector3(0, 0.1, 1.5)
	world.interact_nearby()
	check(s.stonewake.awakened and story.visions.visible and story.text.text.contains("station"), "Relic reveals three destination echoes and changes world visuals")
	check(world.atlas.survey_complete(), "Story relic interaction also completes an active local survey")
	escape(p)
	p.position = story.KEEPER + Vector3(0, 0.1, 1.5)
	world.interact_nearby()
	var gold: int = s.gold
	var count: int = s.inventory.size()
	p.position += Vector3(0, 0, 10)
	story.action.pressed.emit()
	check(not s.stonewake.rewarded and s.gold == gold, "Remote dialogue cannot claim the reward")
	p.position = story.KEEPER + Vector3(0, 0.1, 1.5)
	story.action.pressed.emit()
	check(s.stonewake.rewarded and "stonewake" in s.story_completed and s.gold == gold + 100 and s.inventory.size() == count + 1, "Reporting to Ilyra completes the main chapter and grants its reward")
	var pendant := false
	for item: Dictionary in s.inventory.values():
		if item.custom_name == "Watchkeeper's Pendant": pendant = item.favorite and item.enchant == "insight"
	check(pendant and not story.reward(), "Named enchanted pendant is protected and reward cannot duplicate")
	check(not world.realms.can_enter("aeralis") and not world.realms.can_enter("crucible"), "First chapter never skips later destination prerequisites")
	escape(p)
	world.hud.world_map.selected_quest = "stonewake"
	world.hud.world_map._show_quest()
	check(world.hud.world_map.quest_text.text.contains("Stonewake complete") and world.hud.world_map.quest_action.disabled, "Journal reports completion without survey actions")
	check(s.save_to("user://stonewake-done.json") and loaded.load_from("user://stonewake-done.json") and loaded.stonewake.rewarded, "Completed chapter and story flag reload together")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://stonewake-done.json"))
	data.stonewake.wards = ["hearth", "hearth", "sky"]
	var f := FileAccess.open("user://stonewake-invalid.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data)); f.close()
	check(not loaded.load_from("user://stonewake-invalid.json") and loaded.stonewake.rewarded, "Invalid duplicate ward save is rejected before applying")
	data.erase("stonewake")
	f = FileAccess.open("user://stonewake-legacy.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(data)); f.close()
	check(loaded.load_from("user://stonewake-legacy.json") and not loaded.stonewake.accepted, "Earlier saves without the chapter record remain compatible")
	for path in ["mid", "done", "invalid", "legacy"]: DirAccess.remove_absolute("user://stonewake-" + path + ".json")
	world.queue_free(); await process_frame
	print("STONEWAKE_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
