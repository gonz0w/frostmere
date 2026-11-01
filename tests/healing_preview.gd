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
	var w = load("res://scenes/main.tscn").instantiate(); root.add_child(w)
	w.capture_done = true
	for i in range(8): await physics_frame
	var p = w.player; var s = p.character; var ui = w.hud.workshop
	p.set_physics_process(false); p.set_process_unhandled_input(false)
	check(not s.persist and not w.atlas.persist, "Isolated healing fixture")
	for boosted in [false, true]:
		s.equip(s.add_item("groveheart_chest" if boosted else "leather_chest"), "chest")
		for id in ["healing_draught", "trail_bread", "magicka_draught", "stamina_draught", "hearty_stew"]:
			var food: Dictionary = s.definition("consumables", id)
			var expected: float = float(food.restore) * (1.25 if boosted and food.pool == "health" else 1.0)
			s.consumables[id] = 3; p.set(food.pool, 0.0)
			var preview: Dictionary = s.consumable_preview(id, p)
			check(is_equal_approx(preview.restore, expected), "Equipment-aware capacity: " + id + str(boosted))
			check(s.consumables[id] == 3 and p.get(food.pool) == 0, "Preview spends nothing")
			check(s.consume(id, p).begins_with("Used") and is_equal_approx(p.get(food.pool), expected) and s.consumables[id] == 2, "Real use matches preview")
			p.set(food.pool, float(p.derived[food.pool]) - 7.25)
			preview = s.consumable_preview(id, p)
			check(is_equal_approx(preview.actual, 7.25) and is_equal_approx(preview.unused, expected - 7.25), "Fractional missing resource caps restoration")
			check("Restored 7.25" in s.consume(id, p) and p.get(food.pool) == p.derived[food.pool], "Feedback reports actual capped restoration")
			check("item kept" in s.consume(id, p) and s.consumables[id] == 1, "Full pool keeps item")
	check(s.consumable_preview("missing_item", p).is_empty() and s.consume("missing_item", p) == "None in your bag.", "Unknown item rejected")
	p.health = float(p.derived.health) - 20; s.consumables.healing_draught = 2
	ui.open(); ui.mode = "Consumables"; ui.tabs.select(ui.MODES.find("Consumables")); ui.selected = "healing_draught"; ui.refresh()
	check("62.5 health" in ui.detail.text and "25% armor bonus" in ui.detail.text and "Use now: +20.0 health" in ui.detail.text and "Unused restoration: 42.5" in ui.detail.text, "Inventory shows bonus, actual healing and waste")
	if "--capture" in OS.get_cmdline_user_args():
		for i in range(5): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/healing-preview.png")
	for child in ui.actions.get_children():
		if child is Button and child.text == "Use Healing Draught" and not child.is_queued_for_deletion(): child.pressed.emit(); break
	check(s.consumables.healing_draught == 1 and p.health == p.derived.health, "Inventory button consumes one and heals")
	check("Use now: +0.0 health" in ui.detail.text, "Inventory refreshes after use")
	var disabled := false
	for child in ui.actions.get_children():
		if child is Button and child.text == "Use Healing Draught" and not child.is_queued_for_deletion(): disabled = child.disabled
	check(disabled, "Full-health use button disabled")
	check(s.save_to("user://healing-preview.json"), "Consumed inventory saves")
	var loaded = State.new()
	check(loaded.load_from("user://healing-preview.json") and loaded.consumables.healing_draught == 1 and loaded.item_at("chest").effect == "healing_bonus", "Used inventory and healing equipment reload")
	s.consumables.healing_draught = 0; p.health = 1
	check(s.consume("healing_draught", p) == "None in your bag." and p.health == 1, "Empty bag cannot heal")
	w.queue_free(); await process_frame
	print("HEALING_PREVIEW_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
