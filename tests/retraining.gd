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
	check(not s.refund_perk("fake") and not s.refund_perk("heavy_hand") and s.perk_points() == 0, "Unknown and unlearned perks cannot mint points")
	for skill in s.Skills.NAMES: s.train(skill, 400)
	var xp = s.skills.xp.duplicate(true)
	var gold: int = s.gold
	var initial_points: int = s.perk_points()
	for id in s.Skills.PERKS: s.learn_perk(id)
	var spent: int = initial_points - s.perk_points()
	check(spent == 12, "Full current build spends twelve points")
	var damage: int = s.stats().damage
	check(s.refund_perk("heavy_hand") and s.stats().damage < damage, "Refund immediately removes melee bonus")
	check(not s.refund_perk("heavy_hand"), "Repeated refund cannot duplicate points")
	var before: int = s.perk_points()
	check(s.refund_perk("clear_channel") and s.perk_points() == before + 2 and s.spell_cost(20) == 20, "Two-point refund restores full price and removes spell discount")
	for id in s.skills.perks.duplicate(): s.refund_perk(id)
	check(s.perk_points() == initial_points and s.skills.perks.is_empty(), "All spent points can be recovered exactly")
	check(s.skills.xp == xp and s.gold == gold, "Retraining preserves XP, skill levels and gold")
	check(s.learn_perk("artisan") and s.learn_perk("careful_tempering"), "Returned points can fund a crafting build")
	for material in s.crafting.materials: s.materials[material.id] = 100
	var recipe: Dictionary = s.crafting.recipes.filter(func(x): return x.output_kind == "gear")[0]
	s.blueprints.append(recipe.unlock)
	check(s.craft_recipe(recipe.id, recipe.station).begins_with("Created"), "Artisan crafting succeeds before refund")
	var inventory = s.inventory.duplicate(true)
	var materials = s.materials.duplicate(true)
	s.refund_perk("artisan"); s.refund_perk("careful_tempering")
	check(s.inventory == inventory and s.materials == materials, "Existing crafted gear and materials survive perk refund unchanged")
	var quality_before: int = 0
	for item in s.inventory.values():
		if item.base_id == recipe.output and item.quality == 1: quality_before += 1
	s.craft_recipe(recipe.id, recipe.station)
	var quality_after: int = 0
	for item in s.inventory.values():
		if item.base_id == recipe.output and item.quality == 1: quality_after += 1
	check(quality_before > 0 and quality_after == quality_before, "Future crafts lose Artisan bonus while existing Fine equipment remains")
	check(s.save_to("user://retraining-test.json"), "Refunded character saves")
	var loaded = State.new()
	check(loaded.load_from("user://retraining-test.json") and loaded.skills == s.skills and loaded.inventory == s.inventory, "Refunds and owned equipment round-trip through save")
	var world = load("res://scenes/main.tscn").instantiate(); root.add_child(world)
	for i in range(4): await physics_frame
	var p = world.player; var menu = world.skills_menu
	p.character.train("melee", 400); p.character.learn_perk("heavy_hand")
	menu.open_menu(); menu.selected = "melee"; menu.refresh()
	var button = menu.rows.get_child(2)
	check(not button.disabled and button.text.begins_with("Refund"), "Learned perk exposes live refund button")
	var base = State.new()
	button.pressed.emit()
	check(not p.character.has_perk("heavy_hand") and p.derived.damage == base.stats().damage, "Live refund updates equipped combat stats immediately")
	check(p.paused and menu.visible and menu.rows.get_child(2).text.begins_with("Learn"), "Refund keeps menu open and enables relearning")
	menu.rows.get_child(2).pressed.emit()
	check(p.character.has_perk("heavy_hand"), "Same button can relearn refunded perk")
	menu.close_menu(); check(not p.paused, "Closing retraining resumes play")
	DirAccess.remove_absolute("user://retraining-test.json")
	world.queue_free(); await process_frame
	print("RETRAINING_COMPLETE checks=%d failures=%d" % [checks, failures]); quit(1 if failures else 0)
