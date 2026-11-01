extends SceneTree
const State = preload("res://scripts/character_state.gd")
const Trade = preload("res://scripts/trade.gd")
var failures := 0
var checks := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if ok: print("PASS " + text)
	else:
		failures += 1
		push_error("FAIL " + text)
func frames(n: int = 3) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	var s := State.new()
	var t := Trade.new(s)
	check(s.gold == 150 and s.shop_data.shops.size() == 5, "New character has a starting purse and five shop definitions")
	var price := t.quote(t.value("consumable", "healing_draught"), true)
	var message := t.buy("apothecary", "consumable:healing_draught", 2)
	check(message.begins_with("Bought") and s.gold == 150 - price * 2 and s.consumables.healing_draught == 2, "Buying deducts exact gold and grants exact potion quantity")
	check(t.merchant("apothecary").stock["consumable:healing_draught"] == 10 and t.merchant("apothecary").purse == 450 + price * 2, "Purchase updates persistent stock and merchant purse")
	var gold := s.gold
	var bag := s.consumables.duplicate()
	t.buy("apothecary", "consumable:healing_draught", 99)
	check(s.gold == gold and s.consumables == bag, "Insufficient stock has no transaction side effects")
	t.buy("apothecary", "material:ruby", 1)
	check(s.gold == gold and not s.materials.has("ruby"), "Insufficient gold has no transaction side effects")
	check(t.buy("apothecary", "unknown", 1) == "Invalid purchase." and t.buy("apothecary", "material:herb", -1) == "Invalid purchase.", "Invalid item and negative quantity rejected")
	var uid: String = s.equipment.main_hand
	check(t.sell("outfitter", "gear", uid, 1).contains("Unequip") and s.inventory.has(uid), "Equipped gear cannot be sold")
	uid = s.add_item("steel_sword", 2, "vigor")
	s.inventory[uid].gem = "ruby"
	s.personalize(uid, "The Keeper", true)
	check(t.sell("outfitter", "gear", uid, 1).contains("Unequip") and s.inventory.has(uid), "Favorite gear cannot be sold")
	s.personalize(uid, "The Keeper", false)
	var record: Dictionary = s.inventory[uid].duplicate(true)
	var sale_price := t.quote(t.gear_value(record), false)
	gold = s.gold
	check(t.sell("outfitter", "gear", uid, 1).begins_with("Sold") and s.gold == gold + sale_price and not s.inventory.has(uid), "Sale pays gold and transfers actual owned gear")
	check(t.merchant("outfitter").buyback[uid] == record, "Buyback retains name, quality, enchantment and gem")
	gold = s.gold
	check(t.sell("outfitter", "gear", uid, 1).contains("Unequip") and s.gold == gold, "Sold item cannot be sold a second time")
	s.gold = 5000
	check(t.buyback("outfitter", uid).begins_with("Bought back") and s.inventory[uid] == record and not t.merchant("outfitter").buyback.has(uid), "Buyback restores the same unique upgraded piece")
	gold = s.gold
	check(not t.buyback("outfitter", uid).begins_with("Bought back") and s.gold == gold, "Buyback cannot duplicate restored gear")
	var vendor: Dictionary = t.merchant("outfitter")
	vendor.purse = 0
	s.merchants.outfitter = vendor
	check(t.sell("outfitter", "gear", uid, 1).contains("enough gold") and s.inventory.has(uid), "Merchant cannot pay more gold than it owns")
	gold = s.gold
	var water: int = s.materials.water
	check(t.sell("provisions", "material", "water", 2).begins_with("Sold") and s.materials.water == water - 2 and s.gold > gold, "Material stacks can be sold in exact quantities")
	check(t.sell("outfitter", "consumable", "healing_draught", 1).contains("enough gold"), "Potion sale respects merchant funds")
	check(t.sell("provisions", "consumable", "healing_draught", 1).begins_with("Sold"), "Owned potions can be sold")
	check(t.buy("provisions", "consumable:healing_draught", 1).begins_with("Bought"), "Sold stacks become purchasable even outside original assortment")
	var buy_price := t.quote(100, true)
	var sell_price := t.quote(100, false)
	s.set_identity("Trader", "sunborn", "warrior", "balanced")
	for i in range(10): s.allocate("presence", 1)
	check(t.quote(100, true) < buy_price and t.quote(100, false) > sell_price and t.quote(100, true) > t.quote(100, false), "Presence improves both quotes without buy-sell arbitrage")
	var path := "res://build/shop-save-test.json"
	# Leave a record in buyback for persistence coverage.
	t.sell("provisions", "gear", uid, 1)
	check(s.save_to(path), "Gold and commerce save atomically with inventory")
	var restored := State.new()
	check(restored.load_from(path) and restored.gold == s.gold and restored.merchants == s.merchants and restored.inventory == s.inventory, "Gold, stock, purse and buyback survive save/load")
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	data.gold = -5
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data)); file.close()
	check(not restored.load_from(path) and restored.gold == s.gold, "Invalid gold rejected without partially loading save")
	data.erase("gold"); data.erase("merchants")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data)); file.close()
	check(restored.load_from(path) and restored.gold == 150 and restored.merchants.is_empty(), "Pre-shop saves migrate with one starting purse")
	DirAccess.remove_absolute(path)
	var world: Node3D = load("res://scenes/main.tscn").instantiate()
	root.add_child(world)
	await frames()
	var p: CharacterBody3D = world.player
	var ui: Node3D = world.shops
	# Walk into each shop from its front porch; the narrow apothecary doorway is included.
	for spot in [[-10.0, -1.5, -7.0], [6.0, 11.0, 6.0], [1.0, -36.0, -43.8]]:
		p.position = Vector3(spot[0], 0.3, spot[1])
		p.velocity = Vector3.ZERO
		p.rotation = Vector3.ZERO
		await frames()
		Input.action_press("move_forward")
		await frames(95 if spot[0] != 1.0 else 130)
		Input.action_release("move_forward")
		await frames()
		check(absf(p.position.z - spot[2]) < 2.3, "Player can walk through shop porch and doorway at x=" + str(spot[0]))
		world.interact_nearby()
		await frames()
		check(p.shop_open and p.paused and ui.panel.visible and not world.hud.pause_panel.visible, "E opens reachable shop without stacked overlays")
		ui.close()
	p.position = Vector3(6, 0.3, 6)
	p.velocity = Vector3.ZERO
	await frames()
	# Doorway E routing is checked above; isolate purchase UI from nearby quest hooks.
	ui.open("apothecary")
	ui.selected = "consumable:not_in_this_shop"
	ui.show_detail()
	check(ui.action.disabled, "Stale unavailable shop selection is safely disabled")
	ui.selected = "consumable:healing_draught"
	ui.quantity.value = 1
	ui.show_detail()
	ui.action.pressed.emit()
	check(p.character.consumables.get("healing_draught", 0) == 1, "Actual purchase button grants a potion")
	gold = p.character.gold
	p.position = Vector3(0, 0.2, 17)
	ui.action.pressed.emit()
	check(p.character.gold == gold, "Trade action rechecks merchant proximity")
	var key := InputEventKey.new()
	key.pressed = true
	key.physical_keycode = KEY_I
	p._unhandled_input(key)
	check(not p.shop_open and p.workshop_open, "I switches shop to inventory without stacking")
	key.physical_keycode = KEY_ESCAPE
	p._unhandled_input(key)
	check(not p.paused, "Escape resumes world after shopping")
	world.queue_free()
	await process_frame
	print("SHOPS_COMPLETE checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
